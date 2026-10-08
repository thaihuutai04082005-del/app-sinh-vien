'use strict';

/**
 * Nhãn "🔥 Sinh viên hay ăn" và tỷ lệ của quán (đặc tả mục 3.4 Bước 1, 3.3). Logic thuần, tính mỗi đêm.
 */

const { khoangCachMet } = require('./gia');

/**
 * Đếm SỐ NGƯỜI KHÁC NHAU có check-in hoặc đơn hoàn tất tại quán trong cửa sổ, không tính chủ quán
 * (mỗi người tính tối đa 1 lượt / quán / 7 ngày — đếm người khác nhau nên tự thỏa).
 * `luot`: [{ quanId, uid, luc }]; `chuQuan`: Map quanId → chuQuanId.
 */
function demNguoiTheoQuan(luot, chuQuan, tu, den) {
  const tap = new Map();
  for (const l of luot) {
    if (l.luc < tu || l.luc > den) continue;
    if (chuQuan.get(l.quanId) === l.uid) continue;
    if (!tap.has(l.quanId)) tap.set(l.quanId, new Set());
    tap.get(l.quanId).add(l.uid);
  }
  const kq = new Map();
  for (const [k, s] of tap) kq.set(k, s.size);
  return kq;
}

/**
 * Quán có nhãn khi có ít nhất `soNguoi` người VÀ nằm trong `topPhanTram`% cao nhất so với các quán
 * trong bán kính `banKinhMet` quanh nó (tính cả chính nó).
 * `quan`: [{ id, lat, lng }]; `dem`: Map quanId → số người.
 */
function quanHayAn(quan, dem, { soNguoi, topPhanTram, banKinhMet }) {
  const co = new Set();
  for (const q of quan) {
    const n = dem.get(q.id) || 0;
    if (n < soNguoi) continue;
    const lanCan = quan.filter((x) => x.id === q.id || khoangCachMet(q, x) <= banKinhMet);
    const hang = 1 + lanCan.filter((x) => (dem.get(x.id) || 0) > n).length;
    if (hang <= Math.ceil((lanCan.length * topPhanTram) / 100)) co.add(q.id);
  }
  return co;
}

/**
 * Tỷ lệ nhận đơn: % đơn đã tới quán (không tính SV hủy khi chưa nhận, hết hạn thanh toán) được quán nhận
 * và không hủy / không quá hạn xác nhận / không từ chối. Null nếu chưa có đơn nào.
 */
function tyLeNhanDon(donTrongCuaSo) {
  const tinh = donTrongCuaSo.filter((d) => !['pending_payment', 'expired', 'cancelled_student'].includes(d.status) && !(d.status === 'refunded' && d.lyDoKetThuc === 'system_late_payment'));
  if (!tinh.length) return null;
  const xau = tinh.filter((d) => ['rejected', 'expired_accept', 'cancelled_restaurant'].includes(d.status)
    && d.lyDoKetThuc !== 'restaurant_stopped' && d.lyDoKetThuc !== 'restaurant_fraud');
  return Math.round(((tinh.length - xau.length) / tinh.length) * 100);
}

/** Tỷ lệ giữ bàn: % bàn đã xác nhận mà quán không hủy (không tính bàn bị hủy do admin ẩn / đình chỉ). */
function tyLeGiuBan(banTrongCuaSo) {
  const daXacNhan = banTrongCuaSo.filter((b) => b.xacNhanLuc != null);
  if (!daXacNhan.length) return null;
  const huy = daXacNhan.filter((b) => b.status === 'cancelled_restaurant' && b.lyDoKetThuc !== 'admin_an');
  return Math.round(((daXacNhan.length - huy.length) / daXacNhan.length) * 100);
}

module.exports = { demNguoiTheoQuan, quanHayAn, tyLeNhanDon, tyLeGiuBan };
