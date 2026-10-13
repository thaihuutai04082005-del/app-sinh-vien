import { thamSoSai } from './loi.js';

/** Chuỗi bắt buộc, cắt khoảng trắng, giới hạn độ dài. */
export function chuoi(v, ten, { min = 1, max = 200 } = {}) {
  const s = typeof v === 'string' ? v.trim() : '';
  if (s.length < min) throw thamSoSai(min > 1 ? `${ten} cần ít nhất ${min} ký tự.` : `Nhập ${ten.toLowerCase()}.`);
  if (s.length > max) throw thamSoSai(`${ten} tối đa ${max} ký tự.`);
  return s;
}

export function chuoiTuyChon(v, ten, max = 500) {
  if (v == null || v === '') return '';
  return chuoi(v, ten, { min: 0, max });
}

export function soNguyen(v, ten, { min = 0, max = Number.MAX_SAFE_INTEGER } = {}) {
  if (!Number.isInteger(v) || v < min || v > max) throw thamSoSai(`${ten} không hợp lệ.`);
  return v;
}

export function danhSachLink(v, ten, { min = 0, max = 10 } = {}) {
  const l = v ?? [];
  if (!Array.isArray(l) || l.length < min || l.length > max
      || !l.every((u) => typeof u === 'string' && u.length <= 2000 && /^https:\/\/\S+$/.test(u))) {
    throw thamSoSai(min > 0 ? `Cần ${min}–${max} ${ten}.` : `Tối đa ${max} ${ten}.`);
  }
  return l;
}

/** Số điện thoại Việt Nam: 10 số bắt đầu bằng 0 (cho phép dấu cách, +84). */
export function soDienThoai(v) {
  const s = String(v ?? '').replace(/[\s.-]/g, '').replace(/^\+84/, '0');
  if (!/^0\d{9}$/.test(s)) throw thamSoSai('Số điện thoại không hợp lệ.');
  return s;
}

export function motTrong(v, cacGiaTri, ten) {
  if (!cacGiaTri.includes(v)) throw thamSoSai(`${ten} không hợp lệ.`);
  return v;
}
