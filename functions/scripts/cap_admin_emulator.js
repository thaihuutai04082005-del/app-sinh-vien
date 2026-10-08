/**
 * Cấp quyền admin (Tìm trọ + duyệt danh tính) cho một tài khoản TRÊN EMULATOR, để thử app.
 * Chỉ chạy được khi đang bật emulator (cổng 8080 và 9099); không đụng Firebase thật.
 *
 *   node functions/scripts/cap_admin_emulator.js chu@test.com
 *
 * Bỏ trống email thì cấp cho TẤT CẢ tài khoản đang có trong emulator.
 */
process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ||= '127.0.0.1:9099';

const admin = require('../node_modules/firebase-admin');

admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'app-sinh-vien-b6ea4' });

(async () => {
  const email = (process.argv[2] || '').trim().toLowerCase();
  const { users } = await admin.auth().listUsers(1000);
  const chon = users.filter((u) => !email || (u.email || '').toLowerCase() === email);
  if (chon.length === 0) {
    console.log(email ? `Không thấy tài khoản ${email}. Đã đăng ký trong app chưa?` : 'Chưa có tài khoản nào.');
    console.log('Tài khoản đang có:', users.map((u) => u.email).join(', ') || '(trống)');
    process.exit(1);
  }
  for (const u of chon) {
    await admin.firestore().collection('admins').doc(u.uid).set({ tro: true, danhTinh: true, quanAn: true });
    console.log(`Đã cấp admin cho ${u.email} (uid ${u.uid})`);
  }
  process.exit(0);
})().catch((e) => {
  console.error('Lỗi:', e.message, '\nEmulator đã bật chưa (cổng 8080, 9099)?');
  process.exit(1);
});
