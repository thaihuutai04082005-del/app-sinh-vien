import 'package:cloud_firestore/cloud_firestore.dart';

import 'gio_hang.dart';
import 'quan_an_config.dart';

DateTime? _t(Object? v) => v is Timestamp ? v.toDate() : null;

List<String> _ds(Object? v) => List<String>.from(v as List? ?? const []);

/// Trạng thái của một nút thao tác: có hiện không, bấm được không, vì sao mờ.
///
/// Ví dụ "Chưa nhận được món" của đơn đến lấy: hiện từ khi quán báo "Sẵn sàng" nhưng
/// MỜ cho tới T_lấy, kèm [giaiThich] (mục 3.4 Bước 5c).
class NutThaoTac {
  const NutThaoTac({this.hien = false, this.bam = false, this.giaiThich});

  static const an = NutThaoTac();
  static const bamDuoc = NutThaoTac(hien: true, bam: true);

  /// Nút mờ (hiện nhưng chưa bấm được) kèm lời giải thích.
  const NutThaoTac.mo(String this.giaiThich) : hien = true, bam = false;

  final bool hien;
  final bool bam;
  final String? giaiThich;
}

/// Một món đã chốt giá trong đơn (không đổi khi menu đổi).
class MonTrongDon {
  const MonTrongDon({
    required this.monId,
    required this.ten,
    required this.gia,
    this.soLuong = 1,
    this.tuyChon = const [],
    this.ghiChu = '',
    this.thanhTien = 0,
  });

  final String monId;
  final String ten;
  final num gia;
  final int soLuong;
  final List<TuyChonDaChon> tuyChon;
  final String ghiChu;
  final num thanhTien;

  /// "Cỡ: Lớn · Topping: Thêm trứng".
  String get tuyChonMoTa =>
      tuyChon.map((t) => '${t.nhom}: ${t.ten}').join(' · ');

  static MonTrongDon fromMap(Object? m) {
    final x = m as Map? ?? const {};
    return MonTrongDon(
      monId: x['monId'] as String? ?? '',
      ten: x['ten'] as String? ?? '',
      gia: x['gia'] as num? ?? 0,
      soLuong: (x['soLuong'] as num?)?.toInt() ?? 1,
      tuyChon: [
        for (final t in x['tuyChon'] as List? ?? const [])
          TuyChonDaChon.fromMap(t),
      ],
      ghiChu: x['ghiChu'] as String? ?? '',
      thanhTien: x['thanhTien'] as num? ?? 0,
    );
  }
}

class DiaChiGiao {
  const DiaChiGiao({this.dong = '', this.viTri, this.khoangCachKm});

  final String dong;
  final GeoPoint? viTri;
  final num? khoangCachKm;

  static DiaChiGiao? fromMap(Object? m) => m is Map
      ? DiaChiGiao(
          dong: m['dong'] as String? ?? '',
          viTri: m['viTri'] as GeoPoint?,
          khoangCachKm: m['khoangCachKm'] as num?,
        )
      : null;
}

/// Khuyến mãi đã áp (chốt lúc tạo đơn).
class KhuyenMaiApDung {
  const KhuyenMaiApDung({
    required this.id,
    required this.tieuDe,
    this.loai = '',
    this.giam = 0,
  });

  final String id;
  final String tieuDe;
  final String loai;
  final num giam;

  static KhuyenMaiApDung fromMap(Object? m) {
    final x = m as Map? ?? const {};
    return KhuyenMaiApDung(
      id: x['id'] as String? ?? '',
      tieuDe: x['tieuDe'] as String? ?? '',
      loai: x['loai'] as String? ?? '',
      giam: x['giam'] as num? ?? 0,
    );
  }
}

/// Ảnh giao hàng chụp trong app (có GPS) — bằng chứng đơn giao tận nơi.
class AnhGiao {
  const AnhGiao({required this.url, this.viTri, this.khoangCachM});

  final String url;
  final GeoPoint? viTri;
  final num? khoangCachM;

  static AnhGiao? fromMap(Object? m) => m is Map
      ? AnhGiao(
          url: m['url'] as String? ?? '',
          viTri: m['viTri'] as GeoPoint?,
          khoangCachM: m['khoangCachM'] as num?,
        )
      : null;
}

/// Quán báo "Khách không nhận" (mục 3.5b). Chỉ là báo cáo của quán, chưa phải kết luận.
class KhongNhan {
  const KhongNhan({
    required this.luc,
    required this.hanPhanDoi,
    this.anh = '',
    this.viTri,
    this.phanDoi = false,
    this.phanDoiLuc,
    this.moTaPhanDoi,
  });

  final DateTime luc;
  final DateTime hanPhanDoi;
  final String anh;
  final GeoPoint? viTri;
  final bool phanDoi;
  final DateTime? phanDoiLuc;
  final String? moTaPhanDoi;

  static KhongNhan? fromMap(Object? m) {
    if (m is! Map) return null;
    return KhongNhan(
      luc: _t(m['luc']) ?? DateTime.now(),
      hanPhanDoi: _t(m['hanPhanDoi']) ?? DateTime.now(),
      anh: m['anh'] as String? ?? '',
      viTri: m['viTri'] as GeoPoint?,
      phanDoi: m['phanDoi'] as bool? ?? false,
      phanDoiLuc: _t(m['phanDoiLuc']),
      moTaPhanDoi: m['moTaPhanDoi'] as String?,
    );
  }
}

/// Khiếu nại / "Chưa nhận được món" / phản đối "khách không nhận" / xác minh giao nhận.
class KhieuNaiDon {
  const KhieuNaiDon({
    required this.loai,
    this.lyDo = '',
    this.moTa = '',
    this.anh = const [],
    this.luc,
    this.hanChuTraLoi,
    this.coKhan = false,
    this.chuTraLoi,
    this.deNghiHoan,
    this.quyetDinh,
    this.soTienHoan,
    this.tinhBomHang = false,
    this.lyDoQuyet,
    this.chuTraLoiLuc,
  });

  /// 'khieu_nai' | 'chua_nhan_mon' | 'phan_doi_khong_nhan' | 'xac_minh'
  final String loai;
  final String lyDo;
  final String moTa;
  final List<String> anh;
  final DateTime? luc;
  final DateTime? hanChuTraLoi;
  final bool coKhan;
  final String? chuTraLoi;

  /// Quán đề nghị hoàn: 'hoan_toan' | 'hoan_mot_phan' | null.
  final String? deNghiHoan;

  /// 'hoan_toan' | 'hoan_mot_phan' | 'chuyen_cho_quan' | 'da_giao' | 'khong_giao' khi admin đã quyết.
  final String? quyetDinh;
  final num? soTienHoan;
  final bool tinhBomHang;
  final String? lyDoQuyet;
  final DateTime? chuTraLoiLuc;

  String get loaiLabel => loaiKhieuNaiDonLabels[loai] ?? loai;
  String get lyDoLabel => lyDoKhieuNaiDonLabels[lyDo] ?? lyDo;
  String? get quyetDinhLabel =>
      quyetDinh == null ? null : quyetDinhKhieuNaiLabels[quyetDinh];
  bool get daQuyet => quyetDinh != null;

  static KhieuNaiDon? fromMap(Object? m) {
    if (m is! Map) return null;
    return KhieuNaiDon(
      loai: m['loai'] as String? ?? 'khieu_nai',
      lyDo: m['lyDo'] as String? ?? '',
      moTa: m['moTa'] as String? ?? '',
      anh: _ds(m['anh']),
      luc: _t(m['luc']),
      hanChuTraLoi: _t(m['hanChuTraLoi']),
      coKhan: m['coKhanLuc'] != null || (m['coKhan'] as bool? ?? false),
      chuTraLoi: m['chuTraLoi'] as String?,
      deNghiHoan: m['deNghiHoan'] as String?,
      quyetDinh: m['quyetDinh'] as String?,
      soTienHoan: m['soTienHoan'] as num?,
      tinhBomHang: m['tinhBomHang'] as bool? ?? false,
      lyDoQuyet: m['lyDoQuyet'] as String?,
      chuTraLoiLuc: _t(m['chuTraLoiLuc']),
    );
  }
}

/// Một dòng của dòng thời gian đơn.
class MocLichSu {
  const MocLichSu({required this.trangThai, this.luc, this.ghiChu = ''});

  final String trangThai;
  final DateTime? luc;
  final String ghiChu;

  static MocLichSu? fromMap(Object? m) {
    if (m is! Map) return null;
    final tt =
        (m['status'] ?? m['trangThai'] ?? m['den'] ?? m['loai']) as String?;
    return MocLichSu(
      trangThai: tt ?? '',
      luc: _t(m['luc']),
      ghiChu: (m['ghiChu'] ?? m['lyDo'] ?? '') as String,
    );
  }
}

/// Đơn món — collection `qa_don` (mục 3.5i, hợp đồng dữ liệu).
///
/// Trạng thái do hệ thống đổi. Các hàm `co...` chỉ để quyết định hiện / bật nút nào; hệ thống
/// vẫn kiểm tra lại mọi điều kiện khi bấm. Mọi con số thời gian lấy từ [QuanAnConfig].
class DonMon {
  const DonMon({
    required this.id,
    required this.status,
    required this.version,
    required this.quanId,
    required this.chuQuanId,
    required this.svId,
    this.svSdt = '',
    this.tenQuan = '',
    this.anhBia = '',
    this.monAn = const [],
    this.cachNhan = 'den_lay',
    this.diaChiGiao,
    this.gio = 'asap',
    this.gioHen,
    this.sdtNhan = '',
    this.ghiChuQuan = '',
    this.tienMon = 0,
    this.giamCombo = 0,
    this.giamGia = 0,
    this.khuyenMaiApDung = const [],
    this.phiGiao = 0,
    this.tong = 0,
    this.cachTra = 'app',
    this.lyDoHuy,
    this.taoLuc,
    this.hanThanhToan,
    this.hanQuanNhan,
    this.gioDuKienSanSang,
    this.moHuyChamLuc,
    this.sanSangLuc,
    this.batDauGiaoLuc,
    this.tNhanMonDuKien,
    this.maNhanMonDaNhapLuc,
    this.anhGiao,
    this.bangChungLuc,
    this.bangChungLoai,
    this.hanKhieuNai,
    this.hanQuaHan6h,
    this.coQuaHan = false,
    this.ruaSoatLuaDao = false,
    this.khongNhan,
    this.khieuNai,
    this.daXacMinh = false,
    this.danhGiaHan,
    this.ketThucLuc,
    this.lyDoKetThuc,
    this.hanKeTiep,
    this.lichSu = const [],
    this.capNhatLuc,
  });

  final String id;
  final String status;
  final int version;
  final String quanId;
  final String chuQuanId;
  final String svId;
  final String svSdt;
  final String tenQuan;
  final String anhBia;
  final List<MonTrongDon> monAn;

  /// 'den_lay' | 'giao'
  final String cachNhan;
  final DiaChiGiao? diaChiGiao;

  /// 'asap' | 'hen'
  final String gio;
  final DateTime? gioHen;
  final String sdtNhan;
  final String ghiChuQuan;
  final num tienMon;
  final num giamCombo;
  final num giamGia;
  final List<KhuyenMaiApDung> khuyenMaiApDung;
  final num phiGiao;
  final num tong;

  /// 'app' | 'tien_mat'
  final String cachTra;
  final String? lyDoHuy;
  final DateTime? taoLuc;
  final DateTime? hanThanhToan;
  final DateTime? hanQuanNhan;

  /// Giờ dự kiến sẵn sàng (đơn hẹn giờ: giờ hẹn).
  final DateTime? gioDuKienSanSang;

  /// Lúc nút "Hủy vì quán chậm" mở (= giờ dự kiến sẵn sàng + thời gian quán chậm).
  final DateTime? moHuyChamLuc;

  /// Lúc quán báo "Sẵn sàng" (đọc từ trường `sanSangLuc` hoặc dòng `ready` trong lịch sử).
  final DateTime? sanSangLuc;
  final DateTime? batDauGiaoLuc;

  /// T_lấy: thời điểm nhận món dự kiến của đơn đến lấy.
  final DateTime? tNhanMonDuKien;
  final DateTime? maNhanMonDaNhapLuc;
  final AnhGiao? anhGiao;
  final DateTime? bangChungLuc;

  /// 'ma' | 'anh'
  final String? bangChungLoai;
  final DateTime? hanKhieuNai;
  final DateTime? hanQuaHan6h;
  final bool coQuaHan;
  final bool ruaSoatLuaDao;
  final KhongNhan? khongNhan;
  final KhieuNaiDon? khieuNai;

  /// Đủ điều kiện nhãn 🛵 cho đánh giá.
  final bool daXacMinh;
  final DateTime? danhGiaHan;
  final DateTime? ketThucLuc;
  final String? lyDoKetThuc;
  final DateTime? hanKeTiep;
  final List<MocLichSu> lichSu;
  final DateTime? capNhatLuc;

  // ---- Thuộc tính cơ bản ----
  bool get laDenLay => cachNhan == 'den_lay';
  bool get laGiao => cachNhan == 'giao';
  bool get traApp => cachTra == 'app';
  bool get laTienMat => cachTra == 'tien_mat';
  bool get laHenGio => gio == 'hen';
  bool get coBangChung => bangChungLuc != null;
  String get trangThaiLabel => trangThaiDonLabels[status] ?? status;
  String get cachNhanLabel => cachNhanLabels[cachNhan] ?? cachNhan;

  static const dangChay = {
    'pending_payment',
    'placed',
    'accepted',
    'ready',
    'delivering',
    'delivered',
    'not_received',
    'disputed',
  };
  static const daKetThuc = {
    'expired',
    'cancelled_student',
    'rejected',
    'expired_accept',
    'cancelled_restaurant',
    'completed',
    'refunded',
    'partially_refunded',
  };

  bool get dangDienRa => dangChay.contains(status);
  bool get ketThuc => daKetThuc.contains(status);

  /// Giờ khách thấy là "dự kiến": giờ hẹn nếu hẹn giờ, nếu không thì giờ dự kiến sẵn sàng.
  DateTime? get gioDuKien => laHenGio ? gioHen : gioDuKienSanSang;

  // ---- Sinh viên ----
  /// Nút "Thanh toán" còn bấm được (đơn trả trên app, chưa quá hạn chờ).
  bool coThanhToan(DateTime now) =>
      status == 'pending_payment' &&
      traApp &&
      (hanThanhToan == null || !now.isAfter(hanThanhToan!));

  /// Sinh viên hủy khi quán CHƯA nhận (hoàn 100%). Quán đã nhận thì không hủy được nữa.
  bool get coHuy => status == 'placed';

  /// Mốc mở nút "Hủy vì quán chậm": giờ dự kiến sẵn sàng + [QuanAnConfig.quanChamPhut].
  DateTime? mocHuyQuanCham(QuanAnConfig cfg) =>
      moHuyChamLuc ??
      gioDuKienSanSang?.add(QuanAnConfig.phut(cfg.quanChamPhut));

  /// "Hủy vì quán chậm": quán đã nhận nhưng chưa báo Sẵn sàng / Đang giao, và đã quá mốc chậm.
  bool coHuyQuanCham(DateTime now, {QuanAnConfig cfg = const QuanAnConfig()}) {
    if (status != 'accepted') return false;
    final moc = mocHuyQuanCham(cfg);
    return moc != null && !now.isBefore(moc);
  }

  /// Nút "Chưa nhận được món" (mục 3.4 Bước 5c).
  /// - Đến lấy, đã "Sẵn sàng": hiện nhưng MỜ trước T_lấy ([tNhanMonDuKien]), bấm được từ T_lấy.
  /// - Giao tận nơi "Đang giao": bấm được khi quá [QuanAnConfig.giaoLauPhut] kể từ lúc bắt đầu giao.
  /// - Đã có bằng chứng ("Chờ xác nhận nhận món"): bấm được trong hạn [hanKhieuNai].
  /// - Quán đã báo "Khách không nhận": sinh viên dùng nút "Phản đối" thay vào đó.
  NutThaoTac chuaNhanMon(DateTime now, QuanAnConfig cfg) {
    if (khongNhan != null) return NutThaoTac.an;
    switch (status) {
      case 'ready':
        if (!laDenLay) return NutThaoTac.an;
        final t = tNhanMonDuKien;
        if (t == null || !now.isBefore(t)) return NutThaoTac.bamDuoc;
        return const NutThaoTac.mo(
          'Bạn có thể báo chưa nhận được món từ thời điểm nhận món dự kiến.',
        );
      case 'delivering':
        final bd = batDauGiaoLuc;
        if (bd == null) return NutThaoTac.an;
        final moc = bd.add(QuanAnConfig.phut(cfg.giaoLauPhut));
        if (!now.isBefore(moc)) return NutThaoTac.bamDuoc;
        return NutThaoTac.mo(
          'Bạn có thể báo chưa nhận được món nếu quá ${cfg.giaoLauPhut} phút '
          'kể từ lúc quán bắt đầu giao.',
        );
      case 'delivered':
        final han = hanKhieuNai;
        if (han == null || !now.isAfter(han)) return NutThaoTac.bamDuoc;
        return NutThaoTac.an;
      default:
        return NutThaoTac.an;
    }
  }

  bool coChuaNhanMon(DateTime now, QuanAnConfig cfg) =>
      chuaNhanMon(now, cfg).bam;

  /// Khiếu nại (thiếu / sai / hư món...) chỉ cho đơn TRẢ TRÊN APP, trong hạn sau khi có bằng chứng.
  /// Đơn tiền mặt không mở khiếu nại tiền (dùng "Báo cáo").
  bool coKhieuNai(DateTime now) =>
      status == 'delivered' &&
      traApp &&
      (hanKhieuNai == null || !now.isAfter(hanKhieuNai!));

  /// "Đã nhận món" — chốt đơn, không khiếu nại được nữa. Bấm trước khi quán ghi bằng chứng cũng được.
  bool get coDaNhanMon =>
      status == 'ready' || status == 'delivering' || status == 'delivered';

  /// "Phản đối" việc quán báo khách không nhận, trong hạn 24 giờ.
  bool coPhanDoi(DateTime now) =>
      status == 'not_received' &&
      khongNhan != null &&
      !khongNhan!.phanDoi &&
      !now.isAfter(khongNhan!.hanPhanDoi);

  /// Còn hạn viết đánh giá sau khi hoàn tất.
  bool coDanhGia(DateTime now) =>
      status == 'completed' && danhGiaHan != null && !now.isAfter(danhGiaHan!);

  /// Nút "Đặt lại" khi đơn đã xong.
  bool get coDatLai => status == 'completed';

  // ---- Chủ quán ----
  bool coQuanNhan(DateTime now) =>
      status == 'placed' && (hanQuanNhan == null || !now.isAfter(hanQuanNhan!));

  bool coQuanTuChoi(DateTime now) => coQuanNhan(now);

  /// Quán hủy sau khi đã nhận (hoàn 100%, giảm tỷ lệ nhận đơn).
  bool get coQuanHuy => status == 'accepted';

  /// "Sẵn sàng" (đơn đến lấy).
  bool get coQuanSanSang => status == 'accepted' && laDenLay;

  /// "Đang giao" (đơn giao tận nơi).
  bool get coQuanDangGiao => status == 'accepted' && laGiao;

  /// "Nhập mã nhận món" (đơn đến lấy đã sẵn sàng, chưa nhập mã đúng).
  bool get coNhapMa =>
      status == 'ready' && laDenLay && maNhanMonDaNhapLuc == null;

  /// "Đã giao + chụp ảnh GPS" (đơn giao đang giao, chưa có ảnh).
  bool get coQuanDaGiao => status == 'delivering' && laGiao && anhGiao == null;

  /// "Khách không nhận": đơn giao — bất cứ lúc đang giao (bắt buộc ảnh GPS tại điểm giao);
  /// đơn đến lấy — sau [QuanAnConfig.khachKhongToiLayPhut] phút kể từ lúc "Sẵn sàng" (mờ trước đó).
  NutThaoTac quanKhongNhan(DateTime now, QuanAnConfig cfg) {
    if (khongNhan != null) return NutThaoTac.an;
    if (status == 'delivering' && laGiao) return NutThaoTac.bamDuoc;
    if (status == 'ready' && laDenLay) {
      final s = sanSangLuc;
      final moc = s?.add(QuanAnConfig.phut(cfg.khachKhongToiLayPhut));
      if (moc != null && !now.isBefore(moc)) return NutThaoTac.bamDuoc;
      return NutThaoTac.mo(
        'Chỉ báo khách không nhận sau ${cfg.khachKhongToiLayPhut} phút '
        'kể từ lúc đơn sẵn sàng.',
      );
    }
    return NutThaoTac.an;
  }

  bool coQuanKhongNhan(DateTime now, QuanAnConfig cfg) =>
      quanKhongNhan(now, cfg).bam;

  /// Quán còn trả lời được khiếu nại (đơn trả trên app, trong hạn 2 giờ, chưa trả lời).
  bool coQuanTraLoiKhieuNai(DateTime now) {
    final k = khieuNai;
    return status == 'disputed' &&
        traApp &&
        k != null &&
        (k.loai == 'khieu_nai' || k.loai == 'chua_nhan_mon') &&
        k.chuTraLoi == null &&
        (k.hanChuTraLoi == null || !now.isAfter(k.hanChuTraLoi!));
  }

  // ---- Admin ----
  bool get canAdminXuLy => status == 'disputed' || coQuaHan || ruaSoatLuaDao;

  // ---- Đếm ngược ----
  /// Mốc đếm ngược quan trọng nhất lúc này (để hiện banner); null nếu không có.
  (String, DateTime)? mocDemNguoc(DateTime now, QuanAnConfig cfg) {
    switch (status) {
      case 'pending_payment':
        return hanThanhToan == null ? null : ('Hạn thanh toán', hanThanhToan!);
      case 'placed':
        return hanQuanNhan == null
            ? null
            : ('Quán xác nhận trước', hanQuanNhan!);
      case 'accepted':
        final du = gioDuKienSanSang;
        if (du != null && now.isBefore(du)) {
          return ('Dự kiến sẵn sàng lúc', du);
        }
        final moc = mocHuyQuanCham(cfg);
        if (moc != null && now.isBefore(moc)) {
          return ('Có thể hủy vì quán chậm từ', moc);
        }
        return null;
      case 'ready':
        final t = tNhanMonDuKien;
        if (t != null && now.isBefore(t)) return ('Nhận món dự kiến lúc', t);
        return null;
      case 'delivering':
        final bd = batDauGiaoLuc;
        if (bd == null) return null;
        final moc = bd.add(QuanAnConfig.phut(cfg.giaoLauPhut));
        return now.isBefore(moc)
            ? ('Có thể báo chưa nhận được món từ', moc)
            : null;
      case 'delivered':
        return hanKhieuNai == null ? null : ('Tự hoàn tất lúc', hanKhieuNai!);
      case 'not_received':
        final k = khongNhan;
        return k != null && !k.phanDoi
            ? ('Hạn phản đối "khách không nhận"', k.hanPhanDoi)
            : null;
      case 'disputed':
        final k = khieuNai;
        return k != null && k.chuTraLoi == null && k.hanChuTraLoi != null
            ? ('Quán trả lời trước', k.hanChuTraLoi!)
            : null;
    }
    return null;
  }

  factory DonMon.fromMap(String id, Map<String, dynamic> m) {
    final lichSu = [
      for (final x in m['lichSu'] as List? ?? const []) ?MocLichSu.fromMap(x),
    ];
    DateTime? sanSang = _t(m['sanSangLuc']);
    if (sanSang == null) {
      for (final l in lichSu.reversed) {
        if (l.trangThai == 'ready' && l.luc != null) {
          sanSang = l.luc;
          break;
        }
      }
    }
    final dg = m['danhGia'] as Map?;
    return DonMon(
      id: id,
      status: m['status'] as String? ?? 'pending_payment',
      version: (m['version'] as num?)?.toInt() ?? 1,
      quanId: m['quanId'] as String? ?? '',
      chuQuanId: m['chuQuanId'] as String? ?? '',
      svId: m['svId'] as String? ?? '',
      svSdt: m['svSdt'] as String? ?? '',
      tenQuan: m['tenQuan'] as String? ?? '',
      anhBia: m['anhBia'] as String? ?? '',
      monAn: [
        for (final x in m['monAn'] as List? ?? const []) MonTrongDon.fromMap(x),
      ],
      cachNhan: m['cachNhan'] as String? ?? 'den_lay',
      diaChiGiao: DiaChiGiao.fromMap(m['diaChiGiao']),
      gio: m['gio'] as String? ?? 'asap',
      gioHen: _t(m['gioHen']),
      sdtNhan: m['sdtNhan'] as String? ?? '',
      ghiChuQuan: m['ghiChuQuan'] as String? ?? '',
      tienMon: m['tienMon'] as num? ?? 0,
      giamCombo: m['giamCombo'] as num? ?? 0,
      giamGia: m['giamGia'] as num? ?? 0,
      khuyenMaiApDung: [
        for (final x in m['khuyenMaiApDung'] as List? ?? const [])
          KhuyenMaiApDung.fromMap(x),
      ],
      phiGiao: m['phiGiao'] as num? ?? 0,
      tong: m['tong'] as num? ?? 0,
      cachTra: m['cachTra'] as String? ?? 'app',
      lyDoHuy: m['lyDoHuy'] as String?,
      taoLuc: _t(m['taoLuc']),
      hanThanhToan: _t(m['hanThanhToan']),
      hanQuanNhan: _t(m['hanQuanNhan']),
      gioDuKienSanSang: _t(m['gioDuKienSanSang']),
      moHuyChamLuc: _t(m['moHuyChamLuc']),
      sanSangLuc: sanSang,
      batDauGiaoLuc: _t(m['batDauGiaoLuc']),
      tNhanMonDuKien: _t(m['tNhanMonDuKien']),
      maNhanMonDaNhapLuc: _t(m['maNhanMonDaNhapLuc']),
      anhGiao: AnhGiao.fromMap(m['anhGiao']),
      bangChungLuc: _t(m['bangChungLuc']),
      bangChungLoai: m['bangChungLoai'] as String?,
      hanKhieuNai: _t(m['hanKhieuNai']),
      hanQuaHan6h: _t(m['hanQuaHan6h']),
      coQuaHan: m['coQuaHan'] as bool? ?? false,
      ruaSoatLuaDao: m['ruaSoatLuaDao'] as bool? ?? false,
      khongNhan: KhongNhan.fromMap(m['khongNhan']),
      khieuNai: KhieuNaiDon.fromMap(m['khieuNai']),
      daXacMinh: m['daXacMinh'] as bool? ?? false,
      danhGiaHan: _t(dg?['han']),
      ketThucLuc: _t(m['ketThucLuc']),
      lyDoKetThuc: m['lyDoKetThuc'] as String?,
      hanKeTiep: _t(m['hanKeTiep']),
      lichSu: lichSu,
      capNhatLuc: _t(m['capNhatLuc']),
    );
  }
}
