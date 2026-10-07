import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _t(Object? v) => (v as Timestamp?)?.toDate();

/// Khiếu nại "Chủ trọ không thực hiện đúng cam kết" hoặc phản đối "không đến" (mục 2.5c).
class KhieuNai {
  const KhieuNai({
    required this.loai,
    this.lyDo = '',
    this.moTa = '',
    this.bangChung = const [],
    this.luc,
    this.hanChuTraLoi,
    this.coKhan = false,
    this.chuTraLoi,
    this.chuTraLoiLuc,
    this.chuBangChung = const [],
    this.ketLuan,
    this.lyDoQuyet,
  });

  /// 'khieu_nai' | 'phan_doi'
  final String loai;
  final String lyDo;
  final String moTa;
  final List<String> bangChung;
  final DateTime? luc;
  final DateTime? hanChuTraLoi;
  final bool coKhan;
  final String? chuTraLoi;
  final DateTime? chuTraLoiLuc;
  final List<String> chuBangChung;

  /// 'chu_vi_pham' | 'sv_da_nhan' | 'sv_khong_den' khi admin đã quyết.
  final String? ketLuan;
  final String? lyDoQuyet;

  static const ketLuanLabels = {
    'chu_vi_pham': 'Chủ trọ vi phạm — hoàn 100% cho sinh viên',
    'sv_da_nhan': 'Sinh viên đã nhận phòng — chuyển tiền cho chủ trọ',
    'sv_khong_den': 'Sinh viên không đến — mất cọc',
  };

  static KhieuNai? fromMap(Object? m) {
    if (m is! Map) return null;
    final tl = m['chuTraLoi'] as Map?;
    final q = m['quyet'] as Map?;
    return KhieuNai(
      loai: m['loai'] as String? ?? 'khieu_nai',
      lyDo: m['lyDo'] as String? ?? '',
      moTa: m['moTa'] as String? ?? '',
      bangChung: List<String>.from(m['bangChung'] as List? ?? const []),
      luc: _t(m['luc']),
      hanChuTraLoi: _t(m['hanChuTraLoi']),
      coKhan: m['coKhan'] as bool? ?? false,
      chuTraLoi: tl?['noiDung'] as String?,
      chuTraLoiLuc: _t(tl?['luc']),
      chuBangChung: List<String>.from(tl?['bangChung'] as List? ?? const []),
      ketLuan: q?['ketLuan'] as String?,
      lyDoQuyet: q?['lyDo'] as String?,
    );
  }
}
