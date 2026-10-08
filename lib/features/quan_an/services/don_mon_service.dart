import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/don_mon.dart';
import '../models/quan_an_config.dart';
import '../models/thanh_toan.dart';
import 'quan_an_api.dart';

DateTime? _moc(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  if (v is Map) {
    final s = (v['_seconds'] ?? v['seconds']) as num?;
    if (s != null) return DateTime.fromMillisecondsSinceEpoch(s.toInt() * 1000);
  }
  return null;
}

/// Địa chỉ giao do sinh viên chọn (địa chỉ đã lưu hoặc vị trí hiện tại).
class DiaChiDat {
  const DiaChiDat({required this.lat, required this.lng, this.dong = ''});

  final double lat;
  final double lng;
  final String dong;

  Map<String, dynamic> toApi() => {'lat': lat, 'lng': lng, 'dong': dong};
}

/// Báo giá do hệ thống tính (kết quả `baoGiaDon`). App KHÔNG tự tính giá hay khuyến mãi.
class BaoGia {
  const BaoGia({
    required this.ok,
    this.ma,
    this.thongDiep,
    this.monAn = const [],
    this.tienMon = 0,
    this.giamCombo = 0,
    this.giamGia = 0,
    this.khuyenMaiApDung = const [],
    this.phiGiao = 0,
    this.tong = 0,
    this.gioDuKienSanSang,
    this.tienMatDuocKhong = false,
  });

  /// false = không đặt được; xem [ma] ('mon_het', 'quan_dong', 'ngoai_ban_kinh',
  /// 'chua_du_don_toi_thieu', 'gio_hen_sai'...) và [thongDiep] (tiếng Việt, hiện thẳng).
  final bool ok;
  final String? ma;
  final String? thongDiep;
  final List<MonTrongDon> monAn;
  final num tienMon;
  final num giamCombo;
  final num giamGia;
  final List<KhuyenMaiApDung> khuyenMaiApDung;
  final num phiGiao;
  final num tong;
  final DateTime? gioDuKienSanSang;
  final bool tienMatDuocKhong;

  /// Tổng giảm (combo + khuyến mãi đơn).
  num get tongGiam => giamCombo + giamGia;

  factory BaoGia.fromMap(Map<String, dynamic> m) => BaoGia(
    ok: m['ok'] as bool? ?? false,
    ma: m['ma'] as String?,
    thongDiep: m['thongDiep'] as String?,
    monAn: [
      for (final x in m['monAn'] as List? ?? const []) MonTrongDon.fromMap(x),
    ],
    tienMon: m['tienMon'] as num? ?? 0,
    giamCombo: m['giamCombo'] as num? ?? 0,
    giamGia: m['giamGia'] as num? ?? 0,
    khuyenMaiApDung: [
      for (final x in m['khuyenMaiApDung'] as List? ?? const [])
        KhuyenMaiApDung.fromMap(x),
    ],
    phiGiao: m['phiGiao'] as num? ?? 0,
    tong: m['tong'] as num? ?? 0,
    gioDuKienSanSang: _moc(m['gioDuKienSanSang']),
    tienMatDuocKhong: m['tienMatDuocKhong'] as bool? ?? false,
  );
}

/// Kết quả `datMon`: tạo được đơn, hoặc giá đã đổi (không tạo gì) / không đặt được.
class KetQuaDatMon {
  const KetQuaDatMon({
    required this.ok,
    this.donId,
    this.giaDoi = false,
    this.tong,
    this.ma,
    this.thongDiep,
    this.baoGia,
  });

  final bool ok;
  final String? donId;

  /// Giá vừa đổi so với [tongDaThay]: hiện [tong] mới cho khách xem lại rồi đặt lại.
  final bool giaDoi;
  final num? tong;
  final String? ma;
  final String? thongDiep;

  /// Báo giá mới kèm theo (khi có).
  final BaoGia? baoGia;

  factory KetQuaDatMon.fromMap(Map<String, dynamic> m) => KetQuaDatMon(
    ok: m['ok'] as bool? ?? false,
    donId: m['donId'] as String?,
    giaDoi: m['giaDoi'] as bool? ?? false,
    tong: m['tong'] as num?,
    ma: m['ma'] as String?,
    thongDiep: m['thongDiep'] as String?,
    baoGia: m.containsKey('monAn') ? BaoGia.fromMap(m) : null,
  );
}

/// Tình trạng của sinh viên trong module (`thongTinSinhVien`): khóa và số lần bom hàng.
class ThongTinSinhVien {
  const ThongTinSinhVien({
    this.soLanBomHang = 0,
    this.coTienMat = true,
    this.khoaDatMonDen,
    this.khoaDatBanDen,
    this.khoaTienMatDen,
    this.khoaDatMonAppDen,
    this.khoaBaoCaoDen,
  });

  final int soLanBomHang;

  /// Còn quyền chọn tiền mặt khi nhận không.
  final bool coTienMat;
  final DateTime? khoaDatMonDen;
  final DateTime? khoaDatBanDen;
  final DateTime? khoaTienMatDen;
  final DateTime? khoaDatMonAppDen;
  final DateTime? khoaBaoCaoDen;

  bool datMonBiKhoa(DateTime now) => (khoaDatMonDen?.isAfter(now) ?? false);
  bool datBanBiKhoa(DateTime now) => (khoaDatBanDen?.isAfter(now) ?? false);
  bool datMonAppBiKhoa(DateTime now) =>
      (khoaDatMonAppDen?.isAfter(now) ?? false);

  factory ThongTinSinhVien.fromMap(Map<String, dynamic> m) {
    final khoa = m['khoa'] is Map
        ? Map<String, dynamic>.from(m['khoa'] as Map)
        : const <String, dynamic>{};
    DateTime? k(String ten) => _moc(khoa[ten] ?? m[ten]);
    return ThongTinSinhVien(
      soLanBomHang: (m['soLanBomHang'] as num?)?.toInt() ?? 0,
      coTienMat: m['coTienMat'] as bool? ?? true,
      khoaDatMonDen: k('khoaDatMonDen'),
      khoaDatBanDen: k('khoaDatBanDen'),
      khoaTienMatDen: k('khoaTienMatDen'),
      khoaDatMonAppDen: k('khoaDatMonAppDen'),
      khoaBaoCaoDen: k('khoaBaoCaoDen'),
    );
  }
}

/// Đơn món: báo giá, đặt, thao tác theo bảng 3.5i, thanh toán giả lập, theo dõi realtime.
abstract interface class DonMonService {
  /// Con số quy định (bảng 3.16) từ server; lỗi thì dùng mặc định.
  Future<QuanAnConfig> cauHinh();
  Future<ThongTinSinhVien> thongTinSinhVien();

  /// Hệ thống tính lại toàn bộ giá theo menu hiện tại (app chỉ gửi món, tùy chọn, số lượng...).
  /// [items] lấy từ `GioHang.toApiItems()`. [gio]: 'asap' | 'hen' (kèm [gioHen]).
  Future<BaoGia> baoGia({
    required String quanId,
    required List<Map<String, dynamic>> items,
    required String cachNhan,
    DiaChiDat? diaChi,
    String gio = 'asap',
    DateTime? gioHen,
  });

  /// [tongDaThay] = tổng tiền khách đã thấy; lệch với giá hệ thống tính thì không tạo đơn,
  /// trả `giaDoi: true` cùng tổng mới.
  Future<KetQuaDatMon> datMon({
    required String quanId,
    required List<Map<String, dynamic>> items,
    required String cachNhan,
    DiaChiDat? diaChi,
    String gio = 'asap',
    DateTime? gioHen,
    required String cachTra,
    required String sdtNhan,
    String ghiChuQuan = '',
    required num tongDaThay,
  });

  Stream<DonMon?> donMon(String id);
  Stream<List<DonMon>> cuaSinhVien(String uid);
  Stream<List<DonMon>> cuaChuQuan(String uid);

  /// Số đơn mới (`placed`) của chủ quán — dùng cho chuông.
  Stream<int> donMoiCuaQuan(String uid);

  /// Mã nhận món 4 số (`qa_don/{id}/rieng/ma`) — chỉ sinh viên của đơn đọc được.
  Stream<String?> maNhanMon(String donId);
  Stream<KhoanTien?> khoanTien(String donId);
  Stream<ViChuQuan> vi(String uid);

  /// Mở lại đơn: nhờ hệ thống xử lý các hạn đã tới (thấy đúng trạng thái sau hạn).
  Future<void> xuLyHan(String donId);

  /// `su` = { loai: 'SV_HUY' | 'QUAN_NHAN' | ..., ...tham số }. `version` = phiên bản đang thấy.
  Future<void> thaoTac(String donId, int version, Map<String, dynamic> su);

  /// Phiên thanh toán giả lập của đơn; null nếu chưa có.
  Future<PhienThanhToan?> xemPhien(String donId);

  /// Cổng thanh toán giả lập: 'thanh_cong' | 'that_bai'.
  Future<void> thanhToan(String donId, String ketQua);
}

class FirebaseDonMonService implements DonMonService {
  FirebaseDonMonService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final QuanAnApi api;
  final FirebaseFirestore? _db;
  QuanAnConfig? _cfg;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  @override
  Future<QuanAnConfig> cauHinh() async {
    if (_cfg != null) return _cfg!;
    try {
      _cfg = QuanAnConfig.fromMap(await api.goi('cauHinh'));
    } catch (_) {
      _cfg = const QuanAnConfig();
    }
    return _cfg!;
  }

  @override
  Future<ThongTinSinhVien> thongTinSinhVien() async =>
      ThongTinSinhVien.fromMap(await api.goi('thongTinSinhVien'));

  Map<String, dynamic> _thamBaoGia({
    required String quanId,
    required List<Map<String, dynamic>> items,
    required String cachNhan,
    DiaChiDat? diaChi,
    required String gio,
    DateTime? gioHen,
  }) => {
    'quanId': quanId,
    'items': items,
    'cachNhan': cachNhan,
    if (diaChi != null) 'diaChi': diaChi.toApi(),
    'gio': {
      'loai': gio,
      if (gio == 'hen' && gioHen != null) 'hen': gioHen.millisecondsSinceEpoch,
    },
  };

  @override
  Future<BaoGia> baoGia({
    required String quanId,
    required List<Map<String, dynamic>> items,
    required String cachNhan,
    DiaChiDat? diaChi,
    String gio = 'asap',
    DateTime? gioHen,
  }) async => BaoGia.fromMap(
    await api.goi(
      'baoGiaDon',
      _thamBaoGia(
        quanId: quanId,
        items: items,
        cachNhan: cachNhan,
        diaChi: diaChi,
        gio: gio,
        gioHen: gioHen,
      ),
    ),
  );

  @override
  Future<KetQuaDatMon> datMon({
    required String quanId,
    required List<Map<String, dynamic>> items,
    required String cachNhan,
    DiaChiDat? diaChi,
    String gio = 'asap',
    DateTime? gioHen,
    required String cachTra,
    required String sdtNhan,
    String ghiChuQuan = '',
    required num tongDaThay,
  }) async => KetQuaDatMon.fromMap(
    await api.goi('datMon', {
      ..._thamBaoGia(
        quanId: quanId,
        items: items,
        cachNhan: cachNhan,
        diaChi: diaChi,
        gio: gio,
        gioHen: gioHen,
      ),
      'cachTra': cachTra,
      'sdtNhan': sdtNhan,
      'ghiChuQuan': ghiChuQuan,
      'tongDaThay': tongDaThay,
    }),
  );

  @override
  Stream<DonMon?> donMon(String id) => _f
      .collection('qa_don')
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? DonMon.fromMap(s.id, s.data()!) : null);

  Stream<List<DonMon>> _theo(String truong, String uid) => _f
      .collection('qa_don')
      .where(truong, isEqualTo: uid)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) DonMon.fromMap(d.id, d.data())]
          ..sort(
            (a, b) =>
                (b.taoLuc ?? DateTime(0)).compareTo(a.taoLuc ?? DateTime(0)),
          ),
      );

  @override
  Stream<List<DonMon>> cuaSinhVien(String uid) => _theo('svId', uid);

  @override
  Stream<List<DonMon>> cuaChuQuan(String uid) => _theo('chuQuanId', uid);

  @override
  Stream<int> donMoiCuaQuan(String uid) => _f
      .collection('qa_don')
      .where('chuQuanId', isEqualTo: uid)
      .where('status', isEqualTo: 'placed')
      .snapshots()
      .map((s) => s.docs.length);

  @override
  Stream<String?> maNhanMon(String donId) => _f
      .collection('qa_don')
      .doc(donId)
      .collection('rieng')
      .doc('ma')
      .snapshots()
      .map((s) => s.data()?['ma'] as String?);

  @override
  Stream<KhoanTien?> khoanTien(String donId) => _f
      .collection('qa_khoan_tien')
      .doc(donId)
      .snapshots()
      .map((s) => s.exists ? KhoanTien.fromMap(s.data()!) : null);

  @override
  Stream<ViChuQuan> vi(String uid) => _f
      .collection('qa_vi')
      .doc(uid)
      .snapshots()
      .map((s) => ViChuQuan.fromMap(s.data()));

  @override
  Future<void> xuLyHan(String donId) => api.goi('xuLyHanDon', {'donId': donId});

  @override
  Future<void> thaoTac(String donId, int version, Map<String, dynamic> su) =>
      api.goi('thaoTacDon', {'donId': donId, 'version': version, 'su': su});

  @override
  Future<PhienThanhToan?> xemPhien(String donId) async {
    final r = await api.goi('xemPhienThanhToan', {'donId': donId});
    if (r['soTien'] == null &&
        r['trangThai'] == null &&
        r['trangThaiTien'] == null) {
      return null;
    }
    return PhienThanhToan.fromMap({'donId': donId, ...r});
  }

  @override
  Future<void> thanhToan(String donId, String ketQua) =>
      api.goi('thanhToanGiaLap', {'donId': donId, 'ketQua': ketQua});
}
