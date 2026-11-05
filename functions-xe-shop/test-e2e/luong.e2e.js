// Run with Auth, Firestore and the xe-shop Functions codebase on a demo project.
import assert from 'node:assert/strict';
import { before, test } from 'node:test';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const project = process.env.GCLOUD_PROJECT || 'demo-app-sinh-vien';
assert.ok(project.startsWith('demo-'), 'This test only supports a demo project.');
assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Start the Firestore emulator first.');
assert.ok(process.env.FIREBASE_AUTH_EMULATOR_HOST, 'Start the Auth emulator first.');
initializeApp({ projectId: project });
const db = getFirestore();
const base = `http://127.0.0.1:5001/${project}/asia-southeast1`;
let buyer, seller, driver;

async function user(role) {
  const email = `merge-${role}-${Date.now()}@example.test`;
  const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password: 'emulator-test-only', returnSecureToken: true }),
  });
  const data = await response.json();
  assert.ok(data.localId, 'Auth emulator must create a user.');
  await db.collection('users').doc(data.localId).set({ name: role, email, role: 'student' });
  await db.collection('xac_thuc').doc(data.localId).set({
    sdt: '0912345678', sdtDaXacThuc: true, danhTinh: 'da_xac_thuc',
  });
  return { uid: data.localId, token: data.idToken };
}

async function call(api, who, data) {
  const response = await fetch(`${base}/${api}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${who.token}` },
    body: JSON.stringify({ data }),
  });
  const body = await response.json();
  assert.equal(body.error, undefined, JSON.stringify(body.error));
  return body.result;
}

before(async () => {
  [buyer, seller, driver] = await Promise.all(['buyer', 'seller', 'driver'].map(user));
});

test('Shop callable: create product, accept offer, order and receive goods', async () => {
  const product = await call('shopApi', seller, {
    hanhDong: 'dangSanPham', name: 'Áo thử tích hợp', category: 'ao',
    images: ['https://example.test/shirt.jpg'], videos: [], price: 50000, stock: 3, sizes: ['M'],
  });
  const offer = await call('shopApi', buyer, {
    hanhDong: 'traGia', productId: product.id, offerPrice: 45000, size: 'M', message: '',
  });
  await call('shopApi', seller, { hanhDong: 'phanHoiTraGia', offerId: offer.id, thaoTac: 'chapNhan' });
  const order = await call('shopApi', buyer, {
    hanhDong: 'datHang', items: [{ productId: product.id, size: 'M', quantity: 1, offerId: offer.id }],
    receiverName: 'Người mua thử', phone: '0912345678', deliveryMethod: 'hen_lay', paymentMethod: 'cod',
  });
  const orderId = order.ids[0];
  for (const [who, thaoTac] of [[seller, 'xacNhan'], [seller, 'giaoHang'], [seller, 'daGiao'], [buyer, 'daNhan']]) {
    await call('shopApi', who, { hanhDong: 'thaoTacDon', orderId, thaoTac });
  }
  const saved = await db.collection('orders').doc(orderId).get();
  assert.equal(saved.get('status'), 'buyer_confirmed');
  assert.equal(saved.get('totalPrice'), 45000);
  assert.equal((await db.collection('products').doc(product.id).get()).get('stock'), 2);
});

test('Xe callable: request, quote, accept, start and finish a trip', async () => {
  await db.collection('xe_don_tro').doc(driver.uid).set({
    name: 'Tài xế thử', driverId: driver.uid, approval: 'approved', status: 'available', vehicleType: 'xe_ba_gac',
  });
  const booking = await call('xeApi', buyer, {
    hanhDong: 'guiYeuCau', driverId: driver.uid, fromAddress: 'KTX A', toAddress: 'KTX B',
    contactPhone: '0912345678', itemPhotos: ['https://example.test/boxes.jpg'], videos: [],
    scheduledAt: Date.now() + 3600000,
  });
  for (const [who, thaoTac] of [[driver, 'baoGia'], [buyer, 'chapNhan'], [driver, 'batDau'], [driver, 'hoanThanh']]) {
    await call('xeApi', who, { hanhDong: 'thaoTacDon', bookingId: booking.id, thaoTac, price: 150000 });
  }
  const saved = await db.collection('booking_xe').doc(booking.id).get();
  assert.equal(saved.get('status'), 'done');
  assert.equal(saved.get('quotedPrice'), 150000);
  assert.equal(saved.get('driverPhone'), '0912345678');
});

test('Shop chat callable: open conversation and persist a message', async () => {
  const chat = await call('shopApi', buyer, { hanhDong: 'moChat', otherId: seller.uid });
  await call('shopApi', buyer, { hanhDong: 'guiTin', chatId: chat.id, text: 'Chào shop' });
  const saved = await db.collection('chats').doc(chat.id).get();
  assert.equal(saved.get('lastMessage'), 'Chào shop');
  assert.ok(saved.get('participantIds').includes(seller.uid));
});
