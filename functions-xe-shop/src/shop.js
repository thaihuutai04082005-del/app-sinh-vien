// Firestore của Shop đồ rẻ: sản phẩm `products`, đơn hàng `orders`.
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { khongCoQuyen, khongTimThay, loi } from './loi.js';
import { chuoi } from './kiem_tra.js';
import { tangLuotDang } from './tai_khoan.js';
import {
  HAN_XAC_NHAN_MS, chuyenTrangThaiDon, gioHang, huyQuaHan, nhanHang, sanPham, tachDon, trangThaiKho,
} from './shop_logic.js';

const products = () => getFirestore().collection('products');
const orders = () => getFirestore().collection('orders');
const DON_CHO_TOI_DA = 10;

export async function dangSanPham(nd, tham) {
  const sp = sanPham(tham);
  const now = Date.now();
  const ref = products().doc();
  await getFirestore().runTransaction(async (tx) => {
    const ghiQuota = await tangLuotDang(tx, nd.uid, now);
    ghiQuota();
    tx.create(ref, {
      ...sp,
      shopId: nd.uid,
      shopName: nd.ten,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return { id: ref.id };
}

async function cuaToi(nd, productId) {
  const ref = products().doc(chuoi(productId, 'Sản phẩm', { max: 128 }));
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Sản phẩm');
  if (snap.get('shopId') !== nd.uid) throw khongCoQuyen();
  return ref;
}

export async function suaSanPham(nd, tham) {
  const sp = sanPham(tham);
  const ref = await cuaToi(nd, tham.productId);
  await ref.update({ ...sp, updatedAt: FieldValue.serverTimestamp() });
  return { id: ref.id };
}

/** Xóa hẳn sản phẩm; đơn cũ vẫn giữ tên, ảnh, giá đã chụp lúc đặt. */
export async function xoaSanPham(nd, tham) {
  const ref = await cuaToi(nd, tham.productId);
  await ref.delete();
  return { id: ref.id };
}

export async function datHang(nd, tham) {
  const items = gioHang(tham.items);
  const giao = nhanHang(tham);
  const dangCho = await orders()
    .where('buyerId', '==', nd.uid)
    .where('status', '==', 'pending_confirmation')
    .count().get();
  if (dangCho.data().count >= DON_CHO_TOI_DA) {
    throw loi(`Bạn đang có ${DON_CHO_TOI_DA} đơn chờ shop xác nhận. Đợi shop xác nhận bớt rồi đặt tiếp.`);
  }

  const ids = [];
  await getFirestore().runTransaction(async (tx) => {
    ids.length = 0;
    const refs = [...new Set(items.map((i) => i.productId))].map((id) => products().doc(id));
    const snaps = await tx.getAll(...refs);
    const sanPhams = new Map(snaps.filter((s) => s.exists).map((s) => [s.id, s.data()]));
    const { dons, tonKhoMoi } = tachDon(items, sanPhams, nd.uid);

    const now = Date.now();
    for (const [id, stock] of tonKhoMoi) {
      tx.update(products().doc(id), { stock, status: trangThaiKho(stock), updatedAt: FieldValue.serverTimestamp() });
    }
    for (const don of dons) {
      const ref = orders().doc();
      ids.push(ref.id);
      tx.create(ref, {
        ...don,
        ...giao,
        buyerId: nd.uid,
        buyerName: nd.ten,
        paymentMethod: 'cod',
        voucherCode: null,
        discountAmount: 0,
        offerPrice: null,
        fundsReleased: false,
        status: 'pending_confirmation',
        cancelledBy: null,
        cancelReason: null,
        confirmDeadline: Timestamp.fromMillis(now + HAN_XAC_NHAN_MS),
        lichSu: [{ status: 'pending_confirmation', by: 'buyer', at: now }],
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
  return { ids };
}

/** Trả lại tồn kho cho các món của đơn bị hủy (sản phẩm đã xóa thì bỏ qua). Mọi lần đọc phải trước lần ghi. */
async function hoanKho(tx, don) {
  const soLuong = new Map();
  for (const it of don.items ?? []) soLuong.set(it.productId, (soLuong.get(it.productId) ?? 0) + it.quantity);
  if (soLuong.size === 0) return () => {};
  const snaps = await tx.getAll(...[...soLuong.keys()].map((id) => products().doc(id)));
  return () => {
    for (const s of snaps) {
      if (!s.exists) continue;
      const stock = (s.get('stock') ?? 0) + soLuong.get(s.id);
      tx.update(s.ref, { stock, status: trangThaiKho(stock), updatedAt: FieldValue.serverTimestamp() });
    }
  };
}

export async function thaoTacDon(nd, tham) {
  const id = chuoi(tham.orderId, 'Đơn hàng', { max: 128 });
  const ref = orders().doc(id);
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw khongTimThay('Đơn hàng');
    const don = snap.data();
    const kq = chuyenTrangThaiDon(don, tham.hanhDong, nd.uid, tham, Date.now());
    const ghiKho = kq.hoanKho ? await hoanKho(tx, don) : () => {};
    ghiKho();
    tx.update(ref, { ...kq.ghi, lichSu: FieldValue.arrayUnion(kq.lichSuMoi), updatedAt: FieldValue.serverTimestamp() });
  });
  return { id };
}

/**
 * Hủy các đơn của người gọi (là người mua hoặc shop) đã quá hạn shop xác nhận, trả lại tồn kho.
 * App gọi mỗi khi mở danh sách đơn, nên không cần job hẹn giờ.
 */
export async function xuLyDonQuaHan(nd) {
  const now = Date.now();
  const [mua, ban] = await Promise.all(['buyerId', 'shopId'].map((truong) => orders()
    .where(truong, '==', nd.uid)
    .where('status', '==', 'pending_confirmation')
    .limit(100)
    .get()));
  const qua = [...mua.docs, ...ban.docs].filter((d) => d.get('confirmDeadline')?.toMillis() <= now);
  let soDon = 0;
  for (const doc of qua) {
    await getFirestore().runTransaction(async (tx) => {
      const snap = await tx.get(doc.ref);
      const don = snap.data();
      if (don?.status !== 'pending_confirmation' || don.confirmDeadline.toMillis() > now) return;
      const ghiKho = await hoanKho(tx, don);
      const kq = huyQuaHan(now);
      ghiKho();
      tx.update(doc.ref, { ...kq.ghi, lichSu: FieldValue.arrayUnion(kq.lichSuMoi), updatedAt: FieldValue.serverTimestamp() });
      soDon++;
    });
  }
  return { soDon };
}
