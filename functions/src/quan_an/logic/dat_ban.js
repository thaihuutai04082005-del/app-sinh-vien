'use strict';

/**
 * Máy trạng thái đặt bàn (đặc tả mục 3.4 Bước 4, 3.5e, 3.5j). Logic THUẦN.
 * Đặt bàn KHÔNG thu tiền. Thời điểm tính bằng mili giây.
 */

const { PHUT } = require('../config');

const TT = Object.freeze({
  choXacNhan: 'pending',
  daXacNhan: 'confirmed',
  tuChoi: 'rejected',
  hetHan: 'expired',
  svHuy: 'cancelled_student',
  quanHuy: 'cancelled_restaurant',
  daDen: 'arrived',
  khongDen: 'no_show',
});

const p = (cfg, khoa) => cfg[khoa] * PHUT;
const loi = (thongDiep) => ({ loi: thongDiep });

/** Kiểm tra lúc đặt bàn. `trongGioMoCua` do hệ thống tính từ lịch tuần tại giờ hẹn. */
function kiemTraDatBan({ now, gio, soNguoi, trongGioMoCua }, cfg) {
  if (!Number.isFinite(gio)) return 'Chọn ngày giờ.';
  if (gio < now + p(cfg, 'datBanCachItNhatPhut')) return 'Giờ hẹn phải cách bây giờ ít nhất 1 giờ.';
  if (gio > now + p(cfg, 'datBanToiDaPhut')) return 'Chỉ đặt bàn trước tối đa 7 ngày.';
  if (!Number.isInteger(soNguoi) || soNguoi < cfg.datBanSoNguoiToiThieu || soNguoi > cfg.datBanSoNguoiToiDa) {
    return `Số người từ ${cfg.datBanSoNguoiToiThieu} đến ${cfg.datBanSoNguoiToiDa}.`;
  }
  if (!trongGioMoCua) return 'Quán không mở cửa vào giờ này.';
  return null;
}

/** Tạo yêu cầu đặt bàn: quán xác nhận trong min(30 phút, giờ hẹn − 30 phút). */
function taoBan({ now, gio }, cfg) {
  const hanXacNhan = Math.min(now + p(cfg, 'datBanQuanXacNhanPhut'), gio - p(cfg, 'datBanXacNhanTruocGioHenPhut'));
  const hanGiuBan = gio + p(cfg, 'giuBanPhut');
  return {
    status: TT.choXacNhan, version: 1, gio, taoLuc: now,
    hanXacNhan, hanGiuBan, hanTuDong: hanGiuBan + p(cfg, 'banTuDongDongPhut'),
    huySatGio: false, ghiNhanDen: null, xacNhanLuc: null, daXuLy: {}, lyDoKetThuc: null, ketThucLuc: null,
  };
}

const sao = (d) => ({ ...d, daXuLy: { ...(d.daXuLy || {}) } });
const rong = (d) => ({ d, viPham: [], thongBao: [], laNhac: false });

/** Áp một sự kiện. Trả về { loi } | { boQua } | kết quả có tác động. */
function apDung(dGoc, su, now, cfg) {
  const d = sao(dGoc);
  const S = TT;
  switch (su.loai) {
    case 'QUAN_XAC_NHAN': {
      if (d.status !== S.choXacNhan) return loi('Yêu cầu đặt bàn này không còn chờ xác nhận.');
      if (now > d.hanXacNhan) return loi('Đã quá hạn xác nhận.');
      d.status = S.daXacNhan;
      d.xacNhanLuc = now;
      const r = rong(d);
      r.thongBao.push({ toi: 'sv', loai: 'ban_da_xac_nhan' });
      return r;
    }
    case 'QUAN_TU_CHOI': {
      if (d.status !== S.choXacNhan) return loi('Yêu cầu đặt bàn này không còn chờ xác nhận.');
      d.status = S.tuChoi;
      d.ketThucLuc = now;
      const r = rong(d);
      r.thongBao.push({ toi: 'sv', loai: 'ban_bi_tu_choi' });
      return r;
    }
    case 'SV_HUY': {
      if (![S.choXacNhan, S.daXacNhan].includes(d.status)) return loi('Đặt bàn này không hủy được.');
      const r = rong(d);
      // Hủy khi quán CHƯA xác nhận: không phạt, dù sát giờ. Bàn đã xác nhận: hủy sát giờ (< 1 giờ) tính 1 lần bỏ hẹn.
      if (d.status === S.daXacNhan && d.gio - now < p(cfg, 'huySatGioPhut')) {
        d.huySatGio = true;
        r.viPham.push('bo_hen_dat_ban');
        r.thongBao.push({ toi: 'sv', loai: 'huy_sat_gio_bi_ghi' });
      }
      d.status = S.svHuy;
      d.ketThucLuc = now;
      r.thongBao.push({ toi: 'chu', loai: 'sv_huy_ban' });
      return r;
    }
    case 'QUAN_HUY': {
      if (d.status !== S.daXacNhan) return loi('Chỉ hủy được bàn đã xác nhận.');
      d.status = S.quanHuy;
      d.ketThucLuc = now;
      d.lyDoKetThuc = su.lyDo || 'quan_huy'; // 'quan_huy' / 'quan_tam_nghi' tính vào tỷ lệ giữ bàn; 'admin_an' thì không
      const r = rong(d);
      r.thongBao.push({ toi: 'sv', loai: 'ban_bi_quan_huy' });
      return r;
    }
    case 'QUAN_KHACH_DEN': {
      if (d.status !== S.daXacNhan) return loi('Chỉ ghi nhận khách đến cho bàn đã xác nhận.');
      d.status = S.daDen;
      d.ghiNhanDen = 'quan'; // chỉ để quản lý bàn, KHÔNG cấp nhãn 🍽
      d.ketThucLuc = now;
      return rong(d);
    }
    case 'SV_CHECK_IN': {
      // Check-in hợp lệ của sinh viên: trong khoảng giờ giữ bàn → cấp nhãn 🍽 và vô hiệu "Khách không đến".
      const tu = d.gio - p(cfg, 'checkInSomPhut');
      if (![S.daXacNhan, S.daDen].includes(d.status)) return { boQua: true, d };
      if (now < tu || now > d.hanGiuBan) return { boQua: true, d };
      if (d.status === S.daDen && d.ghiNhanDen === 'check_in') return { boQua: true, d };
      d.status = S.daDen;
      d.ghiNhanDen = 'check_in';
      d.ketThucLuc = d.ketThucLuc || now;
      return rong(d);
    }
    case 'QUAN_KHONG_DEN': {
      if (d.status !== S.daXacNhan) return loi('Chỉ báo "Khách không đến" cho bàn đã xác nhận.');
      if (now < d.hanGiuBan) return loi('Quán giữ bàn 15 phút, hết giờ giữ bàn mới báo khách không đến được.');
      d.status = S.khongDen;
      d.ketThucLuc = now;
      const r = rong(d);
      r.viPham.push('bo_hen_dat_ban');
      r.thongBao.push({ toi: 'sv', loai: 'bi_ghi_bo_hen' });
      return r;
    }
    case 'QUAN_NGUNG_NHAN': {
      // Quán tạm nghỉ / bị ẩn / đình chỉ / bị kết luận lừa đảo.
      if (d.status === S.choXacNhan) {
        d.status = S.tuChoi;
        d.ketThucLuc = now;
        const r = rong(d);
        r.thongBao.push({ toi: 'sv', loai: 'ban_bi_tu_choi' });
        return r;
      }
      if (d.status === S.daXacNhan) {
        d.status = S.quanHuy;
        d.ketThucLuc = now;
        d.lyDoKetThuc = su.lyDo || 'quan_tam_nghi';
        const r = rong(d);
        r.thongBao.push({ toi: 'sv', loai: 'ban_bi_quan_huy' });
        return r;
      }
      return { boQua: true, d };
    }
    default:
      return loi('Thao tác không hợp lệ.');
  }
}

/** Xử lý mọi hạn đã tới (mục 3.18 quy tắc 6). Mỗi hạn chỉ 1 lần. */
function xuLyHan(dGoc, now, cfg) {
  let d = sao(dGoc);
  const tacDong = [];
  const S = TT;
  if (d.status === S.choXacNhan && now > d.hanXacNhan) {
    d.status = S.hetHan;
    d.ketThucLuc = now;
    const r = rong(d);
    r.thongBao.push({ toi: 'sv', loai: 'ban_het_han' });
    tacDong.push({ ...r, d: undefined, khoa: 'HET_HAN_XAC_NHAN' });
  } else if (d.status === S.daXacNhan) {
    if (now >= d.gio - p(cfg, 'nhacDatBanPhut') && now < d.gio && !d.daXuLy.nhac) {
      d.daXuLy.nhac = true;
      const r = rong(d);
      r.laNhac = true;
      r.thongBao.push({ toi: 'sv', loai: 'nhac_dat_ban' });
      tacDong.push({ ...r, d: undefined, khoa: 'NHAC_1H', laNhac: true });
    }
    if (now >= d.hanTuDong) {
      // Quán không bấm gì: tự đóng, không tính bỏ hẹn, KHÔNG cấp nhãn 🍽.
      d.status = S.daDen;
      d.ghiNhanDen = 'tu_dong';
      d.ketThucLuc = now;
      tacDong.push({ ...rong(d), d: undefined, khoa: 'TU_DONG_DONG' });
    }
  }
  return { d, tacDong };
}

function hanKeTiep(d, cfg) {
  const ds = [];
  if (d.status === TT.choXacNhan) ds.push(d.hanXacNhan + 1);
  if (d.status === TT.daXacNhan) {
    if (!(d.daXuLy || {}).nhac) ds.push(d.gio - p(cfg, 'nhacDatBanPhut'));
    ds.push(d.hanTuDong);
  }
  return ds.length ? Math.min(...ds) : null;
}

module.exports = { TT, kiemTraDatBan, taoBan, apDung, xuLyHan, hanKeTiep };
