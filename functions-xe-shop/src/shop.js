// Firestore của Shop đồ rẻ: sản phẩm `products`, đơn hàng `orders`, đánh giá `reviews`,
// điểm của shop `shop_stats/{shopId}`, trả giá `offers`, voucher `vouchers/{code}`
// (lượt đã dùng của từng người ở `vouchers/{code}/used/{uid}`).
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { khongCoQuyen, khongTimThay, loi } from './loi.js';
import { chuoi, motTrong } from './kiem_tra.js';
import { TIEU_CHI_SHOP, noiDungDanhGia } from './danh_gia.js';
import { tangLuotDang } from './tai_khoan.js';
import {
  CACH_THANH_TOAN, HAN_XAC_NHAN_MS, chuyenTrangThaiDon, gioHang, huyQuaHan, maVoucher, nhanHang, phanHoiTraGia,
  phanXuKhieuNai, sanPham, tachDon, tinhGiam, traGiaMoi, trangThaiKho, tuXuLyTraHang, voucherMoi,
} from './shop_logic.js';

const products = () => getFirestore().collection('products');
const orders = () => getFirestore().collection('orders');
const reviews = () => getFirestore().collection('reviews');
const shopStats = (shopId) => getFirestore().collection('shop_stats').doc(shopId);
const offers = () => getFirestore().collection('offers');
const vouchers = () => getFirestore().collection('vouchers');
const DON_CHO_TOI_DA = 10;
const TRA_GIA_CHO_TOI_DA = 10;

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

  const voucherCode = tham.voucherCode ? maVoucher(tham.voucherCode) : null;

  const ids = [];
  await getFirestore().runTransaction(async (tx) => {
    ids.length = 0;
    const now = Date.now();
    const refs = [...new Set(items.map((i) => i.productId))].map((id) => products().doc(id));
    const offerIds = items.filter((i) => i.offerId).map((i) => i.offerId);
    const [snaps, offerSnaps, vSnap, daDung] = await Promise.all([
      tx.getAll(...refs),
      offerIds.length ? tx.getAll(...offerIds.map((id) => offers().doc(id))) : [],
      voucherCode ? tx.get(vouchers().doc(voucherCode)) : null,
      voucherCode ? tx.get(vouchers().doc(voucherCode).collection('used').doc(nd.uid)) : null,
    ]);
    const sanPhams = new Map(snaps.filter((s) => s.exists).map((s) => [s.id, s.data()]));
    const offerMap = new Map(offerSnaps.filter((s) => s.exists).map((s) => [s.id, s.data()]));
    const { dons, tonKhoMoi } = tachDon(items, sanPhams, nd.uid, offerMap, now);

    // Voucher là của một shop: chỉ giảm cho đơn của shop đó.
    let donGiam = null;
    if (voucherCode) {
      const v = vSnap.exists ? vSnap.data() : null;
      donGiam = dons.find((d) => d.shopId === v?.shopId);
      if (v && !donGiam) throw loi(`Mã ${voucherCode} chỉ dùng cho sản phẩm của ${v.shopName || 'shop phát mã'}.`);
      if (daDung?.exists) throw loi('Bạn đã dùng mã này rồi.');
      const giam = tinhGiam(v, donGiam?.subtotal ?? 0, now);
      donGiam.voucherCode = voucherCode;
      donGiam.discountAmount = giam;
      donGiam.totalPrice = donGiam.subtotal - giam;
    }

    for (const [id, stock] of tonKhoMoi) {
      tx.update(products().doc(id), { stock, status: trangThaiKho(stock), updatedAt: FieldValue.serverTimestamp() });
    }
    for (const id of offerIds) tx.update(offers().doc(id), { status: 'used', updatedAt: FieldValue.serverTimestamp() });
    if (donGiam) {
      tx.update(vouchers().doc(voucherCode), { usedCount: FieldValue.increment(1) });
      tx.set(vouchers().doc(voucherCode).collection('used').doc(nd.uid), { at: now });
    }
    for (const don of dons) {
      const ref = orders().doc();
      ids.push(ref.id);
      tx.create(ref, {
        voucherCode: null,
        discountAmount: 0,
        ...don,
        ...giao,
        buyerId: nd.uid,
        buyerName: nd.ten,
        paymentMethod,
        paid: paymentMethod === 'online',
        refunded: false,
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

/**
 * Ghi kết quả chuyển trạng thái `kq` vào đơn, trả lại tồn kho nếu cần. Đơn bị hủy thì trả lại
 * lượt voucher cho người mua (trả hàng thì không, vì đơn đã giao).
 */
async function apDung(tx, ref, don, kq) {
  const ghiKho = kq.hoanKho ? await hoanKho(tx, don) : () => {};
  ghiKho();
  if (kq.ghi.status === 'cancelled' && don.voucherCode) {
    const v = vouchers().doc(don.voucherCode);
    tx.update(v, { usedCount: FieldValue.increment(-1) });
    tx.delete(v.collection('used').doc(don.buyerId));
  }
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

/** Người mua trả giá một sản phẩm (Make an offer, mục 3.4); shop trả lời trong kênh người bán. */
export async function traGia(nd, tham) {
  const productId = chuoi(tham.productId, 'Sản phẩm', { max: 128 });
  const snap = await products().doc(productId).get();
  if (!snap.exists) throw khongTimThay('Sản phẩm');
  const sp = snap.data();
  const tg = traGiaMoi(tham, sp, nd.uid);
  const dangCho = await offers().where('buyerId', '==', nd.uid).where('status', '==', 'pending').get();
  if (dangCho.docs.some((d) => d.get('productId') === productId)) {
    throw loi('Bạn đã trả giá sản phẩm này, chờ shop trả lời.');
  }
  if (dangCho.size >= TRA_GIA_CHO_TOI_DA) throw loi(`Bạn đang có ${TRA_GIA_CHO_TOI_DA} lần trả giá chờ trả lời.`);
  const ref = offers().doc();
  await ref.create({
    ...tg,
    productId,
    productName: sp.name,
    productImage: sp.images?.[0] ?? '',
    shopId: sp.shopId,
    shopName: sp.shopName ?? '',
    buyerId: nd.uid,
    buyerName: nd.ten,
    status: 'pending',
    expiresAt: null,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { id: ref.id };
}

/** hanhDong: chapNhan | tuChoi (shop) | huy (người mua). */
export async function phanHoiTraGiaApi(nd, tham) {
  const ref = offers().doc(chuoi(tham.offerId, 'Trả giá', { max: 128 }));
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw khongTimThay('Lần trả giá');
    const ghi = phanHoiTraGia(snap.data(), tham.hanhDong, nd.uid, Date.now());
    if (typeof ghi.expiresAt === 'number') ghi.expiresAt = Timestamp.fromMillis(ghi.expiresAt);
    tx.update(ref, { ...ghi, updatedAt: FieldValue.serverTimestamp() });
  });
  return { id: ref.id };
}

/** Shop tạo voucher; mã là id document nên không trùng giữa các shop. */
export async function taoVoucher(nd, tham) {
  const now = Date.now();
  const v = voucherMoi(tham, now);
  const ref = vouchers().doc(v.code);
  await getFirestore().runTransaction(async (tx) => {
    if ((await tx.get(ref)).exists) throw loi(`Mã ${v.code} đã có người dùng, chọn mã khác.`);
    tx.create(ref, {
      ...v,
      expiredAt: Timestamp.fromMillis(v.expiredAt),
      shopId: nd.uid,
      shopName: nd.ten,
      usedCount: 0,
      active: true,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { id: v.code };
}

/** Shop ngừng một voucher của mình (đơn đã áp mã vẫn giữ nguyên). */
export async function ngungVoucher(nd, tham) {
  const ref = vouchers().doc(maVoucher(tham.code));
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Voucher');
  if (snap.get('shopId') !== nd.uid) throw khongCoQuyen();
  await ref.update({ active: false });
  return { id: ref.id };
}
