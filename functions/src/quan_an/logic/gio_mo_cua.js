'use strict';

/**
 * Giờ mở cửa của quán (đặc tả mục 3.2): lịch tuần, tối đa 2 ca / ngày, ca qua nửa đêm thuộc
 * ngày bắt đầu ca, tạm nghỉ hôm nay / nghỉ dài ngày. Logic THUẦN, mọi giờ tính theo UTC+7.
 *
 * Lịch: { "1": [{ tu, den }], ..., "7": [...] } — "1" = Thứ hai … "7" = Chủ nhật,
 * `tu` / `den` là phút từ 00:00 (0–1439); `den < tu` nghĩa là ca kéo qua nửa đêm.
 */

const PHUT_MS = 60 * 1000;
const NGAY_MS = 24 * 60 * PHUT_MS;
const LECH_VN_MS = 7 * 60 * PHUT_MS;

/** Mốc 00:00 (giờ Việt Nam) của ngày chứa thời điểm `t`, trả về mili giây UTC. */
function dauNgayVn(t) {
  return Math.floor((t + LECH_VN_MS) / NGAY_MS) * NGAY_MS - LECH_VN_MS;
}

/** Thứ trong tuần theo giờ Việt Nam: 1 = Thứ hai … 7 = Chủ nhật. */
function thuVn(t) {
  const ngay = Math.floor((t + LECH_VN_MS) / NGAY_MS); // 0 = 1/1/1970 (Thứ năm)
  return ((ngay + 3) % 7) + 1;
}

/** Số phút từ 00:00 giờ Việt Nam. */
function phutTrongNgayVn(t) {
  return Math.floor(((t + LECH_VN_MS) % NGAY_MS) / PHUT_MS);
}

/** 'yyyyMMdd' của ngày giờ Việt Nam. */
function maNgayVn(t) {
  const d = new Date(t + LECH_VN_MS);
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getUTCFullYear()}${p(d.getUTCMonth() + 1)}${p(d.getUTCDate())}`;
}

function dinhDangGio(phut) {
  const g = Math.floor(phut / 60) % 24;
  const p = phut % 60;
  return `${g}:${String(p).padStart(2, '0')}`;
}

/** Kiểm tra lịch tuần hợp lệ: tối đa `caToiDa` ca / ngày, ca có đầu ≠ cuối, hai ca trong ngày không chồng nhau. */
function kiemTraLich(lich, caToiDa = 2) {
  if (!lich || typeof lich !== 'object') return 'Khai giờ mở cửa.';
  let coCa = false;
  for (let thu = 1; thu <= 7; thu++) {
    const cas = lich[String(thu)] || [];
    if (!Array.isArray(cas) || cas.length > caToiDa) return `Mỗi ngày tối đa ${caToiDa} ca.`;
    const dai = [];
    for (const c of cas) {
      if (!Number.isInteger(c.tu) || !Number.isInteger(c.den) || c.tu < 0 || c.tu > 1439 || c.den < 0 || c.den > 1439) {
        return 'Giờ mở cửa không hợp lệ.';
      }
      if (c.tu === c.den) return 'Giờ mở và giờ đóng của một ca không được trùng nhau.';
      dai.push([c.tu, c.den > c.tu ? c.den : c.den + 1440]);
      coCa = true;
    }
    dai.sort((a, b) => a[0] - b[0]);
    for (let i = 1; i < dai.length; i++) if (dai[i][0] < dai[i - 1][1]) return 'Hai ca trong một ngày không được chồng nhau.';
  }
  return coCa ? null : 'Quán cần có ít nhất 1 ca mở cửa trong tuần.';
}

/** Các ca bắt đầu vào ngày giờ Việt Nam có mốc 00:00 là `dauNgay`, dạng khoảng thời gian cụ thể. */
function casCuaNgay(lich, dauNgay) {
  const thu = thuVn(dauNgay + 12 * 60 * PHUT_MS);
  const ds = (lich && lich[String(thu)]) || [];
  return ds.map((c) => {
    const batDau = dauNgay + c.tu * PHUT_MS;
    const dai = (((c.den - c.tu) % 1440) + 1440) % 1440 || 1440;
    return { batDau, ketThuc: batDau + dai * PHUT_MS };
  });
}

/** Ca đang mở tại thời điểm `t` (kể cả ca qua nửa đêm bắt đầu từ hôm qua), hoặc null. */
function caDangMo(lich, t) {
  const homNay = dauNgayVn(t);
  for (const dau of [homNay - NGAY_MS, homNay]) {
    for (const ca of casCuaNgay(lich, dau)) {
      if (ca.batDau <= t && t < ca.ketThuc) return ca;
    }
  }
  return null;
}

/** Ca mở kế tiếp bắt đầu sau `t` (tối đa 8 ngày tới). `tuNgayMai`: chỉ tính từ 00:00 ngày mai. */
function caKeTiep(lich, t, { tuNgayMai = false } = {}) {
  const bat = tuNgayMai ? dauNgayVn(t) + NGAY_MS : dauNgayVn(t);
  for (let i = 0; i < 9; i++) {
    const cas = casCuaNgay(lich, bat + i * NGAY_MS).sort((a, b) => a.batDau - b.batDau);
    for (const ca of cas) if (ca.batDau > t) return ca;
  }
  return null;
}

/**
 * Trạng thái mở cửa tại `t`:
 *  - 'tam_nghi' khi còn trong thời gian tạm nghỉ (`tamNghiDen` > t);
 *  - 'mo' / 'sap_dong' (còn ≤ `sapDongPhut`) / 'dong' theo lịch tuần.
 * Kết quả có `dongLuc` (giờ đóng ca đang mở) hoặc `moLuc` (giờ mở ca kế tiếp) để hiện chữ.
 */
function trangThaiMoCua({ gioMoCua, tamNghiDen = null }, t, { sapDongPhut = 30 } = {}) {
  if (tamNghiDen && tamNghiDen > t) return { trangThai: 'tam_nghi', moLuc: tamNghiDen };
  const ca = caDangMo(gioMoCua, t);
  if (ca) {
    const con = (ca.ketThuc - t) / PHUT_MS;
    return { trangThai: con <= sapDongPhut ? 'sap_dong' : 'mo', dongLuc: ca.ketThuc };
  }
  const tiep = caKeTiep(gioMoCua, t);
  return { trangThai: 'dong', moLuc: tiep ? tiep.batDau : null };
}

/**
 * "Tạm nghỉ hôm nay": hết hiệu lực khi tới ca mở kế tiếp theo lịch tuần, tính từ NGÀY MAI (mục 3.2).
 * Trả về mili giây (hoặc null nếu lịch trống).
 */
function hanTamNghiHomNay(lich, t) {
  const tiep = caKeTiep(lich, t, { tuNgayMai: true });
  return tiep ? tiep.batDau : null;
}

/** "Nghỉ đến ngày …": tự mở lại đúng ngày đó (00:00 giờ Việt Nam của ngày `ngay`, mili giây). */
function hanNghiDenNgay(ngay) {
  return dauNgayVn(ngay);
}

/** Số giờ mở cửa lớn nhất trong một ngày (để cảnh báo khai sai loại: > 14 giờ / ngày). */
function gioMoNhieuNhat(lich) {
  let max = 0;
  for (let thu = 1; thu <= 7; thu++) {
    const tong = (lich[String(thu)] || []).reduce((s, c) => s + ((((c.den - c.tu) % 1440) + 1440) % 1440 || 1440), 0);
    if (tong > max) max = tong;
  }
  return max / 60;
}

module.exports = {
  NGAY_MS, PHUT_MS, dauNgayVn, thuVn, phutTrongNgayVn, maNgayVn, dinhDangGio,
  kiemTraLich, caDangMo, caKeTiep, trangThaiMoCua, hanTamNghiHomNay, hanNghiDenNgay, gioMoNhieuNhat,
};
