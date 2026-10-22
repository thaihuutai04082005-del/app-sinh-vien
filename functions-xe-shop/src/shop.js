// Firestore của Shop đồ rẻ: sản phẩm `products`, đơn hàng `orders`, đánh giá `reviews`,
// điểm của shop `shop_stats/{shopId}`.
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { khongCoQuyen, khongTimThay, loi } from './loi.js';
import { chuoi, motTrong } from './kiem_tra.js';
import { TIEU_CHI_SHOP, noiDungDanhGia } from './danh_gia.js';
import { tangLuotDang } from './tai_khoan.js';
import {
  CACH_THANH_TOAN, HAN_XAC_NHAN_MS, chuyenTrangThaiDon, gioHang, huyQuaHan, nhanHang, phanXuKhieuNai, sanPham,
  tachDon, trangThaiKho, tuXuLyTraHang,
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
  // "online" là thanh toán giả lập: coi như đã trả, app giữ tiền đến khi khách xác nhận nhận hàng.
  const paymentMethod = motTrong(tham.paymentMethod ?? 'cod', CACH_THANH_TOAN, 'Cách thanh toán');
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
        paymentMethod,
        paid: paymentMethod === 'online',
        refunded: false,
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

/** Mốc hạn logic trả về dạng mili giây → Timestamp. */
function moc(ghi) {
  for (const k of ['returnDeadline', 'returnResponseDeadline']) {
    if (typeof ghi[k] === 'number') ghi[k] = Timestamp.fromMillis(ghi[k]);
  }
  return ghi;
}

/** Ghi kết quả chuyển trạng thái `kq` vào đơn, trả lại tồn kho nếu cần. */
async function apDung(tx, ref, don, kq) {
  const ghiKho = kq.hoanKho ? await hoanKho(tx, don) : () => {};
  ghiKho();
  tx.update(ref, { ...moc(kq.ghi), lichSu: FieldValue.arrayUnion(kq.lichSuMoi), updatedAt: FieldValue.serverTimestamp() });
}

export async function thaoTacDon(nd, tham) {
  const id = chuoi(tham.orderId, 'Đơn hàng', { max: 128 });
  const ref = orders().doc(id);
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw khongTimThay('Đơn hàng');
    const don = snap.data();
    await apDung(tx, ref, don, chuyenTrangThaiDon(don, tham.hanhDong, nd.uid, tham, Date.now()));
  });
  return { id };
}

/** Admin Shop (admins/{uid}.shop) phân xử đơn khách khiếu nại vì shop từ chối trả hàng. */
export async function xuLyKhieuNai(nd, tham) {
  const admin = await getFirestore().collection('admins').doc(nd.uid).get();
  if (admin.get('shop') !== true) throw khongCoQuyen();
  const id = chuoi(tham.orderId, 'Đơn hàng', { max: 128 });
  const ref = orders().doc(id);
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw khongTimThay('Đơn hàng');
    const don = snap.data();
    const kq = phanXuKhieuNai(don, tham, Date.now());
    kq.ghi.disputeResolvedBy = nd.uid;
    await apDung(tx, ref, don, kq);
  });
  return { id };
}

/**
 * Việc tới hạn trên các đơn của người gọi (là người mua hoặc shop): đơn quá hạn shop xác nhận thì hủy,
 * hết hạn trả hàng thì hoàn tất, shop không trả lời yêu cầu trả hàng thì coi như đồng ý.
 * App gọi mỗi khi mở danh sách đơn, nên không cần job hẹn giờ.
 */
export async function xuLyDonQuaHan(nd) {
  const now = Date.now();
  const lay = await Promise.all(['buyerId', 'shopId'].map((truong) => orders()
    .where(truong, '==', nd.uid)
    .where('status', 'in', ['pending_confirmation', 'delivered', 'return_requested'])
    .limit(200)
    .get()));
  let soDon = 0;
  for (const doc of lay.flatMap((q) => q.docs)) {
    if (!viecToiHan(doc.data(), now)) continue;
    await getFirestore().runTransaction(async (tx) => {
      const snap = await tx.get(doc.ref);
      const kq = snap.exists ? viecToiHan(snap.data(), now) : null;
      if (!kq) return;
      await apDung(tx, doc.ref, snap.data(), kq);
      soDon++;
    });
  }
  return { soDon };
}

function viecToiHan(don, now) {
  if (don.status === 'pending_confirmation') {
    return don.confirmDeadline?.toMillis() <= now ? { ...huyQuaHan(now, don), hoanKho: true } : null;
  }
  return tuXuLyTraHang(don, now);
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
