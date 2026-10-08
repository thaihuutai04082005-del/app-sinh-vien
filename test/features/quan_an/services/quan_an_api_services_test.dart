import 'package:app_sinh_vien/features/quan_an/models/gio_hang.dart';
import 'package:app_sinh_vien/features/quan_an/services/admin_quan_an_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/dat_ban_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/don_mon_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/menu_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/quan_an_api.dart';
import 'package:app_sinh_vien/features/quan_an/services/quan_an_service.dart';
import 'package:app_sinh_vien/features/quan_an/models/nhom_mon.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ghi lại lời gọi API và trả kết quả đặt trước.
class ApiGia implements QuanAnApi {
  final goi_ = <(String, Map<String, dynamic>)>[];
  final Map<String, Map<String, dynamic>> tra = {};

  @override
  Future<Map<String, dynamic>> goi(
    String hanhDong, [
    Map<String, dynamic> thamSo = const {},
  ]) async {
    goi_.add((hanhDong, thamSo));
    return tra[hanhDong] ?? {'ok': true};
  }
}

void main() {
  late ApiGia api;
  setUp(() => api = ApiGia());

  final gio = GioHang.rong.them(
    const DongGioHang(
      monId: 'm1',
      ten: 'Phở',
      gia: 40000,
      soLuong: 2,
      tuyChon: [TuyChonDaChon(nhom: 'Cỡ', ten: 'Lớn', giaThem: 5000)],
    ),
    quanId: 'q1',
    tenQuan: 'A',
  );

  group('DonMonService', () {
    test(
      'baoGia gửi đúng tham số baoGiaDon, không gửi giá, đọc kết quả',
      () async {
        api.tra['baoGiaDon'] = {
          'ok': true,
          'monAn': [
            {
              'monId': 'm1',
              'ten': 'Phở',
              'gia': 40000,
              'soLuong': 2,
              'thanhTien': 90000,
            },
          ],
          'tienMon': 90000,
          'giamCombo': 0,
          'giamGia': 9000,
          'khuyenMaiApDung': [
            {
              'id': 'k',
              'tieuDe': 'Giảm 10%',
              'loai': 'giam_phan_tram',
              'giam': 9000,
            },
          ],
          'phiGiao': 10000,
          'tong': 91000,
          'gioDuKienSanSang': 1760000000000,
          'tienMatDuocKhong': true,
        };
        final dv = FirebaseDonMonService(api: api);
        final bg = await dv.baoGia(
          quanId: 'q1',
          items: gio.toApiItems(),
          cachNhan: 'giao',
          diaChi: const DiaChiDat(lat: 10, lng: 105, dong: '12 Nguyễn Huệ'),
          gio: 'hen',
          gioHen: DateTime.fromMillisecondsSinceEpoch(1760000000000),
        );
        final (hd, tham) = api.goi_.single;
        expect(hd, 'baoGiaDon');
        expect(tham['quanId'], 'q1');
        expect(tham['cachNhan'], 'giao');
        expect(tham['diaChi'], {
          'lat': 10.0,
          'lng': 105.0,
          'dong': '12 Nguyễn Huệ',
        });
        expect(tham['gio'], {'loai': 'hen', 'hen': 1760000000000});
        expect((tham['items'] as List).single['tuyChon'], [
          {'nhom': 'Cỡ', 'lua': 'Lớn'},
        ]);
        expect(tham.containsKey('tong'), isFalse);
        expect(bg.ok, isTrue);
        expect(bg.tong, 91000);
        expect(bg.tongGiam, 9000);
        expect(bg.khuyenMaiApDung.single.tieuDe, 'Giảm 10%');
        expect(bg.tienMatDuocKhong, isTrue);
        expect(bg.gioDuKienSanSang!.millisecondsSinceEpoch, 1760000000000);
      },
    );

    test('baoGia không đặt được: ok=false kèm mã và thông điệp', () async {
      api.tra['baoGiaDon'] = {
        'ok': false,
        'ma': 'mon_het',
        'thongDiep': 'Món "Phở" đã hết.',
      };
      final bg = await FirebaseDonMonService(api: api)
          .baoGia(quanId: 'q1', items: gio.toApiItems(), cachNhan: 'den_lay');
      expect(bg.ok, isFalse);
      expect(bg.ma, 'mon_het');
      expect(bg.thongDiep, 'Món "Phở" đã hết.');
      expect(api.goi_.single.$2.containsKey('diaChi'), isFalse);
      expect(api.goi_.single.$2['gio'], {'loai': 'asap'});
    });

    test(
      'datMon thêm cachTra, sdtNhan, ghiChuQuan, tongDaThay; xử lý giaDoi',
      () async {
        api.tra['datMon'] = {'ok': false, 'giaDoi': true, 'tong': 95000};
        final kq = await FirebaseDonMonService(api: api).datMon(
          quanId: 'q1',
          items: gio.toApiItems(),
          cachNhan: 'den_lay',
          cachTra: 'app',
          sdtNhan: '0901234567',
          ghiChuQuan: 'ít cay',
          tongDaThay: 91000,
        );
        final tham = api.goi_.single.$2;
        expect(api.goi_.single.$1, 'datMon');
        expect(tham['cachTra'], 'app');
        expect(tham['sdtNhan'], '0901234567');
        expect(tham['ghiChuQuan'], 'ít cay');
        expect(tham['tongDaThay'], 91000);
        expect(kq.ok, isFalse);
        expect(kq.giaDoi, isTrue);
        expect(kq.tong, 95000);
        expect(kq.donId, isNull);
      },
    );

    test('datMon thành công trả donId', () async {
      api.tra['datMon'] = {'ok': true, 'donId': 'd9'};
      final kq = await FirebaseDonMonService(api: api).datMon(
        quanId: 'q1',
        items: gio.toApiItems(),
        cachNhan: 'den_lay',
        cachTra: 'tien_mat',
        sdtNhan: '0901234567',
        tongDaThay: 90000,
      );
      expect(kq.ok, isTrue);
      expect(kq.donId, 'd9');
    });

    test('thaoTac, xuLyHan, thanhToan dùng đúng hành động hợp đồng', () async {
      final dv = FirebaseDonMonService(api: api);
      await dv.thaoTac('d1', 3, {'loai': 'QUAN_NHAN', 'chuanBiPhut': 15});
      await dv.xuLyHan('d1');
      await dv.thanhToan('d1', 'thanh_cong');
      expect(api.goi_[0].$1, 'thaoTacDon');
      expect(api.goi_[0].$2, {
        'donId': 'd1',
        'version': 3,
        'su': {'loai': 'QUAN_NHAN', 'chuanBiPhut': 15},
      });
      expect(api.goi_[1].$1, 'xuLyHanDon');
      expect(api.goi_[1].$2, {'donId': 'd1'});
      expect(api.goi_[2].$1, 'thanhToanGiaLap');
      expect(api.goi_[2].$2, {'donId': 'd1', 'ketQua': 'thanh_cong'});
    });

    test('xemPhien trả PhienThanhToan, null nếu không có phiên', () async {
      final dv = FirebaseDonMonService(api: api);
      api.tra['xemPhienThanhToan'] = {
        'soTien': 91000,
        'trangThai': 'cho_tra',
        'tenQuan': 'A',
      };
      final p = await dv.xemPhien('d1');
      expect(p!.donId, 'd1');
      expect(p.soTien, 91000);
      api.tra['xemPhienThanhToan'] = {'ok': true};
      expect(await dv.xemPhien('d1'), isNull);
    });

    test(
      'cauHinh dựng QuanAnConfig từ server, lỗi thì dùng mặc định',
      () async {
        api.tra['cauHinh'] = {'giuBanPhut': 5};
        final dv = FirebaseDonMonService(api: api);
        expect((await dv.cauHinh()).giuBanPhut, 5);
        expect((await dv.cauHinh()).giuBanPhut, 5);
        expect(api.goi_.where((c) => c.$1 == 'cauHinh'), hasLength(1));
      },
    );

    test('thongTinSinhVien đọc khóa và số lần bom hàng', () async {
      api.tra['thongTinSinhVien'] = {
        'khoa': {'khoaDatMonAppDen': 1760000000000},
        'soLanBomHang': 2,
        'coTienMat': false,
      };
      final t = await FirebaseDonMonService(api: api).thongTinSinhVien();
      expect(t.soLanBomHang, 2);
      expect(t.coTienMat, isFalse);
      expect(
        t.datMonAppBiKhoa(DateTime.fromMillisecondsSinceEpoch(1759999999000)),
        isTrue,
      );
      expect(
        t.datMonAppBiKhoa(DateTime.fromMillisecondsSinceEpoch(1760000001000)),
        isFalse,
      );
      expect(t.datMonBiKhoa(DateTime.now()), isFalse);
    });
  });

  group('DatBanService', () {
    test(
      'gửi đặt bàn đổi giờ ra mili giây; thao tác dùng thaoTacBan',
      () async {
        api.tra['datBan'] = {'ok': true, 'banId': 'b7'};
        final dv = FirebaseDatBanService(api: api);
        final id = await dv.guiDatBan(
          quanId: 'q1',
          gio: DateTime.fromMillisecondsSinceEpoch(1760000000000),
          soNguoi: 4,
          ghiChu: 'gần cửa sổ',
        );
        expect(id, 'b7');
        expect(api.goi_.single.$2, {
          'quanId': 'q1',
          'gio': 1760000000000,
          'soNguoi': 4,
          'ghiChu': 'gần cửa sổ',
        });
        await dv.thaoTac('b7', 2, 'QUAN_XAC_NHAN');
        await dv.xuLyHan('b7');
        expect(api.goi_[1].$1, 'thaoTacBan');
        expect(api.goi_[1].$2, {
          'banId': 'b7',
          'version': 2,
          'loai': 'QUAN_XAC_NHAN',
        });
        expect(api.goi_[2].$1, 'xuLyHanBan');
        expect(api.goi_[2].$2, {'banId': 'b7'});
      },
    );
  });

  group('QuanAnService, MenuService', () {
    test('thaoTac trả kết quả server (tạm nghỉ cần xác nhận)', () async {
      api.tra['tamNghi'] = {
        'ok': true,
        'canXacNhan': true,
        'donAnhHuong': 2,
        'banAnhHuong': 1,
      };
      final r = await FirebaseQuanAnService(
        api: api,
        uid: 'u',
      ).thaoTac('tamNghi', {'quanId': 'q1', 'kieu': 'hom_nay'});
      expect(r['canXacNhan'], isTrue);
      expect(r['donAnhHuong'], 2);
    });

    test('layGiayTo đọc giấy tờ', () async {
      api.tra['layGiayToQuan'] = {
        'maSoThue': '0123456789',
        'anhGiayChungNhan': ['u1'],
      };
      final g = await FirebaseQuanAnService(api: api, uid: 'u').layGiayTo('q1');
      expect(g.maSoThue, '0123456789');
      expect(g.anhGiayChungNhan, ['u1']);
      expect(g.anhAttp, isEmpty);
    });

    test('menu ghi qua API với tham số đúng hợp đồng', () async {
      api.tra['luuNhomMon'] = {'ok': true, 'nhomId': 'n1'};
      final menu = FirebaseMenuService(api: api, uid: 'u');
      final id = await menu.luuNhomMon(
        const NhomMon(
          id: '',
          quanId: 'q1',
          ten: 'Đồ uống',
          laDoUong: true,
          thuTu: 2,
        ),
      );
      expect(id, 'n1');
      expect(api.goi_.single.$2, {
        'quanId': 'q1',
        'ten': 'Đồ uống',
        'laDoUong': true,
        'thuTu': 2,
      });
      await menu.batTatMon('m1', conHang: false);
      await menu.xoaMon('m1');
      await menu.xoaNhomMon('n1');
      expect(api.goi_[1].$1, 'batTatMon');
      expect(api.goi_[1].$2, {'monId': 'm1', 'conHang': false});
      expect(api.goi_[2].$1, 'xoaMon');
      expect(api.goi_[2].$2, {'monId': 'm1'});
      expect(api.goi_[3].$1, 'xoaNhomMon');
      expect(api.goi_[3].$2, {'nhomId': 'n1'});
    });
  });

  group('AdminQuanAnService', () {
    test('các hàm gọi đúng hành động admin', () async {
      final ad = FirebaseAdminQuanAnService(api: api);
      await ad.duyet(loai: 'quan', id: 'q1', dongY: true, daDoiChieuMst: true);
      await ad.duyet(
        loai: 'chinh_sua',
        id: 'q1',
        dongY: false,
        lyDo: 'Địa chỉ không khớp',
      );
      await ad.yeuCauChuyenLoai('q1', 'lý do');
      await ad.anHien('q1', an: true, lyDo: 'x');
      await ad.dinhChi('q1', dinhChi: true, lyDo: 'x');
      await ad.khoaBan('q1', 'x');
      await ad.luaDao('q1', 'x');
      await ad.thaoTacDon('d1', 4, {
        'loai': 'ADMIN_QUYET',
        'quyetDinh': 'hoan_toan',
        'lyDo': 'x',
      });
      expect(api.goi_.map((c) => c.$1), [
        'adminDuyet',
        'adminDuyet',
        'adminYeuCauChuyenLoai',
        'adminAnHien',
        'adminDinhChi',
        'adminKhoaBan',
        'adminLuaDao',
        'thaoTacDon',
      ]);
      expect(api.goi_[0].$2, {
        'loai': 'quan',
        'id': 'q1',
        'dongY': true,
        'daDoiChieuMst': true,
      });
      expect(api.goi_[1].$2.containsKey('daDoiChieuMst'), isFalse);
      expect(api.goi_[4].$2['dinhChi'], isTrue);
      expect(api.goi_[7].$2['su']['loai'], 'ADMIN_QUYET');
    });

    test('khóa chức năng gửi uid hoặc sdt, hạn bằng mili giây', () async {
      final ad = FirebaseAdminQuanAnService(api: api);
      await ad.khoaChucNang(
        sdt: '0901234567',
        chucNang: 'khoaDatBanDen',
        den: DateTime.fromMillisecondsSinceEpoch(1760000000000),
        lyDo: 'x',
      );
      expect(api.goi_.single.$2, {
        'sdt': '0901234567',
        'chucNang': 'khoaDatBanDen',
        'den': 1760000000000,
        'lyDo': 'x',
      });
    });

    test('hàng chờ sắp: cờ khẩn → khiếu nại tiền / báo cáo ưu tiên → hồ sơ gắn cờ → còn lại theo thời gian', () {
      ViecAdminQuan v(String id, int uuTien, int phut) => ViecAdminQuan(
        loai: 'quan',
        id: id,
        tieuDe: id,
        moTa: '',
        luc: DateTime(2026, 10, 13, 12, phut),
        uuTien: uuTien,
      );
      final ds = sapXepHangCho([
        v('thuong_muon', 3, 50),
        v('co_khan', 0, 40),
        v('thuong_som', 3, 10),
        v('gan_co', 2, 5),
        v('tien', 1, 30),
      ]);
      expect(
        [for (final x in ds) x.id],
        ['co_khan', 'tien', 'gan_co', 'thuong_som', 'thuong_muon'],
      );
      expect(ds.first.loaiLabel, 'Quán chờ duyệt');
    });
  });
}
