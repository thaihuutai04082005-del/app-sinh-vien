import 'package:cloud_firestore/cloud_firestore.dart';

import 'don_mon.dart';
import 'quan_an_config.dart';

DateTime? _t(Object? v) => v is Timestamp ? v.toDate() : null;

/// Đặt bàn — collection `qa_dat_ban` (mục 3.5j, hợp đồng dữ liệu). Không thu tiền.
///
/// Các hàm `co...` chỉ quyết định hiện / bật nút; hệ thống kiểm tra lại khi bấm.
class DatBan {
  const DatBan({
    required this.id,
    required this.status,
    required this.version,
    required this.quanId,
    required this.chuQuanId,
    required this.svId,
    required this.gio,
    required this.soNguoi,
    this.svSdt = '',
    this.tenQuan = '',
    this.ghiChu = '',
    this.taoLuc,
    this.hanXacNhan,
    this.hanGiuBan,
    this.hanTuDong,
    this.huySatGio = false,
    this.ghiNhanDen,
    this.checkInId,
    this.xacNhanLuc,
    this.nhacLuc,
    this.lichSu = const [],
  });

  final String id;
  final String status;
  final int version;
  final String quanId;
  final String chuQuanId;
  final String svId;
  final String svSdt;
  final String tenQuan;

  /// Giờ hẹn.
  final DateTime gio;
  final int soNguoi;
  final String ghiChu;
  final DateTime? taoLuc;

  /// Hạn quán xác nhận = min(gửi + 30 phút, giờ hẹn − 30 phút).
  final DateTime? hanXacNhan;

  /// Hết giờ giữ bàn (giờ hẹn + 15 phút).
  final DateTime? hanGiuBan;

  /// Hết giờ giữ bàn + 24 giờ: tự đóng nếu quán không bấm gì.
  final DateTime? hanTuDong;
  final bool huySatGio;

  /// 'quan' | 'check_in' | 'tu_dong' | null
  final String? ghiNhanDen;
  final String? checkInId;
  final DateTime? xacNhanLuc;
  final DateTime? nhacLuc;
  final List<MocLichSu> lichSu;

  String get trangThaiLabel => trangThaiBanLabels[status] ?? status;
  bool get dangChay => status == 'pending' || status == 'confirmed';

  /// Sinh viên đã check-in hợp lệ tại quán (có nhãn 🍽).
  bool get daCheckIn => ghiNhanDen == 'check_in';

  /// Hết giờ giữ bàn: dùng trường lưu sẵn, thiếu thì giờ hẹn + [QuanAnConfig.giuBanPhut].
  DateTime hetGiuBan(QuanAnConfig cfg) =>
      hanGiuBan ?? gio.add(QuanAnConfig.phut(cfg.giuBanPhut));

  /// Đang trong giờ giữ bàn (từ giờ hẹn tới hết giữ bàn).
  bool trongGioGiuBan(DateTime now, QuanAnConfig cfg) =>
      !now.isBefore(gio) && !now.isAfter(hetGiuBan(cfg));

  // ---- Chủ quán ----
  /// Xác nhận / từ chối khi còn chờ và chưa quá hạn xác nhận.
  bool coQuanXacNhan(DateTime now) =>
      status == 'pending' && (hanXacNhan == null || !now.isAfter(hanXacNhan!));

  bool coQuanTuChoi(DateTime now) => coQuanXacNhan(now);

  /// Quán hủy bàn đã xác nhận (giảm tỷ lệ giữ bàn) — còn trong giờ hẹn + giữ bàn.
  bool coQuanHuy(DateTime now, QuanAnConfig cfg) =>
      status == 'confirmed' && !now.isAfter(hetGiuBan(cfg));

  /// "Khách đã đến" (chỉ quản lý bàn, KHÔNG cấp nhãn 🍽).
  bool get coQuanKhachDen => status == 'confirmed' && ghiNhanDen == null;

  /// "Khách không đến": sau 15 phút giữ bàn; vô hiệu nếu sinh viên đã check-in hợp lệ.
  NutThaoTac quanKhachKhongDen(DateTime now, QuanAnConfig cfg) {
    if (status != 'confirmed') return NutThaoTac.an;
    if (daCheckIn) {
      return const NutThaoTac.mo('Khách đã check-in tại quán.');
    }
    final het = hetGiuBan(cfg);
    if (!now.isBefore(het)) return NutThaoTac.bamDuoc;
    return NutThaoTac.mo(
      'Quán giữ bàn ${cfg.giuBanPhut} phút kể từ giờ hẹn, bấm được sau mốc này.',
    );
  }

  bool coQuanKhongDen(DateTime now, QuanAnConfig cfg) =>
      quanKhachKhongDen(now, cfg).bam;

  // ---- Sinh viên ----
  /// Sinh viên hủy: khi chờ quán, hoặc bàn đã xác nhận còn trong giờ giữ bàn.
  bool coSvHuy(DateTime now, QuanAnConfig cfg) =>
      status == 'pending' ||
      (status == 'confirmed' && !now.isAfter(hetGiuBan(cfg)));

  /// Hủy bây giờ có bị tính 1 lần bỏ hẹn không: bàn ĐÃ xác nhận và còn dưới
  /// [QuanAnConfig.huySatGioPhut] phút tới giờ hẹn. Hủy khi quán chưa xác nhận: không phạt.
  bool huyBiTinhBoHen(DateTime now, QuanAnConfig cfg) =>
      status == 'confirmed' &&
      gio.difference(now) < QuanAnConfig.phut(cfg.huySatGioPhut);

  /// Nút Check-in của sinh viên cho lượt đặt bàn: bàn đã xác nhận, chưa ghi nhận đến,
  /// đang trong giờ giữ bàn.
  bool coSvCheckIn(DateTime now, QuanAnConfig cfg) =>
      status == 'confirmed' && ghiNhanDen == null && trongGioGiuBan(now, cfg);

  /// Đã tới lúc nhắc 1 giờ trước giờ hẹn (chỉ để hiển thị).
  bool get daNhac => nhacLuc != null;

  /// Mốc đếm ngược quan trọng nhất lúc này.
  (String, DateTime)? mocDemNguoc(DateTime now, QuanAnConfig cfg) {
    switch (status) {
      case 'pending':
        return hanXacNhan == null ? null : ('Quán xác nhận trước', hanXacNhan!);
      case 'confirmed':
        if (now.isBefore(gio)) return ('Giờ hẹn', gio);
        final het = hetGiuBan(cfg);
        if (!now.isAfter(het)) return ('Giữ bàn đến', het);
        final tu =
            hanTuDong ?? het.add(QuanAnConfig.phut(cfg.tuDongDongBanPhut));
        return now.isBefore(tu) ? ('Tự đóng lúc', tu) : null;
    }
    return null;
  }

  factory DatBan.fromMap(String id, Map<String, dynamic> m) => DatBan(
    id: id,
    status: m['status'] as String? ?? 'pending',
    version: (m['version'] as num?)?.toInt() ?? 1,
    quanId: m['quanId'] as String? ?? '',
    chuQuanId: m['chuQuanId'] as String? ?? '',
    svId: m['svId'] as String? ?? '',
    svSdt: m['svSdt'] as String? ?? '',
    tenQuan: m['tenQuan'] as String? ?? '',
    gio: _t(m['gio']) ?? DateTime.now(),
    soNguoi: (m['soNguoi'] as num?)?.toInt() ?? 1,
    ghiChu: m['ghiChu'] as String? ?? '',
    taoLuc: _t(m['taoLuc']),
    hanXacNhan: _t(m['hanXacNhan']),
    hanGiuBan: _t(m['hanGiuBan']),
    hanTuDong: _t(m['hanTuDong']),
    huySatGio: m['huySatGio'] as bool? ?? false,
    ghiNhanDen: m['ghiNhanDen'] as String?,
    checkInId: m['checkInId'] as String?,
    xacNhanLuc: _t(m['xacNhanLuc']),
    nhacLuc: _t(m['nhacLuc']),
    lichSu: [
      for (final x in m['lichSu'] as List? ?? const []) ?MocLichSu.fromMap(x),
    ],
  );
}
