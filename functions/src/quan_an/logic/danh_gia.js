'use strict';

/**
 * Đánh giá có cấu trúc 4 tiêu chí và điểm của quán (đặc tả mục 3.4 Bước 6, 3.9). Logic thuần.
 */

const TIEU_CHI = ['monAn', 'giaCa', 'veSinh', 'phucVu'];
const THE_NHANH = ['mon_ngon', 'phuc_vu_nhanh', 'gia_hop_ly', 'phan_an_nhieu', 'sach_se', 'hop_hoc_nhom', 'cho_lau', 'gia_cao', 'on_ao', 'it_cho_ngoi'];

/** Nhãn từ mạnh tới yếu (mục 3.4 Bước 6). */
const NHAN = ['dat_mon', 'dat_ban', 'check_in'];

/** Điểm tổng thể của MỘT đánh giá = trung bình 4 tiêu chí, hệ thống tính (không có ô nhập). Null nếu thiếu tiêu chí. */
function diemTong(diem) {
  if (!diem) return null;
  const ds = TIEU_CHI.map((k) => diem[k]);
  if (!ds.every((x) => Number.isInteger(x) && x >= 1 && x <= 5)) return null;
  return ds.reduce((s, x) => s + x, 0) / ds.length;
}

/** Nhãn mạnh nhất trong các bằng chứng có. */
function nhanManhNhat(coBangChung) {
  for (const n of NHAN) if (coBangChung[n]) return n;
  return null;
}

const lam1 = (x) => Math.round(x * 10) / 10;

/**
 * Điểm của quán: điểm tổng thể = trung bình điểm tổng thể các đánh giá có nhãn của người đã OTP (đã hiển thị);
 * đồng thời điểm trung bình riêng từng tiêu chí. Đánh giá "Chưa xác minh" chỉ tính điểm phụ.
 * `danhGia`: [{ diemTong, diem, tinhDiem, trangThaiHienThi }].
 */
function tinhDiemQuan(danhGia) {
  const hien = danhGia.filter((d) => d.trangThaiHienThi !== 'an' && d.trangThaiHienThi !== 'an_tam');
  const xm = hien.filter((d) => d.tinhDiem);
  const chua = hien.filter((d) => !d.tinhDiem);
  const tb = (ds, f) => (ds.length ? lam1(ds.reduce((s, d) => s + f(d), 0) / ds.length) : null);
  return {
    diemTong: tb(xm, (d) => d.diemTong),
    soDanhGia: xm.length,
    diemTieuChi: Object.fromEntries(TIEU_CHI.map((k) => [k, tb(xm, (d) => d.diem[k])])),
    diemChuaXm: tb(chua, (d) => d.diemTong),
    soDanhGiaChuaXm: chua.length,
  };
}

module.exports = { TIEU_CHI, THE_NHANH, NHAN, diemTong, nhanManhNhat, tinhDiemQuan };
