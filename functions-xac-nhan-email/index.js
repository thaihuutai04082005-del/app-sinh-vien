// Xác nhận email bằng mã 6 số thay cho link của Firebase.
// Mã chỉ nằm ở server (collection email_otps, client không đọc được),
// đúng mã thì server bật emailVerified cho tài khoản.
import { createHash, randomInt } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { defineSecret } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import nodemailer from 'nodemailer';

initializeApp();

const GUI_TU = 'huongprovn002@gmail.com';
// App Password của GUI_TU, đặt bằng: firebase functions:secrets:set SMTP_PASS
const SMTP_PASS = defineSecret('SMTP_PASS');

const REGION = 'asia-southeast1';
const HET_HAN_PHUT = 10;
const CHO_GUI_LAI_GIAY = 60;
const SO_LAN_NHAP_SAI = 5;

const otpDoc = (uid) => getFirestore().collection('email_otps').doc(uid);
const bam = (uid, code) => createHash('sha256').update(`${uid}:${code}`).digest('hex');

async function layNguoiDung(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Chưa đăng nhập');
  const user = await getAuth().getUser(uid);
  if (!user.email) throw new HttpsError('failed-precondition', 'Tài khoản không có email');
  return user;
}

export const guiMaXacNhan = onCall({ region: REGION, secrets: [SMTP_PASS] }, async (request) => {
  const user = await layNguoiDung(request);
  if (user.emailVerified) return { daXacNhan: true };

  const ref = otpDoc(user.uid);
  const cu = (await ref.get()).data();
  if (cu?.sentAt && Date.now() - cu.sentAt.toMillis() < CHO_GUI_LAI_GIAY * 1000) {
    throw new HttpsError('resource-exhausted', 'Vui lòng đợi một lúc rồi gửi lại');
  }

  const code = String(randomInt(0, 1_000_000)).padStart(6, '0');
  await ref.set({
    hash: bam(user.uid, code),
    sentAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + HET_HAN_PHUT * 60_000),
    attempts: 0,
  });

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: GUI_TU, pass: SMTP_PASS.value() },
  });
  await transporter.sendMail({
    from: `"App Sinh Viên" <${GUI_TU}>`,
    to: user.email,
    subject: `${code} là mã xác nhận App Sinh Viên`,
    text:
      `Mã xác nhận email của bạn là ${code}. Mã có hiệu lực trong ${HET_HAN_PHUT} phút.\n\n` +
      'Nếu bạn không đăng ký tài khoản, hãy bỏ qua thư này.',
    html: `<p>Mã xác nhận email của bạn là:</p>
<p style="font-size:28px;font-weight:bold;letter-spacing:6px">${code}</p>
<p>Mã có hiệu lực trong ${HET_HAN_PHUT} phút.</p>
<p style="color:#888">Nếu bạn không đăng ký tài khoản, hãy bỏ qua thư này.</p>`,
  });
  return { daXacNhan: false };
});

export const xacNhanMa = onCall({ region: REGION }, async (request) => {
  const user = await layNguoiDung(request);
  if (user.emailVerified) return { ok: true };

  const code = String(request.data?.code ?? '').trim();
  if (!/^\d{6}$/.test(code)) throw new HttpsError('invalid-argument', 'Mã gồm 6 chữ số');

  const ref = otpDoc(user.uid);
  const otp = (await ref.get()).data();
  if (!otp) throw new HttpsError('not-found', 'Chưa có mã, hãy bấm Gửi lại mã');
  if (otp.expiresAt.toMillis() < Date.now()) {
    throw new HttpsError('deadline-exceeded', 'Mã đã hết hạn, hãy bấm Gửi lại mã');
  }
  if (otp.attempts >= SO_LAN_NHAP_SAI) {
    throw new HttpsError('permission-denied', 'Nhập sai quá nhiều lần, hãy bấm Gửi lại mã');
  }
  if (otp.hash !== bam(user.uid, code)) {
    await ref.update({ attempts: FieldValue.increment(1) });
    throw new HttpsError('invalid-argument', 'Mã không đúng');
  }

  await getAuth().updateUser(user.uid, { emailVerified: true });
  await ref.delete();
  return { ok: true };
});
