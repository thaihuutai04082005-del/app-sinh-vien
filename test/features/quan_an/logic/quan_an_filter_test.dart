import 'package:app_sinh_vien/features/quan_an/models/gio_mo_cua.dart';
import 'package:app_sinh_vien/features/quan_an/models/quan_an.dart';
import 'package:app_sinh_vien/features/quan_an/models/quan_an_config.dart';
import 'package:app_sinh_vien/features/quan_an/models/quan_an_filter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime vn(int y, int m, int d, [int gio = 0, int phut = 0]) =>
    DateTime.utc(y, m, d, gio, phut).subtract(const Duration(hours: 7));

/// Thứ ba 13/10/2026, 12:00 giờ Việt Nam.
final bayGio = vn(2026, 10, 13, 12);

LichMoCua moCaNgay() => {
  for (var d = 1; d <= 7; d++) d: [const CaMoCua(tu: 6 * 60, den: 22 * 60)],
};

LichMoCua dongCua() => {
  for (var d = 1; d <= 7; d++) d: [const CaMoCua(tu: 6 * 60, den: 9 * 60)],
};

/// 0,001 độ vĩ ≈ 111 m.
const goc = DiemGoc(lat: 10.0, lng: 105.0);

QuanAn quan(
  String id, {
  String ten = 'Quán',
  String searchText = '',
  String loaiQuan = 'ho_kinh_doanh',
  List<String> loaiMon = const ['com'],
  double lat = 10.0,
  double lng = 105.0,
  LichMoCua? gio,
  DateTime? tamNghiDen,
  PhucVu phucVu = const PhucVu(anTaiQuan: true, mangDi: false),
  List<String> tienIch = const [],
  bool nhanDatBan = false,
  CaiDatDatMon datMon = const CaiDatDatMon(),
  String trangThai = 'active',
  int soMon = 10,
  num? giaTrungVi = 30000,
  double? diem,
  int soDanhGia = 5,
  int soNguoi = 0,
  bool hayAn = false,
  bool coKhuyenMai = false,
  DateTime? duyetLuc,
}) => QuanAn(
  id: id,
  chuQuanId: 'c',
  ten: ten,
  loaiQuan: loaiQuan,
  loaiMon: loaiMon,
  searchText: searchText,
  viTri: GeoPoint(lat, lng),
  gioMoCua: gio ?? moCaNgay(),
  tamNghiDen: tamNghiDen,
  phucVu: phucVu,
  tienIch: tienIch,
  nhanDatBan: nhanDatBan,
  datMon: datMon,
  trangThai: trangThai,
  duyetLuc: duyetLuc,
  soLieu: SoLieuQuan(
    soMon: soMon,
    giaTrungVi: giaTrungVi,
    diemTong: diem,
    soDanhGia: diem == null ? 0 : soDanhGia,
    soNguoi30Ngay: soNguoi,
    hayAn: hayAn,
    coKhuyenMai: coKhuyenMai,
  ),
);

List<String> ids(List<KetQuaQuan> k) => [for (final x in k) x.quan.id];

List<KetQuaQuan> loc(
  List<QuanAn> ds, [
  QuanAnFilter f = const QuanAnFilter(),
  DiemGoc? g,
]) => locQuan(quan: ds, filter: f, goc: g, now: bayGio);

void main() {
  group('bỏ dấu, khoảng cách', () {
    test('boDau', () {
      expect(boDau('Đường Nguyễn Huệ (P.1)*'), 'duong nguyen hue p 1');
      expect(boDau('(*.'), '');
    });

    test('haversine: 0,001 độ vĩ ≈ 111 m', () {
      final m = khoangCachMet(10, 105, 10.001, 105);
      expect(m, closeTo(111.2, 1));
    });
  });

  group('điều kiện hiện ở sảnh', () {
    test('chỉ quán active có ít nhất 3 món', () {
      final kq = loc([
        quan('ok'),
        quan('nhap', trangThai: 'draft'),
        quan('an', trangThai: 'hidden'),
        quan('dinhchi', trangThai: 'suspended'),
        quan('it_mon', soMon: 2),
        quan('du_3_mon', soMon: 3),
      ]);
      expect(ids(kq).toSet(), {'ok', 'du_3_mon'});
    });

    test('số món tối thiểu lấy từ cấu hình', () {
      final kq = locQuan(
        quan: [quan('a', soMon: 4)],
        filter: const QuanAnFilter(),
        now: bayGio,
        cfg: const QuanAnConfig(monToiThieuHienThi: 5),
      );
      expect(kq, isEmpty);
    });
  });

  group('tìm kiếm', () {
    test('gõ không dấu "com tam" ra quán có món "Cơm tấm" / tên quán', () {
      final ds = [
        quan('a', ten: 'Quán A', searchText: 'quán a cơm tấm sườn nguyễn huệ'),
        quan('b', ten: 'Quán B', searchText: 'quán b bún bò lê lợi'),
      ];
      expect(ids(loc(ds, const QuanAnFilter(tuKhoa: 'com tam'))), ['a']);
      expect(ids(loc(ds, const QuanAnFilter(tuKhoa: 'Cơm Tấm'))), ['a']);
    });

    test('tìm theo tên đường và phường, nhiều từ không cần liền nhau', () {
      final ds = [
        quan('a', searchText: 'quán a nguyễn huệ phường 1'),
        quan('b', searchText: 'quán b lê lợi phường 2'),
      ];
      expect(ids(loc(ds, const QuanAnFilter(tuKhoa: 'hue phuong 1'))), ['a']);
    });

    test('ký tự đặc biệt không làm lỗi', () {
      expect(ids(loc([quan('a')], const QuanAnFilter(tuKhoa: '(*.'))), ['a']);
    });

    test('searchText rỗng thì tìm theo tên quán', () {
      final ds = [quan('a', ten: 'Phở Hòa')];
      expect(ids(loc(ds, const QuanAnFilter(tuKhoa: 'pho hoa'))), ['a']);
    });
  });

  group('loại món', () {
    test('khớp khi có ít nhất một loại món được chọn', () {
      final ds = [
        quan('com', loaiMon: ['com', 'an_vat']),
        quan('bun', loaiMon: ['bun_pho_mi']),
        quan('tra', loaiMon: ['tra_sua']),
      ];
      expect(
        ids(loc(ds, const QuanAnFilter(loaiMon: {'an_vat', 'tra_sua'})))
            .toSet(),
        {'com', 'tra'},
      );
    });
  });

  group('mức giá theo giá TRUNG VỊ', () {
    final ds = [
      quan('re', giaTrungVi: 15000),
      quan('b20', giaTrungVi: 20000),
      quan('b34', giaTrungVi: 34999),
      quan('b35', giaTrungVi: 35000),
      quan('b50', giaTrungVi: 50000),
      quan('dat', giaTrungVi: 80000),
      quan('chua_menu', giaTrungVi: null),
    ];
    final moc = mocGiaNhanh(const QuanAnConfig());

    QuanAnFilter chon(int i) =>
        QuanAnFilter(giaTu: moc[i].$2, giaDen: moc[i].$3);

    test('mốc sinh từ cấu hình: dưới 20k · 20–35k · 35–50k · trên 50k', () {
      expect(
        [for (final m in moc) m.$1],
        ['Dưới 20k', '20–35k', '35–50k', 'Trên 50k'],
      );
    });

    test('dưới 20k', () {
      expect(ids(loc(ds, chon(0))), ['re']);
    });
    test('20–35k: 20.000 vào mốc, 35.000 sang mốc sau', () {
      expect(ids(loc(ds, chon(1))).toSet(), {'b20', 'b34'});
    });
    test('35–50k', () {
      expect(ids(loc(ds, chon(2))).toSet(), {'b35'});
    });
    test('trên 50k gồm đúng 50.000', () {
      expect(ids(loc(ds, chon(3))).toSet(), {'b50', 'dat'});
    });
    test(
      'chip "Dưới 35k" = trung vị dưới 35.000đ; quán chưa có menu bị loại',
      () {
        const cfg = QuanAnConfig();
        final f = QuanAnFilter(giaDen: cfg.chipGiaReDen);
        expect(f.chipDuoiGiaRe(cfg), isTrue);
        expect(ids(loc(ds, f)).toSet(), {'re', 'b20', 'b34'});
      },
    );
  });

  group('khoảng cách + bán kính', () {
    final ds = [
      quan('gan', lat: 10.002), // ~222 m
      quan('vua', lat: 10.004), // ~445 m
      quan('xa', lat: 10.03), // ~3,3 km
    ];

    test('không có điểm gốc: không lọc bán kính', () {
      expect(ids(loc(ds, const QuanAnFilter(banKinhMet: 500))).toSet(), {
        'gan',
        'vua',
        'xa',
      });
    });

    test('bán kính 300 m / 500 m / 5 km', () {
      expect(ids(loc(ds, const QuanAnFilter(banKinhMet: 300), goc)), ['gan']);
      expect(ids(loc(ds, const QuanAnFilter(banKinhMet: 500), goc)).toSet(), {
        'gan',
        'vua',
      });
      expect(ids(loc(ds, const QuanAnFilter(banKinhMet: 5000), goc)).length, 3);
    });

    test('kết quả có khoảng cách', () {
      final kq = loc(ds, const QuanAnFilter(), goc);
      expect(kq.first.khoangCach, closeTo(222, 3));
    });

    test('bán kính lọc mặc định lấy từ cấu hình', () {
      expect(const QuanAnConfig().banKinhMet, [
        300,
        500,
        1000,
        2000,
        3000,
        5000,
      ]);
    });
  });

  group('đang mở cửa (bật sẵn)', () {
    final ds = [
      quan('mo'),
      quan('dong', gio: dongCua()),
      quan('nghi', tamNghiDen: vn(2026, 10, 15)),
    ];

    test('mặc định chỉ ra quán đang mở (tạm nghỉ không tính)', () {
      expect(ids(loc(ds)), ['mo']);
      expect(QuanAnFilter.macDinh.dangMo, isTrue);
    });

    test('tắt "Đang mở cửa": ra cả quán đóng, quán đang mở xếp trước', () {
      final kq = loc(ds, const QuanAnFilter(dangMo: false));
      expect(ids(kq).first, 'mo');
      expect(ids(kq).toSet(), {'mo', 'dong', 'nghi'});
      expect(kq.last.dangMo, isFalse);
    });
  });

  group('hình thức phục vụ', () {
    final ds = [
      quan('tai_quan'),
      quan('mang_di', phucVu: const PhucVu(anTaiQuan: false, mangDi: true)),
      quan('ca_hai', phucVu: const PhucVu(anTaiQuan: true, mangDi: true)),
    ];
    test('ăn tại quán', () {
      expect(ids(loc(ds, const QuanAnFilter(anTaiQuan: true))).toSet(), {
        'tai_quan',
        'ca_hai',
      });
    });
    test('mang đi', () {
      expect(ids(loc(ds, const QuanAnFilter(mangDi: true))).toSet(), {
        'mang_di',
        'ca_hai',
      });
    });
    test('chọn cả hai: phải có cả hai', () {
      expect(ids(loc(ds, const QuanAnFilter(anTaiQuan: true, mangDi: true))), [
        'ca_hai',
      ]);
    });
  });

  group('giao hàng qua app', () {
    const giao = CaiDatDatMon(
      bat: true,
      denLay: false,
      giaoTanNoi: true,
      banKinhKm: 2,
    );
    final ds = [
      // Giao tới điểm gốc ~222 m, trong bán kính 2 km.
      quan('giao_gan', lat: 10.002, datMon: giao),
      // Cách ~3,3 km > 2 km, không có đến lấy.
      quan('giao_xa', lat: 10.03, datMon: giao),
      // Ngoài bán kính giao nhưng có đến lấy.
      quan('den_lay', lat: 10.03, datMon: giao.copyWith(denLay: true)),
      // Chưa bật đặt món.
      quan('tat', datMon: giao.copyWith(bat: false)),
      // Bán lẻ: không bao giờ, dù khai giao hàng.
      quan('ban_le', loaiQuan: 'ban_le', datMon: giao),
    ];

    test('chỉ hộ kinh doanh bật đặt món, giao tới chỗ bạn hoặc có đến lấy', () {
      expect(ids(loc(ds, const QuanAnFilter(giaoHang: true), goc)).toSet(), {
        'giao_gan',
        'den_lay',
      });
    });

    test('chưa có điểm gốc: chỉ quán có đến lấy', () {
      expect(ids(loc(ds, const QuanAnFilter(giaoHang: true))), ['den_lay']);
    });

    test('kết quả đánh dấu giaoDuoc', () {
      final kq = loc(ds, const QuanAnFilter(), goc);
      expect(kq.firstWhere((k) => k.quan.id == 'giao_gan').giaoDuoc, isTrue);
      expect(kq.firstWhere((k) => k.quan.id == 'giao_xa').giaoDuoc, isFalse);
      expect(kq.firstWhere((k) => k.quan.id == 'ban_le').giaoDuoc, isFalse);
    });
  });

  group('điểm đánh giá đã xác minh', () {
    final ds = [
      quan('a45', diem: 4.5),
      quan('a40', diem: 4.0),
      quan('a37', diem: 3.7),
      quan('a30', diem: 3.0),
      quan('chua'),
    ];
    test('từ 4 sao', () {
      expect(ids(loc(ds, const QuanAnFilter(diemTu: 4))).toSet(), {
        'a45',
        'a40',
      });
    });
    test('từ 3,5 sao', () {
      expect(ids(loc(ds, const QuanAnFilter(diemTu: 3.5))).toSet(), {
        'a45',
        'a40',
        'a37',
      });
    });
    test('quán chưa có đánh giá xác minh bị loại khi lọc điểm', () {
      expect(
        ids(loc(ds, const QuanAnFilter(diemTu: 3.5))),
        isNot(contains('chua')),
      );
    });
  });

  group('tiện ích, loại quán, khuyến mãi, đặt bàn', () {
    final ds = [
      quan('a', tienIch: ['wifi', 'may_lanh'], coKhuyenMai: true),
      quan('b', tienIch: ['wifi'], loaiQuan: 'ban_le'),
      quan('c', nhanDatBan: true),
      quan('d', nhanDatBan: true, loaiQuan: 'ban_le'),
    ];
    test('tiện ích: phải có đủ mọi tiện ích đã chọn', () {
      expect(ids(loc(ds, const QuanAnFilter(tienIch: {'wifi'}))).toSet(), {
        'a',
        'b',
      });
      expect(ids(loc(ds, const QuanAnFilter(tienIch: {'wifi', 'may_lanh'}))), [
        'a',
      ]);
    });
    test('loại quán', () {
      expect(ids(loc(ds, const QuanAnFilter(loaiQuan: 'ban_le'))).toSet(), {
        'b',
        'd',
      });
    });
    test('có khuyến mãi', () {
      expect(ids(loc(ds, const QuanAnFilter(coKhuyenMai: true))), ['a']);
    });
    test('nhận đặt bàn: chỉ hộ kinh doanh', () {
      expect(ids(loc(ds, const QuanAnFilter(nhanDatBan: true))), ['c']);
    });
  });

  group('sắp xếp', () {
    test(
      'quán đang mở luôn trước quán đã đóng, kể cả khi gần hơn / điểm cao hơn',
      () {
        final ds = [
          quan('dong_gan', lat: 10.0005, gio: dongCua(), diem: 5),
          quan('mo_xa', lat: 10.01, diem: 3),
        ];
        for (final sx in SapXepQuan.values) {
          final kq = loc(ds, QuanAnFilter(dangMo: false, sapXep: sx), goc);
          expect(ids(kq), ['mo_xa', 'dong_gan'], reason: sx.name);
        }
      },
    );

    test('gần nhất: theo khoảng cách, KHÔNG đẩy hộ kinh doanh lên', () {
      final ds = [
        quan('hkd_xa', lat: 10.004),
        quan('le_gan', lat: 10.001, loaiQuan: 'ban_le'),
        quan('hkd_gan', lat: 10.002),
      ];
      expect(
        ids(loc(ds, const QuanAnFilter(sapXep: SapXepQuan.ganNhat), goc)),
        ['le_gan', 'hkd_gan', 'hkd_xa'],
      );
    });

    test('đánh giá cao nhất: điểm giảm dần, cùng điểm thì hộ kinh doanh trước, chưa đánh giá cuối', () {
      final ds = [
        quan('chua'),
        quan('le45', loaiQuan: 'ban_le', diem: 4.5),
        quan('hkd45', diem: 4.5),
        quan('hkd48', diem: 4.8),
      ];
      expect(ids(loc(ds, const QuanAnFilter(sapXep: SapXepQuan.danhGia))), [
        'hkd48',
        'hkd45',
        'le45',
        'chua',
      ]);
    });

    test('đánh giá cao nhất: điểm chưa xác minh không được tính', () {
      final ds = [
        quan('a', diem: 4.0),
        // soDanhGia = 0 nghĩa là chưa có đánh giá xác minh dù có điểm phụ.
        QuanAn(
          id: 'b',
          chuQuanId: 'c',
          ten: 'b',
          gioMoCua: moCaNgay(),
          trangThai: 'active',
          soLieu: const SoLieuQuan(soMon: 5, diemTong: 5.0, soDanhGia: 0),
        ),
      ];
      expect(ids(loc(ds, const QuanAnFilter(sapXep: SapXepQuan.danhGia))), [
        'a',
        'b',
      ]);
    });

    test(
      'giá thấp nhất: theo trung vị tăng dần, hòa thì hộ kinh doanh trước',
      () {
        final ds = [
          quan('dat', giaTrungVi: 60000),
          quan('le30', giaTrungVi: 30000, loaiQuan: 'ban_le'),
          quan('hkd30', giaTrungVi: 30000),
          quan('re', giaTrungVi: 12000),
        ];
        expect(ids(loc(ds, const QuanAnFilter(sapXep: SapXepQuan.giaThap))), [
          're',
          'hkd30',
          'le30',
          'dat',
        ]);
      },
    );

    test('sinh viên hay ăn: quán có nhãn trước, rồi theo số người', () {
      final ds = [
        quan('it', soNguoi: 3),
        quan('nhan_it', hayAn: true, soNguoi: 12),
        quan('nhan_nhieu', hayAn: true, soNguoi: 40),
      ];
      expect(ids(loc(ds, const QuanAnFilter(sapXep: SapXepQuan.hayAn))), [
        'nhan_nhieu',
        'nhan_it',
        'it',
      ]);
    });

    test('mới mở: duyệt gần đây nhất trước', () {
      final ds = [
        quan('cu', duyetLuc: vn(2026, 1, 1)),
        quan('moi', duyetLuc: vn(2026, 10, 10)),
        quan('giua', duyetLuc: vn(2026, 6, 1)),
      ];
      expect(ids(loc(ds, const QuanAnFilter(sapXep: SapXepQuan.moiMo))), [
        'moi',
        'giua',
        'cu',
      ]);
    });
  });

  group('lưu / đọc bộ lọc', () {
    test('toJson / fromJson giữ nguyên', () {
      const f = QuanAnFilter(
        loaiMon: {'com'},
        giaTu: 20000,
        giaDen: 35000,
        banKinhMet: 500,
        dangMo: false,
        anTaiQuan: true,
        giaoHang: true,
        diemTu: 3.5,
        tienIch: {'wifi'},
        nhanDatBan: true,
        loaiQuan: 'ban_le',
        coKhuyenMai: true,
        sapXep: SapXepQuan.giaThap,
      );
      final g = QuanAnFilter.fromJson(f.toJson());
      expect(g.toJson(), f.toJson());
      expect(g.dangLoc, isTrue);
    });

    test(
      'mặc định: bật "Đang mở", chưa lọc gì; xoaLoc giữ từ khóa và sắp xếp',
      () {
        expect(QuanAnFilter.macDinh.dangLoc, isFalse);
        final f = const QuanAnFilter(
          tuKhoa: 'pho',
          giaDen: 35000,
          dangMo: false,
          sapXep: SapXepQuan.moiMo,
        ).xoaLoc();
        expect(f.tuKhoa, 'pho');
        expect(f.sapXep, SapXepQuan.moiMo);
        expect(f.dangMo, isTrue);
        expect(f.giaDen, isNull);
      },
    );

    test('DiemGoc toJson / fromJson', () {
      final g = DiemGoc.fromJson(
        const DiemGoc(lat: 1, lng: 2, ten: 'x').toJson(),
      )!;
      expect([g.lat, g.lng, g.ten], [1, 2, 'x']);
      expect(DiemGoc.fromJson('hỏng'), isNull);
    });
  });
}
