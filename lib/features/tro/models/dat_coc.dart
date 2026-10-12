import 'package:cloud_firestore/cloud_firestore.dart';

import 'khieu_nai.dart';
import 'tro_config.dart';

DateTime? _t(Object? v) => (v as Timestamp?)?.toDate();

/// Yêu cầu thay đổi thời điểm nhận phòng (mục 2.5b).
class YeuCauDoi {
  const YeuCauDoi({
    required this.thoiDiemMoi,
    required this.hanTraLoi,
    required this.ketQua,
    this.guiLuc,
    this.tCu,
  });

  final DateTime thoiDiemMoi;
  final DateTime hanTraLoi;

  /// 'cho' | 'dong_y' | 'tu_choi' | 'qua_han' | 'dong'
  final String ketQua;
  final DateTime? guiLuc;
  final DateTime? tCu;

  bool get dangCho => ketQua == 'cho';

  static YeuCauDoi? fromMap(Object? m) {
    if (m is! Map) return null;
    return YeuCauDoi(
      thoiDiemMoi: _t(m['thoiDiemMoi'])!,
      hanTraLoi: _t(m['hanTraLoi'])!,
      ketQua: m['ketQua'] as String? ?? 'cho',
      guiLuc: _t(m['guiLuc']),
      tCu: _t(m['tCu']),
    );
  }
}

/// Chủ trọ báo "Sinh viên không đến nhận phòng" (mục 2.4 Bước 4).
class BaoKhongDen {
  const BaoKhongDen({
    required this.luc,
    required this.hanPhanDoi,
    this.phanDoi = false,
  });

  final DateTime luc;
  final DateTime hanPhanDoi;
  final bool phanDoi;

  static BaoKhongDen? fromMap(Object? m) {
    if (m is! Map) return null;
    return BaoKhongDen(
      luc: _t(m['luc'])!,
      hanPhanDoi: _t(m['hanPhanDoi'])!,
      phanDoi: m['phanDoi'] as bool? ?? false,
    );
  }
}

/// Khoản cọc trên app — collection `tro_dat_coc` (mục 2.5g, 2.17).
///
/// Trạng thái do hệ thống đổi. Các hàm `co...` dưới đây chỉ để quyết định hiện nút nào;
/// hệ thống vẫn kiểm tra lại mọi điều kiện khi bấm (mục 2.18 quy tắc 4).
class DatCoc {
  const DatCoc({
    required this.id,
    required this.status,
    required this.version,
    required this.phongId,
    required this.nhaTroId,
    required this.chuTroId,
    required this.sinhVienId,
    required this.soTien,
    required this.t,
    this.tBanDau,
    this.tenPhong = '',
    this.tenNhaTro = '',
    this.anhBia = '',
    this.coQuyenHuyMienPhi = false,
    this.hanThanhToan,
    this.heldAt,
    this.hanHuyMienPhi,
    this.ngayVaoO,
    this.daDungDoi = false,
    this.doi,
    this.khongDen,
    this.khieuNai,
    this.danhGiaNhan,
    this.danhGiaHan,
    this.danhGiaTinhDiem = false,
    this.lyDoKetThuc,
    this.ketThucLuc,
    this.chupThongTin,
    this.taoLuc,
  });

  final String id;
  final String status;
  final int version;
  final String phongId;
  final String nhaTroId;
  final String chuTroId;
  final String sinhVienId;
  final num soTien;

  /// T — thời điểm nhận phòng hiện hành.
  final DateTime t;
  final DateTime? tBanDau;
  final String tenPhong;
  final String tenNhaTro;
  final String anhBia;
  final bool coQuyenHuyMienPhi;
  final DateTime? hanThanhToan;
  final DateTime? heldAt;
  final DateTime? hanHuyMienPhi;
  final DateTime? ngayVaoO;
  final bool daDungDoi;
  final YeuCauDoi? doi;
  final BaoKhongDen? khongDen;
  final KhieuNai? khieuNai;
  final String? danhGiaNhan;
  final DateTime? danhGiaHan;
  final bool danhGiaTinhDiem;
  final String? lyDoKetThuc;
  final DateTime? ketThucLuc;
  final Map<String, dynamic>? chupThongTin;
  final DateTime? taoLuc;

  static const dangChay = {'pending_payment', 'held', 'disputed'};

  bool get dangDienRa => dangChay.contains(status);
  bool get dangGiu => status == 'held';
  String get trangThaiLabel => trangThaiCocLabels[status] ?? status;

  // ---- Sinh viên ----
  bool coHuyMienPhi(DateTime now) =>
      dangGiu &&
      coQuyenHuyMienPhi &&
      hanHuyMienPhi != null &&
      !now.isAfter(hanHuyMienPhi!);

  bool coKhongThue(DateTime now) =>
      dangGiu && now.isBefore(t) && !coHuyMienPhi(now);

  bool coYeuCauDoi(DateTime now, TroConfig cfg) =>
      dangGiu &&
      !daDungDoi &&
      t.difference(now) > TroConfig.phut(cfg.doiPhaiTruocPhut);

  bool coDaNhanPhong(DateTime now) =>
      dangGiu && !now.isBefore(t) && khongDen == null;

  bool coKhieuNai(DateTime now, TroConfig cfg) =>
      dangGiu &&
      !now.isBefore(t) &&
      !now.isAfter(t.add(TroConfig.phut(cfg.khieuNaiDenPhut))) &&
      khongDen == null;

  bool coPhanDoi(DateTime now) =>
      dangGiu &&
      khongDen != null &&
      !khongDen!.phanDoi &&
      !now.isAfter(khongDen!.hanPhanDoi);

  bool get coDanhGia =>
      danhGiaHan != null && DateTime.now().isBefore(danhGiaHan!);

  // ---- Chủ trọ ----
  bool coHuyCoc(DateTime now) => dangGiu && now.isBefore(t);

  bool get coTraLoiDoi => dangGiu && doi != null && doi!.dangCho;

  bool coBaoKhongDen(DateTime now, TroConfig cfg) =>
      dangGiu &&
      khongDen == null &&
      !now.isBefore(t.add(TroConfig.phut(cfg.anHanKhongDenPhut))) &&
      !now.isAfter(t.add(TroConfig.phut(cfg.baoKhongDenDenPhut)));

  bool get coTraLoiKhieuNai =>
      status == 'disputed' &&
      khieuNai != null &&
      khieuNai!.chuTraLoi == null &&
      (khieuNai!.hanChuTraLoi == null ||
          DateTime.now().isBefore(khieuNai!.hanChuTraLoi!));

  /// Mốc đếm ngược quan trọng nhất lúc này (để hiện banner).
  (String, DateTime)? mocDemNguoc(DateTime now, TroConfig cfg) {
    if (status == 'pending_payment' && hanThanhToan != null) {
      return ('Hạn thanh toán', hanThanhToan!);
    }
    if (!dangGiu) return null;
    if (khongDen != null && !khongDen!.phanDoi) {
      return ('Hạn phản đối "không đến"', khongDen!.hanPhanDoi);
    }
    if (doi != null && doi!.dangCho) {
      return ('Chủ trọ trả lời yêu cầu thay đổi trước', doi!.hanTraLoi);
    }
    if (coHuyMienPhi(now)) return ('Hủy miễn phí tới', hanHuyMienPhi!);
    if (now.isBefore(t)) return ('Thời điểm nhận phòng', t);
    return ('Tự hoàn tất lúc', t.add(TroConfig.phut(cfg.tuHoanTatPhut)));
  }

  factory DatCoc.fromMap(String id, Map<String, dynamic> m) {
    final dg = m['danhGia'] as Map?;
    return DatCoc(
      id: id,
      status: m['status'] as String? ?? 'pending_payment',
      version: (m['version'] as num?)?.toInt() ?? 1,
      phongId: m['phongId'] as String? ?? '',
      nhaTroId: m['nhaTroId'] as String? ?? '',
      chuTroId: m['chuTroId'] as String? ?? '',
      sinhVienId: m['sinhVienId'] as String? ?? '',
      soTien: m['soTien'] as num? ?? 0,
      t: _t(m['t']) ?? DateTime.now(),
      tBanDau: _t(m['tBanDau']),
      tenPhong: m['tenPhong'] as String? ?? '',
      tenNhaTro: m['tenNhaTro'] as String? ?? '',
      anhBia: m['anhBia'] as String? ?? '',
      coQuyenHuyMienPhi: m['coQuyenHuyMienPhi'] as bool? ?? false,
      hanThanhToan: _t(m['hanThanhToan']),
      heldAt: _t(m['heldAt']),
      hanHuyMienPhi: _t(m['hanHuyMienPhi']),
      ngayVaoO: _t(m['ngayVaoO']),
      daDungDoi: m['daDungDoi'] as bool? ?? false,
      doi: YeuCauDoi.fromMap(m['doi']),
      khongDen: BaoKhongDen.fromMap(m['khongDen']),
      khieuNai: KhieuNai.fromMap(m['khieuNai']),
      danhGiaNhan: dg?['nhan'] as String?,
      danhGiaHan: _t(dg?['han']),
      danhGiaTinhDiem: dg?['tinhDiem'] as bool? ?? false,
      lyDoKetThuc: m['lyDoKetThuc'] as String?,
      ketThucLuc: _t(m['ketThucLuc']),
      chupThongTin: (m['chupThongTin'] as Map?)?.cast<String, dynamic>(),
      taoLuc: _t(m['taoLuc']),
    );
  }
}
