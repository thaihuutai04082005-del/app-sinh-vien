import { getFirestore } from 'firebase-admin/firestore';
import { loi } from './loi.js';

/** Hạn mức đăng tin mỗi ngày, dùng chung bộ đếm quota/{uid} với app (xem firestore.rules). */
export const TIN_MOI_NGAY = 10;

/** Người gọi phải đăng nhập bằng email (không ẩn danh) và không bị khóa. */
export async function nguoiDung(request) {
  const uid = request.auth?.uid;
  if (!uid || request.auth.token?.firebase?.sign_in_provider === 'anonymous') {
    throw loi('Vui lòng đăng nhập để tiếp tục.', 'unauthenticated');
  }
  const db = getFirestore();
  const [xt, user] = await Promise.all([
    db.collection('xac_thuc').doc(uid).get(),
    db.collection('users').doc(uid).get(),
  ]);
  const xacThuc = xt.exists ? xt.data() : {};
  if (xacThuc.khoaTaiKhoan) throw loi('Tài khoản của bạn đã bị khóa.', 'permission-denied');
  const ten = xacThuc.hoTenXacThuc || user.get('name') || 'Người dùng';
  return { uid, xacThuc, ten };
}

/** Tăng lượt đăng tin hôm nay trong transaction `tx`; quá hạn mức thì báo lỗi. */
export async function tangLuotDang(tx, uid, now) {
  const ref = getFirestore().collection('quota').doc(uid);
  const snap = await tx.get(ref);
  const day = Math.floor(now / 86_400_000);
  const cu = snap.exists && snap.get('day') === day ? snap.data() : { posts: 0, uploads: 0 };
  if ((cu.posts ?? 0) >= TIN_MOI_NGAY) {
    throw loi(`Mỗi ngày chỉ đăng được ${TIN_MOI_NGAY} tin. Vui lòng thử lại vào ngày mai.`, 'resource-exhausted');
  }
  return () => tx.set(ref, { day, posts: (cu.posts ?? 0) + 1, uploads: cu.uploads ?? 0 });
}
