'use strict';

/**
 * Cửa vào duy nhất của module Quán ăn cho app: callable `quanAnApi({ hanhDong, ...thamSo })`.
 * Mỗi hành động tự kiểm tra quyền; hệ thống quyết định, không tin app (mục 3.18 quy tắc 4).
 */

const { db } = require('../chung/firebase');
const { thamSoSai, loiNguoiDung, khongTimThay, khongCoQuyen } = require('../chung/loi');
const { nguoiDung, canAdmin } = require('../chung/tai_khoan');
const { layCauHinh, xoaBoNho, choApp } = require('./cau_hinh');
const { COL, ghiNhatKy, laAdminQuanAn } = require('./ho_tro');
const QS = require('./quan_service');
const MN = require('./menu_service');
const CI = require('./check_in_service');
const DB = require('./dat_ban_service');
const DM = require('./don_mon_service');
const TT = require('./tuong_tac_service');
const AD = require('./admin_service');
const CONG = require('./cong_gia_lap');

const THAO_TAC_BAN = new Set(['QUAN_XAC_NHAN', 'QUAN_TU_CHOI', 'QUAN_HUY', 'QUAN_KHACH_DEN', 'QUAN_KHONG_DEN', 'SV_HUY']);
const THAO_TAC_DON = new Set([
  'SV_HUY', 'SV_HUY_QUAN_CHAM', 'SV_DA_NHAN', 'SV_CHUA_NHAN_MON', 'SV_KHIEU_NAI', 'SV_PHAN_DOI',
  'QUAN_NHAN', 'QUAN_TU_CHOI', 'QUAN_HUY', 'QUAN_SAN_SANG', 'QUAN_DANG_GIAO', 'QUAN_NHAP_MA', 'QUAN_DA_GIAO', 'QUAN_KHONG_NHAN', 'QUAN_TRA_LOI_KHIEU_NAI',
  'ADMIN_QUYET', 'ADMIN_QUA_HAN', 'ADMIN_LUA_DAO',
]);

async function xuLy(request, biMat) {
  const { hanhDong, ...tham } = request.data || {};
  const nd = await nguoiDung(request);
  const admin = async () => { await canAdmin(nd.uid, 'quanAn'); return nd.uid; };

  switch (hanhDong) {
    // ---- Cấu hình, thông tin sinh viên ----
    case 'cauHinh': return choApp(await layCauHinh());
    case 'thongTinSinhVien': return DM.thongTinSinhVien(nd);

    // ---- Quán (chủ quán) ----
    case 'guiDuyetQuan': return QS.guiDuyetQuan(nd, tham);
    case 'suaQuan': return QS.suaQuan(nd, tham);
    case 'nangCapLoaiQuan': return QS.nangCapLoaiQuan(nd, tham);
    case 'caiDatDatMon': return QS.caiDatDatMon(nd, tham);
    case 'tamNghi': return QS.tamNghi(nd, tham);
    case 'tamNgungNhanDon': return QS.tamNgungNhanDon(nd, tham);
    case 'anHienQuan': return QS.anHienQuan(nd, tham);
    case 'ngungKinhDoanh': return QS.ngungKinhDoanh(nd, tham);
    case 'xacNhanConHoatDong': return QS.xacNhanConHoatDong(nd, tham);
    case 'laySdtQuan': {
      const q = await db.collection(COL.quan).doc(String(tham.quanId || '')).get();
      if (!q.exists) throw khongTimThay('Quán');
      return { sdt: q.get('sdt') || null };
    }
    case 'layGiayToQuan': {
      const q = await db.collection(COL.quan).doc(String(tham.quanId || '')).get();
      if (!q.exists) throw khongTimThay('Quán');
      if (q.get('chuQuanId') !== nd.uid && !(await laAdminQuanAn(nd.uid))) throw khongCoQuyen();
      const g = await QS.docGiayTo(q.id);
      return { maSoThue: g.maSoThue || '', anhGiayChungNhan: g.anhGiayChungNhan || [], anhAttp: g.anhAttp || [] };
    }

    // ---- Menu, khuyến mãi ----
    case 'luuNhomMon': return MN.luuNhomMon(nd, tham);
    case 'xoaNhomMon': return MN.xoaNhomMon(nd, tham);
    case 'luuMon': return MN.luuMon(nd, tham);
    case 'xoaMon': return MN.xoaMon(nd, tham);
    case 'batTatMon': return MN.batTatMon(nd, tham);
    case 'luuKhuyenMai': return MN.luuKhuyenMai(nd, tham);
    case 'dungKhuyenMai': return MN.dungKhuyenMai(nd, tham);

    // ---- Check-in ----
    case 'checkIn': return CI.checkIn(nd, tham);

    // ---- Đặt bàn ----
    case 'datBan': return DB.datBan(nd, tham);
    case 'thaoTacBan': {
      const { banId, version, loai } = tham;
      if (!THAO_TAC_BAN.has(loai)) throw thamSoSai('Thao tác không hợp lệ.');
      return DB.chayTrenBan(banId, { su: { loai }, nguoiLam: { uid: nd.uid, vaiTro: 'nguoi_dung' }, versionDaThay: version ?? null });
    }
    case 'xuLyHanBan': {
      const s = await db.collection(COL.datBan).doc(String(tham.banId || '')).get();
      if (!s.exists) throw thamSoSai();
      if (![s.get('svId'), s.get('chuQuanId')].includes(nd.uid) && !(await laAdminQuanAn(nd.uid))) throw khongCoQuyen();
      return DB.chayTrenBan(tham.banId);
    }

    // ---- Đặt món, thanh toán ----
    case 'baoGiaDon': return DM.baoGiaDon(nd, tham);
    case 'datMon': return DM.datMon(nd, tham);
    case 'thanhToanGiaLap': return CONG.thanhToan({ uid: nd.uid, laAdmin: await laAdminQuanAn(nd.uid) }, tham, biMat());
    case 'xemPhienThanhToan': return CONG.xemPhien(nd.uid, tham.donId);
    case 'xuLyHanDon': return DM.xuLyHanDon(nd, tham, await laAdminQuanAn(nd.uid));
    case 'thaoTacDon': {
      const { donId, version, su } = tham;
      if (!su || !THAO_TAC_DON.has(su.loai)) throw thamSoSai('Thao tác không hợp lệ.');
      if (su.loai.startsWith('ADMIN_')) {
        const adminUid = await admin();
        const kq = await AD.quyetDon(adminUid, { donId, loai: su.loai, quyetDinh: su.quyetDinh, soTienHoan: su.soTienHoan, lyDo: su.lyDo });
        return kq;
      }
      return DM.chayTrenDon(donId, { su, nguoiLam: { uid: nd.uid, vaiTro: 'nguoi_dung' }, versionDaThay: version ?? null });
    }

    // ---- Chat, đánh giá, báo cáo, kháng nghị ----
    case 'guiTin': return TT.guiTin(nd, tham);
    case 'daXemChat': return TT.daXem(nd, tham);
    case 'chanChat': return TT.chan(nd, tham);
    case 'guiDanhGia': return TT.guiDanhGia(nd, tham);
    case 'traLoiDanhGia': return TT.chuTraLoiDanhGia(nd, tham);
    case 'guiBaoCao': return TT.guiBaoCao(nd, tham);
    case 'guiKhangNghi': return TT.guiKhangNghi(nd, tham);

    // ---- Admin Quán ăn ----
    case 'adminDuyet': return QS.adminDuyet(await admin(), tham);
    case 'adminYeuCauChuyenLoai': return QS.adminYeuCauChuyenLoai(await admin(), tham);
    case 'adminBoCoKhaiSai': return QS.adminBoCoKhaiSai(await admin(), tham);
    case 'adminAnHien': return QS.adminAnHien(await admin(), tham);
    case 'adminDinhChi': return QS.adminDinhChi(await admin(), tham);
    case 'adminKhoaBan': return QS.adminKhoaBan(await admin(), tham);
    case 'adminLuaDao': return QS.adminLuaDao(await admin(), tham);
    case 'adminKhoaChucNang': return AD.khoaChucNang(await admin(), tham);
    case 'adminXuLyBaoCao': return TT.xuLyBaoCao(await admin(), tham);
    case 'adminXuLyKhangNghi': return TT.xuLyKhangNghi(await admin(), tham);
    case 'adminCauHinh': {
      const uid = await admin();
      if (!tham.ghiDe || typeof tham.ghiDe !== 'object') throw thamSoSai();
      await db.collection('qa_cau_hinh').doc('hien_hanh').set(tham.ghiDe, { merge: false });
      xoaBoNho();
      await ghiNhatKy(uid, 'doi_cau_hinh', { loai: 'cau_hinh', id: 'hien_hanh' }, JSON.stringify(tham.ghiDe));
      return choApp(await layCauHinh());
    }

    default:
      throw loiNguoiDung('Hành động không hợp lệ.', 'invalid-argument');
  }
}

module.exports = { xuLy };
