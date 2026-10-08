'use strict';

/** Check-in khi tới quán (mục 3.4 Bước 3): gần quán, trong giờ mở cửa, 1 lần / quán / ngày. */

const { db, Timestamp, ms } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, thamSoSai } = require('../chung/loi');
const { layCauHinh } = require('./cau_hinh');
const { khoangCachMet } = require('./logic/gia');
const H = require('./logic/gio_mo_cua');
const K = require('./logic/kiem_tra');
const { COL } = require('./ho_tro');

async function checkIn({ uid }, { quanId, lat, lng, anh = null, camNghi = '', congKhai = true }) {
  const cfg = await layCauHinh();
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) throw thamSoSai('Không lấy được vị trí của bạn.');
  if (anh && !K.laHttps(anh)) throw thamSoSai('Ảnh không hợp lệ.');
  const qSnap = await db.collection(COL.quan).doc(String(quanId || '')).get();
  if (!qSnap.exists) throw khongTimThay('Quán');
  const q = qSnap.data();
  if (q.chuQuanId === uid) throw loiNguoiDung('Bạn không check-in tại quán của chính mình.', 'permission-denied');
  if (q.trangThai !== 'active') throw loiNguoiDung('Quán này hiện không nhận check-in.');
  const now = Date.now();
  const tt = H.trangThaiMoCua({ gioMoCua: q.gioMoCua, tamNghiDen: ms(q.tamNghiDen) }, now, { sapDongPhut: cfg.sapDongPhut });
  if (!['mo', 'sap_dong'].includes(tt.trangThai)) throw loiNguoiDung('Chỉ check-in được trong giờ mở cửa.');
  const kc = Math.round(khoangCachMet({ lat, lng }, { lat: q.viTri.latitude, lng: q.viTri.longitude }));
  if (kc > cfg.checkInMet) throw loiNguoiDung(`Bạn đang cách quán ${kc} m. Hãy tới gần quán (trong ${cfg.checkInMet} m) rồi check-in.`);

  const id = `${uid}_${quanId}_${H.maNgayVn(now)}`; // 1 lần / quán / ngày
  const ref = db.collection(COL.checkIn).doc(id);
  const ten = ((await db.collection('users').doc(uid).get()).get('name')) || 'Sinh viên';
  await db.runTransaction(async (tx) => {
    if ((await tx.get(ref)).exists) throw loiNguoiDung('Hôm nay bạn đã check-in tại quán này rồi.');
    tx.set(ref, {
      svId: uid, tenSv: ten, quanId, viTri: new (require('../chung/firebase').GeoPoint)(lat, lng), khoangCachM: kc, anh, camNghi: String(camNghi || '').slice(0, 200),
      congKhai: !!congKhai, tinhHayAn: true, luc: Timestamp.fromMillis(now),
    });
    tx.update(db.collection(COL.quan).doc(quanId), { hoatDongLuc: Timestamp.fromMillis(now), hanXacNhanHoatDong: null });
  });

  // Bảo vệ đặt bàn: check-in hợp lệ trong giờ giữ bàn → cấp nhãn 🍽 và vô hiệu "Khách không đến".
  const { chayTrenBan } = require('./dat_ban_service');
  const ban = await db.collection(COL.datBan).where('svId', '==', uid).where('quanId', '==', quanId).where('status', 'in', ['confirmed', 'arrived']).get();
  let banId = null;
  for (const b of ban.docs) {
    const r = await chayTrenBan(b.id, { su: { loai: 'SV_CHECK_IN', checkInId: id }, nguoiLam: { vaiTro: 'he_thong' } }).catch(() => null);
    if (r && r.daCheckIn) banId = b.id;
  }
  return { ok: true, khoangCachM: kc, checkInId: id, datBanId: banId };
}

module.exports = { checkIn };
