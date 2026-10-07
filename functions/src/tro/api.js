'use strict';

/**
 * Cửa vào duy nhất của module Tìm trọ cho app: callable `troApi({ hanhDong, ...thamSo })`.
 * Mỗi hành động tự kiểm tra quyền; hệ thống quyết định, không tin app (mục 2.18 quy tắc 4).
 */

const { db, ms } = require('../chung/firebase');
const { thamSoSai, loiNguoiDung } = require('../chung/loi');
const { nguoiDung, canOtp, canAdmin } = require('../chung/tai_khoan');
const DC = require('./dat_coc_service');
const NT = require('./nha_tro_service');
const CTT = require('./coc_truc_tiep_service');
const TT = require('./tuong_tac_service');
const AD = require('./admin_service');
const CONG = require('./cong_gia_lap');
const { layCauHinh, xoaBoNho } = require('./cau_hinh');

const THAO_TAC_COC = new Set([
  'SV_HUY', 'SV_KHONG_THUE', 'SV_YEU_CAU_DOI', 'SV_DA_NHAN', 'SV_KHIEU_NAI', 'SV_PHAN_DOI',
  'CT_HUY_COC', 'CT_DONG_Y_DOI', 'CT_TU_CHOI_DOI', 'CT_BAO_KHONG_DEN', 'CT_TRA_LOI_KHIEU_NAI',
]);

/** Khiếu nại / phản đối bắt buộc mô tả + bằng chứng (mục 2.5c). */
function kiemTraBangChung(tham) {
  if (String(tham.moTa || '').trim().length < 10) throw thamSoSai('Nhập mô tả (ít nhất 10 ký tự).');
  const bc = tham.bangChung;
  if (!Array.isArray(bc) || bc.length < 1 || bc.length > 5 || !bc.every((u) => typeof u === 'string' && u.length > 5)) {
    throw thamSoSai('Cần 1–5 ảnh / video bằng chứng.');
  }
}

async function xuLy(request, biMat) {
  const { hanhDong, ...tham } = request.data || {};
  const nd = await nguoiDung(request);
  const admin = async () => { await canAdmin(nd.uid, 'tro'); return nd.uid; };

  switch (hanhDong) {
    // ---- Cấu hình (để app hiện đúng con số) ----
    case 'cauHinh': return layCauHinh();

    // ---- Nhà trọ, phòng ----
    case 'guiDuyetNhaTro': return NT.guiDuyetNhaTro(nd, tham);
    case 'guiDuyetPhong': return NT.guiDuyetPhong(nd, tham);
    case 'suaNhaTro': return NT.suaNhaTro(nd, tham);
    case 'suaPhong': return NT.suaPhong(nd, tham);
    case 'anHienPhong': return NT.anHienPhong(nd, tham);
    case 'xoaPhong': return NT.xoaPhong(nd, tham);
    case 'daChoThueNgoaiApp': return NT.daChoThueNgoaiApp(nd, tham);
    case 'dangLaiPhong': return NT.dangLaiPhong(nd, tham);
    case 'anHienNhaTro': return NT.anHienNhaTro(nd, tham);
    case 'giaHanNhaTro': return NT.giaHanNhaTro(nd, tham);
    case 'laySdtChuTro': {
      const n = await db.collection('nha_tro').doc(String(tham.nhaTroId || '')).get();
      if (!n.exists) throw thamSoSai();
      const xt = await db.collection('xac_thuc').doc(n.get('chuTroId')).get();
      return { sdt: xt.exists ? xt.get('sdt') || null : null };
    }

    // ---- Đặt cọc ----
    case 'thongTinDatCoc': {
      const sdt = canOtp(nd.xacThuc);
      const khoa = await db.collection('tro_khoa').doc(sdt).get();
      return {
        conHuyMienPhi: await DC.soLanHuyMienPhiConLai(sdt),
        khoaCocDen: khoa.exists ? ms(khoa.get('khoaCocDen')) : null,
      };
    }
    case 'taoCoc': {
      const sdt = canOtp(nd.xacThuc);
      return DC.taoCoc({ uid: nd.uid, sdt }, tham);
    }
    case 'thanhToanGiaLap': {
      const laAdmin = await DC.laAdminTro(nd.uid);
      return CONG.thanhToan({ uid: nd.uid, laAdmin }, tham, biMat());
    }
    case 'xemPhienThanhToan': return CONG.xemPhien(nd.uid, tham.datCocId);
    case 'xuLyHanCoc': {
      // Mở lại khoản cọc: tự xử lý hạn đã tới để thấy đúng trạng thái sau hạn.
      const snap = await db.collection('tro_dat_coc').doc(String(tham.datCocId || '')).get();
      if (!snap.exists) throw thamSoSai();
      const x = snap.data();
      const laAdminTro = await DC.laAdminTro(nd.uid);
      if (![x.sinhVienId, x.chuTroId].includes(nd.uid) && !laAdminTro) throw loiNguoiDung('Không có quyền.', 'permission-denied');
      return DC.chayTrenKhoanCoc(tham.datCocId);
    }
    case 'thaoTacCoc': {
      const { datCocId, version, su } = tham;
      if (!su || !THAO_TAC_COC.has(su.loai)) throw thamSoSai('Thao tác không hợp lệ.');
      if (su.loai === 'SV_KHIEU_NAI' || su.loai === 'SV_PHAN_DOI') kiemTraBangChung(su);
      return DC.chayTrenKhoanCoc(datCocId, { su, nguoiLam: { uid: nd.uid, vaiTro: 'nguoi_dung' }, versionDaThay: version ?? null });
    }

    // ---- Cọc trực tiếp ----
    case 'xacNhanCocTrucTiep': return CTT.xacNhan(nd, tham);
    case 'capNhatCocTrucTiep': return CTT.capNhat(nd, tham);
    case 'toiDaThuePhong': return CTT.nguoiCocXacNhan(nd, tham);

    // ---- Chat, đánh giá, báo cáo, kháng nghị ----
    case 'guiTin': return TT.guiTin(nd, tham);
    case 'daXemChat': return TT.daXem(nd, tham);
    case 'chanChat': return TT.chan(nd, tham);
    case 'guiDanhGia': return TT.guiDanhGia(nd, tham);
    case 'traLoiDanhGia': return TT.chuTraLoiDanhGia(nd, tham);
    case 'guiBaoCao': return TT.guiBaoCao(nd, tham);
    case 'guiKhangNghi': return TT.guiKhangNghi(nd, tham);

    // ---- Admin Tìm trọ ----
    case 'adminDuyet': return NT.adminDuyet(await admin(), tham);
    case 'adminQuyetKhieuNai': return AD.quyetKhieuNai(await admin(), tham);
    case 'adminLuaDao': return AD.ketLuanLuaDao(await admin(), tham);
    case 'adminAnHien': return AD.anHien(await admin(), tham);
    case 'adminKhoaChucNang': return AD.khoaChucNang(await admin(), tham);
    case 'adminXuLyBaoCao': return TT.xuLyBaoCao(await admin(), tham);
    case 'adminXuLyKhangNghi': return TT.xuLyKhangNghi(await admin(), tham);
    case 'adminCauHinh': {
      const uid = await admin();
      await db.collection('tro_cau_hinh').doc('hien_hanh').set(tham.ghiDe || {}, { merge: false });
      xoaBoNho();
      await NT.ghiNhatKy(uid, 'doi_cau_hinh', { loai: 'cau_hinh', id: 'hien_hanh' }, JSON.stringify(tham.ghiDe || {}));
      return layCauHinh();
    }

    default:
      throw thamSoSai('Hành động không hợp lệ.');
  }
}

module.exports = { xuLy };
