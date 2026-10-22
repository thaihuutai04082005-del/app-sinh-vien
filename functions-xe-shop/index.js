// Backend Xe dọn trọ + Shop đồ rẻ. Mọi chuyển trạng thái, giá, tồn kho đều do server quyết định;
// app chỉ đọc (theo firestore.rules) và gọi 2 callable dưới đây.
import { initializeApp } from 'firebase-admin/app';
import { onCall } from 'firebase-functions/v2/https';
import { thamSoSai } from './src/loi.js';
import { nguoiDung } from './src/tai_khoan.js';
import * as xe from './src/xe.js';
import * as shop from './src/shop.js';
import * as chat from './src/chat.js';

initializeApp();

const REGION = 'asia-southeast1';

export const xeApi = onCall({ region: REGION }, async (request) => {
  const { hanhDong, ...tham } = request.data ?? {};
  const nd = await nguoiDung(request);
  switch (hanhDong) {
    case 'luuHoSoTaiXe': return xe.luuHoSoTaiXe(nd, tham);
    case 'doiTrangThaiTaiXe': return xe.doiTrangThaiTaiXe(nd, tham);
    case 'duyetTaiXe': return xe.duyetTaiXe(nd, tham);
    case 'guiYeuCau': return xe.guiYeuCau(nd, tham);
    case 'thaoTacDon': return xe.thaoTacDon(nd, tham);
    case 'danhGiaChuyen': return xe.danhGiaChuyen(nd, tham);
    case 'moChat': return chat.moChat('xe', nd, tham);
    case 'guiTin': return chat.guiTin('xe', nd, tham);
    case 'daDoc': return chat.daDoc('xe', nd, tham);
    default: throw thamSoSai('Hành động không hợp lệ.');
  }
});

export const shopApi = onCall({ region: REGION }, async (request) => {
  const { hanhDong, ...tham } = request.data ?? {};
  const nd = await nguoiDung(request);
  switch (hanhDong) {
    case 'dangSanPham': return shop.dangSanPham(nd, tham);
    case 'suaSanPham': return shop.suaSanPham(nd, tham);
    case 'xoaSanPham': return shop.xoaSanPham(nd, tham);
    case 'datHang': return shop.datHang(nd, tham);
    case 'thaoTacDon': return shop.thaoTacDon(nd, tham);
    case 'xuLyDonQuaHan': return shop.xuLyDonQuaHan(nd);
    case 'danhGiaDon': return shop.danhGiaDon(nd, tham);
    case 'xuLyKhieuNai': return shop.xuLyKhieuNai(nd, tham);
    case 'traGia': return shop.traGia(nd, tham);
    case 'phanHoiTraGia': return shop.phanHoiTraGiaApi(nd, tham);
    case 'taoVoucher': return shop.taoVoucher(nd, tham);
    case 'ngungVoucher': return shop.ngungVoucher(nd, tham);
    case 'moChat': return chat.moChat('shop', nd, tham);
    case 'guiTin': return chat.guiTin('shop', nd, tham);
    case 'daDoc': return chat.daDoc('shop', nd, tham);
    default: throw thamSoSai('Hành động không hợp lệ.');
  }
});
