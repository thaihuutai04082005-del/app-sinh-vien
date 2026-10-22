// Firestore của Xe dọn trọ: hồ sơ tài xế `xe_don_tro/{uid}`, đơn `booking_xe`, đánh giá `reviews`.
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { khongCoQuyen, khongTimThay, loi, thamSoSai } from './loi.js';
import { chuoi } from './kiem_tra.js';
import { TIEU_CHI_XE, noiDungDanhGia } from './danh_gia.js';
import { tangLuotDang } from './tai_khoan.js';
import {
  YEU_CAU_CHO_TOI_DA, chuyenTrangThai, hoSoTaiXe, ketQuaDuyet, trangThaiDuyetSauKhiLuu, yeuCauMoi,
} from './xe_logic.js';

const taiXe = (uid) => getFirestore().collection('xe_don_tro').doc(uid);
const bookings = () => getFirestore().collection('booking_xe');

const giayTo = (uid) => taiXe(uid).collection('rieng').doc('giayTo');

/**
 * Đăng ký hoặc sửa hồ sơ tài xế. Phải xác thực danh tính (CCCD) trước, rồi admin Xe dọn trọ
 * duyệt hồ sơ xe mới được hiện trong danh sách (mục 3.3). Ảnh bằng lái nằm ở rieng/giayTo.
 */
export async function luuHoSoTaiXe(nd, tham) {
  if (nd.xacThuc.danhTinh !== 'da_xac_thuc') {
    throw loi('Bạn cần xác thực danh tính (CCCD) ở tab Cá nhân trước khi đăng ký làm tài xế.');
  }
  const moi = hoSoTaiXe(tham);
  const ref = taiXe(nd.uid);
  const [cu, gtCu] = await Promise.all([ref.get(), giayTo(nd.uid).get()]);
  const approval = trangThaiDuyetSauKhiLuu(cu.exists ? cu.data() : null, gtCu.exists ? gtCu.data() : null, moi);
  const batch = getFirestore().batch();
  batch.set(ref, {
    ...moi.hoSo,
    driverId: nd.uid,
    name: nd.ten,
    driverVerified: true,
    approval,
    ...(approval === 'pending' ? { rejectReason: null, submittedAt: FieldValue.serverTimestamp() } : {}),
    status: cu.exists ? cu.get('status') ?? 'available' : 'available',
    updatedAt: FieldValue.serverTimestamp(),
    ...(cu.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
  }, { merge: true });
  batch.set(giayTo(nd.uid), moi.giayTo);
  await batch.commit();
  return { id: nd.uid, approval };
}

export async function doiTrangThaiTaiXe(nd, tham) {
  if (!['available', 'busy'].includes(tham.status)) throw thamSoSai();
  const ref = taiXe(nd.uid);
  const snap = await ref.get();
  if (!snap.exists) throw khongTimThay('Hồ sơ tài xế');
  if (snap.get('approval') !== 'approved') throw loi('Hồ sơ của bạn chưa được duyệt.');
  await ref.update({ status: tham.status, updatedAt: FieldValue.serverTimestamp() });
  return { status: tham.status };
}

/** Admin Xe dọn trọ (admins/{uid}.xe) duyệt hoặc từ chối hồ sơ tài xế. */
export async function duyetTaiXe(nd, tham) {
  const admin = await getFirestore().collection('admins').doc(nd.uid).get();
  if (admin.get('xe') !== true) throw khongCoQuyen();
  const id = chuoi(tham.driverId, 'Tài xế', { max: 128 });
  const ref = taiXe(id);
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const kq = ketQuaDuyet(snap.exists ? snap.data() : null, tham);
    tx.update(ref, { ...kq, reviewedBy: nd.uid, reviewedAt: FieldValue.serverTimestamp() });
  });
  return { id };
}

export async function guiYeuCau(nd, tham) {
  const now = Date.now();
  const yc = yeuCauMoi(tham, now);
  if (yc.driverId === nd.uid) throw loi('Không thể tự đặt xe của chính bạn.');

  const dangCho = await bookings()
    .where('userId', '==', nd.uid)
    .where('status', 'in', ['pending', 'quoted'])
    .count().get();
  if (dangCho.data().count >= YEU_CAU_CHO_TOI_DA) {
    throw loi(`Bạn đang có ${YEU_CAU_CHO_TOI_DA} yêu cầu chờ chốt. Hủy bớt hoặc chờ tài xế trả lời trước.`);
  }

  const ref = bookings().doc();
  await getFirestore().runTransaction(async (tx) => {
    const tx1 = await tx.get(taiXe(yc.driverId));
    const ghiQuota = await tangLuotDang(tx, nd.uid, now);
    if (!tx1.exists || tx1.get('approval') !== 'approved') throw khongTimThay('Tài xế');
    if (tx1.get('status') !== 'available') throw loi('Tài xế này đang bận, hãy chọn tài xế khác.');
    ghiQuota();
    tx.create(ref, {
      ...yc,
      scheduledAt: Timestamp.fromMillis(yc.scheduledAt),
      userId: nd.uid,
      userName: nd.ten,
      driverName: tx1.get('name') ?? '',
      vehicleType: tx1.get('vehicleType') ?? '',
      driverPhone: null,
      quotedPrice: null,
      reviewed: false,
      status: 'pending',
      cancelledBy: null,
      cancelReason: null,
      lichSu: [{ status: 'pending', by: 'user', at: now }],
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return { id: ref.id };
}

export async function thaoTacDon(nd, tham) {
  const id = chuoi(tham.bookingId, 'Đơn', { max: 128 });
  const ref = bookings().doc(id);
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw khongTimThay('Đơn đặt xe');
    const don = snap.data();
    const { ghi, lichSuMoi } = chuyenTrangThai(don, tham.hanhDong, nd.uid, tham, Date.now());
    if (tham.hanhDong === 'chapNhan') {
      // Chốt đơn thì sinh viên mới thấy số điện thoại tài xế (đã OTP).
      const xt = await tx.get(getFirestore().collection('xac_thuc').doc(don.driverId));
      ghi.driverPhone = xt.exists && xt.get('sdtDaXacThuc') ? xt.get('sdt') ?? null : null;
    }
    tx.update(ref, { ...ghi, lichSu: FieldValue.arrayUnion(lichSuMoi), updatedAt: FieldValue.serverTimestamp() });
  });
  return { id };
}

/** Sinh viên đánh giá tài xế sau chuyến đã hoàn thành (thái độ, đúng giờ, giá đúng như báo), mỗi đơn một lần. */
export async function danhGiaChuyen(nd, tham) {
  const id = chuoi(tham.bookingId, 'Đơn', { max: 128 });
  const dg = noiDungDanhGia(tham, TIEU_CHI_XE);
  const ref = bookings().doc(id);
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw khongTimThay('Đơn đặt xe');
    const don = snap.data();
    if (don.userId !== nd.uid) throw khongCoQuyen();
    if (don.status !== 'done') throw loi('Chuyến hoàn thành rồi mới đánh giá được.');
    if (don.reviewed) throw loi('Bạn đã đánh giá chuyến này rồi.');
    const tx1 = await tx.get(taiXe(don.driverId));

    tx.create(getFirestore().collection('reviews').doc(`booking_${id}`), {
      ...dg,
      targetType: 'xe_don_tro',
      targetId: don.driverId,
      bookingId: id,
      userId: nd.uid,
      userName: nd.ten,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(ref, { reviewed: true, updatedAt: FieldValue.serverTimestamp() });
    if (tx1.exists) {
      tx.update(tx1.ref, { ratingSum: FieldValue.increment(dg.rating), ratingCount: FieldValue.increment(1) });
    }
  });
  return { id: `booking_${id}` };
}
