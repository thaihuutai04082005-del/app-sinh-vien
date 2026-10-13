// Firestore của Xe dọn trọ: hồ sơ tài xế `xe_don_tro/{uid}`, đơn `booking_xe`.
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { khongTimThay, loi, thamSoSai } from './loi.js';
import { chuoi } from './kiem_tra.js';
import { tangLuotDang } from './tai_khoan.js';
import { YEU_CAU_CHO_TOI_DA, chuyenTrangThai, hoSoTaiXe, yeuCauMoi } from './xe_logic.js';

const taiXe = (uid) => getFirestore().collection('xe_don_tro').doc(uid);
const bookings = () => getFirestore().collection('booking_xe');

/** Đăng ký hoặc sửa hồ sơ tài xế. Phải xác thực danh tính trước (ID-checked, mục 3.3). */
export async function luuHoSoTaiXe(nd, tham) {
  if (nd.xacThuc.danhTinh !== 'da_xac_thuc') {
    throw loi('Bạn cần xác thực danh tính (CCCD) ở trang Hồ sơ trước khi đăng ký làm tài xế.');
  }
  const hoSo = hoSoTaiXe(tham);
  const ref = taiXe(nd.uid);
  const cu = await ref.get();
  await ref.set({
    ...hoSo,
    driverId: nd.uid,
    name: nd.ten,
    driverVerified: true,
    status: cu.exists ? cu.get('status') : 'available',
    updatedAt: FieldValue.serverTimestamp(),
    ...(cu.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
  }, { merge: true });
  return { id: nd.uid };
}

export async function doiTrangThaiTaiXe(nd, tham) {
  if (!['available', 'busy'].includes(tham.status)) throw thamSoSai();
  const ref = taiXe(nd.uid);
  if (!(await ref.get()).exists) throw khongTimThay('Hồ sơ tài xế');
  await ref.update({ status: tham.status, updatedAt: FieldValue.serverTimestamp() });
  return { status: tham.status };
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
    if (!tx1.exists || !tx1.get('driverVerified')) throw khongTimThay('Tài xế');
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
