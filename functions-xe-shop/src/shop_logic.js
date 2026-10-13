// Quy tắc nghiệp vụ Shop đồ rẻ (mục 3.4), không đụng Firestore để test được.
import { khongCoQuyen, loi, thamSoSai } from './loi.js';
import { chuoi, chuoiTuyChon, danhSachLink, motTrong, soDienThoai, soNguyen } from './kiem_tra.js';

export const DANH_MUC = ['ao', 'quan', 'phu_kien'];
export const SIZE = ['S', 'M', 'L', 'XL', 'XXL', 'Freesize'];
export const HAN_XAC_NHAN_MS = 2 * 86_400_000;
const SO_MON_TOI_DA = 20;
const SO_LUONG_TOI_DA = 10;

export const trangThaiKho = (stock) => (stock > 0 ? 'active' : 'out_of_stock');

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

/** Kiểm tra giỏ gửi lên, gộp các dòng trùng (cùng sản phẩm + size). */
export function gioHang(items) {
  if (!Array.isArray(items) || items.length === 0) throw thamSoSai('Giỏ hàng trống.');
  const gop = new Map();
  for (const it of items) {
    const productId = chuoi(it?.productId, 'Sản phẩm', { max: 128 });
    const size = it?.size == null || it.size === '' ? '' : motTrong(it.size, SIZE, 'Size');
    const quantity = soNguyen(it?.quantity, 'Số lượng', { min: 1, max: SO_LUONG_TOI_DA });
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

/**
 * Tách giỏ thành từng đơn theo shop; giá lấy từ sản phẩm trên server, không tin giá app gửi.
 * `sanPhams`: Map productId → dữ liệu sản phẩm (thiếu nghĩa là đã bị xóa).
 * Trả về { dons: [{shopId, shopName, items, totalPrice}], tonKhoMoi: Map productId → stock }.
 */
export function tachDon(items, sanPhams, buyerId) {
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

    const don = theoShop.get(sp.shopId) ?? { shopId: sp.shopId, shopName: sp.shopName ?? '', items: [], totalPrice: 0 };
    don.items.push({
      productId: it.productId,
      name: sp.name,
      image: sp.images?.[0] ?? '',
      price: sp.price,
      size: it.size,
      quantity: it.quantity,
    });
    don.totalPrice += sp.price * it.quantity;
    theoShop.set(sp.shopId, don);
  }
  return { dons: [...theoShop.values()], tonKhoMoi };
}

const CHUYEN = {
  xacNhan: { ai: 'shop', tu: ['pending_confirmation'], sang: 'to_ship' },
  giaoHang: { ai: 'shop', tu: ['to_ship'], sang: 'shipping' },
  daGiao: { ai: 'shop', tu: ['shipping'], sang: 'delivered' },
  daNhan: { ai: 'buyer', tu: ['shipping', 'delivered'], sang: 'buyer_confirmed' },
  huy: { ai: 'ca_hai', tu: ['pending_confirmation', 'to_ship'], sang: 'cancelled' },
};

export const HANH_DONG_DON = Object.keys(CHUYEN);

/** Trả về { ghi, lichSuMoi, hoanKho } khi `uid` làm `hanhDong` trên đơn; ném lỗi nếu không được. */
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

  const ghi = { status: quy.sang };
  if (hanhDong === 'huy') {
    ghi.cancelledBy = vaiTro;
    ghi.cancelReason = chuoi(tham.reason, 'Lý do hủy', { max: 300 });
  }
  return { ghi, lichSuMoi: { status: quy.sang, by: vaiTro, at: now }, hoanKho: hanhDong === 'huy' };
}

/** Đơn quá hạn shop xác nhận thì hệ thống tự hủy. */
export function huyQuaHan(now) {
  return {
    ghi: { status: 'cancelled', cancelledBy: 'system', cancelReason: 'Shop không xác nhận đơn trong 2 ngày.' },
    lichSuMoi: { status: 'cancelled', by: 'system', at: now },
  };
}
