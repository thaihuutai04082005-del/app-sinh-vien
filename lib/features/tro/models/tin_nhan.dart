import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _t(Object? v) => (v as Timestamp?)?.toDate();

/// Cuộc trò chuyện riêng của Tìm trọ — mỗi cặp người dùng chỉ 1 cuộc (mục 2.8).
class CuocTroChuyen {
  const CuocTroChuyen({
    required this.id,
    required this.thanhVien,
    this.tinCuoi = '',
    this.tinCuoiLuc,
    this.chuaDoc = const {},
    this.chanBoi = const [],
    this.ten = const {},
  });

  final String id;
  final List<String> thanhVien;
  final Map<String, String> ten;
  final String tinCuoi;
  final DateTime? tinCuoiLuc;
  final Map<String, int> chuaDoc;
  final List<String> chanBoi;

  String nguoiKia(String uid) =>
      thanhVien.firstWhere((x) => x != uid, orElse: () => '');
  String tenNguoiKia(String uid) => ten[nguoiKia(uid)] ?? 'Người dùng';
  int chuaDocCua(String uid) => chuaDoc[uid] ?? 0;
  bool get biChan => chanBoi.isNotEmpty;

  static String maCuoc(String a, String b) => ([a, b]..sort()).join('_');

  factory CuocTroChuyen.fromMap(String id, Map<String, dynamic> m) =>
      CuocTroChuyen(
        id: id,
        thanhVien: List<String>.from(m['thanhVien'] as List? ?? const []),
        tinCuoi: m['tinCuoi'] as String? ?? '',
        tinCuoiLuc: _t(m['tinCuoiLuc']),
        chuaDoc: {
          for (final e in ((m['chuaDoc'] as Map?) ?? const {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
        chanBoi: List<String>.from(m['chanBoi'] as List? ?? const []),
        ten: {
          for (final e in ((m['ten'] as Map?) ?? const {}).entries)
            e.key as String: e.value as String,
        },
      );
}

class TinNhan {
  const TinNhan({
    required this.id,
    required this.nguoiGui,
    required this.loai,
    this.noiDung = '',
    this.the,
    this.guiLuc,
    this.daXemLuc,
    this.tuKhoaCanhBao = const [],
    this.hienThi = 'hien',
  });

  final String id;
  final String nguoiGui;

  /// 'chu' | 'anh' | 'the_tin'
  final String loai;
  final String noiDung;
  final Map<String, dynamic>? the;
  final DateTime? guiLuc;
  final DateTime? daXemLuc;
  final List<String> tuKhoaCanhBao;

  /// 'hien' | 'an_tam' | 'an'
  final String hienThi;

  bool get coCanhBao => tuKhoaCanhBao.isNotEmpty;

  factory TinNhan.fromMap(String id, Map<String, dynamic> m) => TinNhan(
    id: id,
    nguoiGui: m['nguoiGui'] as String? ?? '',
    loai: m['loai'] as String? ?? 'chu',
    noiDung: m['noiDung'] as String? ?? '',
    the: (m['the'] as Map?)?.cast<String, dynamic>(),
    guiLuc: _t(m['guiLuc']),
    daXemLuc: _t(m['daXemLuc']),
    tuKhoaCanhBao: List<String>.from(m['tuKhoaCanhBao'] as List? ?? const []),
    hienThi: m['hienThi'] as String? ?? 'hien',
  );
}

/// Câu hỏi nhanh cho sinh viên và mẫu trả lời nhanh cho chủ trọ (mục 2.4, 2.8).
const cauHoiNhanh = [
  'Phòng còn trống không ạ?',
  'Em qua xem phòng lúc … được không ạ?',
  'Giá đã gồm điện nước chưa ạ?',
  'Có chỗ để xe không ạ?',
];

const mauTraLoiNhanh = [
  'Phòng còn trống nha em.',
  'Em qua xem lúc nào cũng được, nhắn trước giúp anh/chị nhé.',
  'Giá chưa gồm điện nước, chi tiết có trong bảng chi phí.',
  'Muốn giữ phòng em đặt cọc trên app để được bảo vệ nhé.',
];

const canhBaoLuaDao =
    '⚠️ Hãy đặt cọc qua app để được bảo vệ. Không chuyển tiền cọc ngoài app.';
