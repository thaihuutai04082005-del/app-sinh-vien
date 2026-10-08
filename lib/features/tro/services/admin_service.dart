import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dat_coc.dart';
import '../models/nha_tro.dart';
import '../models/phong_tro.dart';
import 'tro_api.dart';

/// Một việc trong hàng chờ admin Tìm trọ (mục 2.12).
class ViecAdmin {
  const ViecAdmin({
    required this.loai,
    required this.id,
    required this.tieuDe,
    required this.moTa,
    required this.luc,
    this.uuTien = 3,
    this.duLieu = const {},
  });

  /// nha_tro | phong | chinh_sua_nha | chinh_sua_phong | khieu_nai | bao_cao | khang_nghi
  final String loai;
  final String id;
  final String tieuDe;
  final String moTa;
  final DateTime luc;

  /// 0 = cờ khẩn, 1 = khiếu nại tiền / báo cáo ưu tiên cao, 2 = hồ sơ bị gắn cờ, 3 = còn lại.
  final int uuTien;
  final Map<String, dynamic> duLieu;

  static const loaiLabels = {
    'nha_tro': 'Nhà trọ',
    'phong': 'Phòng',
    'chinh_sua_nha': 'Chỉnh sửa chờ duyệt',
    'chinh_sua_phong': 'Chỉnh sửa chờ duyệt',
    'khieu_nai': 'Khiếu nại cọc',
    'bao_cao': 'Báo cáo',
    'khang_nghi': 'Kháng nghị',
  };
}

/// Hàng chờ sắp theo: cờ khẩn → khiếu nại tiền và báo cáo ưu tiên cao → hồ sơ bị gắn cờ → còn lại theo thời gian.
List<ViecAdmin> sapXepHangCho(List<ViecAdmin> ds) => [...ds]
  ..sort(
    (a, b) => a.uuTien != b.uuTien
        ? a.uuTien.compareTo(b.uuTien)
        : a.luc.compareTo(b.luc),
  );

abstract interface class AdminTroService {
  Stream<List<ViecAdmin>> hangCho();
  Future<List<String>> giayTo(String nhaTroId);
  Future<void> goi(String hanhDong, Map<String, dynamic> thamSo);
}

class FirebaseAdminTroService implements AdminTroService {
  FirebaseAdminTroService({required this.api, FirebaseFirestore? firestore})
    : _db = firestore;

  final TroApi api;
  final FirebaseFirestore? _db;

  FirebaseFirestore get _f => _db ?? FirebaseFirestore.instance;

  DateTime _t(Object? v) => (v as Timestamp?)?.toDate() ?? DateTime.now();

  @override
  Stream<List<ViecAdmin>> hangCho() {
    final nguon = <Stream<List<ViecAdmin>>>[
      _f
          .collection('nha_tro')
          .where('trangThai', isEqualTo: 'pending_review')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdmin(
                  loai: 'nha_tro',
                  id: d.id,
                  tieuDe: d.data()['ten'] as String? ?? '',
                  moTa: d.data()['diaChi'] as String? ?? '',
                  luc: _t(d.data()['guiDuyetLuc']),
                  uuTien: d.data()['coGanCo'] == true ? 2 : 3,
                  duLieu: d.data(),
                ),
            ],
          ),
      _f
          .collection('phong_tro')
          .where('trangThai', isEqualTo: 'pending_review')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdmin(
                  loai: 'phong',
                  id: d.id,
                  tieuDe: 'Phòng ${d.data()['ten'] ?? ''}',
                  moTa: (d.data()['nhaTro'] as Map?)?['ten'] as String? ?? '',
                  luc: _t(d.data()['guiDuyetLuc']),
                  duLieu: d.data(),
                ),
            ],
          ),
      _f
          .collection('nha_tro')
          .where('banChinhSua.trangThai', isEqualTo: 'cho')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdmin(
                  loai: 'chinh_sua_nha',
                  id: d.id,
                  tieuDe: 'Sửa: ${d.data()['ten'] ?? ''}',
                  moTa: 'Ảnh / video / vị trí mới',
                  luc: _t((d.data()['banChinhSua'] as Map?)?['guiLuc']),
                  duLieu: d.data(),
                ),
            ],
          ),
      _f
          .collection('phong_tro')
          .where('banChinhSua.trangThai', isEqualTo: 'cho')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdmin(
                  loai: 'chinh_sua_phong',
                  id: d.id,
                  tieuDe: 'Sửa phòng ${d.data()['ten'] ?? ''}',
                  moTa: 'Ảnh / video mới',
                  luc: _t((d.data()['banChinhSua'] as Map?)?['guiLuc']),
                  duLieu: d.data(),
                ),
            ],
          ),
      _f
          .collection('tro_dat_coc')
          .where('status', isEqualTo: 'disputed')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdmin(
                  loai: 'khieu_nai',
                  id: d.id,
                  tieuDe: 'Khiếu nại cọc ${d.data()['tenPhong'] ?? ''}',
                  moTa: d.data()['tenNhaTro'] as String? ?? '',
                  luc: _t((d.data()['khieuNai'] as Map?)?['luc']),
                  uuTien: (d.data()['khieuNai'] as Map?)?['coKhan'] == true
                      ? 0
                      : 1,
                  duLieu: d.data(),
                ),
            ],
          ),
      _f
          .collection('tro_bao_cao')
          .where('trangThai', isEqualTo: 'cho_xu_ly')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdmin(
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
      _f
          .collection('tro_khang_nghi')
          .where('trangThai', isEqualTo: 'cho_xu_ly')
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                ViecAdmin(
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
  Stream<List<ViecAdmin>> _gop(List<Stream<List<ViecAdmin>>> nguon) {
    final moiNhat = List<List<ViecAdmin>>.filled(nguon.length, const []);
    late final StreamController<List<ViecAdmin>> c;
    final subs = <StreamSubscription<List<ViecAdmin>>>[];
    c = StreamController<List<ViecAdmin>>(
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
  Future<List<String>> giayTo(String nhaTroId) async {
    final s = await _f
        .collection('nha_tro')
        .doc(nhaTroId)
        .collection('rieng')
        .doc('giay_to')
        .get();
    return List<String>.from(s.data()?['giayTo'] as List? ?? const []);
  }

  @override
  Future<void> goi(String hanhDong, Map<String, dynamic> thamSo) =>
      api.goi(hanhDong, thamSo);
}

// Dùng các model để hiển thị chi tiết việc trong màn hình admin.
NhaTro nhaTuViec(ViecAdmin v) => NhaTro.fromMap(v.id, v.duLieu);
PhongTro phongTuViec(ViecAdmin v) => PhongTro.fromMap(v.id, v.duLieu);
DatCoc cocTuViec(ViecAdmin v) => DatCoc.fromMap(v.id, v.duLieu);
