import 'dart:async';
import 'dart:typed_data';

import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/features/auth/models/xac_thuc.dart';
import 'package:app_sinh_vien/features/auth/services/xac_thuc_service.dart';
import 'package:app_sinh_vien/features/quan_an/models/check_in.dart';
import 'package:app_sinh_vien/features/quan_an/models/danh_gia.dart';
import 'package:app_sinh_vien/features/quan_an/models/dat_ban.dart';
import 'package:app_sinh_vien/features/quan_an/models/don_mon.dart';
import 'package:app_sinh_vien/features/quan_an/models/gio_mo_cua.dart';
import 'package:app_sinh_vien/features/quan_an/models/khang_nghi.dart';
import 'package:app_sinh_vien/features/quan_an/models/khuyen_mai.dart';
import 'package:app_sinh_vien/features/quan_an/models/mon_an.dart';
import 'package:app_sinh_vien/features/quan_an/models/nhom_mon.dart';
import 'package:app_sinh_vien/features/quan_an/models/quan_an.dart';
import 'package:app_sinh_vien/features/quan_an/models/quan_an_config.dart';
import 'package:app_sinh_vien/features/quan_an/models/thanh_toan.dart';
import 'package:app_sinh_vien/features/quan_an/models/thong_bao.dart';
import 'package:app_sinh_vien/features/quan_an/models/tin_nhan.dart';
import 'package:app_sinh_vien/features/quan_an/services/admin_quan_an_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/bao_cao_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/chat_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/check_in_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/danh_gia_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/dat_ban_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/don_mon_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/gio_hang_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/khuyen_mai_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/menu_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/quan_an_dich_vu.dart';
import 'package:app_sinh_vien/features/quan_an/services/quan_an_service.dart';
import 'package:app_sinh_vien/features/quan_an/services/thong_bao_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Bộ dịch vụ giả cho widget test của module Quán ăn: dữ liệu trong bộ nhớ (sửa được ở các danh sách
/// công khai), ghi lại mọi lời gọi ghi vào [goi] và [thamSo] (cùng chỉ số).
///
/// Quy ước tên trong [goi]: tên hành động của backend (`adminDuyet`, `adminDinhChi`, `guiDatBan`,
/// `baoGia`, `datMon`, `baoCao`, `luu`...); thao tác đơn / bàn ghi dạng `thaoTacDon:SV_HUY`,
/// `thaoTacBan:QUAN_XAC_NHAN` (tham số gồm `donId` / `banId`, `version` và phần còn lại của `su`).
class QuanAnGia {
  QuanAnGia({
    this.uid = 'sv',
    this.xacThuc = const XacThuc(sdt: '0902000002', sdtDaXacThuc: true),
    this.quyenAdmin = const QuyenAdmin(quanAn: true),
  });

  final String uid;
  XacThuc xacThuc;
  QuyenAdmin quyenAdmin;

  // ---- Dữ liệu sửa được ----
  List<QuanAn> quan = [];
  List<MonAn> mon = [];
  List<NhomMon> nhom = [];
  List<KhuyenMai> khuyenMai = [];
  List<DonMon> don = [];
  List<DatBan> ban = [];
  List<CheckIn> checkIn = [];
  List<CuocChat> cuocChat = [];
  List<TinNhan> tinNhan = [];
  List<DanhGia> danhGia = [];
  List<ViPham> viPham = [];
  List<KhangNghi> khangNghi = [];
  List<ThongBao> thongBao = [];
  List<ViecAdminQuan> viecAdmin = [];
  final Set<String> quanDaLuu = {};
  final Map<String, GiayToQuan> giayTo = {};
  final Map<String, KhoanTien> khoanTien = {};
  final Map<String, String> maNhanMon = {};
  final Map<String, Map<String, dynamic>> ketQuaThaoTac = {};
  Map<String, bool> caiDatThongBao = {};
  Map<String, DateTime?> khoa = {};
  ViChuQuan vi = const ViChuQuan();
  ChiSoChuQuan chiSoChu = const ChiSoChuQuan(
    hoTen: 'Chủ quán A',
    daXacThucDanhTinh: true,
  );
  QuanAnConfig cauHinh = const QuanAnConfig();
  ThongTinSinhVien thongTin = const ThongTinSinhVien();
  PhienThanhToan? phien;
  String sdtQuan = '0901000001';
  num? khoangCachCheckIn = 30;
  bool daCheckInHomNay = false;

  /// Kết quả `baoGia` cố định (sửa để thử giá đổi, món hết...).
  BaoGia baoGia = const BaoGia(
    ok: true,
    monAn: [
      MonTrongDon(
        monId: 'm1',
        ten: 'Cơm sườn',
        gia: 35000,
        soLuong: 2,
        thanhTien: 70000,
      ),
    ],
    tienMon: 70000,
    phiGiao: 10000,
    tong: 80000,
    tienMatDuocKhong: true,
  );

  /// Kết quả `datMon` cố định; dùng [datMonGiaDoi] để giả lập "giá đã đổi".
  KetQuaDatMon ketQuaDatMon = const KetQuaDatMon(ok: true, donId: 'don_moi');

  /// Giả lập giá đổi sau khi khách đã thấy tổng: không tạo đơn, trả tổng mới.
  void datMonGiaDoi(num tongMoi) => ketQuaDatMon = KetQuaDatMon(
    ok: false,
    giaDoi: true,
    tong: tongMoi,
    baoGia: BaoGia(ok: true, tong: tongMoi, tienMon: tongMoi),
  );

  /// Lỗi bắn ra ở các danh sách quán / đơn / bàn (thử trạng thái lỗi).
  Object? loiSanh;

  /// Lỗi bắn ra ở hàng chờ admin.
  Object? loiHangCho;

  /// true = mọi danh sách đứng ở trạng thái đang tải (không bao giờ có dữ liệu).
  bool dangTai = false;

  /// Lời gọi đã ghi (xem quy ước ở đầu lớp) và tham số tương ứng (cùng chỉ số).
  final goi = <String>[];
  final thamSo = <Map<String, dynamic>>[];

  /// Gọi [ten] ít nhất một lần chưa.
  bool daGoi(String ten) => goi.contains(ten);

  /// Tham số của lần gọi [ten] gần nhất; null nếu chưa gọi.
  Map<String, dynamic>? thamSoCua(String ten) {
    final i = goi.lastIndexOf(ten);
    return i < 0 ? null : thamSo[i];
  }

  final gioHang = GioHangService(luuBoNho: false);

  void _ghi(String ten, [Map<String, dynamic> tham = const {}]) {
    goi.add(ten);
    thamSo.add(tham);
  }

  Stream<T> _stream<T>(T Function() f, {Object? loi}) {
    if (dangTai) return StreamController<T>().stream;
    if (loi != null) return Stream<T>.error(loi);
    return Stream.value(f());
  }

  Stream<T> _sanh<T>(T Function() f) => _stream(f, loi: loiSanh);

  QuanAnDichVu get dv => QuanAnDichVu(
    uid: uid,
    quan: _QuanAnGia(this),
    menu: _MenuGia(this),
    khuyenMai: _KhuyenMaiGia(this),
    gioHang: gioHang,
    donMon: _DonMonGia(this),
    datBan: _DatBanGia(this),
    checkIn: _CheckInGia(this),
    chat: _ChatGia(this),
    danhGia: _DanhGiaGia(this),
    baoCao: _BaoCaoGia(this),
    thongBao: _ThongBaoGia(this),
    admin: _AdminGia(this),
    xacThuc: _XacThucGia(this),
    storage: _StorageGia(),
  );
}

// ---------------------------------------------------------------------------
// Dựng nhanh dữ liệu mẫu.
// ---------------------------------------------------------------------------

/// Quán hộ kinh doanh mở cửa cả tuần (6:00–22:00), nhận đặt món (đến lấy + giao, tiền mặt)
/// và đặt bàn, đã có ảnh mặt tiền và ghim bản đồ.
QuanAn quanMau({
  String id = 'q1',
  String chuQuanId = 'chu',
  String ten = 'Cơm tấm Cô Ba',
  String loaiQuan = 'ho_kinh_doanh',
  String trangThai = 'active',
  bool datMon = true,
  bool datBan = true,
  bool khoaBan = false,
  String diaChi = '12 Lê Lợi, Quận 1',
  GeoPoint viTri = const GeoPoint(10.7769, 106.7009),
  Map<String, dynamic>? banChinhSua,
  KhaiSaiLoai? khaiSaiLoai,
}) {
  final hkd = loaiQuan == 'ho_kinh_doanh';
  return QuanAn(
    id: id,
    chuQuanId: chuQuanId,
    ten: ten,
    loaiQuan: loaiQuan,
    loaiMon: const ['com'],
    moTa: 'Cơm tấm sườn bì chả, giá sinh viên.',
    sdt: '0901000001',
    diaChi: diaChi,
    phuong: 'Bến Nghé',
    viTri: viTri,
    gioMoCua: {
      for (var d = 1; d <= 7; d++) d: const [CaMoCua(tu: 360, den: 1320)],
    },
    phucVu: const PhucVu(anTaiQuan: true, mangDi: true),
    tienIch: const ['wifi'],
    nhanDatBan: hkd && datBan,
    datMon: hkd && datMon
        ? const CaiDatDatMon(
            bat: true,
            denLay: true,
            giaoTanNoi: true,
            banKinhKm: 3,
            phiGiao: 10000,
            tienMat: true,
          )
        : const CaiDatDatMon(),
    anhMatTien: ['https://cdn.test/$id/mat_tien.jpg'],
    anhBia: 'https://cdn.test/$id/mat_tien.jpg',
    viTriAnh: viTri,
    camKet: true,
    trangThai: trangThai,
    khoaBan: khoaBan,
    banChinhSua: banChinhSua,
    khaiSaiLoai: khaiSaiLoai,
    taoLuc: DateTime(2026, 9, 1),
    duyetLuc: trangThai == 'active' ? DateTime(2026, 9, 2) : null,
    soLieu: const SoLieuQuan(soMon: 12, giaP25: 30000, giaP75: 45000),
  );
}

NhomMon nhomMau({
  String id = 'n1',
  String quanId = 'q1',
  String ten = 'Cơm',
  String chuQuanId = 'chu',
  int thuTu = 0,
}) => NhomMon(
  id: id,
  quanId: quanId,
  chuQuanId: chuQuanId,
  ten: ten,
  thuTu: thuTu,
);

MonAn monMau({
  String id = 'm1',
  String quanId = 'q1',
  String nhomId = 'n1',
  String ten = 'Cơm sườn',
  num gia = 35000,
  bool conHang = true,
  String chuQuanId = 'chu',
}) => MonAn(
  id: id,
  quanId: quanId,
  nhomId: nhomId,
  chuQuanId: chuQuanId,
  ten: ten,
  gia: gia,
  conHang: conHang,
);

/// Đơn món mẫu: 2 phần Cơm sườn (70.000đ), đến lấy, trả trên app. Chỉnh bằng tham số.
DonMon donMau({
  String id = 'd1',
  String status = 'placed',
  int version = 1,
  String quanId = 'q1',
  String chuQuanId = 'chu',
  String svId = 'sv',
  String tenQuan = 'Cơm tấm Cô Ba',
  String cachNhan = 'den_lay',
  String cachTra = 'app',
  num tong = 70000,
  num phiGiao = 0,
  DateTime? taoLuc,
  DateTime? hanQuanNhan,
  DateTime? hanThanhToan,
  DateTime? gioDuKienSanSang,
  DateTime? sanSangLuc,
  DateTime? batDauGiaoLuc,
  DateTime? tNhanMonDuKien,
  DateTime? bangChungLuc,
  String? bangChungLoai,
  DateTime? hanKhieuNai,
  AnhGiao? anhGiao,
  KhongNhan? khongNhan,
  KhieuNaiDon? khieuNai,
  bool coQuaHan = false,
  bool ruaSoatLuaDao = false,
  List<MocLichSu> lichSu = const [],
}) => DonMon(
  id: id,
  status: status,
  version: version,
  quanId: quanId,
  chuQuanId: chuQuanId,
  svId: svId,
  svSdt: '0902000002',
  tenQuan: tenQuan,
  monAn: const [
    MonTrongDon(
      monId: 'm1',
      ten: 'Cơm sườn',
      gia: 35000,
      soLuong: 2,
      thanhTien: 70000,
    ),
  ],
  cachNhan: cachNhan,
  diaChiGiao: cachNhan == 'giao'
      ? const DiaChiGiao(dong: '5 Nguyễn Huệ, Quận 1', khoangCachKm: 1.2)
      : null,
  sdtNhan: '0902000002',
  tienMon: 70000,
  phiGiao: phiGiao,
  tong: tong,
  cachTra: cachTra,
  taoLuc: taoLuc ?? DateTime.now(),
  hanQuanNhan: hanQuanNhan,
  hanThanhToan: hanThanhToan,
  gioDuKienSanSang: gioDuKienSanSang,
  sanSangLuc: sanSangLuc,
  batDauGiaoLuc: batDauGiaoLuc,
  tNhanMonDuKien: tNhanMonDuKien,
  bangChungLuc: bangChungLuc,
  bangChungLoai: bangChungLoai,
  hanKhieuNai: hanKhieuNai,
  anhGiao: anhGiao,
  khongNhan: khongNhan,
  khieuNai: khieuNai,
  coQuaHan: coQuaHan,
  ruaSoatLuaDao: ruaSoatLuaDao,
  lichSu: lichSu,
);

/// Lượt đặt bàn mẫu: 4 người, hẹn sau 3 giờ.
DatBan banMau({
  String id = 'b1',
  String status = 'pending',
  int version = 1,
  String quanId = 'q1',
  String chuQuanId = 'chu',
  String svId = 'sv',
  String tenQuan = 'Cơm tấm Cô Ba',
  DateTime? gio,
  int soNguoi = 4,
  DateTime? hanXacNhan,
  DateTime? hanGiuBan,
  String? ghiNhanDen,
}) {
  final hen = gio ?? DateTime.now().add(const Duration(hours: 3));
  return DatBan(
    id: id,
    status: status,
    version: version,
    quanId: quanId,
    chuQuanId: chuQuanId,
    svId: svId,
    svSdt: '0902000002',
    tenQuan: tenQuan,
    gio: hen,
    soNguoi: soNguoi,
    taoLuc: DateTime.now(),
    hanXacNhan: hanXacNhan ?? hen.subtract(const Duration(minutes: 30)),
    hanGiuBan: hanGiuBan ?? hen.add(const Duration(minutes: 15)),
    ghiNhanDen: ghiNhanDen,
  );
}

/// Một việc trong hàng chờ admin. [duLieu] là dữ liệu thô của tài liệu gốc (quán, đơn, báo cáo...).
ViecAdminQuan viecMau({
  String loai = 'quan',
  String id = 'q1',
  String tieuDe = 'Cơm tấm Cô Ba',
  String moTa = '12 Lê Lợi, Quận 1',
  DateTime? luc,
  int uuTien = 3,
  Map<String, dynamic> duLieu = const {},
}) => ViecAdminQuan(
  loai: loai,
  id: id,
  tieuDe: tieuDe,
  moTa: moTa,
  luc: luc ?? DateTime.now().subtract(const Duration(hours: 2)),
  uuTien: uuTien,
  duLieu: duLieu,
);

/// Dữ liệu thô của một quán (như document `qa_quan`) để đặt vào [ViecAdminQuan.duLieu].
Map<String, dynamic> duLieuQuanMau({
  String chuQuanId = 'chu',
  String ten = 'Cơm tấm Cô Ba',
  String loaiQuan = 'ho_kinh_doanh',
  String trangThai = 'pending_review',
  Map<String, dynamic>? banChinhSua,
  Map<String, dynamic>? khaiSaiLoai,
}) => {
  'chuQuanId': chuQuanId,
  'ten': ten,
  'loaiQuan': loaiQuan,
  'loaiMon': ['com'],
  'moTa': 'Cơm tấm sườn bì chả.',
  'sdt': '0901000001',
  'diaChi': '12 Lê Lợi, Quận 1',
  'phuong': 'Bến Nghé',
  'viTri': const GeoPoint(10.7769, 106.7009),
  'viTriAnh': const GeoPoint(10.7769, 106.7009),
  'anhMatTien': ['https://cdn.test/q1/mat_tien.jpg'],
  'trangThai': trangThai,
  'banChinhSua': ?banChinhSua,
  'khaiSaiLoai': ?khaiSaiLoai,
};

// ---------------------------------------------------------------------------
// Các dịch vụ giả.
// ---------------------------------------------------------------------------

class _StorageGia implements ImageStorageService {
  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async => 'https://cdn.test/$folder/$fileName';
}

class _XacThucGia implements XacThucService {
  _XacThucGia(this.g);

  final QuanAnGia g;

  @override
  Stream<XacThuc> cuaToi(String uid) => Stream.value(g.xacThuc);
  @override
  Stream<QuyenAdmin> quyenAdmin(String uid) => Stream.value(g.quyenAdmin);
  @override
  Future<String> guiOtp(String sdt) async =>
      'Bản thử nghiệm: mã OTP là 123456.';
  @override
  Future<void> xacNhanOtp(String ma) async => g._ghi('xacNhanOtp', {'ma': ma});
  @override
  Future<void> guiDanhTinh({
    required String hoTen,
    required String soCccd,
  }) async => g._ghi('guiDanhTinh', {'hoTen': hoTen, 'soCccd': soCccd});
  @override
  Stream<List<(String, String, String)>> danhTinhChoDuyet() =>
      Stream.value(const []);
  @override
  Future<void> duyetDanhTinh(
    String uid, {
    required bool dongY,
    String? lyDo,
  }) async {}
}

class _QuanAnGia implements QuanAnService {
  _QuanAnGia(this.g);

  final QuanAnGia g;

  @override
  Stream<List<QuanAn>> quanDangHien() =>
      g._sanh(() => g.quan.where((q) => q.trangThai == 'active').toList());
  @override
  Stream<QuanAn?> quan(String id) =>
      g._stream(() => g.quan.where((q) => q.id == id).firstOrNull);
  @override
  Stream<List<MonAn>> monCuaQuan(String quanId) => g._stream(
    () => g.mon.where((m) => m.quanId == quanId && !m.daXoa).toList(),
  );
  @override
  Stream<List<NhomMon>> nhomMon(String quanId) =>
      g._stream(() => g.nhom.where((n) => n.quanId == quanId).toList());
  @override
  Stream<ChiSoChuQuan> chiSoChu(String chuQuanId) =>
      g._stream(() => g.chiSoChu);
  @override
  Future<String?> laySdtQuan(String quanId) async => g.sdtQuan;
  @override
  Stream<bool> daLuu(String uid, String quanId) =>
      g._stream(() => g.quanDaLuu.contains(quanId));
  @override
  Stream<List<String>> quanDaLuu(String uid) =>
      g._stream(() => g.quanDaLuu.toList());
  @override
  Future<void> luu(String uid, String quanId, {required bool luu}) async {
    g._ghi('luu', {'quanId': quanId, 'luu': luu});
    luu ? g.quanDaLuu.add(quanId) : g.quanDaLuu.remove(quanId);
  }

  @override
  Stream<List<QuanAn>> quanCuaToi(String uid) =>
      g._sanh(() => g.quan.where((q) => q.chuQuanId == uid).toList());
  @override
  Future<String> luuNhapQuan(String? id, Map<String, dynamic> duLieu) async {
    g._ghi('luuNhapQuan', {'id': id, ...duLieu});
    return id ?? 'quan_moi';
  }

  @override
  Future<void> luuGiayTo(String quanId, GiayToQuan giayTo) async {
    g._ghi('luuGiayTo', {'quanId': quanId, ...giayTo.toMap()});
    g.giayTo[quanId] = giayTo;
  }

  @override
  Future<GiayToQuan> layGiayTo(String quanId) async =>
      g.giayTo[quanId] ??
      const GiayToQuan(
        maSoThue: '0312345678',
        anhGiayChungNhan: ['https://cdn.test/giay_to/gcn.jpg'],
      );
  @override
  Future<Map<String, dynamic>> thaoTac(
    String hanhDong,
    Map<String, dynamic> tham,
  ) async {
    g._ghi(hanhDong, tham);
    return g.ketQuaThaoTac[hanhDong] ?? {'ok': true};
  }
}

class _MenuGia implements MenuService {
  _MenuGia(this.g);

  final QuanAnGia g;

  @override
  Stream<List<NhomMon>> nhomMon(String quanId) =>
      g._stream(() => g.nhom.where((n) => n.quanId == quanId).toList());
  @override
  Stream<List<MonAn>> mon(String quanId) => g._stream(
    () => g.mon.where((m) => m.quanId == quanId && !m.daXoa).toList(),
  );
  @override
  Stream<List<NhomMon>> nhomMonCuaChu(String quanId) => nhomMon(quanId);
  @override
  Stream<List<MonAn>> monCuaChu(String quanId) => mon(quanId);
  @override
  Future<String?> luuNhomMon(NhomMon nhom) async {
    g._ghi('luuNhomMon', {'id': nhom.id, 'ten': nhom.ten});
    return nhom.id.isEmpty ? 'nhom_moi' : nhom.id;
  }

  @override
  Future<void> xoaNhomMon(String nhomId) async =>
      g._ghi('xoaNhomMon', {'nhomId': nhomId});
  @override
  Future<String?> luuMon(MonAn mon) async {
    g._ghi('luuMon', {'id': mon.id, 'ten': mon.ten, 'gia': mon.gia});
    return mon.id.isEmpty ? 'mon_moi' : mon.id;
  }

  @override
  Future<void> xoaMon(String monId) async => g._ghi('xoaMon', {'monId': monId});
  @override
  Future<void> batTatMon(String monId, {required bool conHang}) async =>
      g._ghi('batTatMon', {'monId': monId, 'conHang': conHang});
}

class _KhuyenMaiGia implements KhuyenMaiService {
  _KhuyenMaiGia(this.g);

  final QuanAnGia g;

  @override
  Stream<List<KhuyenMai>> dangChay(String quanId) => g._stream(
    () => g.khuyenMai
        .where((k) => k.quanId == quanId && k.trangThai == 'chay')
        .toList(),
  );
  @override
  Stream<List<KhuyenMai>> cuaChu(String quanId) =>
      g._stream(() => g.khuyenMai.where((k) => k.quanId == quanId).toList());
  @override
  Future<String?> luu(KhuyenMai km) async {
    g._ghi('luuKhuyenMai', {'id': km.id, 'tieuDe': km.tieuDe});
    return km.id.isEmpty ? 'km_moi' : km.id;
  }

  @override
  Future<void> dung(String khuyenMaiId) async =>
      g._ghi('dungKhuyenMai', {'khuyenMaiId': khuyenMaiId});
}

class _DonMonGia implements DonMonService {
  _DonMonGia(this.g);

  final QuanAnGia g;

  @override
  Future<QuanAnConfig> cauHinh() async => g.cauHinh;
  @override
  Future<ThongTinSinhVien> thongTinSinhVien() async => g.thongTin;
  @override
  Future<BaoGia> baoGia({
    required String quanId,
    required List<Map<String, dynamic>> items,
    required String cachNhan,
    DiaChiDat? diaChi,
    String gio = 'asap',
    DateTime? gioHen,
  }) async {
    g._ghi('baoGia', {
      'quanId': quanId,
      'items': items,
      'cachNhan': cachNhan,
      'diaChi': diaChi?.toApi(),
      'gio': gio,
      'gioHen': gioHen,
    });
    return g.baoGia;
  }

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
  }) async {
    g._ghi('datMon', {
      'quanId': quanId,
      'items': items,
      'cachNhan': cachNhan,
      'diaChi': diaChi?.toApi(),
      'gio': gio,
      'gioHen': gioHen,
      'cachTra': cachTra,
      'sdtNhan': sdtNhan,
      'ghiChuQuan': ghiChuQuan,
      'tongDaThay': tongDaThay,
    });
    return g.ketQuaDatMon;
  }

  @override
  Stream<DonMon?> donMon(String id) =>
      g._sanh(() => g.don.where((d) => d.id == id).firstOrNull);
  @override
  Stream<List<DonMon>> cuaSinhVien(String uid) =>
      g._sanh(() => g.don.where((d) => d.svId == uid).toList());
  @override
  Stream<List<DonMon>> cuaChuQuan(String uid) =>
      g._sanh(() => g.don.where((d) => d.chuQuanId == uid).toList());
  @override
  Stream<int> donMoiCuaQuan(String uid) => g._stream(
    () => g.don.where((d) => d.chuQuanId == uid && d.status == 'placed').length,
  );
  @override
  Stream<String?> maNhanMon(String donId) =>
      g._stream(() => g.maNhanMon[donId]);
  @override
  Stream<KhoanTien?> khoanTien(String donId) =>
      g._stream(() => g.khoanTien[donId]);
  @override
  Stream<ViChuQuan> vi(String uid) => g._stream(() => g.vi);
  @override
  Future<void> xuLyHan(String donId) async =>
      g._ghi('xuLyHanDon', {'donId': donId});
  @override
  Future<void> thaoTac(
    String donId,
    int version,
    Map<String, dynamic> su,
  ) async => g._ghi('thaoTacDon:${su['loai']}', {
    'donId': donId,
    'version': version,
    ...su,
  });
  @override
  Future<PhienThanhToan?> xemPhien(String donId) async => g.phien;
  @override
  Future<void> thanhToan(String donId, String ketQua) async =>
      g._ghi('thanhToan:$ketQua', {'donId': donId});
}

class _DatBanGia implements DatBanService {
  _DatBanGia(this.g);

  final QuanAnGia g;

  @override
  Future<String> guiDatBan({
    required String quanId,
    required DateTime gio,
    required int soNguoi,
    String ghiChu = '',
  }) async {
    g._ghi('guiDatBan', {
      'quanId': quanId,
      'gio': gio,
      'soNguoi': soNguoi,
      'ghiChu': ghiChu,
    });
    return 'ban_moi';
  }

  @override
  Stream<DatBan?> datBan(String id) =>
      g._sanh(() => g.ban.where((b) => b.id == id).firstOrNull);
  @override
  Stream<List<DatBan>> cuaSinhVien(String uid) =>
      g._sanh(() => g.ban.where((b) => b.svId == uid).toList());
  @override
  Stream<List<DatBan>> cuaChuQuan(String uid) =>
      g._sanh(() => g.ban.where((b) => b.chuQuanId == uid).toList());
  @override
  Stream<int> banChoXacNhan(String uid) => g._stream(
    () =>
        g.ban.where((b) => b.chuQuanId == uid && b.status == 'pending').length,
  );
  @override
  Future<void> thaoTac(String banId, int version, String loai) async =>
      g._ghi('thaoTacBan:$loai', {'banId': banId, 'version': version});
  @override
  Future<void> xuLyHan(String banId) async =>
      g._ghi('xuLyHanBan', {'banId': banId});
}

class _CheckInGia implements CheckInService {
  _CheckInGia(this.g);

  final QuanAnGia g;

  @override
  Future<num?> checkIn({
    required String quanId,
    required double lat,
    required double lng,
    String? anh,
    String? camNghi,
    bool congKhai = false,
  }) async {
    g._ghi('checkIn', {
      'quanId': quanId,
      'lat': lat,
      'lng': lng,
      'anh': anh,
      'camNghi': camNghi,
      'congKhai': congKhai,
    });
    return g.khoangCachCheckIn;
  }

  @override
  Future<bool> daCheckInHomNay(String uid, String quanId) async =>
      g.daCheckInHomNay;
  @override
  Stream<List<CheckIn>> cuaSinhVien(String uid) =>
      g._stream(() => g.checkIn.where((c) => c.svId == uid).toList());
}

class _ChatGia implements ChatService {
  _ChatGia(this.g);

  final QuanAnGia g;

  @override
  Stream<List<CuocChat>> cuocCuaToi(String uid) => g._stream(
    () => g.cuocChat.where((c) => c.thanhVien.contains(uid)).toList(),
  );
  @override
  Stream<CuocChat?> cuoc(String chatId) => g._stream(
    () =>
        g.cuocChat.where((c) => c.id == chatId).firstOrNull ??
        CuocChat(
          id: chatId,
          thanhVien: chatId.split('_'),
          ten: const {'chu': 'Chủ quán A', 'sv': 'Sinh viên B'},
        ),
  );
  @override
  Stream<List<TinNhan>> tinNhan(String chatId) => g._stream(() => g.tinNhan);
  @override
  Future<String?> gui(
    String nguoiNhan, {
    String? noiDung,
    String? quanId,
    String? donId,
    String? anh,
  }) async {
    g._ghi(quanId != null || donId != null ? 'gui_the' : 'gui', {
      'nguoiNhan': nguoiNhan,
      'noiDung': noiDung,
      'quanId': quanId,
      'donId': donId,
      'anh': anh,
    });
    return noiDung != null && noiDung.toLowerCase().contains('chuyển khoản')
        ? canhBaoLuaDao
        : null;
  }

  @override
  Future<void> daXem(String chatId) async =>
      g._ghi('daXem', {'chatId': chatId});
  @override
  Future<void> chan(String chatId, {required bool chan}) async =>
      g._ghi('chan', {'chatId': chatId, 'chan': chan});
}

class _DanhGiaGia implements DanhGiaService {
  _DanhGiaGia(this.g);

  final QuanAnGia g;

  @override
  Stream<List<DanhGia>> cuaQuan(String quanId) =>
      g._stream(() => g.danhGia.where((d) => d.quanId == quanId).toList());
  @override
  Stream<DanhGia?> cuaToi(String quanId) => g._stream(
    () => g.danhGia
        .where((d) => d.quanId == quanId && d.nguoiViet == g.uid)
        .firstOrNull,
  );
  @override
  Future<void> gui(
    String quanId, {
    required Map<String, int> diem,
    required List<String> the,
    required String nhanXet,
    required List<String> anh,
  }) async => g._ghi('guiDanhGia', {
    'quanId': quanId,
    'diem': diem,
    'the': the,
    'nhanXet': nhanXet,
    'anh': anh,
  });
  @override
  Future<void> traLoi(String danhGiaId, String noiDung) async =>
      g._ghi('traLoiDanhGia', {'danhGiaId': danhGiaId, 'noiDung': noiDung});
}

class _BaoCaoGia implements BaoCaoService {
  _BaoCaoGia(this.g);

  final QuanAnGia g;

  @override
  Future<void> baoCao({
    required String loai,
    required String id,
    String? chatId,
    required String lyDo,
    String ghiChu = '',
  }) async => g._ghi('baoCao', {
    'loai': loai,
    'id': id,
    'chatId': chatId,
    'lyDo': lyDo,
    'ghiChu': ghiChu,
  });
  @override
  Stream<List<ViPham>> viPhamCuaToi(String uid) => g._stream(() => g.viPham);
  @override
  Stream<List<KhangNghi>> khangNghiCuaToi(String uid) =>
      g._stream(() => g.khangNghi);
  @override
  Stream<Map<String, DateTime?>> khoaCuaToi(String khoa) =>
      g._stream(() => g.khoa);
  @override
  Future<void> khangNghi({
    required String loai,
    required String id,
    String? col,
    required String lyDo,
    List<String> bangChung = const [],
  }) async => g._ghi('guiKhangNghi', {
    'loai': loai,
    'id': id,
    'col': col,
    'lyDo': lyDo,
    'bangChung': bangChung,
  });
}

class _ThongBaoGia implements ThongBaoService {
  _ThongBaoGia(this.g);

  final QuanAnGia g;

  @override
  Stream<List<ThongBao>> cuaToi(String uid) => g._stream(() => g.thongBao);
  @override
  Future<void> daDoc(String id) async => g._ghi('daDoc', {'id': id});
  @override
  Stream<Map<String, bool>> caiDat(String uid) =>
      g._stream(() => g.caiDatThongBao);
  @override
  Future<void> doiCaiDat(String uid, String nhom, bool bat) async =>
      g._ghi('doiCaiDat', {'nhom': nhom, 'bat': bat});
}

class _AdminGia implements AdminQuanAnService {
  _AdminGia(this.g);

  final QuanAnGia g;

  @override
  Stream<List<ViecAdminQuan>> hangCho() =>
      g._stream(() => sapXepHangCho(g.viecAdmin), loi: g.loiHangCho);
  @override
  Future<GiayToQuan> giayTo(String quanId) async =>
      g.giayTo[quanId] ?? const GiayToQuan();
  @override
  Future<Map<String, dynamic>> goi(
    String hanhDong,
    Map<String, dynamic> tham,
  ) async {
    g._ghi(hanhDong, tham);
    return g.ketQuaThaoTac[hanhDong] ?? {'ok': true};
  }

  @override
  Future<void> duyet({
    required String loai,
    required String id,
    required bool dongY,
    String? lyDo,
    bool? daDoiChieuMst,
  }) async => g._ghi('adminDuyet', {
    'loai': loai,
    'id': id,
    'dongY': dongY,
    'lyDo': lyDo,
    'daDoiChieuMst': daDoiChieuMst,
  });
  @override
  Future<void> yeuCauChuyenLoai(String quanId, String lyDo) async =>
      g._ghi('adminYeuCauChuyenLoai', {'quanId': quanId, 'lyDo': lyDo});
  @override
  Future<void> anHien(
    String quanId, {
    required bool an,
    required String lyDo,
  }) async => g._ghi('adminAnHien', {'quanId': quanId, 'an': an, 'lyDo': lyDo});
  @override
  Future<void> dinhChi(
    String quanId, {
    required bool dinhChi,
    required String lyDo,
  }) async => g._ghi('adminDinhChi', {
    'quanId': quanId,
    'dinhChi': dinhChi,
    'lyDo': lyDo,
  });
  @override
  Future<void> khoaBan(String quanId, String lyDo) async =>
      g._ghi('adminKhoaBan', {'quanId': quanId, 'lyDo': lyDo});
  @override
  Future<void> khoaChucNang({
    String? uid,
    String? sdt,
    required String chucNang,
    required DateTime den,
    required String lyDo,
  }) async => g._ghi('adminKhoaChucNang', {
    'uid': uid,
    'sdt': sdt,
    'chucNang': chucNang,
    'den': den,
    'lyDo': lyDo,
  });
  @override
  Future<void> xuLyBaoCao(Map<String, dynamic> tham) async =>
      g._ghi('adminXuLyBaoCao', tham);
  @override
  Future<void> xuLyKhangNghi(Map<String, dynamic> tham) async =>
      g._ghi('adminXuLyKhangNghi', tham);
  @override
  Future<void> capNhatCauHinh(Map<String, dynamic> ghiDe) async =>
      g._ghi('adminCauHinh', {'ghiDe': ghiDe});
  @override
  Future<void> luaDao(String quanId, String lyDo) async =>
      g._ghi('adminLuaDao', {'quanId': quanId, 'lyDo': lyDo});
  @override
  Future<void> thaoTacDon(
    String donId,
    int version,
    Map<String, dynamic> su,
  ) async => g._ghi('thaoTacDon:${su['loai']}', {
    'donId': donId,
    'version': version,
    ...su,
  });
}
