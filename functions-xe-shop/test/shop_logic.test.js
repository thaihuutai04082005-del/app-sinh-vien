import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  chuyenTrangThaiDon, demHieuSuat, gioHang, huyQuaHan, nhanHang, phanHoiTraGia, phanXuKhieuNai, sanPham, tachDon, tinhGiam,
  traGiaMoi, tuXuLyTraHang, voucherMoi,
} from '../src/shop_logic.js';

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

const H = 86_400_000;

test('đã giao thì có hạn trả hàng 3 ngày; hết hạn hệ thống tự hoàn tất, chuyển tiền cho shop', () => {
  const kq = chuyenTrangThaiDon(don('shipping'), 'daGiao', 's', {}, NOW);
  assert.equal(kq.ghi.returnDeadline, NOW + 3 * H);
  const d = { ...don('delivered'), paymentMethod: 'online', returnDeadline: NOW + 3 * H };
  assert.equal(tuXuLyTraHang(d, NOW + 2 * H), null);
  const het = tuXuLyTraHang(d, NOW + 3 * H);
  assert.deepEqual(het.ghi, { status: 'buyer_confirmed', fundsReleased: true });
  assert.equal(het.lichSuMoi.by, 'system');
  // COD: tiền đã trả tận tay, không có gì để giữ / chuyển.
  assert.deepEqual(tuXuLyTraHang({ ...d, paymentMethod: 'cod' }, NOW + 3 * H).ghi, { status: 'buyer_confirmed' });
});

test('trả hàng: khách yêu cầu kèm lý do trong hạn; shop đồng ý thì hoàn tiền, hoàn kho', () => {
  const d = { ...don('delivered'), paymentMethod: 'online', returnDeadline: NOW + H };
  assert.throws(() => chuyenTrangThaiDon(d, 'yeuCauTraHang', 'm', {}, NOW), loiCo(/lý do trả hàng/));
  assert.throws(() => chuyenTrangThaiDon(d, 'yeuCauTraHang', 'm', { reason: 'Rách' }, NOW + 2 * H), loiCo(/quá hạn/));
  assert.throws(() => chuyenTrangThaiDon(d, 'yeuCauTraHang', 's', { reason: 'x' }, NOW), loiCo(/quyền/));
  assert.throws(() => chuyenTrangThaiDon(don('buyer_confirmed'), 'yeuCauTraHang', 'm', { reason: 'x' }, NOW), loiCo(/trạng thái/));

  const yc = chuyenTrangThaiDon(d, 'yeuCauTraHang', 'm', { reason: 'Áo rách', images: ['https://x/r.jpg'] }, NOW);
  assert.equal(yc.ghi.status, 'return_requested');
  assert.equal(yc.ghi.returnReason, 'Áo rách');
  assert.deepEqual(yc.ghi.returnImages, ['https://x/r.jpg']);
  assert.equal(yc.ghi.returnResponseDeadline, NOW + 2 * H);
  assert.equal(yc.hoanKho, false);

  const dy = chuyenTrangThaiDon({ ...d, ...yc.ghi }, 'dongYTraHang', 's', {}, NOW);
  assert.deepEqual(dy.ghi, { status: 'return_refund', refunded: true });
  assert.equal(dy.hoanKho, true);
});

test('shop im lặng quá 2 ngày thì coi như đồng ý trả hàng', () => {
  const d = { ...don('return_requested'), returnResponseDeadline: NOW };
  const kq = tuXuLyTraHang(d, NOW);
  assert.equal(kq.ghi.status, 'return_refund');
  assert.equal(kq.hoanKho, true);
  assert.equal(tuXuLyTraHang({ ...d, returnResponseDeadline: NOW + 1 }, NOW), null);
});

test('shop từ chối phải có lý do; khách nhận hàng hoặc khiếu nại; admin phân xử', () => {
  const d = { ...don('return_requested'), paymentMethod: 'online' };
  assert.throws(() => chuyenTrangThaiDon(d, 'tuChoiTraHang', 's', {}, NOW), loiCo(/lý do từ chối/));
  const tc = chuyenTrangThaiDon(d, 'tuChoiTraHang', 's', { reason: 'Hàng đã giặt' }, NOW);
  assert.equal(tc.ghi.status, 'return_rejected');
  const bi = { ...d, ...tc.ghi };
  assert.equal(chuyenTrangThaiDon(bi, 'daNhan', 'm', {}, NOW).ghi.fundsReleased, true);
  assert.throws(() => chuyenTrangThaiDon(bi, 'khieuNai', 'm', {}, NOW), loiCo(/khiếu nại/));
  const kn = { ...bi, ...chuyenTrangThaiDon(bi, 'khieuNai', 'm', { reason: 'Chưa giặt' }, NOW).ghi };
  assert.equal(kn.status, 'return_disputed');

  assert.throws(() => phanXuKhieuNai(bi, { dongY: true, lyDo: 'x' }, NOW), loiCo(/không còn chờ/));
  assert.throws(() => phanXuKhieuNai(kn, { dongY: true }, NOW), loiCo(/kết luận/));
  const dongY = phanXuKhieuNai(kn, { dongY: true, lyDo: 'Ảnh cho thấy rách sẵn' }, NOW);
  assert.equal(dongY.ghi.status, 'return_refund');
  assert.equal(dongY.ghi.refunded, true);
  assert.equal(dongY.hoanKho, true);
  assert.equal(dongY.lichSuMoi.by, 'admin');
  const khong = phanXuKhieuNai(kn, { dongY: false, lyDo: 'Không đủ bằng chứng' }, NOW);
  assert.deepEqual([khong.ghi.status, khong.ghi.fundsReleased, khong.hoanKho], ['buyer_confirmed', true, false]);
});

test('đơn online bị hủy thì hoàn tiền', () => {
  const kq = chuyenTrangThaiDon({ ...don('pending_confirmation'), paymentMethod: 'online' }, 'huy', 'm', { reason: 'x' }, NOW);
  assert.equal(kq.ghi.refunded, true);
  assert.equal(huyQuaHan(NOW, { paymentMethod: 'online' }).ghi.refunded, true);
});

test('trả giá: từ 50% đến dưới giá niêm yết, không tự trả giá hàng mình, hết hàng thì thôi', () => {
  const sp = { shopId: 's', name: 'Áo', price: 100000, stock: 2 };
  assert.deepEqual(traGiaMoi({ offerPrice: 70000, message: ' Bớt nha ' }, sp, 'm'), {
    offerPrice: 70000, price: 100000, size: '', message: 'Bớt nha',
  });
  const coSize = { ...sp, sizes: ['M'] };
  assert.throws(() => traGiaMoi({ offerPrice: 70000 }, coSize, 'm'), loiCo(/Chọn size/));
  assert.equal(traGiaMoi({ offerPrice: 70000, size: 'M' }, coSize, 'm').size, 'M');
  assert.throws(() => traGiaMoi({ offerPrice: 49000 }, sp, 'm'), loiCo(/tối thiểu là 50\.000đ/));
  assert.throws(() => traGiaMoi({ offerPrice: 100000 }, sp, 'm'), loiCo(/Giá trả/));
  assert.throws(() => traGiaMoi({ offerPrice: 70000 }, sp, 's'), loiCo(/chính bạn/));
  assert.throws(() => traGiaMoi({ offerPrice: 70000 }, { ...sp, stock: 0 }, 'm'), loiCo(/hết hàng/));
});

test('trả lời trả giá: shop chấp nhận thì có hạn mua 24 giờ; người mua chỉ rút lại', () => {
  const o = { buyerId: 'm', shopId: 's', status: 'pending' };
  assert.deepEqual(phanHoiTraGia(o, 'chapNhan', 's', NOW), { status: 'accepted', expiresAt: NOW + H });
  assert.deepEqual(phanHoiTraGia(o, 'tuChoi', 's', NOW), { status: 'rejected' });
  assert.deepEqual(phanHoiTraGia(o, 'huy', 'm', NOW), { status: 'cancelled' });
  assert.throws(() => phanHoiTraGia(o, 'chapNhan', 'm', NOW), loiCo(/quyền/));
  assert.throws(() => phanHoiTraGia({ ...o, status: 'accepted' }, 'tuChoi', 's', NOW), loiCo(/đã được trả lời/));
});

test('đặt hàng theo giá trả: đúng người, đúng sản phẩm, còn hạn, 1 cái', () => {
  const offers = new Map([['o1', { buyerId: 'buyer', productId: 'c', status: 'accepted', offerPrice: 90000, expiresAt: NOW + H }]]);
  const { dons } = tachDon([{ productId: 'c', size: '', quantity: 1, offerId: 'o1' }], KHO, 'buyer', offers, NOW);
  assert.equal(dons[0].totalPrice, 90000);
  assert.equal(dons[0].offerPrice, 90000);
  assert.equal(dons[0].items[0].listPrice, 120000);
  const dat = (it, ds = offers, ai = 'buyer', luc = NOW) => () => tachDon([{ productId: 'c', size: '', quantity: 1, offerId: 'o1', ...it }], KHO, ai, ds, luc);
  assert.throws(dat({ quantity: 2 }), loiCo(/1 sản phẩm/));
  assert.throws(dat({}, offers, 'khac'), loiCo(/không hợp lệ/));
  assert.throws(dat({}, offers, 'buyer', NOW + H), loiCo(/hết hạn/));
  assert.throws(dat({}, new Map([['o1', { ...offers.get('o1'), status: 'used' }]])), loiCo(/chưa được shop chấp nhận/));
  // Giỏ không gộp dòng trả giá với dòng giá thường.
  assert.equal(gioHang([
    { productId: 'c', quantity: 1, offerId: 'o1' },
    { productId: 'c', quantity: 1 },
  ]).length, 2);
});

test('voucher: tạo đúng dữ liệu, tính giảm theo % có trần, theo số tiền, đơn tối thiểu', () => {
  const v = voucherMoi({
    code: ' sale10 ', discountType: 'percent', discountValue: 10, maxDiscount: 20000,
    minOrderValue: 100000, usageLimit: 50, expiredAt: NOW + H,
  }, NOW);
  assert.equal(v.code, 'SALE10');
  assert.throws(() => voucherMoi({ ...v, code: 'GIẢM' }, NOW), loiCo(/Mã voucher/));
  assert.throws(() => voucherMoi({ ...v, discountValue: 95 }, NOW), loiCo(/Phần trăm/));
  assert.throws(() => voucherMoi({ ...v, expiredAt: NOW - 1 }, NOW), loiCo(/90 ngày/));

  assert.equal(tinhGiam(v, 150000, NOW), 15000);
  assert.equal(tinhGiam(v, 500000, NOW), 20000);
  assert.throws(() => tinhGiam(v, 99000, NOW), loiCo(/từ 100\.000đ/));
  assert.throws(() => tinhGiam({ ...v, usedCount: 50 }, 150000, NOW), loiCo(/hết lượt/));
  assert.throws(() => tinhGiam(v, 150000, NOW + H), loiCo(/hết hạn/));
  assert.throws(() => tinhGiam({ ...v, active: false }, 150000, NOW), loiCo(/ngừng/));
  assert.throws(() => tinhGiam(null, 150000, NOW), loiCo(/không tồn tại/));
  const fixed = { ...v, discountType: 'fixed', discountValue: 30000, maxDiscount: null, minOrderValue: 0 };
  assert.equal(tinhGiam(fixed, 20000, NOW), 20000);
});

test('hiệu suất shop: đếm đơn shop / hệ thống hủy và thời gian xác nhận', () => {
  const d = { ...don('pending_confirmation'), lichSu: [{ status: 'pending_confirmation', by: 'buyer', at: NOW }] };
  assert.deepEqual(demHieuSuat(d, chuyenTrangThaiDon(d, 'xacNhan', 's', {}, NOW + 3_600_000)), {
    confirmCount: 1, confirmMsSum: 3_600_000,
  });
  assert.deepEqual(demHieuSuat(d, chuyenTrangThaiDon(d, 'huy', 's', { reason: 'Hết' }, NOW)), { cancelCount: 1 });
  assert.deepEqual(demHieuSuat(d, { ...huyQuaHan(NOW), hoanKho: true }), { cancelCount: 1 });
  // Khách tự hủy không trừ điểm shop.
  assert.deepEqual(demHieuSuat(d, chuyenTrangThaiDon(d, 'huy', 'm', { reason: 'Nhầm' }, NOW)), {});
});
