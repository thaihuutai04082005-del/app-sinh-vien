import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _t(Object? v) => (v as Timestamp?)?.toDate();

/// Cuộc trò chuyện riêng của Quán ăn — mỗi cặp người dùng chỉ 1 cuộc (mục 3.8).
class CuocChat {
  const CuocChat({
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

  /// Mã cuộc chat: hai uid sắp xếp rồi nối bằng "_" (giống backend).
  static String maCuoc(String a, String b) => ([a, b]..sort()).join('_');

  factory CuocChat.fromMap(String id, Map<String, dynamic> m) => CuocChat(
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

/// Thẻ tin trong chat: trỏ tới một quán hoặc một đơn món (mục 3.8).
/// `loai`: 'quan' | 'don'.
class TheTin {
  const TheTin({
    required this.loai,
    required this.id,
    this.tieuDe = '',
    this.anh = '',
    this.gia,
  });

  static const loaiQuan = 'quan';
  static const loaiDon = 'don';

  final String loai;
  final String id;
  final String tieuDe;
  final String anh;

  /// Quán: giá trung vị món (nếu có); đơn: tổng tiền.
  final num? gia;

  bool get laQuan => loai == loaiQuan;
  bool get laDon => loai == loaiDon;

  factory TheTin.fromMap(Map<String, dynamic> m) => TheTin(
    loai: m['loai'] as String? ?? loaiQuan,
    id: m['id'] as String? ?? '',
    tieuDe: m['tieuDe'] as String? ?? '',
    anh: m['anh'] as String? ?? '',
    gia: m['gia'] as num?,
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

  /// Thẻ tin `{loai: 'quan'|'don', id, tieuDe, anh, gia}` (chỉ khi `loai == 'the_tin'`).
  final Map<String, dynamic>? the;
  final DateTime? guiLuc;
  final DateTime? daXemLuc;
  final List<String> tuKhoaCanhBao;

  /// 'hien' | 'an_tam' | 'an'
  final String hienThi;

  bool get coCanhBao => tuKhoaCanhBao.isNotEmpty;
  TheTin? get theTin => the == null ? null : TheTin.fromMap(the!);

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

/// Câu hỏi nhanh cho sinh viên (mục 3.4, 3.8). Dấu "…" để sinh viên điền rồi gửi.
const cauHoiNhanh = [
  'Quán còn mở không ạ?',
  'Quán có giao tới … không ạ?',
  'Món này còn không ạ?',
  'Còn bàn cho … người không ạ?',
];

/// Mẫu trả lời nhanh cho chủ quán (mục 3.8).
const mauTraLoiNhanh = [
  'Quán vẫn đang mở nha em.',
  'Quán có giao tới chỗ em nhé, em đặt món trên app giúp quán.',
  'Món này còn nha em.',
  'Còn bàn nha em, em đặt bàn trên app để quán giữ chỗ nhé.',
];

const canhBaoLuaDao =
    '⚠️ Hãy thanh toán qua app để được bảo vệ. Không chuyển tiền trước khi nhận món.';
