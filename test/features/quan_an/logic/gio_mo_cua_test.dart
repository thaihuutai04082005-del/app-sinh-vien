import 'package:app_sinh_vien/features/quan_an/models/gio_mo_cua.dart';
import 'package:flutter_test/flutter_test.dart';

/// Thời điểm thật ứng với giờ Việt Nam (UTC+7) đã cho.
DateTime vn(int y, int m, int d, [int gio = 0, int phut = 0]) =>
    DateTime.utc(y, m, d, gio, phut).subtract(const Duration(hours: 7));

int h(int gio, [int phut = 0]) => gio * 60 + phut;

/// Tuần mẫu: mọi ngày 2 ca 6:00–10:00 và 16:00–21:00, trừ Thứ ba chỉ có ca sáng.
LichMoCua tuanMau() => {
  for (var d = 1; d <= 7; d++)
    d: d == 2
        ? [CaMoCua(tu: h(6), den: h(10))]
        : [CaMoCua(tu: h(6), den: h(10)), CaMoCua(tu: h(16), den: h(21))],
};

void main() {
  // 12/10/2026 là Thứ hai.
  test('ngày mẫu: 12/10/2026 là Thứ hai', () {
    expect(DateTime.utc(2026, 10, 12).weekday, DateTime.monday);
  });

  group('2 ca trong ngày', () {
    final lich = tuanMau();

    test('trong ca sáng: đang mở, đóng lúc 10:00', () {
      final t = tinhMoCua(lich, vn(2026, 10, 12, 7));
      expect(t.trangThai, TrangThaiMoCua.mo);
      expect(t.thongDiep, 'Đang mở · Đóng lúc 10:00');
      expect(t.dongLuc, vn(2026, 10, 12, 10));
      expect(
        gioDongCuaCaDangMo(lich, vn(2026, 10, 12, 7)),
        vn(2026, 10, 12, 10),
      );
    });

    test('giữa hai ca: đóng, mở lại lúc 16:00 hôm nay', () {
      final t = tinhMoCua(lich, vn(2026, 10, 12, 11));
      expect(t.trangThai, TrangThaiMoCua.dong);
      expect(t.thongDiep, 'Mở lúc 16:00 hôm nay');
      expect(t.moLuc, vn(2026, 10, 12, 16));
    });

    test('ca chiều: mở rồi sắp đóng khi còn đúng 30 phút', () {
      expect(trangThaiMoCua(lich, vn(2026, 10, 12, 20, 29)), TrangThaiMoCua.mo);
      final t = tinhMoCua(lich, vn(2026, 10, 12, 20, 30));
      expect(t.trangThai, TrangThaiMoCua.sapDong);
      expect(t.thongDiep, 'Sắp đóng · 21:00');
      expect(
        trangThaiMoCua(lich, vn(2026, 10, 12, 20, 59)),
        TrangThaiMoCua.sapDong,
      );
    });

    test('ngưỡng sắp đóng đổi được qua tham số', () {
      expect(
        trangThaiMoCua(lich, vn(2026, 10, 12, 20, 15), sapDongPhut: 10),
        TrangThaiMoCua.mo,
      );
      expect(
        trangThaiMoCua(lich, vn(2026, 10, 12, 20, 15), sapDongPhut: 45),
        TrangThaiMoCua.sapDong,
      );
    });

    test('đúng giờ đóng cửa là đã đóng; đúng giờ mở là mở', () {
      expect(trangThaiMoCua(lich, vn(2026, 10, 12, 21)), TrangThaiMoCua.dong);
      expect(trangThaiMoCua(lich, vn(2026, 10, 12, 6)), TrangThaiMoCua.mo);
      expect(
        trangThaiMoCua(lich, vn(2026, 10, 12, 5, 59)),
        TrangThaiMoCua.dong,
      );
    });

    test('tối: mở lúc 6:00 sáng mai (Thứ ba có ca sáng)', () {
      final t = tinhMoCua(lich, vn(2026, 10, 12, 22));
      expect(t.trangThai, TrangThaiMoCua.dong);
      expect(t.thongDiep, 'Mở lúc 6:00 sáng mai');
    });

    test('Thứ ba sau ca sáng: ngày mai (Thứ tư) mở 6:00 sáng', () {
      final t = tinhMoCua(lich, vn(2026, 10, 13, 12));
      expect(t.thongDiep, 'Mở lúc 6:00 sáng mai');
    });

    test('caKeTiep là ca bắt đầu sau thời điểm hiện tại', () {
      final k = caKeTiep(lich, vn(2026, 10, 12, 11))!;
      expect(k.tu, vn(2026, 10, 12, 16));
      expect(k.den, vn(2026, 10, 12, 21));
      // Đang trong ca thì ca kế tiếp là ca sau.
      expect(caKeTiep(lich, vn(2026, 10, 12, 7))!.tu, vn(2026, 10, 12, 16));
    });
  });

  group('ca qua nửa đêm 18:00–02:00 (thuộc ngày bắt đầu)', () {
    // Chỉ Thứ sáu (5) có ca 18:00–02:00.
    final lich = <int, List<CaMoCua>>{
      5: [CaMoCua(tu: h(18), den: h(2))],
    };

    test('CaMoCua nhận biết qua nửa đêm', () {
      expect(lich[5]!.single.quaNuaDem, isTrue);
    });

    test('Thứ sáu 17:00 chưa mở, mở lúc 18:00 hôm nay', () {
      // 16/10/2026 là Thứ sáu.
      expect(DateTime.utc(2026, 10, 16).weekday, DateTime.friday);
      final t = tinhMoCua(lich, vn(2026, 10, 16, 17));
      expect(t.trangThai, TrangThaiMoCua.dong);
      expect(t.thongDiep, 'Mở lúc 18:00 hôm nay');
    });

    test('Thứ sáu 23:00: đang mở, đóng lúc 2:00', () {
      final t = tinhMoCua(lich, vn(2026, 10, 16, 23));
      expect(t.trangThai, TrangThaiMoCua.mo);
      expect(t.thongDiep, 'Đang mở · Đóng lúc 2:00');
    });

    test('01:00 sáng Thứ bảy vẫn mở dù Thứ bảy không có ca', () {
      final t = tinhMoCua(lich, vn(2026, 10, 17, 1));
      expect(t.trangThai, TrangThaiMoCua.mo);
      expect(t.dongLuc, vn(2026, 10, 17, 2));
    });

    test('01:30 sáng Thứ bảy: sắp đóng (còn 30 phút)', () {
      expect(
        trangThaiMoCua(lich, vn(2026, 10, 17, 1, 30)),
        TrangThaiMoCua.sapDong,
      );
    });

    test('02:00 sáng Thứ bảy: đã đóng, mở lại Thứ sáu tuần sau', () {
      final t = tinhMoCua(lich, vn(2026, 10, 17, 2));
      expect(t.trangThai, TrangThaiMoCua.dong);
      expect(t.thongDiep, 'Mở lúc 18:00 Thứ sáu');
    });

    test('Thứ sáu 01:00 sáng (ca của Thứ năm không có) vẫn đóng', () {
      expect(trangThaiMoCua(lich, vn(2026, 10, 16, 1)), TrangThaiMoCua.dong);
    });
  });

  group('tạm nghỉ', () {
    final lich = tuanMau();

    test(
      'tạm nghỉ đến ngày: hiện "Tạm nghỉ đến …", kể cả khi đang trong giờ mở',
      () {
        final t = tinhMoCua(
          lich,
          vn(2026, 10, 12, 7),
          tamNghiDen: vn(2026, 10, 15),
        );
        expect(t.trangThai, TrangThaiMoCua.tamNghi);
        expect(t.thongDiep, 'Tạm nghỉ đến 15/10/2026');
        expect(t.moLuc, vn(2026, 10, 15));
      },
    );

    test('tạm nghỉ có giờ cụ thể thì hiện cả giờ', () {
      final t = tinhMoCua(
        lich,
        vn(2026, 10, 12, 18),
        tamNghiDen: vn(2026, 10, 13, 6),
      );
      expect(t.thongDiep, 'Tạm nghỉ đến 06:00 13/10/2026');
    });

    test('tới đúng ngày hẹn thì tự mở lại theo lịch', () {
      final den = vn(2026, 10, 15);
      expect(
        trangThaiMoCua(lich, vn(2026, 10, 14, 23, 59), tamNghiDen: den),
        TrangThaiMoCua.tamNghi,
      );
      expect(
        trangThaiMoCua(lich, vn(2026, 10, 15, 7), tamNghiDen: den),
        TrangThaiMoCua.mo,
      );
      expect(
        trangThaiMoCua(lich, vn(2026, 10, 15, 12), tamNghiDen: den),
        TrangThaiMoCua.dong,
      );
    });

    test(
      '"Tạm nghỉ hôm nay" hết hiệu lực ở ca mở kế tiếp tính từ ngày mai',
      () {
        // Thứ hai 12/10 bấm nghỉ: mở lại lúc 6:00 Thứ ba 13/10 dù hôm nay còn ca chiều.
        expect(
          moLaiSauTamNghiHomNay(lich, vn(2026, 10, 12, 9)),
          vn(2026, 10, 13, 6),
        );
        // Thứ ba có lịch chỉ ca sáng, mai Thứ tư mở 6:00.
        expect(
          moLaiSauTamNghiHomNay(lich, vn(2026, 10, 13, 9)),
          vn(2026, 10, 14, 6),
        );
      },
    );

    test(
      'Tạm nghỉ hôm nay lúc 1:00 sáng sau ca đêm tính từ ngày mai (lịch)',
      () {
        final dem = <int, List<CaMoCua>>{
          for (var d = 1; d <= 7; d++) d: [CaMoCua(tu: h(18), den: h(2))],
        };
        expect(
          moLaiSauTamNghiHomNay(dem, vn(2026, 10, 12, 1)),
          vn(2026, 10, 13, 18),
        );
      },
    );
  });

  group('lịch đặc biệt', () {
    test('lịch trống: luôn đóng, chưa có giờ mở', () {
      final t = tinhMoCua(const {}, vn(2026, 10, 12, 12));
      expect(t.trangThai, TrangThaiMoCua.dong);
      expect(t.thongDiep, 'Chưa có giờ mở cửa');
      expect(caDangMo(const {}, vn(2026, 10, 12, 12)), isNull);
      expect(caKeTiep(const {}, vn(2026, 10, 12, 12)), isNull);
    });

    test('hai ca liền nhau được gộp: đóng lúc 14:00', () {
      final lich = <int, List<CaMoCua>>{
        1: [CaMoCua(tu: h(6), den: h(10)), CaMoCua(tu: h(10), den: h(14))],
      };
      expect(
        gioDongCuaCaDangMo(lich, vn(2026, 10, 12, 8)),
        vn(2026, 10, 12, 14),
      );
    });

    test('chỉ mở Thứ năm: từ Thứ hai thấy "Mở lúc 6:00 Thứ năm"', () {
      final lich = <int, List<CaMoCua>>{
        4: [CaMoCua(tu: h(6), den: h(10))],
      };
      expect(thongDiepMoCua(lich, vn(2026, 10, 12, 12)), 'Mở lúc 6:00 Thứ năm');
    });

    test('đọc / ghi lịch từ Map của Firestore, bỏ qua phần tử hỏng', () {
      final lich = lichTuMap({
        '1': [
          {'tu': 360, 'den': 600},
          {'tu': 'x'},
        ],
        '5': [
          {'tu': 1080, 'den': 120},
        ],
        '9': [
          {'tu': 1, 'den': 2},
        ],
      });
      expect(lich[1], [CaMoCua(tu: 360, den: 600)]);
      expect(lich[5]!.single.quaNuaDem, isTrue);
      expect(lich.containsKey(9), isFalse);
      final ra = lichToMap(lich);
      expect(ra.keys, ['1', '2', '3', '4', '5', '6', '7']);
      expect(ra['2'], isEmpty);
      expect(lichTuMap(ra), {
        1: lich[1],
        2: <CaMoCua>[],
        3: <CaMoCua>[],
        4: <CaMoCua>[],
        5: lich[5],
        6: <CaMoCua>[],
        7: <CaMoCua>[],
      });
    });

    test('tomTatNgay và phutHienThi', () {
      expect(
        tomTatNgay([
          CaMoCua(tu: h(6), den: h(10)),
          CaMoCua(tu: h(16), den: h(21, 30)),
        ]),
        '6:00–10:00 · 16:00–21:30',
      );
      expect(tomTatNgay(const []), 'Nghỉ');
      expect(phutHienThi(h(2)), '2:00');
    });

    test(
      'múi giờ máy không ảnh hưởng: UTC và giờ địa phương cho cùng kết quả',
      () {
        final lich = tuanMau();
        final utc = vn(2026, 10, 12, 7);
        final local = DateTime.fromMillisecondsSinceEpoch(
          utc.millisecondsSinceEpoch,
        );
        expect(
          tinhMoCua(lich, local).thongDiep,
          tinhMoCua(lich, utc).thongDiep,
        );
      },
    );
  });
}
