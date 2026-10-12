import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dat_ban.dart';
import '../models/don_mon.dart';
import '../models/quan_an.dart';
import 'quan_an_api.dart';

/// Một việc trong hàng chờ admin Quán ăn (mục 3.12).
class ViecAdminQuan {
  const ViecAdminQuan({
    required this.loai,
    required this.id,
    required this.tieuDe,
    required this.moTa,
    required this.luc,
    this.uuTien = 3,
    this.duLieu = const {},
  });

  /// quan | chinh_sua | nang_cap | khai_sai_loai | bao_cao | khieu_nai_don | phan_doi |
  /// qua_han_6h | rua_soat_lua_dao | khang_nghi
  final String loai;
  final String id;
  final String tieuDe;
  final String moTa;
  final DateTime luc;

  /// 0 = cờ khẩn, 1 = khiếu nại tiền / báo cáo ưu tiên cao, 2 = hồ sơ bị gắn cờ, 3 = còn lại.
  final int uuTien;
  final Map<String, dynamic> duLieu;

  static const loaiLabels = {
    'quan': 'Quán chờ duyệt',
    'chinh_sua': 'Chỉnh sửa chờ duyệt',
    'nang_cap': 'Nâng cấp loại chờ duyệt',
    'khai_sai_loai': 'Quán nghi khai sai loại',
    'bao_cao': 'Báo cáo',
    'khieu_nai_don': 'Khiếu nại đơn',
    'phan_doi': 'Phản đối "khách không nhận"',
    'qua_han_6h': 'Đơn quá 6 giờ chưa có bằng chứng',
    'rua_soat_lua_dao': 'Đơn cần rà soát (quán lừa đảo)',
    'khang_nghi': 'Kháng nghị',
  };

  String get loaiLabel => loaiLabels[loai] ?? loai;
}

/// Hàng chờ sắp theo (mục 3.12): cờ khẩn → khiếu nại tiền và báo cáo ưu tiên cao →
/// hồ sơ bị gắn cờ → còn lại theo thời gian.
List<ViecAdminQuan> sapXepHangCho(List<ViecAdminQuan> ds) => [...ds]
  ..sort(
    (a, b) => a.uuTien != b.uuTien
        ? a.uuTien.compareTo(b.uuTien)
        : a.luc.compareTo(b.luc),
  );

/// Admin Quán ăn (`admins/{uid}.quanAn == true`): hàng chờ + các quyết định.
abstract interface class AdminQuanAnService {
  Stream<List<ViecAdminQuan>> hangCho();
  Future<GiayToQuan> giayTo(String quanId);

  /// Gọi tự do một hành động admin (ví dụ `adminXuLyBaoCao`).
  Future<Map<String, dynamic>> goi(String hanhDong, Map<String, dynamic> tham);

  /// `loai` ∈ 'quan' | 'chinh_sua' | 'nang_cap'.
  Future<void> duyet({
    required String loai,
    required String id,
    required bool dongY,
    String? lyDo,
    bool? daDoiChieuMst,
  });
  Future<void> yeuCauChuyenLoai(String quanId, String lyDo);
  Future<void> anHien(String quanId, {required bool an, required String lyDo});
  Future<void> dinhChi(
    String quanId, {
    required bool dinhChi,
    required String lyDo,
  });
  Future<void> khoaBan(String quanId, String lyDo);

  /// Khóa chức năng của người dùng trong Quán ăn: [chucNang] = khoaDatMon | khoaDatBan |
  /// khoaTienMat | khoaBaoCao...; định danh bằng [uid] hoặc [sdt].
  Future<void> khoaChucNang({
    String? uid,
    String? sdt,
    required String chucNang,
    required DateTime den,
    required String lyDo,
  });
  Future<void> xuLyBaoCao(Map<String, dynamic> tham);
  Future<void> xuLyKhangNghi(Map<String, dynamic> tham);
  Future<void> capNhatCauHinh(Map<String, dynamic> ghiDe);

  /// Kết luận quán lừa đảo: gắn cờ rà soát mọi đơn đang chạy, hủy bàn đã xác nhận,
  /// gửi đề nghị khóa tài khoản.
  Future<void> luaDao(String quanId, String lyDo);

  /// Quyết định đơn: `ADMIN_QUYET` (khiếu nại / phản đối), `ADMIN_QUA_HAN`, `ADMIN_LUA_DAO`.
  Future<void> thaoTacDon(String donId, int version, Map<String, dynamic> su);
}

class FirebaseAdminQuanAnService implements AdminQuanAnService {
  FirebaseAdminQuanAnService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final QuanAnApi api;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  DateTime _t(Object? v) => (v as Timestamp?)?.toDate() ?? DateTime.now();

  static const _donDangChay = {
    'placed',
    'accepted',
    'ready',
    'delivering',
    'delivered',
    'not_received',
    'disputed',
  };

  @override
  Stream<List<ViecAdminQuan>> hangCho() {
    final nguon = <Stream<List<ViecAdminQuan>>>[
      // Quán chờ duyệt.
      _f
          .collection('qa_quan')
          .where('trangThai', isEqualTo: 'pending_review')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdminQuan(
                  loai: 'quan',
                  id: d.id,
                  tieuDe: d.data()['ten'] as String? ?? '',
                  moTa: d.data()['diaChi'] as String? ?? '',
                  luc: _t(d.data()['guiDuyetLuc'] ?? d.data()['capNhatLuc']),
                  duLieu: d.data(),
                ),
            ],
          ),
      // Chỉnh sửa / nâng cấp loại chờ duyệt.
      _f
          .collection('qa_quan')
          .where('banChinhSua.loai', whereIn: ['sua', 'nang_cap'])
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdminQuan(
                  loai: (d.data()['banChinhSua'] as Map?)?['loai'] == 'nang_cap'
                      ? 'nang_cap'
                      : 'chinh_sua',
                  id: d.id,
                  tieuDe: d.data()['ten'] as String? ?? '',
                  moTa: (d.data()['banChinhSua'] as Map?)?['loai'] == 'nang_cap'
                      ? 'Nâng cấp lên hộ kinh doanh'
                      : 'Thông tin cần duyệt lại',
                  luc: _t((d.data()['banChinhSua'] as Map?)?['guiLuc']),
                  duLieu: d.data(),
                ),
            ],
          ),
      // Quán nghi khai sai loại (hạn chuyển loại còn trống = admin chưa yêu cầu chuyển).
      _f
          .collection('qa_quan')
          .where('khaiSaiLoai.hanChuyen', isNull: true)
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdminQuan(
                  loai: 'khai_sai_loai',
                  id: d.id,
                  tieuDe: d.data()['ten'] as String? ?? '',
                  moTa: 'Nghi khai bán lẻ nhưng hoạt động như hộ kinh doanh',
                  luc: _t(d.data()['capNhatLuc']),
                  uuTien: 2,
                  duLieu: d.data(),
                ),
            ],
          ),
      _f
          .collection('qa_bao_cao')
          .where('trangThai', isEqualTo: 'cho_xu_ly')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdminQuan(
                  loai: 'bao_cao',
                  id: d.id,
                  tieuDe:
                      'Báo cáo ${(d.data()['doiTuong'] as Map?)?['loai'] ?? ''}',
                  moTa: d.data()['lyDo'] as String? ?? '',
                  luc: _t(d.data()['luc']),
                  uuTien: d.data()['uuTienCao'] == true ? 1 : 3,
                  duLieu: d.data(),
                ),
            ],
          ),
      // Khiếu nại đơn + phản đối "khách không nhận" (cùng trạng thái disputed).
      _f
          .collection('qa_don')
          .where('status', isEqualTo: 'disputed')
          .snapshots()
          .map((s) {
            final ds = <ViecAdminQuan>[];
            for (final d in s.docs) {
              final x = d.data();
              final k = x['khieuNai'] as Map?;
              final phanDoi = k?['loai'] == 'phan_doi_khong_nhan';
              final traApp = x['cachTra'] == 'app';
              ds.add(
                ViecAdminQuan(
                  loai: phanDoi ? 'phan_doi' : 'khieu_nai_don',
                  id: d.id,
                  tieuDe:
                      '${phanDoi ? 'Phản đối' : 'Khiếu nại'} đơn ${x['tenQuan'] ?? ''}',
                  moTa: k?['lyDo'] as String? ?? k?['loai'] as String? ?? '',
                  luc: _t(k?['luc']),
                  uuTien: k?['coKhanLuc'] != null ? 0 : (traApp ? 1 : 3),
                  duLieu: x,
                ),
              );
            }
            return ds;
          }),
      // Đơn quá 6 giờ chưa có bằng chứng giao / nhận.
      _f
          .collection('qa_don')
          .where('coQuaHan', isEqualTo: true)
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                if (const {'ready', 'delivering'}.contains(d.data()['status']))
                  ViecAdminQuan(
                    loai: 'qua_han_6h',
                    id: d.id,
                    tieuDe: 'Đơn quá hạn ${d.data()['tenQuan'] ?? ''}',
                    moTa: 'Chưa có bằng chứng giao / nhận',
                    luc: _t(d.data()['hanQuaHan6h']),
                    uuTien: 2,
                    duLieu: d.data(),
                  ),
            ],
          ),
      // Đơn cần rà soát do quán bị kết luận lừa đảo.
      _f
          .collection('qa_don')
          .where('ruaSoatLuaDao', isEqualTo: true)
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                if (_donDangChay.contains(d.data()['status']))
                  ViecAdminQuan(
                    loai: 'rua_soat_lua_dao',
                    id: d.id,
                    tieuDe: 'Rà soát đơn ${d.data()['tenQuan'] ?? ''}',
                    moTa: 'Quán bị kết luận lừa đảo',
                    luc: _t(d.data()['capNhatLuc']),
                    uuTien: 2,
                    duLieu: d.data(),
                  ),
            ],
          ),
      _f
          .collection('qa_khang_nghi')
          .where('trangThai', isEqualTo: 'cho_xu_ly')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdminQuan(
                  loai: 'khang_nghi',
                  id: d.id,
                  tieuDe:
                      'Kháng nghị ${(d.data()['quyetDinh'] as Map?)?['loai'] ?? ''}',
                  moTa: d.data()['lyDo'] as String? ?? '',
                  luc: _t(d.data()['guiLuc']),
                  duLieu: d.data(),
                ),
            ],
          ),
    ];
    return _gop(nguon).map(sapXepHangCho);
  }

  /// Gộp nhiều stream danh sách thành 1 (giữ bản mới nhất của từng nguồn).
  Stream<List<ViecAdminQuan>> _gop(List<Stream<List<ViecAdminQuan>>> nguon) {
    final moiNhat = List<List<ViecAdminQuan>>.filled(nguon.length, const []);
    late final StreamController<List<ViecAdminQuan>> c;
    final subs = <StreamSubscription<List<ViecAdminQuan>>>[];
    c = StreamController<List<ViecAdminQuan>>(
      onListen: () {
        for (var i = 0; i < nguon.length; i++) {
          subs.add(
            nguon[i].listen((v) {
              moiNhat[i] = v;
              c.add([for (final x in moiNhat) ...x]);
            }, onError: c.addError),
          );
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return c.stream;
  }

  @override
  Future<GiayToQuan> giayTo(String quanId) async {
    final r = await api.goi('layGiayToQuan', {'quanId': quanId});
    final g = r['giayTo'];
    return GiayToQuan.fromMap(g is Map ? Map<String, dynamic>.from(g) : r);
  }

  @override
  Future<Map<String, dynamic>> goi(
    String hanhDong,
    Map<String, dynamic> tham,
  ) => api.goi(hanhDong, tham);

  @override
  Future<void> duyet({
    required String loai,
    required String id,
    required bool dongY,
    String? lyDo,
    bool? daDoiChieuMst,
  }) => api.goi('adminDuyet', {
    'loai': loai,
    'id': id,
    'dongY': dongY,
    'lyDo': ?lyDo,
    'daDoiChieuMst': ?daDoiChieuMst,
  });

  @override
  Future<void> yeuCauChuyenLoai(String quanId, String lyDo) =>
      api.goi('adminYeuCauChuyenLoai', {'quanId': quanId, 'lyDo': lyDo});

  @override
  Future<void> anHien(
    String quanId, {
    required bool an,
    required String lyDo,
  }) => api.goi('adminAnHien', {'quanId': quanId, 'an': an, 'lyDo': lyDo});

  @override
  Future<void> dinhChi(
    String quanId, {
    required bool dinhChi,
    required String lyDo,
  }) => api.goi('adminDinhChi', {
    'quanId': quanId,
    'dinhChi': dinhChi,
    'lyDo': lyDo,
  });

  @override
  Future<void> khoaBan(String quanId, String lyDo) =>
      api.goi('adminKhoaBan', {'quanId': quanId, 'lyDo': lyDo});

  @override
  Future<void> khoaChucNang({
    String? uid,
    String? sdt,
    required String chucNang,
    required DateTime den,
    required String lyDo,
  }) => api.goi('adminKhoaChucNang', {
    'uid': ?uid,
    'sdt': ?sdt,
    'chucNang': chucNang,
    'den': den.millisecondsSinceEpoch,
    'lyDo': lyDo,
  });

  @override
  Future<void> xuLyBaoCao(Map<String, dynamic> tham) =>
      api.goi('adminXuLyBaoCao', tham);

  @override
  Future<void> xuLyKhangNghi(Map<String, dynamic> tham) =>
      api.goi('adminXuLyKhangNghi', tham);

  @override
  Future<void> capNhatCauHinh(Map<String, dynamic> ghiDe) =>
      api.goi('adminCauHinh', {'ghiDe': ghiDe});

  @override
  Future<void> luaDao(String quanId, String lyDo) =>
      api.goi('adminLuaDao', {'quanId': quanId, 'lyDo': lyDo});

  @override
  Future<void> thaoTacDon(String donId, int version, Map<String, dynamic> su) =>
      api.goi('thaoTacDon', {'donId': donId, 'version': version, 'su': su});
}

// Dùng các model để hiển thị chi tiết việc trong màn hình admin.
QuanAn quanTuViec(ViecAdminQuan v) => QuanAn.fromMap(v.id, v.duLieu);
DonMon donTuViec(ViecAdminQuan v) => DonMon.fromMap(v.id, v.duLieu);
DatBan banTuViec(ViecAdminQuan v) => DatBan.fromMap(v.id, v.duLieu);
