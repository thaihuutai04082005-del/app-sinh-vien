import assert from 'node:assert/strict';
import { test } from 'node:test';
import { TIEU_CHI_SHOP, TIEU_CHI_XE, noiDungDanhGia } from '../src/danh_gia.js';

const loiCo = (re) => (e) => re.test(e.message);

test('đánh giá shop: điểm tổng là trung bình 3 tiêu chí, làm tròn 1 chữ số', () => {
  const dg = noiDungDanhGia(
    { ratingDetail: { quality: 5, accuracy: 4, service: 4 }, comment: ' Áo đẹp ', images: ['https://x/a.jpg'] },
    TIEU_CHI_SHOP,
  );
  assert.equal(dg.rating, 4.3);
  assert.deepEqual(dg.ratingDetail, { quality: 5, accuracy: 4, service: 4 });
  assert.equal(dg.comment, 'Áo đẹp');
  assert.deepEqual(dg.images, ['https://x/a.jpg']);
});

test('đánh giá: thiếu tiêu chí, sao ngoài 1–5, quá 5 ảnh thì báo lỗi', () => {
  const du = { attitude: 5, punctuality: 5, priceAccuracy: 3 };
  assert.equal(noiDungDanhGia({ ratingDetail: du }, TIEU_CHI_XE).rating, 4.3);
  assert.equal(noiDungDanhGia({ ratingDetail: du }, TIEU_CHI_XE).comment, '');
  assert.throws(() => noiDungDanhGia({ ratingDetail: { attitude: 5, punctuality: 5 } }, TIEU_CHI_XE), loiCo(/giá đúng như báo/));
  assert.throws(() => noiDungDanhGia({ ratingDetail: { ...du, attitude: 0 } }, TIEU_CHI_XE), loiCo(/thái độ/));
  assert.throws(() => noiDungDanhGia({ ratingDetail: { ...du, attitude: 4.5 } }, TIEU_CHI_XE), loiCo(/thái độ/));
  assert.throws(() => noiDungDanhGia({}, TIEU_CHI_SHOP), loiCo(/chất lượng/));
  assert.throws(
    () => noiDungDanhGia({ ratingDetail: du, images: Array(6).fill('https://x/a.jpg') }, TIEU_CHI_XE),
    loiCo(/Tối đa 5 ảnh/),
  );
});
