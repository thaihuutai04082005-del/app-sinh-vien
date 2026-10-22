// Firestore của Shop đồ rẻ: sản phẩm `products`, đơn hàng `orders`, đánh giá `reviews`,
// điểm của shop `shop_stats/{shopId}`.
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { khongCoQuyen, khongTimThay, loi } from './loi.js';
import { chuoi } from './kiem_tra.js';
import { TIEU_CHI_SHOP, noiDungDanhGia } from './danh_gia.js';
import { tangLuotDang } from './tai_khoan.js';
import {
  HAN_XAC_NHAN_MS, chuyenTrangThaiDon, gioHang, huyQuaHan, nhanHang, sanPham, tachDon, trangThaiKho,
} from './shop_logic.js';

const products = () => getFirestore().collection('products');
const orders = () => getFirestore().collection('orders');
const reviews = () => getFirestore().collection('reviews');
const shopStats = (shopId) => getFirestore().collection('shop_stats').doc(shopId);
const DON_CHO_TOI_DA = 10;

export async function dangSanPham(nd, tham) {
  // Ai cũng bán được (như Vinted), chỉ cần số điện thoại đã OTP để người mua liên hệ được.
  if (!nd.xacThuc.sdtDaXacThuc || !nd.xacThuc.sdt) {
    throw loi('Bạn cần xác thực số điện thoại (OTP) ở tab Cá nhân trước khi đăng bán.');
  }
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
        reviewed: false,
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

/**
 * Người mua đánh giá đơn đã nhận (3 tiêu chí, mục 3.4), mỗi đơn một lần. Điểm cộng vào shop
 * và từng sản phẩm trong đơn (sản phẩm đã xóa thì bỏ qua).
 */
export async function danhGiaDon(nd, tham) {
  const id = chuoi(tham.orderId, 'Đơn hàng', { max: 128 });
  const dg = noiDungDanhGia(tham, TIEU_CHI_SHOP);
  const ref = orders().doc(id);
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw khongTimThay('Đơn hàng');
    const don = snap.data();
    if (don.buyerId !== nd.uid) throw khongCoQuyen();
    if (don.status !== 'buyer_confirmed') throw loi('Xác nhận đã nhận hàng rồi mới đánh giá được.');
    if (don.reviewed) throw loi('Bạn đã đánh giá đơn này rồi.');
    const productIds = [...new Set((don.items ?? []).map((i) => i.productId))];
    const sps = productIds.length ? await tx.getAll(...productIds.map((p) => products().doc(p))) : [];

    const cong = { ratingSum: FieldValue.increment(dg.rating), ratingCount: FieldValue.increment(1) };
    tx.create(reviews().doc(`order_${id}`), {
      ...dg,
      targetType: 'shop',
      targetId: don.shopId,
      productIds,
      orderId: id,
      userId: nd.uid,
      userName: nd.ten,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(ref, { reviewed: true, updatedAt: FieldValue.serverTimestamp() });
    tx.set(shopStats(don.shopId), cong, { merge: true });
    for (const s of sps) if (s.exists) tx.update(s.ref, cong);
  });
  return { id: `order_${id}` };
}
