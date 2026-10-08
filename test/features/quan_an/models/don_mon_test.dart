import 'package:app_sinh_vien/features/quan_an/models/don_mon.dart';
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

DonMon don(
  String status, {
  String cachNhan = 'den_lay',
  String cachTra = 'app',
  String gio = 'asap',
  DateTime? gioHen,
  DateTime? hanThanhToan,
  DateTime? hanQuanNhan,
  DateTime? gioDuKienSanSang,
  DateTime? moHuyChamLuc,
  DateTime? sanSangLuc,
  DateTime? batDauGiaoLuc,
  DateTime? tNhanMonDuKien,
  DateTime? maNhanMonDaNhapLuc,
  AnhGiao? anhGiao,
  DateTime? bangChungLuc,
  DateTime? hanKhieuNai,
  KhongNhan? khongNhan,
  KhieuNaiDon? khieuNai,
  DateTime? danhGiaHan,
  bool coQuaHan = false,
}) => DonMon(
  id: 'd1',
  status: status,
  version: 3,
  quanId: 'q',
  chuQuanId: 'c',
  svId: 's',
  cachNhan: cachNhan,
  cachTra: cachTra,
  gio: gio,
  gioHen: gioHen,
  hanThanhToan: hanThanhToan,
  hanQuanNhan: hanQuanNhan,
  gioDuKienSanSang: gioDuKienSanSang,
  moHuyChamLuc: moHuyChamLuc,
  sanSangLuc: sanSangLuc,
  batDauGiaoLuc: batDauGiaoLuc,
  tNhanMonDuKien: tNhanMonDuKien,
  maNhanMonDaNhapLuc: maNhanMonDaNhapLuc,
  anhGiao: anhGiao,
  bangChungLuc: bangChungLuc,
  hanKhieuNai: hanKhieuNai,
  khongNhan: khongNhan,
  khieuNai: khieuNai,
  danhGiaHan: danhGiaHan,
  coQuaHan: coQuaHan,
);

void main() {
  group('thanh toán, sinh viên hủy', () {
    test('thanh toán: đơn trả trên app, trong hạn chờ', () {
      final d = don('pending_payment', hanThanhToan: g(14));
      expect(d.coThanhToan(g(13, 59)), isTrue);
      expect(d.coThanhToan(g(14)), isTrue);
      expect(d.coThanhToan(g(14, 0, 1)), isFalse);
      expect(don('placed', hanThanhToan: g(14)).coThanhToan(g(13)), isFalse);
      expect(
        don('pending_payment', cachTra: 'tien_mat').coThanhToan(g(13)),
        isFalse,
      );
    });

    test('sinh viên chỉ hủy khi quán CHƯA nhận', () {
      expect(don('placed').coHuy, isTrue);
      for (final s in [
        'accepted',
        'ready',
        'delivering',
        'delivered',
        'completed',
      ]) {
        expect(don(s).coHuy, isFalse, reason: s);
      }
    });
  });

  group('Hủy vì quán chậm (giờ dự kiến sẵn sàng + 30 phút)', () {
    final du = g(17, 30);
    final d = don('accepted', gioDuKienSanSang: du, moHuyChamLuc: g(18));

    test('trước mốc: chưa; đúng mốc +30 phút: bấm được', () {
      expect(d.coHuyQuanCham(g(17, 59, 59)), isFalse);
      expect(d.coHuyQuanCham(g(18)), isTrue);
      expect(d.coHuyQuanCham(g(20)), isTrue);
    });

    test('quán đã báo Sẵn sàng / Đang giao thì không còn', () {
      for (final s in ['ready', 'delivering', 'placed']) {
        expect(
          don(
            s,
            gioDuKienSanSang: du,
            moHuyChamLuc: g(18),
          ).coHuyQuanCham(g(19)),
          isFalse,
          reason: s,
        );
      }
    });

    test('thiếu moHuyChamLuc thì tính từ giờ dự kiến + cấu hình', () {
      final k = don('accepted', gioDuKienSanSang: du);
      expect(k.coHuyQuanCham(g(17, 59)), isFalse);
      expect(k.coHuyQuanCham(g(18)), isTrue);
      expect(
        k.coHuyQuanCham(g(18), cfg: const QuanAnConfig(quanChamPhut: 45)),
        isFalse,
      );
      expect(
        k.coHuyQuanCham(g(18, 15), cfg: const QuanAnConfig(quanChamPhut: 45)),
        isTrue,
      );
    });

    test('đơn hẹn giờ: giờ dự kiến = giờ hẹn', () {
      final hen = don(
        'accepted',
        gio: 'hen',
        gioHen: g(19),
        gioDuKienSanSang: g(19),
      );
      expect(hen.gioDuKien, g(19));
      expect(hen.coHuyQuanCham(g(19, 29)), isFalse);
      expect(hen.coHuyQuanCham(g(19, 30)), isTrue);
    });

    test('chưa có mốc nào thì không hủy được', () {
      expect(don('accepted').coHuyQuanCham(g(23)), isFalse);
    });
  });

  group('"Chưa nhận được món" — đến lấy (T_lấy)', () {
    final t = g(18);
    final d = don('ready', tNhanMonDuKien: t, sanSangLuc: g(17, 30));

    test('quán xong sớm: 17:30–17:59 nút hiện nhưng MỜ kèm giải thích', () {
      for (final luc in [g(17, 30), g(17, 59), g(17, 59, 59)]) {
        final n = d.chuaNhanMon(luc, cfg);
        expect(n.hien, isTrue);
        expect(n.bam, isFalse);
        expect(
          n.giaiThich,
          'Bạn có thể báo chưa nhận được món từ thời điểm nhận món dự kiến.',
        );
        expect(d.coChuaNhanMon(luc, cfg), isFalse);
      }
    });

    test('từ T_lấy bấm được, không cần chờ thêm', () {
      final n = d.chuaNhanMon(g(18), cfg);
      expect(n.hien && n.bam, isTrue);
      expect(n.giaiThich, isNull);
      expect(d.coChuaNhanMon(g(18, 0, 1), cfg), isTrue);
      expect(d.coChuaNhanMon(g(23), cfg), isTrue);
    });

    test('đơn tiền mặt đến lấy: cùng quy tắc', () {
      final k = don('ready', cachTra: 'tien_mat', tNhanMonDuKien: t);
      expect(k.coChuaNhanMon(g(17, 59), cfg), isFalse);
      expect(k.coChuaNhanMon(g(18), cfg), isTrue);
    });

    test(
      'quán đã báo khách không nhận thì ẩn (sinh viên dùng nút Phản đối)',
      () {
        final k = don(
          'ready',
          tNhanMonDuKien: t,
          khongNhan: KhongNhan(luc: g(18, 40), hanPhanDoi: g(18, 40)),
        );
        expect(k.chuaNhanMon(g(19), cfg).hien, isFalse);
      },
    );

    test('trạng thái khác (chờ quán, đang chuẩn bị) không có nút', () {
      for (final s in [
        'placed',
        'accepted',
        'completed',
        'cancelled_restaurant',
      ]) {
        expect(
          don(s, tNhanMonDuKien: t).chuaNhanMon(g(19), cfg).hien,
          isFalse,
          reason: s,
        );
      }
    });
  });

  group('"Chưa nhận được món" — giao tận nơi', () {
    final d = don('delivering', cachNhan: 'giao', batDauGiaoLuc: g(17));

    test('Đang giao quá 60 phút mới bấm được', () {
      final som = d.chuaNhanMon(g(17, 59), cfg);
      expect(som.hien, isTrue);
      expect(som.bam, isFalse);
      expect(som.giaiThich, contains('60 phút'));
      expect(d.coChuaNhanMon(g(18), cfg), isTrue);
    });

    test('giới hạn lấy từ cấu hình', () {
      const c = QuanAnConfig(giaoLauPhut: 30);
      expect(d.coChuaNhanMon(g(17, 29), c), isFalse);
      expect(d.coChuaNhanMon(g(17, 30), c), isTrue);
    });

    test(
      'đã có ảnh giao (delivered): bấm được trong 24 giờ, hết hạn thì ẩn',
      () {
        final k = don(
          'delivered',
          cachNhan: 'giao',
          bangChungLuc: g(17),
          hanKhieuNai: g(17).add(const Duration(hours: 24)),
        );
        expect(k.coChuaNhanMon(g(18), cfg), isTrue);
        expect(
          k.coChuaNhanMon(g(17).add(const Duration(hours: 24)), cfg),
          isTrue,
        );
        final qua = g(17).add(const Duration(hours: 24, seconds: 1));
        expect(k.coChuaNhanMon(qua, cfg), isFalse);
        expect(k.chuaNhanMon(qua, cfg).hien, isFalse);
      },
    );
  });

  group('khiếu nại, đã nhận món, phản đối', () {
    final han = g(17).add(const Duration(hours: 24));
    final d = don('delivered', bangChungLuc: g(17), hanKhieuNai: han);

    test('khiếu nại: chỉ đơn trả trên app, trong hạn 24 giờ', () {
      expect(d.coKhieuNai(g(20)), isTrue);
      expect(d.coKhieuNai(han), isTrue);
      expect(d.coKhieuNai(han.add(const Duration(seconds: 1))), isFalse);
      expect(
        don(
          'delivered',
          cachTra: 'tien_mat',
          hanKhieuNai: han,
        ).coKhieuNai(g(20)),
        isFalse,
      );
      expect(don('ready').coKhieuNai(g(20)), isFalse);
    });

    test(
      '"Đã nhận món" khi sẵn sàng / đang giao / chờ xác nhận; sau đó thì không',
      () {
        for (final s in ['ready', 'delivering', 'delivered']) {
          expect(don(s).coDaNhanMon, isTrue, reason: s);
        }
        for (final s in [
          'placed',
          'accepted',
          'completed',
          'disputed',
          'not_received',
        ]) {
          expect(don(s).coDaNhanMon, isFalse, reason: s);
        }
      },
    );

    test('phản đối "khách không nhận" trong 24 giờ, một lần', () {
      final k = don(
        'not_received',
        khongNhan: KhongNhan(
          luc: g(19),
          hanPhanDoi: g(19).add(const Duration(hours: 24)),
        ),
      );
      expect(k.coPhanDoi(g(23)), isTrue);
      expect(k.coPhanDoi(g(19).add(const Duration(hours: 24))), isTrue);
      expect(
        k.coPhanDoi(g(19).add(const Duration(hours: 24, seconds: 1))),
        isFalse,
      );
      final da = don(
        'not_received',
        khongNhan: KhongNhan(luc: g(19), hanPhanDoi: g(23), phanDoi: true),
      );
      expect(da.coPhanDoi(g(20)), isFalse);
    });

    test('đánh giá và đặt lại sau khi hoàn tất', () {
      final k = don('completed', danhGiaHan: g(20));
      expect(k.coDanhGia(g(19)), isTrue);
      expect(k.coDanhGia(g(21)), isFalse);
      expect(k.coDatLai, isTrue);
      expect(don('placed', danhGiaHan: g(20)).coDanhGia(g(19)), isFalse);
    });
  });

  group('nút của chủ quán', () {
    test('nhận / từ chối trong hạn 5 phút', () {
      final d = don('placed', hanQuanNhan: g(12, 5));
      expect(d.coQuanNhan(g(12, 4)), isTrue);
      expect(d.coQuanTuChoi(g(12, 5)), isTrue);
      expect(d.coQuanNhan(g(12, 5, 1)), isFalse);
      expect(don('accepted', hanQuanNhan: g(12, 5)).coQuanNhan(g(12)), isFalse);
    });

    test('sẵn sàng (đến lấy) / đang giao (giao) / hủy', () {
      final lay = don('accepted');
      final giao = don('accepted', cachNhan: 'giao');
      expect(lay.coQuanSanSang, isTrue);
      expect(lay.coQuanDangGiao, isFalse);
      expect(giao.coQuanDangGiao, isTrue);
      expect(giao.coQuanSanSang, isFalse);
      expect(lay.coQuanHuy, isTrue);
      expect(don('ready').coQuanHuy, isFalse);
    });

    test('nhập mã: đơn đến lấy sẵn sàng, chưa nhập đúng', () {
      expect(don('ready').coNhapMa, isTrue);
      expect(don('ready', maNhanMonDaNhapLuc: g(18)).coNhapMa, isFalse);
      expect(don('ready', cachNhan: 'giao').coNhapMa, isFalse);
      expect(don('accepted').coNhapMa, isFalse);
    });

    test('đã giao + ảnh: đơn giao đang giao, chưa có ảnh', () {
      expect(don('delivering', cachNhan: 'giao').coQuanDaGiao, isTrue);
      expect(
        don(
          'delivering',
          cachNhan: 'giao',
          anhGiao: const AnhGiao(url: 'u'),
        ).coQuanDaGiao,
        isFalse,
      );
      expect(don('delivering').coQuanDaGiao, isFalse);
    });

    test('Khách không nhận (đến lấy): mờ tới 30 phút sau Sẵn sàng', () {
      final d = don('ready', sanSangLuc: g(18));
      final som = d.quanKhongNhan(g(18, 29, 59), cfg);
      expect(som.hien, isTrue);
      expect(som.bam, isFalse);
      expect(som.giaiThich, contains('30 phút'));
      expect(d.coQuanKhongNhan(g(18, 30), cfg), isTrue);
      expect(d.coQuanKhongNhan(g(20), cfg), isTrue);
    });

    test('Khách không nhận (đến lấy) khi chưa biết lúc sẵn sàng: mờ', () {
      expect(don('ready').coQuanKhongNhan(g(23), cfg), isFalse);
    });

    test(
      'Khách không nhận (giao): bấm được khi đang giao; đã báo rồi thì ẩn',
      () {
        final d = don('delivering', cachNhan: 'giao', batDauGiaoLuc: g(17));
        expect(d.coQuanKhongNhan(g(17, 1), cfg), isTrue);
        final da = don(
          'delivering',
          cachNhan: 'giao',
          khongNhan: KhongNhan(luc: g(18), hanPhanDoi: g(23)),
        );
        expect(da.quanKhongNhan(g(19), cfg).hien, isFalse);
      },
    );

    test(
      'trả lời khiếu nại: đơn trả trên app, trong hạn 2 giờ, chưa trả lời',
      () {
        final k = KhieuNaiDon(
          loai: 'khieu_nai',
          luc: g(18),
          hanChuTraLoi: g(20),
        );
        final d = don('disputed', khieuNai: k);
        expect(d.coQuanTraLoiKhieuNai(g(19, 59)), isTrue);
        expect(d.coQuanTraLoiKhieuNai(g(20, 0, 1)), isFalse);
        expect(
          don(
            'disputed',
            khieuNai: KhieuNaiDon(
              loai: 'khieu_nai',
              hanChuTraLoi: g(20),
              chuTraLoi: 'ok',
            ),
          ).coQuanTraLoiKhieuNai(g(19)),
          isFalse,
        );
        expect(
          don(
            'disputed',
            cachTra: 'tien_mat',
            khieuNai: KhieuNaiDon(loai: 'chua_nhan_mon', hanChuTraLoi: g(20)),
          ).coQuanTraLoiKhieuNai(g(19)),
          isFalse,
        );
      },
    );
  });

  group('mốc đếm ngược', () {
    test('chờ thanh toán / chờ quán', () {
      expect(
        don('pending_payment', hanThanhToan: g(14)).mocDemNguoc(g(13), cfg)!.$2,
        g(14),
      );
      final p = don('placed', hanQuanNhan: g(12, 5)).mocDemNguoc(g(12), cfg)!;
      expect(p.$1, 'Quán xác nhận trước');
      expect(p.$2, g(12, 5));
    });

    test('đang chuẩn bị: dự kiến sẵn sàng, rồi mốc hủy vì quán chậm', () {
      final d = don(
        'accepted',
        gioDuKienSanSang: g(17, 30),
        moHuyChamLuc: g(18),
      );
      expect(d.mocDemNguoc(g(17), cfg)!.$2, g(17, 30));
      expect(d.mocDemNguoc(g(17, 45), cfg)!.$2, g(18));
      expect(d.mocDemNguoc(g(18, 1), cfg), isNull);
    });

    test(
      'sẵn sàng: T_lấy; chờ xác nhận: tự hoàn tất; không nhận: hạn phản đối',
      () {
        expect(
          don('ready', tNhanMonDuKien: g(18)).mocDemNguoc(g(17), cfg)!.$2,
          g(18),
        );
        expect(
          don('ready', tNhanMonDuKien: g(18)).mocDemNguoc(g(19), cfg),
          isNull,
        );
        expect(
          don('delivered', hanKhieuNai: g(23)).mocDemNguoc(g(19), cfg)!.$1,
          'Tự hoàn tất lúc',
        );
        expect(
          don(
            'not_received',
            khongNhan: KhongNhan(luc: g(18), hanPhanDoi: g(23)),
          ).mocDemNguoc(g(19), cfg)!.$2,
          g(23),
        );
        expect(don('completed').mocDemNguoc(g(19), cfg), isNull);
      },
    );
  });

  group('phân loại trạng thái', () {
    test(
      'mọi trạng thái trong hợp đồng thuộc đúng một nhóm đang chạy / kết thúc',
      () {
        for (final s in trangThaiDonLabels.keys) {
          final d = don(s);
          expect(d.dangDienRa != d.ketThuc, isTrue, reason: s);
          expect(d.trangThaiLabel, isNot(s));
        }
      },
    );
  });

  group('fromMap', () {
    test('đọc đủ trường, lấy lúc sẵn sàng từ lịch sử nếu thiếu', () {
      final d = DonMon.fromMap('x', {
        'status': 'ready',
        'version': 4,
        'quanId': 'q',
        'chuQuanId': 'c',
        'svId': 's',
        'cachNhan': 'den_lay',
        'cachTra': 'app',
        'gio': 'hen',
        'gioHen': Timestamp.fromDate(g(18)),
        'tNhanMonDuKien': Timestamp.fromDate(g(18)),
        'tong': 85000,
        'monAn': [
          {
            'monId': 'm1',
            'ten': 'Phở',
            'gia': 40000,
            'soLuong': 2,
            'tuyChon': [
              {'nhom': 'Cỡ', 'ten': 'Lớn', 'giaThem': 5000},
            ],
            'thanhTien': 90000,
          },
        ],
        'khuyenMaiApDung': [
          {'id': 'k', 'tieuDe': 'Giảm 5k', 'loai': 'giam_tien', 'giam': 5000},
        ],
        'khieuNai': {
          'loai': 'khieu_nai',
          'lyDo': 'thieu_mon',
          'anh': ['a'],
          'hanChuTraLoi': Timestamp.fromDate(g(20)),
        },
        'lichSu': [
          {'status': 'accepted', 'luc': Timestamp.fromDate(g(17))},
          {'status': 'ready', 'luc': Timestamp.fromDate(g(17, 30))},
        ],
        'danhGia': {'han': Timestamp.fromDate(g(23))},
      });
      expect(d.version, 4);
      expect(d.laHenGio, isTrue);
      expect(d.tong, 85000);
      expect(d.monAn.single.tuyChonMoTa, 'Cỡ: Lớn');
      expect(d.monAn.single.tuyChon.single.giaThem, 5000);
      expect(d.khuyenMaiApDung.single.giam, 5000);
      expect(d.khieuNai!.lyDoLabel, 'Thiếu món');
      expect(d.sanSangLuc!.isAtSameMomentAs(g(17, 30)), isTrue);
      expect(d.danhGiaHan!.isAtSameMomentAs(g(23)), isTrue);
      expect(d.lichSu, hasLength(2));
    });

    test('map rỗng không làm lỗi', () {
      final d = DonMon.fromMap('x', {});
      expect(d.status, 'pending_payment');
      expect(d.monAn, isEmpty);
    });
  });
}
