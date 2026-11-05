import { readFileSync } from 'node:fs';
import { after, before, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, serverTimestamp, GeoPoint } from 'firebase/firestore';

let env;
const auth = (uid) => env.authenticatedContext(uid, {
  email: `${uid}@example.test`, firebase: { sign_in_provider: 'password' },
});
const db = (uid) => uid ? auth(uid).firestore() : env.unauthenticatedContext().firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-rules',
    firestore: {
      host: '127.0.0.1', port: 8080,
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const store = ctx.firestore();
    const docs = {
      'admins/xe-shop-admin': { xe: true, shop: true },
      'products/xe-shop-product': { shopId: 'seller', name: 'Áo', price: 50000 },
      'orders/xe-shop-order': { shopId: 'seller', buyerId: 'buyer', status: 'pending_confirmation' },
      'xe_don_tro/driver/rieng/giayTo': { licensePhotos: ['https://example.test/license'] },
      'booking_xe/xe-shop-moving': { userId: 'buyer', driverId: 'driver', status: 'in_progress' },
      'booking_xe/xe-shop-done': { userId: 'buyer', driverId: 'driver', status: 'done' },
      'chats/xe-shop-chat': { participantIds: ['buyer', 'seller'], module: 'shop' },
      'chats/xe-shop-chat/messages/m1': { senderId: 'buyer', text: 'Chào shop' },
    };
    for (const [path, data] of Object.entries(docs)) await setDoc(doc(store, path), data);
  });
});

after(async () => { await env?.cleanup(); });

test('products remain public but clients cannot write products', async () => {
  await assertSucceeds(getDoc(doc(db(), 'products/xe-shop-product')));
  await assertFails(updateDoc(doc(db('seller'), 'products/xe-shop-product'), { price: 1 }));
});

test('only buyer, seller and Shop admin can read an order', async () => {
  for (const uid of ['buyer', 'seller', 'xe-shop-admin']) {
    await assertSucceeds(getDoc(doc(db(uid), 'orders/xe-shop-order')));
  }
  await assertFails(getDoc(doc(db('outsider'), 'orders/xe-shop-order')));
  await assertFails(getDoc(doc(db(), 'orders/xe-shop-order')));
});

test('a buyer cannot bypass the order API', async () => {
  await assertFails(updateDoc(doc(db('buyer'), 'orders/xe-shop-order'), { status: 'buyer_confirmed' }));
});

test('driver documents remain private to driver and Xe admin', async () => {
  for (const uid of ['driver', 'xe-shop-admin']) {
    await assertSucceeds(getDoc(doc(db(uid), 'xe_don_tro/driver/rieng/giayTo')));
  }
  await assertFails(getDoc(doc(db('buyer'), 'xe_don_tro/driver/rieng/giayTo')));
});

test('only the assigned driver and student can read booking addresses', async () => {
  for (const uid of ['buyer', 'driver']) {
    await assertSucceeds(getDoc(doc(db(uid), 'booking_xe/xe-shop-moving')));
  }
  await assertFails(getDoc(doc(db('outsider'), 'booking_xe/xe-shop-moving')));
  await assertFails(getDoc(doc(db(), 'booking_xe/xe-shop-moving')));
});

const location = () => ({ driverLastLocation: new GeoPoint(10.8, 106.7), driverLocationAt: serverTimestamp() });

test('assigned driver can share location only during an active trip', async () => {
  await assertSucceeds(updateDoc(doc(db('driver'), 'booking_xe/xe-shop-moving'), location()));
  await assertFails(updateDoc(doc(db('driver'), 'booking_xe/xe-shop-done'), location()));
});

test('location sharing cannot change price or trip status', async () => {
  await assertFails(updateDoc(doc(db('driver'), 'booking_xe/xe-shop-moving'), { ...location(), quotedPrice: 1 }));
  await assertFails(updateDoc(doc(db('driver'), 'booking_xe/xe-shop-moving'), { ...location(), status: 'done' }));
});

test('student and outsider cannot impersonate the driver location', async () => {
  for (const uid of ['buyer', 'outsider']) {
    await assertFails(updateDoc(doc(db(uid), 'booking_xe/xe-shop-moving'), location()));
  }
});

test('only chat participants can read chat messages; sending uses the API', async () => {
  await assertSucceeds(getDoc(doc(db('buyer'), 'chats/xe-shop-chat/messages/m1')));
  await assertFails(getDoc(doc(db('outsider'), 'chats/xe-shop-chat/messages/m1')));
  await assertFails(setDoc(doc(db('buyer'), 'chats/xe-shop-chat/messages/forged'), { text: 'Giả mạo' }));
});
