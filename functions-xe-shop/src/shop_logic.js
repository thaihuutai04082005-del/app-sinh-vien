// Quy tắc nghiệp vụ Shop đồ rẻ (mục 3.4), không đụng Firestore để test được.
import { khongCoQuyen, loi, thamSoSai } from './loi.js';
import { chuoi, chuoiTuyChon, danhSachLink, motTrong, soDienThoai, soNguyen } from './kiem_tra.js';

export const DANH_MUC = ['ao', 'quan', 'phu_kien'];
export const SIZE = ['S', 'M', 'L', 'XL', 'XXL', 'Freesize'];
export const HAN_XAC_NHAN_MS = 2 * 86_400_000;
const SO_MON_TOI_DA = 20;
const SO_LUONG_TOI_DA = 10;

export const trangThaiKho = (stock) => (stock > 0 ? 'active' : 'out_of_stock');

/** Mốc thời gian: số mili giây (test) hoặc Timestamp của Firestore. */
const ms = (v) => (typeof v === 'number' ? v : v?.toMillis?.() ?? null);

export function sanPham(tham) {
  const sizes = tham.sizes ?? [];
  if (!Array.isArray(sizes) || !sizes.every((s) => SIZE.includes(s)) || new Set(sizes).size !== sizes.length) {
    throw thamSoSai('Size không hợp lệ.');
  }
  const stock = soNguyen(tham.stock, 'Tồn kho', { max: 9999 });
  return {
    name: chuoi(tham.name, 'Tên sản phẩm', { max: 200 }),
    description: chuoiTuyChon(tham.description, 'Mô tả', 2000),
    images: danhSachLink(tham.images, 'ảnh sản phẩm', { min: 1, max: 8 }),
    videos: danhSachLink(tham.videos, 'video', { max: 1 }),
    price: soNguyen(tham.price, 'Giá', { min: 1000, max: 50_000_000 }),
    sizes: SIZE.filter((s) => sizes.includes(s)),
    stock,
    category: motTrong(tham.category, DANH_MUC, 'Danh mục'),
    status: trangThaiKho(stock),
  };
}

/**
 * Kiểm tra giỏ gửi lên, gộp các dòng trùng (cùng sản phẩm + size). Dòng mua theo giá đã trả
 * (`offerId`) đứng riêng, không gộp với dòng giá thường.
 */
export function gioHang(items) {
  if (!Array.isArray(items) || items.length === 0) throw thamSoSai('Giỏ hàng trống.');
  const gop = new Map();
  for (const it of items) {
    const productId = chuoi(it?.productId, 'Sản phẩm', { max: 128 });
    const size = it?.size == null || it.size === '' ? '' : motTrong(it.size, SIZE, 'Size');
    const quantity = soNguyen(it?.quantity, 'Số lượng', { min: 1, max: SO_LUONG_TOI_DA });
    const offerId = it?.offerId ? chuoi(it.offerId, 'Trả giá', { max: 128 }) : null;
    if (offerId) {
      if (gop.has(`offer|${offerId}`)) throw thamSoSai('Mỗi lần trả giá chỉ mua được một lần.');
      gop.set(`offer|${offerId}`, { productId, size, quantity, offerId });
      continue;
    }
    const khoa = `${productId}|${size}`;
    const cu = gop.get(khoa);
    gop.set(khoa, { productId, size, quantity: (cu?.quantity ?? 0) + quantity });
  }
  if (gop.size > SO_MON_TOI_DA) throw thamSoSai(`Mỗi lần đặt tối đa ${SO_MON_TOI_DA} món.`);
  return [...gop.values()];
}

export function nhanHang(tham) {
  const deliveryMethod = motTrong(tham.deliveryMethod, ['giao_tan_tro', 'hen_lay'], 'Cách nhận hàng');
  return {
    receiverName: chuoi(tham.receiverName, 'Tên người nhận', { max: 100 }),
    phone: soDienThoai(tham.phone),
    deliveryMethod,
    address: deliveryMethod === 'giao_tan_tro'
      ? chuoi(tham.address, 'Địa chỉ nhận', { max: 300 })
      : chuoiTuyChon(tham.address, 'Nơi hẹn lấy', 300),
    note: chuoiTuyChon(tham.note, 'Ghi chú', 300),
  };
}

/** Giá của một dòng: giá niêm yết, hoặc giá trả đã được shop chấp nhận (chỉ 1 sản phẩm). */
function giaDong(it, sp, buyerId, offers, now) {
  if (!it.offerId) return sp.price;
  const o = offers.get(it.offerId);
  if (!o || o.buyerId !== buyerId || o.productId !== it.productId) throw loi('Trả giá không hợp lệ.');
  if (o.status !== 'accepted') throw loi(`Trả giá cho "${sp.name}" chưa được shop chấp nhận hoặc đã dùng.`);
  if (o.expiresAt != null && ms(o.expiresAt) <= now) throw loi(`Giá đã trả cho "${sp.name}" đã hết hạn.`);
  if (it.quantity !== 1) throw loi('Giá đã trả chỉ áp dụng cho 1 sản phẩm.');
  return o.offerPrice;
}

/**
 * Tách giỏ thành từng đơn theo shop; giá lấy từ sản phẩm trên server (hoặc giá trả đã được chấp nhận
 * trong `offers`), không tin giá app gửi.
 * `sanPhams`: Map productId → dữ liệu sản phẩm (thiếu nghĩa là đã bị xóa).
 * Trả về { dons: [{shopId, shopName, items, subtotal, totalPrice}], tonKhoMoi: Map productId → stock }.
 */
export function tachDon(items, sanPhams, buyerId, offers = new Map(), now = Date.now()) {
  const tonKhoMoi = new Map();
  const theoShop = new Map();
  for (const it of items) {
    const sp = sanPhams.get(it.productId);
    if (!sp) throw loi('Có sản phẩm trong giỏ đã bị xóa. Vui lòng bỏ khỏi giỏ.');
    if (sp.shopId === buyerId) throw loi(`Không thể mua sản phẩm của chính bạn (${sp.name}).`);
    if (sp.sizes?.length) {
      if (!sp.sizes.includes(it.size)) throw loi(`Chọn size có sẵn cho "${sp.name}".`);
    } else if (it.size) {
      throw loi(`"${sp.name}" không có size.`);
    }
    const truoc = tonKhoMoi.get(it.productId) ?? sp.stock;
    if (truoc < it.quantity) {
      throw loi(truoc > 0 ? `"${sp.name}" chỉ còn ${truoc} sản phẩm.` : `"${sp.name}" đã hết hàng.`);
    }
    tonKhoMoi.set(it.productId, truoc - it.quantity);

    const gia = giaDong(it, sp, buyerId, offers, now);
    const don = theoShop.get(sp.shopId)
      ?? { shopId: sp.shopId, shopName: sp.shopName ?? '', items: [], subtotal: 0, totalPrice: 0, offerPrice: null };
    don.items.push({
      productId: it.productId,
      name: sp.name,
      image: sp.images?.[0] ?? '',
      price: gia,
      size: it.size,
      quantity: it.quantity,
      ...(it.offerId ? { offerId: it.offerId, listPrice: sp.price } : {}),
    });
    if (it.offerId) don.offerPrice = gia;
    don.subtotal += gia * it.quantity;
    don.totalPrice = don.subtotal;
    theoShop.set(sp.shopId, don);
  }
  return { dons: [...theoShop.values()], tonKhoMoi };
}

// ---------------------------------------------------------------- Trả giá (Make an offer)

/** Thời gian người mua được mua theo giá đã trả sau khi shop chấp nhận. */
export const HAN_MUA_THEO_GIA_TRA_MS = 86_400_000;
/** Giá trả thấp nhất so với giá niêm yết. */
export const TRA_GIA_TOI_THIEU = 0.5;

/** Kiểm tra lần trả giá `tham.offerPrice` cho sản phẩm `sp` (đã đọc từ server). */
export function traGiaMoi(tham, sp, buyerId) {
  if (sp.shopId === buyerId) throw loi('Không thể trả giá sản phẩm của chính bạn.');
  if (!(sp.stock > 0)) throw loi('Sản phẩm đã hết hàng.');
  const thapNhat = Math.ceil(sp.price * TRA_GIA_TOI_THIEU);
  const offerPrice = soNguyen(tham.offerPrice, 'Giá trả', { min: 1000, max: sp.price - 1 });
  if (offerPrice < thapNhat) throw loi(`Giá trả tối thiểu là ${thapNhat.toLocaleString('vi-VN')}đ.`);
  const size = tham.size ?? '';
  if (sp.sizes?.length ? !sp.sizes.includes(size) : size !== '') throw loi('Chọn size có sẵn trước khi trả giá.');
  return { offerPrice, price: sp.price, size, message: chuoiTuyChon(tham.message, 'Lời nhắn', 200) };
}

const CHUYEN_TRA_GIA = {
  chapNhan: { ai: 'shop', sang: 'accepted' },
  tuChoi: { ai: 'shop', sang: 'rejected' },
  huy: { ai: 'buyer', sang: 'cancelled' },
};

/** Shop chấp nhận / từ chối, người mua rút lại một lần trả giá đang chờ. */
export function phanHoiTraGia(offer, hanhDong, uid, now) {
  const quy = CHUYEN_TRA_GIA[hanhDong];
  if (!quy) throw thamSoSai('Hành động không hợp lệ.');
  const vaiTro = uid === offer.buyerId ? 'buyer' : uid === offer.shopId ? 'shop' : null;
  if (vaiTro !== quy.ai) throw khongCoQuyen();
  if (offer.status !== 'pending') throw loi('Lần trả giá này đã được trả lời.');
  return {
    status: quy.sang,
    ...(quy.sang === 'accepted' ? { expiresAt: now + HAN_MUA_THEO_GIA_TRA_MS } : {}),
  };
}

// ---------------------------------------------------------------- Voucher của shop

export const LOAI_GIAM = ['percent', 'fixed'];
const NGAY = 86_400_000;

/** Mã voucher: chữ in hoa + số, 4–15 ký tự (cũng là id document `vouchers/{code}`). */
export function maVoucher(v) {
  const s = String(v ?? '').trim().toUpperCase();
  if (!/^[A-Z0-9]{4,15}$/.test(s)) throw thamSoSai('Mã voucher gồm 4–15 chữ cái không dấu hoặc số.');
  return s;
}

export function voucherMoi(tham, now) {
  const discountType = motTrong(tham.discountType, LOAI_GIAM, 'Loại giảm giá');
  const discountValue = discountType === 'percent'
    ? soNguyen(tham.discountValue, 'Phần trăm giảm', { min: 1, max: 90 })
    : soNguyen(tham.discountValue, 'Số tiền giảm', { min: 1000, max: 5_000_000 });
  const expiredAt = tham.expiredAt;
  if (!Number.isInteger(expiredAt) || expiredAt <= now || expiredAt > now + 90 * NGAY) {
    throw thamSoSai('Hạn dùng phải trong 90 ngày tới.');
  }
  return {
    code: maVoucher(tham.code),
    discountType,
    discountValue,
    maxDiscount: discountType === 'percent' && tham.maxDiscount != null
      ? soNguyen(tham.maxDiscount, 'Giảm tối đa', { min: 1000, max: 5_000_000 })
      : null,
    minOrderValue: soNguyen(tham.minOrderValue ?? 0, 'Đơn tối thiểu', { max: 50_000_000 }),
    usageLimit: soNguyen(tham.usageLimit, 'Số lượt dùng', { min: 1, max: 1000 }),
    expiredAt,
  };
}

/** Số tiền giảm khi áp `voucher` cho đơn có tạm tính `subtotal`; ném lỗi nếu không dùng được. */
export function tinhGiam(voucher, subtotal, now) {
  if (!voucher || voucher.active === false) throw loi('Mã voucher không tồn tại hoặc đã ngừng.');
  if (ms(voucher.expiredAt) <= now) throw loi('Mã voucher đã hết hạn.');
  if ((voucher.usedCount ?? 0) >= voucher.usageLimit) throw loi('Mã voucher đã hết lượt dùng.');
  if (subtotal < (voucher.minOrderValue ?? 0)) {
    throw loi(`Mã này áp dụng cho đơn từ ${voucher.minOrderValue.toLocaleString('vi-VN')}đ.`);
  }
  let giam = voucher.discountType === 'percent'
    ? Math.floor((subtotal * voucher.discountValue) / 100)
    : voucher.discountValue;
  if (voucher.maxDiscount != null) giam = Math.min(giam, voucher.maxDiscount);
  return Math.min(giam, subtotal);
}

/** Thời gian khách được yêu cầu trả hàng sau khi shop báo đã giao; hết hạn thì đơn tự hoàn tất. */
export const HAN_TRA_HANG_MS = 3 * 86_400_000;
/** Shop phải trả lời yêu cầu trả hàng trong thời gian này, quá hạn coi như đồng ý. */
export const HAN_TRA_LOI_TRA_HANG_MS = 2 * 86_400_000;
export const CACH_THANH_TOAN = ['cod', 'online'];

/**
 * Bảng chuyển trạng thái (mục 3.4): hành động → ai làm và từ trạng thái nào sang trạng thái nào.
 * Trả hàng: đã giao → khách yêu cầu → shop đồng ý (hoàn tiền) hoặc từ chối → khách nhận
 * hoặc khiếu nại để admin Shop phân xử (xuLyKhieuNai).
 */
const CHUYEN = {
  xacNhan: { ai: 'shop', tu: ['pending_confirmation'], sang: 'to_ship' },
  giaoHang: { ai: 'shop', tu: ['to_ship'], sang: 'shipping' },
  daGiao: { ai: 'shop', tu: ['shipping'], sang: 'delivered' },
  daNhan: { ai: 'buyer', tu: ['shipping', 'delivered', 'return_rejected'], sang: 'buyer_confirmed' },
  huy: { ai: 'ca_hai', tu: ['pending_confirmation', 'to_ship'], sang: 'cancelled' },
  yeuCauTraHang: { ai: 'buyer', tu: ['delivered'], sang: 'return_requested' },
  dongYTraHang: { ai: 'shop', tu: ['return_requested'], sang: 'return_refund' },
  tuChoiTraHang: { ai: 'shop', tu: ['return_requested'], sang: 'return_rejected' },
  khieuNai: { ai: 'buyer', tu: ['return_rejected'], sang: 'return_disputed' },
};

export const HANH_DONG_DON = Object.keys(CHUYEN);

/** Tiền đi đâu khi đơn kết thúc: chỉ đơn trả online mới có tiền app đang giữ. */
function tien(don, sang) {
  if (don.paymentMethod !== 'online') return {};
  if (sang === 'buyer_confirmed') return { fundsReleased: true };
  if (sang === 'cancelled' || sang === 'return_refund') return { refunded: true };
  return {};
}

/**
 * Trả về { ghi, lichSuMoi, hoanKho } khi `uid` làm `hanhDong` trên đơn; ném lỗi nếu không được.
 * Các mốc hạn trong `ghi` (returnDeadline, returnResponseDeadline) là mili giây.
 */
export function chuyenTrangThaiDon(don, hanhDong, uid, tham, now) {
  const quy = CHUYEN[hanhDong];
  if (!quy) throw thamSoSai('Hành động không hợp lệ.');
  const vaiTro = uid === don.buyerId ? 'buyer' : uid === don.shopId ? 'shop' : null;
  if (!vaiTro || (quy.ai !== 'ca_hai' && quy.ai !== vaiTro)) throw khongCoQuyen();
  // Người mua chỉ hủy được khi shop chưa xác nhận (mục 3.4).
  if (hanhDong === 'huy' && vaiTro === 'buyer' && don.status === 'to_ship') {
    throw loi('Shop đã xác nhận đơn, bạn không thể hủy nữa.');
  }
  if (!quy.tu.includes(don.status)) throw loi('Đơn không còn ở trạng thái làm được việc này.');
  if (hanhDong === 'yeuCauTraHang' && ms(don.returnDeadline) != null && ms(don.returnDeadline) < now) {
    throw loi('Đã quá hạn yêu cầu trả hàng.');
  }

  const ghi = { status: quy.sang, ...tien(don, quy.sang) };
  const lichSuMoi = { status: quy.sang, by: vaiTro, at: now };
  switch (hanhDong) {
    case 'huy':
      ghi.cancelledBy = vaiTro;
      ghi.cancelReason = chuoi(tham.reason, 'Lý do hủy', { max: 300 });
      break;
    case 'daGiao':
      ghi.returnDeadline = now + HAN_TRA_HANG_MS;
      break;
    case 'yeuCauTraHang':
      ghi.returnReason = chuoi(tham.reason, 'Lý do trả hàng', { max: 500 });
      ghi.returnImages = danhSachLink(tham.images, 'ảnh', { max: 5 });
      ghi.returnResponseDeadline = now + HAN_TRA_LOI_TRA_HANG_MS;
      break;
    case 'tuChoiTraHang':
      ghi.returnRejectReason = chuoi(tham.reason, 'Lý do từ chối', { max: 500 });
      break;
    case 'khieuNai':
      ghi.disputeReason = chuoi(tham.reason, 'Nội dung khiếu nại', { max: 500 });
      break;
  }
  return { ghi, lichSuMoi, hoanKho: quy.sang === 'cancelled' || quy.sang === 'return_refund' };
}

/** Admin Shop phân xử khiếu nại trả hàng: đồng ý thì hoàn tiền cho khách, không thì đơn hoàn tất. */
export function phanXuKhieuNai(don, tham, now) {
  if (don.status !== 'return_disputed') throw loi('Đơn này không còn chờ phân xử.');
  if (typeof tham.dongY !== 'boolean') throw thamSoSai();
  const sang = tham.dongY ? 'return_refund' : 'buyer_confirmed';
  return {
    ghi: { status: sang, ...tien(don, sang), disputeResult: chuoi(tham.lyDo, 'Kết luận', { max: 500 }) },
    lichSuMoi: { status: sang, by: 'admin', at: now },
    hoanKho: tham.dongY,
  };
}

/** Đơn quá hạn shop xác nhận thì hệ thống tự hủy. */
export function huyQuaHan(now, don = {}) {
  return {
    ghi: {
      status: 'cancelled',
      ...tien(don, 'cancelled'),
      cancelledBy: 'system',
      cancelReason: 'Shop không xác nhận đơn trong 2 ngày.',
    },
    lichSuMoi: { status: 'cancelled', by: 'system', at: now },
  };
}

/**
 * Việc hệ thống tự làm khi tới hạn: hết hạn trả hàng thì đơn hoàn tất (tiền chuyển cho shop);
 * shop không trả lời yêu cầu trả hàng thì coi như đồng ý. Trả về null nếu chưa tới hạn.
 */
export function tuXuLyTraHang(don, now) {
  const tra = (sang, hoanKho) => ({
    ghi: { status: sang, ...tien(don, sang) },
    lichSuMoi: { status: sang, by: 'system', at: now },
    hoanKho,
  });
  if (don.status === 'delivered' && ms(don.returnDeadline) != null && ms(don.returnDeadline) <= now) {
    return tra('buyer_confirmed', false);
  }
  if (don.status === 'return_requested' && ms(don.returnResponseDeadline) != null
      && ms(don.returnResponseDeadline) <= now) {
    return tra('return_refund', true);
  }
  return null;
}
