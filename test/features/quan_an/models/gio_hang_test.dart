import 'package:app_sinh_vien/features/quan_an/models/gio_hang.dart';
import 'package:app_sinh_vien/features/quan_an/services/gio_hang_service.dart';
import 'package:flutter_test/flutter_test.dart';

DongGioHang pho({
  int sl = 1,
  List<TuyChonDaChon> tc = const [],
  String ghiChu = '',
}) => DongGioHang(
  monId: 'pho',
  ten: 'Phở bò',
  gia: 40000,
  soLuong: sl,
  tuyChon: tc,
  ghiChu: ghiChu,
);

const lon = TuyChonDaChon(nhom: 'Cỡ', ten: 'Lớn', giaThem: 5000);
const trung = TuyChonDaChon(nhom: 'Topping', ten: 'Trứng', giaThem: 5000);

DongGioHang tra() => const DongGioHang(monId: 'tra', ten: 'Trà đá', gia: 5000);

void main() {
  group('DongGioHang', () {
    test(
      'đơn giá = giá món + giá cộng thêm của tùy chọn; thành tiền × số lượng',
      () {
        final d = pho(sl: 2, tc: [lon, trung]);
        expect(d.donGia, 50000);
        expect(d.thanhTien, 100000);
      },
    );

    test(
      'khóa không phụ thuộc thứ tự tùy chọn; khác ghi chú thì khác khóa',
      () {
        expect(pho(tc: [lon, trung]).khoa, pho(tc: [trung, lon]).khoa);
        expect(pho().khoa, isNot(pho(ghiChu: 'ít hành').khoa));
        expect(pho(tc: [lon]).khoa, isNot(pho().khoa));
      },
    );
  });

  group('GioHang', () {
    test('giỏ rỗng', () {
      expect(GioHang.rong.laRong, isTrue);
      expect(GioHang.rong.soMon, 0);
      expect(GioHang.rong.tamTinh, 0);
      expect(GioHang.rong.toApiItems(), isEmpty);
    });

    test('thêm cùng món + tùy chọn thì gộp số lượng', () {
      var g = GioHang.rong.them(pho(), quanId: 'q1', tenQuan: 'Phở A');
      g = g.them(pho(sl: 2), quanId: 'q1', tenQuan: 'Phở A');
      expect(g.dong, hasLength(1));
      expect(g.dong.single.soLuong, 3);
      expect(g.soMon, 3);
      expect(g.quanId, 'q1');
      expect(g.tenQuan, 'Phở A');
    });

    test('cùng món khác tùy chọn thì tách dòng; tạm tính cộng đủ', () {
      var g = GioHang.rong.them(pho(), quanId: 'q1', tenQuan: 'A');
      g = g.them(
        pho(tc: [lon]),
        quanId: 'q1',
        tenQuan: 'A',
      );
      g = g.them(tra(), quanId: 'q1', tenQuan: 'A');
      expect(g.dong, hasLength(3));
      expect(g.soMon, 3);
      // 40k + 45k + 5k, KHÔNG trừ khuyến mãi, KHÔNG gồm phí giao.
      expect(g.tamTinh, 90000);
      expect(g.soLuongMon('pho'), 2);
    });

    test('chỉ chứa món của 1 quán: khacQuan báo, them ném lỗi', () {
      final g = GioHang.rong.them(pho(), quanId: 'q1', tenQuan: 'A');
      expect(g.khacQuan('q1'), isFalse);
      expect(g.khacQuan('q2'), isTrue);
      expect(GioHang.rong.khacQuan('q2'), isFalse);
      expect(() => g.them(tra(), quanId: 'q2', tenQuan: 'B'), throwsStateError);
      final moi = GioHang.moi('q2', 'B', tra());
      expect(moi.quanId, 'q2');
      expect(moi.dong.single.monId, 'tra');
    });

    test('bớt: giảm 1 phần, về 0 thì xóa dòng, hết dòng thì giỏ rỗng', () {
      var g = GioHang.rong.them(pho(sl: 2), quanId: 'q1', tenQuan: 'A');
      g = g.boBot(pho().khoa);
      expect(g.dong.single.soLuong, 1);
      g = g.boBot(pho().khoa);
      expect(g.laRong, isTrue);
      expect(g.quanId, '');
    });

    test('xóa dòng theo khóa; bớt khóa không có thì không đổi', () {
      var g = GioHang.rong.them(pho(), quanId: 'q1', tenQuan: 'A');
      g = g.them(tra(), quanId: 'q1', tenQuan: 'A');
      expect(g.boBot('khong-co').dong, hasLength(2));
      g = g.xoa(pho().khoa);
      expect(g.dong.single.monId, 'tra');
      expect(g.xoa(tra().khoa).laRong, isTrue);
    });

    test('toApiItems đúng tham số items của baoGiaDon: không gửi giá', () {
      final g = GioHang.rong.them(
        pho(sl: 2, tc: [lon, trung], ghiChu: ' ít hành '),
        quanId: 'q1',
        tenQuan: 'A',
      );
      expect(g.toApiItems(), [
        {
          'monId': 'pho',
          'soLuong': 2,
          'tuyChon': [
            {'nhom': 'Cỡ', 'lua': 'Lớn'},
            {'nhom': 'Topping', 'lua': 'Trứng'},
          ],
          'ghiChu': 'ít hành',
        },
      ]);
    });

    test('toJson / fromJson giữ nguyên; dữ liệu hỏng thành giỏ rỗng', () {
      final g = GioHang.rong
          .them(
            pho(sl: 2, tc: [lon]),
            quanId: 'q1',
            tenQuan: 'A',
          )
          .them(tra(), quanId: 'q1', tenQuan: 'A');
      final lai = GioHang.fromJson(g.toJson());
      expect(lai.quanId, 'q1');
      expect(lai.dong, hasLength(2));
      expect(lai.tamTinh, g.tamTinh);
      expect(lai.dong.first.tuyChon.single, lon);
      expect(GioHang.fromJson('hỏng').laRong, isTrue);
      expect(GioHang.fromJson({'quanId': '', 'dong': []}).laRong, isTrue);
    });
  });

  group('GioHangService', () {
    test('thêm món cùng quán', () {
      final s = GioHangService(luuBoNho: false);
      var dem = 0;
      s.addListener(() => dem++);
      final kq = s.them(quanId: 'q1', tenQuan: 'A', dong: pho());
      expect(kq, KetQuaThemGio.daThem);
      expect(s.gio.soMon, 1);
      expect(dem, 1);
    });

    test(
      'món quán khác: needConfirm, giỏ cũ giữ nguyên; đồng ý thì thay giỏ',
      () {
        final s = GioHangService(luuBoNho: false);
        s.them(quanId: 'q1', tenQuan: 'A', dong: pho());
        final kq = s.them(quanId: 'q2', tenQuan: 'B', dong: tra());
        expect(kq, KetQuaThemGio.needConfirm);
        expect(s.gio.quanId, 'q1');
        expect(s.choXacNhan!.quanId, 'q2');
        s.xacNhanDoiQuan();
        expect(s.gio.quanId, 'q2');
        expect(s.gio.dong.single.monId, 'tra');
        expect(s.choXacNhan, isNull);
      },
    );

    test('từ chối đổi quán: giữ giỏ cũ', () {
      final s = GioHangService(luuBoNho: false);
      s.them(quanId: 'q1', tenQuan: 'A', dong: pho());
      s.them(quanId: 'q2', tenQuan: 'B', dong: tra());
      s.huyDoiQuan();
      expect(s.gio.quanId, 'q1');
      expect(s.choXacNhan, isNull);
    });

    test('bớt, thêm một phần, xóa dòng, xóa hết', () {
      final s = GioHangService(luuBoNho: false);
      s.them(quanId: 'q1', tenQuan: 'A', dong: pho());
      s.themMotPhan(pho().khoa);
      expect(s.gio.soMon, 2);
      s.boBot(pho().khoa);
      expect(s.gio.soMon, 1);
      s.them(quanId: 'q1', tenQuan: 'A', dong: tra());
      s.xoaDong(pho().khoa);
      expect(s.gio.dong.single.monId, 'tra');
      s.xoaHet();
      expect(s.gio.laRong, isTrue);
    });
  });
}
