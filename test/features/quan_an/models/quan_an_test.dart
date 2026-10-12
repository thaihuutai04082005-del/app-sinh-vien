import 'package:app_sinh_vien/features/quan_an/models/gio_mo_cua.dart';
import 'package:app_sinh_vien/features/quan_an/models/khuyen_mai.dart';
import 'package:app_sinh_vien/features/quan_an/models/mon_an.dart';
import 'package:app_sinh_vien/features/quan_an/models/quan_an.dart';
import 'package:app_sinh_vien/features/quan_an/models/quan_an_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime g(int ngay, [int gio = 12]) =>
    DateTime.utc(2026, 10, ngay, gio).subtract(const Duration(hours: 7));

QuanAn quan({
  String loai = 'ho_kinh_doanh',
  num? p25,
  num? p75,
  CaiDatDatMon datMon = const CaiDatDatMon(bat: true, denLay: true),
  bool tamNgung = false,
  DateTime? tamNgungDen,
  DateTime? tamNghiDen,
  bool khoaBan = false,
}) => QuanAn(
  id: 'q',
  chuQuanId: 'c',
  ten: 'Quán',
  loaiQuan: loai,
  datMon: datMon,
  tamNgungNhanDon: tamNgung,
  tamNgungDen: tamNgungDen,
  tamNghiDen: tamNghiDen,
  khoaBan: khoaBan,
  trangThai: 'active',
  gioMoCua: {
    for (var d = 1; d <= 7; d++) d: [const CaMoCua(tu: 360, den: 1320)],
  },
  soLieu: SoLieuQuan(giaP25: p25, giaP75: p75),
);

void main() {
  group('QuanAnConfig', () {
    test('mặc định đúng bảng 3.16', () {
      const c = QuanAnConfig();
      expect(c.monToiThieuHienThi, 3);
      expect(c.sapDongPhut, 30);
      expect(c.mocGia, [20000, 35000, 50000]);
      expect(c.chipGiaReDen, 35000);
      expect(c.checkInMet, 100);
      expect(c.giuBanPhut, 15);
      expect(c.quanChamPhut, 30);
      expect(c.giaoLauPhut, 60);
      expect(c.quaHanPhut, 360);
      expect(c.tienMatDuoi, 200000);
      expect(c.khuyenMaiToiDa('ho_kinh_doanh'), 5);
      expect(c.khuyenMaiToiDa('ban_le'), 1);
      expect(c.banKinhMet, [300, 500, 1000, 2000, 3000, 5000]);
    });

    test('fromMap ghi đè số có mặt, còn lại giữ mặc định', () {
      final c = QuanAnConfig.fromMap({
        'giuBanPhut': 1,
        'mocGia': [10000, 20000],
        'sapDongPhut': 5,
        'giaoLauPhut': 'hỏng',
      });
      expect(c.giuBanPhut, 1);
      expect(c.mocGia, [10000, 20000]);
      expect(c.sapDongPhut, 5);
      expect(c.giaoLauPhut, 60);
      expect(c.quanChamPhut, 30);
    });

    test('nhãn đủ cho mọi mã trong hợp đồng', () {
      expect(trangThaiDonLabels, hasLength(16));
      expect(trangThaiBanLabels, hasLength(8));
      expect(trangThaiQuanLabels, hasLength(7));
      expect(loaiMonLabels, hasLength(11));
      expect(tienIchLabels, hasLength(7));
      expect(lyDoKhieuNaiDonLabels, hasLength(5));
      expect(loaiKhuyenMaiLabels, hasLength(5));
      expect(trangThaiTienLabels, hasLength(7));
      expect(
        lyDoBaoCaoLabels.keys,
        containsAll(['mat_ve_sinh', 'chuyen_khoan_ngoai_app']),
      );
      expect(trangThaiBanLabels['no_show'], 'Khách không đến');
      expect(trangThaiDonLabels['delivered'], 'Chờ xác nhận nhận món');
    });
  });

  group('QuanAn', () {
    test('giá hiển thị từ P25–P75', () {
      expect(quan(p25: 25000, p75: 40000).giaHienThi, '25–40k');
      expect(quan(p25: 30000, p75: 30000).giaHienThi, '30k');
      expect(quan(p25: 25000).giaHienThi, '—');
      expect(quan().giaHienThi, '—');
      expect(quan(p25: 900000, p75: 1500000).giaHienThi, '900k–1,5tr');
    });

    test('huy hiệu theo loại quán', () {
      expect(quan().daXacThucLabel, 'Đã xác thực kinh doanh');
      expect(quan(loai: 'ban_le').daXacThucLabel, 'Đã xác thực chủ quán');
    });

    test('nhận đặt món: chỉ hộ kinh doanh đã bật và có cách nhận', () {
      expect(quan().nhanDatMon, isTrue);
      expect(quan(loai: 'ban_le').nhanDatMon, isFalse);
      expect(quan(datMon: const CaiDatDatMon(bat: false)).nhanDatMon, isFalse);
      expect(
        quan(datMon: const CaiDatDatMon(bat: true, denLay: false)).nhanDatMon,
        isFalse,
      );
    });

    test(
      'đặt món được ngay lúc này: đang mở, chưa tạm ngưng / nghỉ / khóa bán',
      () {
        final luc = g(13);
        expect(quan().datMonDuocLuc(luc), isTrue);
        expect(quan(tamNgung: true).datMonDuocLuc(luc), isFalse);
        expect(quan(tamNgungDen: g(13, 23)).datMonDuocLuc(luc), isFalse);
        expect(quan(tamNgungDen: g(12, 23)).datMonDuocLuc(luc), isTrue);
        expect(quan(tamNghiDen: g(15, 0)).datMonDuocLuc(luc), isFalse);
        expect(quan(khoaBan: true).datMonDuocLuc(luc), isFalse);
      },
    );

    test('fromMap đọc lịch, cài đặt đặt món, số liệu', () {
      final q = QuanAn.fromMap('q1', {
        'chuQuanId': 'c',
        'ten': 'Cơm tấm Cô Ba',
        'loaiQuan': 'ho_kinh_doanh',
        'loaiMon': ['com', 'an_vat'],
        'viTri': const GeoPoint(10, 105),
        'gioMoCua': {
          '1': [
            {'tu': 360, 'den': 600},
          ],
          '7': <dynamic>[],
        },
        'tamNghiDen': Timestamp.fromDate(g(15)),
        'phucVu': {'anTaiQuan': true, 'mangDi': true},
        'datMon': {
          'bat': true,
          'denLay': true,
          'giaoTanNoi': true,
          'banKinhKm': 2.5,
          'phiGiaoKieu': 'theo_km',
          'phiMoiKm': 5000,
          'donToiThieu': 50000,
          'chuanBiPhut': 20,
          'tienMat': true,
        },
        'banChinhSua': {'loai': 'sua', 'ten': 'Tên mới'},
        'khaiSaiLoai': {
          'lyDo': ['may_lanh'],
        },
        'trangThai': 'active',
        'soLieu': {
          'soMon': 12,
          'giaP25': 25000,
          'giaTrungVi': 30000,
          'giaP75': 40000,
          'diemTong': 4.4,
          'soDanhGia': 8,
          'diemTieuChi': {'monAn': 4.6, 'giaCa': 4.7},
          'hayAn': true,
          'coKhuyenMai': true,
        },
      });
      expect(q.loaiMonLabel, 'Cơm · Ăn vặt');
      expect(q.gioMoCua[1]!.single.tu, 360);
      expect(q.phucVu.mangDi, isTrue);
      expect(q.datMon.theoKm, isTrue);
      expect(q.datMon.phiGiaoMoTa, 'Phí giao 5.000đ/km');
      expect(q.datMon.banKinhKm, 2.5);
      expect(q.coBanChinhSua, isTrue);
      expect(q.khaiSaiLoai!.lyDo, ['may_lanh']);
      expect(q.soLieu.coDiemXacMinh, isTrue);
      expect(q.soLieu.diemTieuChi['monAn'], 4.6);
      expect(q.giaHienThi, '25–40k');
      expect(q.nhanHuyHieu, [
        '🏷 Khuyến mãi',
        '🛵 Đặt món',
        '🔥 Sinh viên hay ăn',
      ]);
    });

    test(
      'bản nháp ghi ra đủ trường chủ quán sửa, ảnh bìa = ảnh mặt tiền đầu',
      () {
        const q = QuanAn(
          id: '',
          chuQuanId: 'c',
          ten: 'A',
          anhMatTien: ['u1', 'u2'],
          datMon: CaiDatDatMon(bat: true),
        );
        final m = q.toDraftMap();
        expect(m['anhBia'], 'u1');
        expect(m['datMon'], isA<Map>());
        expect(m['gioMoCua'], isA<Map>());
        expect(m.containsKey('trangThai'), isFalse);
        expect(m.containsKey('soLieu'), isFalse);
      },
    );

    test('CaiDatDatMon toMap / fromMap', () {
      const c = CaiDatDatMon(
        bat: true,
        giaoTanNoi: true,
        banKinhKm: 3,
        phiGiao: 10000,
        donToiThieu: 40000,
        tienMat: true,
      );
      final lai = CaiDatDatMon.fromMap(c.toMap());
      expect(lai.toMap(), c.toMap());
      expect(c.phiGiaoMoTa, 'Phí giao 10.000đ');
      expect(const CaiDatDatMon().phiGiaoMoTa, 'Miễn phí giao');
    });
  });

  group('MonAn', () {
    const mon = MonAn(
      id: 'm',
      quanId: 'q',
      nhomId: 'n',
      ten: 'Phở',
      gia: 40000,
      tuyChon: [
        NhomTuyChon(
          ten: 'Cỡ',
          batBuoc: true,
          lua: [
            LuaChon(ten: 'Nhỏ'),
            LuaChon(ten: 'Lớn', giaThem: 5000),
          ],
        ),
        NhomTuyChon(
          ten: 'Topping',
          toiDa: 2,
          lua: [
            LuaChon(ten: 'Trứng', giaThem: 5000),
            LuaChon(ten: 'Bò viên', giaThem: 10000),
            LuaChon(ten: 'Hành'),
          ],
        ),
      ],
    );

    test('kiểm tra tùy chọn bắt buộc / tối đa / không tồn tại', () {
      expect(
        mon.kiemTraTuyChon({
          'Cỡ': ['Lớn'],
        }),
        isNull,
      );
      expect(mon.kiemTraTuyChon({}), 'Vui lòng chọn "Cỡ".');
      expect(
        mon.kiemTraTuyChon({
          'Cỡ': ['Lớn', 'Nhỏ'],
        }),
        '"Cỡ" chỉ chọn được 1.',
      );
      expect(
        mon.kiemTraTuyChon({
          'Cỡ': ['Nhỏ'],
          'Topping': ['Trứng', 'Hành', 'Bò viên'],
        }),
        '"Topping" chọn tối đa 2.',
      );
      expect(
        mon.kiemTraTuyChon({
          'Cỡ': ['Siêu lớn'],
        }),
        contains('không còn'),
      );
    });

    test('toApiMap đúng tham số luuMon, fromMap đọc lại', () {
      final api = mon.toApiMap();
      expect(api['quanId'], 'q');
      expect(api['monId'], 'm');
      expect(api.containsKey('laDoUong'), isFalse);
      final lai = MonAn.fromMap('m', {...api, 'laDoUong': true});
      expect(lai.tuyChon.first.lua.last.giaThem, 5000);
      expect(lai.tuyChon[1].chonNhieu, isTrue);
      expect(lai.laDoUong, isTrue);
      expect(mon.coTuyChonBatBuoc, isTrue);
    });
  });

  group('KhuyenMai', () {
    test('mô tả ngắn các loại', () {
      const pt = KhuyenMai(
        id: 'a',
        quanId: 'q',
        loai: 'giam_phan_tram',
        tieuDe: 't',
        phanTram: 10,
        giamToiDa: 20000,
        donToiThieu: 50000,
      );
      expect(pt.moTaNgan, 'Giảm 10% tối đa 20k cho đơn từ 50k');
      const tien = KhuyenMai(
        id: 'b',
        quanId: 'q',
        loai: 'giam_tien',
        tieuDe: 't',
        giamTien: 15000,
        donToiThieu: 80000,
      );
      expect(tien.moTaNgan, 'Giảm 15k cho đơn từ 80k');
      const combo = KhuyenMai(
        id: 'c',
        quanId: 'q',
        loai: 'combo',
        tieuDe: 'Cơm + nước',
        combo: ComboKm(
          mon: [
            MonCombo(monId: 'a'),
            MonCombo(monId: 'b'),
          ],
          gia: 35000,
        ),
      );
      expect(combo.moTaNgan, 'Combo 2 món chỉ 35k');
      const vang = KhuyenMai(
        id: 'd',
        quanId: 'q',
        loai: 'gio_vang',
        tieuDe: 't',
        gioVang: GioVangKm(
          tu: 840,
          den: 960,
          ngay: [1, 2, 3, 4, 5],
          phanTram: 20,
        ),
      );
      expect(vang.moTaNgan, 'Giờ vàng 14:00–16:00 T2–T6 giảm 20%');
      const sv = KhuyenMai(
        id: 'e',
        quanId: 'q',
        loai: 'sinh_vien',
        tieuDe: 't',
        giamTien: 5000,
      );
      expect(sv.moTaNgan, 'Ưu đãi sinh viên: giảm 5k');
    });

    test('còn hiệu lực: đang chạy và trong khoảng ngày', () {
      final km = KhuyenMai(
        id: 'a',
        quanId: 'q',
        loai: 'giam_tien',
        tieuDe: 't',
        batDau: g(10),
        ketThuc: g(20),
      );
      expect(km.conHieuLuc(g(9)), isFalse);
      expect(km.conHieuLuc(g(10)), isTrue);
      expect(km.conHieuLuc(g(20)), isTrue);
      expect(km.conHieuLuc(g(21)), isFalse);
      final dung = KhuyenMai(
        id: 'a',
        quanId: 'q',
        loai: 'giam_tien',
        tieuDe: 't',
        trangThai: 'dung',
      );
      expect(dung.conHieuLuc(g(12)), isFalse);
    });
  });
}
