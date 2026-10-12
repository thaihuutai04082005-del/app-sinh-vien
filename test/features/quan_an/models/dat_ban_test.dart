import 'package:app_sinh_vien/features/quan_an/models/dat_ban.dart';
import 'package:app_sinh_vien/features/quan_an/models/quan_an_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

const cfg = QuanAnConfig();

/// Giờ Việt Nam 13/10/2026.
DateTime g(int gio, [int phut = 0, int giay = 0]) => DateTime.utc(
  2026,
  10,
  13,
  gio,
  phut,
  giay,
).subtract(const Duration(hours: 7));

/// Bàn hẹn 19:00, giữ bàn tới 19:15.
DatBan ban(
  String status, {
  DateTime? hanXacNhan,
  String? ghiNhanDen,
  DateTime? hanGiuBan,
  DateTime? hanTuDong,
}) => DatBan(
  id: 'b1',
  status: status,
  version: 2,
  quanId: 'q',
  chuQuanId: 'c',
  svId: 's',
  gio: g(19),
  soNguoi: 4,
  hanXacNhan: hanXacNhan,
  hanGiuBan: hanGiuBan,
  hanTuDong: hanTuDong,
  ghiNhanDen: ghiNhanDen,
);

void main() {
  group('quán xác nhận / từ chối', () {
    final b = ban('pending', hanXacNhan: g(15, 30));
    test('trong hạn thì được; quá hạn thì không', () {
      expect(b.coQuanXacNhan(g(15, 30)), isTrue);
      expect(b.coQuanTuChoi(g(15)), isTrue);
      expect(b.coQuanXacNhan(g(15, 30, 1)), isFalse);
    });
    test('chỉ khi đang chờ', () {
      expect(ban('confirmed', hanXacNhan: g(23)).coQuanXacNhan(g(12)), isFalse);
      expect(ban('rejected', hanXacNhan: g(23)).coQuanXacNhan(g(12)), isFalse);
    });
  });

  group('giữ bàn 15 phút và "Khách không đến"', () {
    final b = ban('confirmed');

    test('hết giữ bàn = giờ hẹn + 15 phút (từ cấu hình)', () {
      expect(b.hetGiuBan(cfg), g(19, 15));
      expect(b.hetGiuBan(const QuanAnConfig(giuBanPhut: 20)), g(19, 20));
      expect(ban('confirmed', hanGiuBan: g(19, 10)).hetGiuBan(cfg), g(19, 10));
    });

    test('trước 15 phút: nút mờ kèm giải thích; đúng 15 phút: bấm được', () {
      final som = b.quanKhachKhongDen(g(19, 14, 59), cfg);
      expect(som.hien, isTrue);
      expect(som.bam, isFalse);
      expect(som.giaiThich, contains('15 phút'));
      expect(b.coQuanKhongDen(g(19, 15), cfg), isTrue);
      expect(b.coQuanKhongDen(g(21), cfg), isTrue);
    });

    test('sinh viên đã check-in hợp lệ thì vô hiệu, dù quá giờ giữ bàn', () {
      final k = ban('confirmed', ghiNhanDen: 'check_in');
      final n = k.quanKhachKhongDen(g(20), cfg);
      expect(n.bam, isFalse);
      expect(n.giaiThich, 'Khách đã check-in tại quán.');
      expect(k.daCheckIn, isTrue);
    });

    test('quán bấm "Khách đã đến" rồi vẫn bấm "không đến" được sau giờ giữ bàn (chỉ để quản lý)', () {
      // ghiNhanDen 'quan' không chặn: chỉ check-in hợp lệ mới chặn.
      expect(
        ban('confirmed', ghiNhanDen: 'quan').coQuanKhongDen(g(20), cfg),
        isTrue,
      );
    });

    test('trạng thái khác confirmed thì không có nút', () {
      for (final s in ['pending', 'arrived', 'no_show', 'cancelled_student']) {
        expect(ban(s).quanKhachKhongDen(g(20), cfg).hien, isFalse, reason: s);
      }
    });

    test('"Khách đã đến" khi đã xác nhận và chưa ghi nhận', () {
      expect(b.coQuanKhachDen, isTrue);
      expect(ban('confirmed', ghiNhanDen: 'check_in').coQuanKhachDen, isFalse);
      expect(ban('pending').coQuanKhachDen, isFalse);
    });
  });

  group('hủy', () {
    test('quán hủy bàn đã xác nhận tới hết giờ giữ bàn', () {
      final b = ban('confirmed');
      expect(b.coQuanHuy(g(18), cfg), isTrue);
      expect(b.coQuanHuy(g(19, 15), cfg), isTrue);
      expect(b.coQuanHuy(g(19, 16), cfg), isFalse);
      expect(ban('pending').coQuanHuy(g(18), cfg), isFalse);
    });

    test(
      'sinh viên hủy: khi chờ quán hoặc bàn đã xác nhận còn trong giờ giữ bàn',
      () {
        expect(ban('pending').coSvHuy(g(18, 59), cfg), isTrue);
        expect(ban('confirmed').coSvHuy(g(19, 15), cfg), isTrue);
        expect(ban('confirmed').coSvHuy(g(19, 16), cfg), isFalse);
        expect(ban('rejected').coSvHuy(g(15), cfg), isFalse);
      },
    );

    test('hủy sát giờ (dưới 1 giờ) bàn ĐÃ xác nhận mới bị tính bỏ hẹn', () {
      final b = ban('confirmed');
      expect(b.huyBiTinhBoHen(g(17, 59), cfg), isFalse); // còn 61 phút
      expect(b.huyBiTinhBoHen(g(18), cfg), isFalse); // đúng 60 phút
      expect(b.huyBiTinhBoHen(g(18, 0, 1), cfg), isTrue);
      expect(b.huyBiTinhBoHen(g(19, 10), cfg), isTrue);
    });

    test('hủy khi quán chưa xác nhận không phạt, dù sát giờ', () {
      expect(ban('pending').huyBiTinhBoHen(g(18, 50), cfg), isFalse);
    });

    test('mốc hủy sát giờ lấy từ cấu hình', () {
      const c = QuanAnConfig(huySatGioPhut: 120);
      expect(ban('confirmed').huyBiTinhBoHen(g(17, 30), c), isTrue);
    });
  });

  group('check-in của sinh viên', () {
    test('chỉ bấm được trong giờ giữ bàn (giờ hẹn tới giờ hẹn + 15 phút)', () {
      final b = ban('confirmed');
      expect(b.coSvCheckIn(g(18, 59), cfg), isFalse);
      expect(b.coSvCheckIn(g(19), cfg), isTrue);
      expect(b.coSvCheckIn(g(19, 15), cfg), isTrue);
      expect(b.coSvCheckIn(g(19, 16), cfg), isFalse);
    });

    test('đã ghi nhận đến hoặc chưa xác nhận thì không', () {
      expect(
        ban('confirmed', ghiNhanDen: 'check_in').coSvCheckIn(g(19, 5), cfg),
        isFalse,
      );
      expect(ban('pending').coSvCheckIn(g(19, 5), cfg), isFalse);
    });
  });

  group('mốc đếm ngược', () {
    test('chờ quán, trước giờ hẹn, đang giữ bàn, chờ tự đóng', () {
      expect(
        ban('pending', hanXacNhan: g(15)).mocDemNguoc(g(14), cfg)!.$2,
        g(15),
      );
      final c = ban('confirmed');
      expect(c.mocDemNguoc(g(18), cfg)!.$2, g(19));
      expect(c.mocDemNguoc(g(19, 5), cfg)!.$1, 'Giữ bàn đến');
      final tuDong = c.mocDemNguoc(g(20), cfg)!;
      expect(tuDong.$1, 'Tự đóng lúc');
      // hết giờ giữ bàn + 24 giờ.
      expect(tuDong.$2, g(19, 15).add(const Duration(hours: 24)));
      expect(ban('arrived').mocDemNguoc(g(20), cfg), isNull);
    });
  });

  test('fromMap', () {
    final b = DatBan.fromMap('x', {
      'status': 'confirmed',
      'version': 3,
      'quanId': 'q',
      'chuQuanId': 'c',
      'svId': 's',
      'gio': Timestamp.fromDate(g(19)),
      'soNguoi': 6,
      'hanXacNhan': Timestamp.fromDate(g(15)),
      'hanGiuBan': Timestamp.fromDate(g(19, 15)),
      'ghiNhanDen': 'check_in',
      'lichSu': [
        {'status': 'confirmed', 'luc': Timestamp.fromDate(g(15))},
      ],
    });
    expect(b.soNguoi, 6);
    expect(b.daCheckIn, isTrue);
    expect(b.trangThaiLabel, 'Đã xác nhận');
    expect(b.dangChay, isTrue);
    expect(b.lichSu, hasLength(1));
  });
}
