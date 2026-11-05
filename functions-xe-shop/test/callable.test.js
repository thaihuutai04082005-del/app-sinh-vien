import assert from 'node:assert/strict';
import { test } from 'node:test';
import { getFirestore } from 'firebase-admin/firestore';
import { shopApi, xeApi } from '../index.js';

// Exercise the exported callable handlers and transaction logic, without network I/O.
function firestoreGia(t, docs) {
  const writes = [];
  const snapshot = (ref) => ({
    ref,
    exists: Object.hasOwn(docs, ref.path),
    data: () => docs[ref.path],
    get: (key) => docs[ref.path]?.[key],
  });
  const reference = (path) => {
    const ref = { path, id: path.split('/').at(-1) };
    ref.get = async () => snapshot(ref);
    ref.collection = (name) => ({ doc: (id) => reference(`${path}/${name}/${id}`) });
    return ref;
  };
  const db = getFirestore();
  t.mock.method(db, 'collection', (name) => ({ doc: (id) => reference(`${name}/${id}`) }));
  t.mock.method(db, 'runTransaction', async (callback) => callback({
    get: async (ref) => snapshot(ref),
    update: (ref, data) => writes.push({ path: ref.path, data }),
    set: (ref, data) => writes.push({ path: ref.path, data }),
  }));
  return writes;
}

const request = (uid, data) => ({ auth: { uid, token: { firebase: { sign_in_provider: 'password' } } }, data });

test('shopApi routes confirmation separately from the order operation', async (t) => {
  const writes = firestoreGia(t, {
    'users/shop': { name: 'Shop' },
    'orders/o1': { shopId: 'shop', buyerId: 'buyer', status: 'pending_confirmation' },
  });
  assert.deepEqual(await shopApi.run(request('shop', {
    hanhDong: 'thaoTacDon', thaoTac: 'xacNhan', orderId: 'o1',
  })), { id: 'o1' });
  assert.equal(writes.find((w) => w.path === 'orders/o1').data.status, 'to_ship');
});

test('xeApi routes a driver quote and preserves the submitted price', async (t) => {
  const writes = firestoreGia(t, {
    'users/driver': { name: 'Tài xế' },
    'booking_xe/b1': { driverId: 'driver', userId: 'student', status: 'pending' },
  });
  await xeApi.run(request('driver', {
    hanhDong: 'thaoTacDon', thaoTac: 'baoGia', bookingId: 'b1', price: 150000,
  }));
  const write = writes.find((w) => w.path === 'booking_xe/b1');
  assert.equal(write.data.status, 'quoted');
  assert.equal(write.data.quotedPrice, 150000);
});

test('shopApi routes acceptance of an offer', async (t) => {
  const writes = firestoreGia(t, {
    'users/shop': { name: 'Shop' },
    'offers/f1': { shopId: 'shop', buyerId: 'buyer', status: 'pending' },
  });
  await shopApi.run(request('shop', {
    hanhDong: 'phanHoiTraGia', thaoTac: 'chapNhan', offerId: 'f1',
  }));
  assert.equal(writes.find((w) => w.path === 'offers/f1').data.status, 'accepted');
});

test('an unrelated user cannot confirm another shop order', async (t) => {
  const writes = firestoreGia(t, {
    'users/outsider': { name: 'Người ngoài' },
    'orders/o1': { shopId: 'shop', buyerId: 'buyer', status: 'pending_confirmation' },
  });
  await assert.rejects(shopApi.run(request('outsider', {
    hanhDong: 'thaoTacDon', thaoTac: 'xacNhan', orderId: 'o1',
  })), { code: 'permission-denied' });
  assert.deepEqual(writes, []);
});
