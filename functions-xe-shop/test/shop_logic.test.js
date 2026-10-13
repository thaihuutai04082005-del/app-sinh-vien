import assert from 'node:assert/strict';
import { test } from 'node:test';
import { chuyenTrangThaiDon, gioHang, huyQuaHan, nhanHang, sanPham, tachDon } from '../src/shop_logic.js';

const NOW = Date.UTC(2026, 9, 13, 3);
const loiCo = (re) => (e) => re.test(e.message);

const SP_HOP = {
  name: ' Áo thun ', images: ['https://x/a.jpg'], price: 85000, sizes: ['L', 'M'], stock: 3, category: 'ao',
};

test('sản phẩm: chuẩn hóa size, trạng thái theo tồn kho', () => {
  const sp = sanPham(SP_HOP);
  assert.equal(sp.name, 'Áo thun');
  assert.deepEqual(sp.sizes, ['M', 'L']);
  assert.equal(sp.status, 'active');
  assert.equal(sanPham({ ...SP_HOP, stock: 0 }).status, 'out_of_stock');
  assert.throws(() => sanPham({ ...SP_HOP, images: [] }), loiCo(/ảnh sản phẩm/));
  assert.throws(() => sanPham({ ...SP_HOP, sizes: ['M', 'M'] }), loiCo(/Size/));
  assert.throws(() => sanPham({ ...SP_HOP, category: 'giay' }), loiCo(/Danh mục/));
  assert.throws(() => sanPham({ ...SP_HOP, price: 0 }), loiCo(/Giá/));
  assert.throws(() => sanPham({ ...SP_HOP, stock: -1 }), loiCo(/Tồn kho/));
});

test('giỏ hàng gộp dòng trùng, chặn số lượng sai', () => {
  assert.deepEqual(
    gioHang([
      { productId: 'a', size: 'M', quantity: 1 },
      { productId: 'a', size: 'M', quantity: 2 },
      { productId: 'a', size: 'L', quantity: 1 },
    ]),
    [{ productId: 'a', size: 'M', quantity: 3 }, { productId: 'a', size: 'L', quantity: 1 }],
  );
  assert.throws(() => gioHang([]), loiCo(/trống/));
  assert.throws(() => gioHang([{ productId: 'a', quantity: 0 }]), loiCo(/Số lượng/));
  assert.throws(() => gioHang([{ productId: 'a', quantity: 1.5 }]), loiCo(/Số lượng/));
});

test('nhận hàng: giao tận trọ bắt buộc địa chỉ, hẹn lấy thì không', () => {
  const co = { receiverName: 'An', phone: '0912345678', deliveryMethod: 'giao_tan_tro' };
  assert.throws(() => nhanHang(co), loiCo(/địa chỉ/i));
  assert.equal(nhanHang({ ...co, address: 'KTX B' }).address, 'KTX B');
  assert.equal(nhanHang({ ...co, deliveryMethod: 'hen_lay' }).address, '');
  assert.throws(() => nhanHang({ ...co, deliveryMethod: 'bay' }), loiCo(/Cách nhận/));
});

const KHO = new Map([
  ['a', { shopId: 's1', shopName: 'Shop 1', name: 'Áo', images: ['https://x/a'], price: 50000, sizes: ['M', 'L'], stock: 3 }],
  ['b', { shopId: 's1', shopName: 'Shop 1', name: 'Mũ', images: [], price: 20000, sizes: [], stock: 1 }],
  ['c', { shopId: 's2', shopName: 'Shop 2', name: 'Quần', images: [], price: 120000, sizes: [], stock: 5 }],
]);

test('tách đơn theo shop, giá lấy từ server, trừ tồn kho', () => {
  const { dons, tonKhoMoi } = tachDon(
    [
      { productId: 'a', size: 'M', quantity: 2 },
      { productId: 'b', size: '', quantity: 1 },
      { productId: 'c', size: '', quantity: 1 },
      { productId: 'a', size: 'L', quantity: 1 },
    ],
    KHO,
    'buyer',
  );
  assert.equal(dons.length, 2);
  const s1 = dons.find((d) => d.shopId === 's1');
  assert.equal(s1.totalPrice, 50000 * 3 + 20000);
  assert.equal(s1.items.length, 3);
  assert.equal(s1.items[0].image, 'https://x/a');
  assert.equal(dons.find((d) => d.shopId === 's2').totalPrice, 120000);
  assert.deepEqual(Object.fromEntries(tonKhoMoi), { a: 0, b: 0, c: 4 });
});

test('tách đơn chặn: hết hàng, tự mua, size sai, sản phẩm đã xóa', () => {
  assert.throws(() => tachDon([{ productId: 'a', size: 'M', quantity: 4 }], KHO, 'buyer'), loiCo(/chỉ còn 3/));
  assert.throws(
    () => tachDon([{ productId: 'a', size: 'M', quantity: 2 }, { productId: 'a', size: 'L', quantity: 2 }], KHO, 'buyer'),
    loiCo(/chỉ còn 1/),
  );
  assert.throws(() => tachDon([{ productId: 'c', size: '', quantity: 1 }], KHO, 's2'), loiCo(/chính bạn/));
  assert.throws(() => tachDon([{ productId: 'a', size: '', quantity: 1 }], KHO, 'buyer'), loiCo(/Chọn size/));
  assert.throws(() => tachDon([{ productId: 'b', size: 'M', quantity: 1 }], KHO, 'buyer'), loiCo(/không có size/));
  assert.throws(() => tachDon([{ productId: 'z', size: '', quantity: 1 }], KHO, 'buyer'), loiCo(/đã bị xóa/));
  const het = new Map([['b', { ...KHO.get('b'), stock: 0 }]]);
  assert.throws(() => tachDon([{ productId: 'b', size: '', quantity: 1 }], het, 'buyer'), loiCo(/hết hàng/));
});

const don = (status) => ({ buyerId: 'm', shopId: 's', status });

test('luồng đơn: xác nhận → giao → đã giao → khách nhận', () => {
  let d = don('pending_confirmation');
  for (const [hd, ai, sang] of [
    ['xacNhan', 's', 'to_ship'],
    ['giaoHang', 's', 'shipping'],
    ['daGiao', 's', 'delivered'],
    ['daNhan', 'm', 'buyer_confirmed'],
  ]) {
    const kq = chuyenTrangThaiDon(d, hd, ai, {}, NOW);
    assert.equal(kq.ghi.status, sang);
    assert.equal(kq.hoanKho, false);
    d = { ...d, ...kq.ghi };
  }
  // Khách nhận hàng trước khi shop bấm "đã giao" cũng được.
  assert.equal(chuyenTrangThaiDon(don('shipping'), 'daNhan', 'm', {}, NOW).ghi.status, 'buyer_confirmed');
});

test('hủy đơn: khách chỉ hủy khi chờ xác nhận, shop hủy trước khi giao; hủy thì hoàn kho', () => {
  const kq = chuyenTrangThaiDon(don('pending_confirmation'), 'huy', 'm', { reason: 'Đặt nhầm' }, NOW);
  assert.deepEqual(kq.ghi, { status: 'cancelled', cancelledBy: 'buyer', cancelReason: 'Đặt nhầm' });
  assert.equal(kq.hoanKho, true);
  assert.throws(() => chuyenTrangThaiDon(don('to_ship'), 'huy', 'm', { reason: 'x' }, NOW), loiCo(/không thể hủy/));
  assert.equal(chuyenTrangThaiDon(don('to_ship'), 'huy', 's', { reason: 'Hết size' }, NOW).ghi.cancelledBy, 'shop');
  assert.throws(() => chuyenTrangThaiDon(don('shipping'), 'huy', 's', { reason: 'x' }, NOW), loiCo(/trạng thái/));
  assert.throws(() => chuyenTrangThaiDon(don('pending_confirmation'), 'huy', 'm', {}, NOW), loiCo(/lý do/i));
});

test('đúng vai mới được làm', () => {
  assert.throws(() => chuyenTrangThaiDon(don('pending_confirmation'), 'xacNhan', 'm', {}, NOW), loiCo(/quyền/));
  assert.throws(() => chuyenTrangThaiDon(don('delivered'), 'daNhan', 's', {}, NOW), loiCo(/quyền/));
  assert.throws(() => chuyenTrangThaiDon(don('pending_confirmation'), 'huy', 'x', { reason: 'x' }, NOW), loiCo(/quyền/));
  assert.throws(() => chuyenTrangThaiDon(don('pending_confirmation'), 'giaoHang', 's', {}, NOW), loiCo(/trạng thái/));
});

test('hệ thống tự hủy đơn quá hạn', () => {
  const kq = huyQuaHan(NOW);
  assert.equal(kq.ghi.cancelledBy, 'system');
  assert.equal(kq.lichSuMoi.at, NOW);
});
