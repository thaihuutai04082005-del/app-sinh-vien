'use strict';

/**
 * Máy trạng thái khoản cọc trên app (đặc tả mục 2.5a, 2.5b, 2.5c, 2.5g, 2.5h).
 *
 * Đây là logic THUẦN: không đọc / ghi Firestore, không gọi mạng. Nhận khoản cọc
 * (thời điểm là số mili giây), sự kiện và giờ hiện tại; trả về khoản cọc mới và
 * danh sách "tác động" (đổi phòng, tiền, vi phạm, thông báo) để lớp Cloud Functions
 * ghi xuống trong cùng một transaction. Nhờ vậy mọi dòng của bảng 2.5h test được.
 *
 * T = thời điểm nhận phòng hiện hành (`d.t`).
 */

const { PHUT } = require('./../config');

const TRANG_THAI = Object.freeze({
  choThanhToan: 'pending_payment',
  hetHan: 'expired',
  dangGiu: 'held',
  huyTrongAnHan: 'cancelled_grace',
  khieuNai: 'disputed',
  daChuyen: 'released',
  daHoan: 'refunded',
  matCoc: 'forfeited',
});

const DANG_CHAY = new Set([TRANG_THAI.choThanhToan, TRANG_THAI.dangGiu, TRANG_THAI.khieuNai]);

const LY_DO = Object.freeze({
  graceCancel: 'grace_cancel',
  studentConfirmed: 'student_confirmed',
  autoComplete: 'auto_complete',
  studentChangedMind: 'student_changed_mind',
  studentNoShow: 'student_no_show',
  ownerCancelled: 'owner_cancelled',
  ownerNoReplyReschedule: 'owner_no_reply_reschedule',
  ownerViolation: 'owner_violation',
  adminReleased: 'admin_released',
  systemLatePayment: 'system_late_payment',
  adminFraud: 'admin_fraud',
});

const LOI_DA_THAY_DOI = 'Thông tin đã thay đổi, vui lòng tải lại.';

const p = (cfg, khoa) => cfg[khoa] * PHUT;

/** Kiểm tra lúc tạo khoản cọc (mục 2.4 Bước 3, 2.16). Trả về chuỗi lỗi hoặc null. */
function kiemTraTaoCoc({ now, t, ngayVaoO, soTien, giaThue }, cfg) {
  if (!Number.isFinite(t)) return 'Chọn thời điểm nhận phòng.';
  if (t < now + p(cfg, 'nhanPhongSauItNhatPhut')) {
    return 'Thời điểm nhận phòng phải cách bây giờ ít nhất 2 giờ.';
  }
  if (ngayVaoO && t < ngayVaoO) {
    return 'Thời điểm nhận phòng không được trước ngày có thể vào ở của phòng.';
  }
  if (t > now + p(cfg, 'nhanPhongToiDaPhut')) {
    return 'Thời điểm nhận phòng không được quá 14 ngày kể từ bây giờ.';
  }
  if (!(soTien > 0)) return 'Phòng chưa có số tiền cọc hợp lệ.';
  if (soTien > giaThue * cfg.cocToiDaSoThang) {
    return 'Tiền cọc không được vượt quá 1 tháng tiền thuê.';
  }
  return null;
}

/** Tạo khoản cọc mới ở trạng thái chờ thanh toán. */
function taoKhoanCoc({ now, t, ngayVaoO, soTien, coQuyenHuyMienPhi }, cfg) {
  return {
    status: TRANG_THAI.choThanhToan,
    version: 1,
    soTien,
    coQuyenHuyMienPhi: !!coQuyenHuyMienPhi,
    taoLuc: now,
    hanThanhToan: now + p(cfg, 'choThanhToanPhut'),
    heldAt: null,
    hanHuyMienPhi: null,
    tBanDau: t,
    t,
    ngayVaoO: ngayVaoO || null,
    daDungDoi: false,
    doi: null,
    khongDen: null,
    khieuNai: null,
    danhGia: null,
    daXuLy: {},
    lyDoKetThuc: null,
    ketThucLuc: null,
  };
}

function ketQuaRong(d) {
  return {
    d,
    phong: null, // trạng thái phòng mới (nếu đổi)
    goKhoa: false, // gỡ khóa thanh toán của phòng
    tien: [], // 'giu' | 'chuyen' | 'hoan' | 'het_han' | 'that_bai'
    viPham: [], // loại vi phạm của chủ trọ
    khieuNaiSai: false, // ghi 1 lần khiếu nại sai cho sinh viên
    ghiHuyMienPhi: false, // ghi 1 lần dùng quyền hủy miễn phí
    chupThongTin: false, // lưu bản chụp thông tin phòng lúc cọc
    thongBao: [], // { toi: 'sv' | 'chu' | 'admin', loai }
  };
}

function loi(thongDiep) {
  return { loi: thongDiep };
}

function ketThuc(d, status, lyDo, now) {
  d.status = status;
  d.lyDoKetThuc = lyDo;
  d.ketThucLuc = now;
  if (d.doi && d.doi.ketQua === 'cho') d.doi = { ...d.doi, ketQua: 'dong' };
}

function moDanhGia(d, { nhan, tinhDiem, han }) {
  d.danhGia = { nhan, tinhDiem, han };
}

function sao(d) {
  return {
    ...d,
    doi: d.doi ? { ...d.doi } : null,
    khongDen: d.khongDen ? { ...d.khongDen } : null,
    khieuNai: d.khieuNai ? { ...d.khieuNai } : null,
    danhGia: d.danhGia ? { ...d.danhGia } : null,
    daXuLy: { ...d.daXuLy },
  };
}

/** Thanh toán được ghi nhận (đúng hạn → giữ tiền; trễ hạn → tự hoàn 100%). */
function nhanThanhToan(d, ghiNhanLuc, now, cfg, { phongConTrong = true } = {}) {
  const trongHan = ghiNhanLuc <= d.hanThanhToan + cfg.congChenhGiay * 1000;
  if (d.status === TRANG_THAI.choThanhToan || (d.status === TRANG_THAI.hetHan && trongHan && phongConTrong && !d.daNhanTien)) {
    const kq = ketQuaRong(d);
    if (trongHan) {
      d.status = TRANG_THAI.dangGiu;
      d.daNhanTien = true;
      d.heldAt = now;
      d.hanHuyMienPhi = now + p(cfg, 'huyMienPhiPhut');
      kq.phong = 'reserved';
      kq.goKhoa = true;
      kq.tien.push('giu');
      kq.chupThongTin = true;
      kq.thongBao.push({ toi: 'sv', loai: 'coc_thanh_cong' }, { toi: 'chu', loai: 'co_nguoi_coc' });
      return kq;
    }
    // Cổng ghi nhận sau hạn: không nhận, hoàn 100%, phòng không đổi.
    kq.goKhoa = d.status === TRANG_THAI.choThanhToan;
    d.daNhanTien = true;
    ketThuc(d, TRANG_THAI.daHoan, LY_DO.systemLatePayment, now);
    kq.tien.push('hoan');
    kq.thongBao.push({ toi: 'sv', loai: 'tien_den_muon_da_hoan' });
    return kq;
  }
  if (d.status === TRANG_THAI.hetHan && !d.daNhanTien) {
    // Đã hết hạn (hoặc phòng đã thuộc người khác) mà tiền mới về: tự hoàn 100%.
    const kq = ketQuaRong(d);
    d.daNhanTien = true;
    ketThuc(d, TRANG_THAI.daHoan, LY_DO.systemLatePayment, now);
    kq.tien.push('hoan');
    kq.thongBao.push({ toi: 'sv', loai: 'tien_den_muon_da_hoan' });
    return kq;
  }
  return { boQua: true, d }; // Cổng báo "đã trả" lần 2: chỉ ghi nhận lần đầu.
}

/**
 * Áp một sự kiện lên khoản cọc. `su` = { loai, ...tham số }.
 * Trả về { loi } nếu không hợp lệ, { boQua } nếu không có gì đổi, hoặc kết quả có tác động.
 */
function apDung(dGoc, su, now, cfg) {
  const d = sao(dGoc);
  const t = d.t;
  const kq = () => ketQuaRong(d);
  const S = TRANG_THAI;

  switch (su.loai) {
    case 'THANH_TOAN_OK':
      return nhanThanhToan(d, su.ghiNhanLuc, now, cfg, su);

    case 'THANH_TOAN_LOI': {
      if (d.status !== S.choThanhToan) return { boQua: true, d };
      d.status = S.hetHan;
      d.ketThucLuc = now;
      const r = kq();
      r.goKhoa = true;
      r.tien.push('that_bai');
      r.thongBao.push({ toi: 'sv', loai: 'thanh_toan_that_bai' });
      return r;
    }

    case 'HET_HAN_THANH_TOAN': {
      if (d.status !== S.choThanhToan) return { boQua: true, d };
      // Hỏi lại cổng trước khi cho hết hạn: cổng đã ghi nhận đúng hạn thì vẫn giữ tiền.
      if (su.congDaThu && su.congDaThu.ghiNhanLuc != null) {
        return nhanThanhToan(d, su.congDaThu.ghiNhanLuc, now, cfg);
      }
      d.status = S.hetHan;
      d.ketThucLuc = now;
      const r = kq();
      r.goKhoa = true;
      r.tien.push('het_han');
      r.thongBao.push({ toi: 'sv', loai: 'thanh_toan_het_han' });
      return r;
    }

    case 'SV_HUY': {
      if (d.status !== S.dangGiu) return loi(LOI_DA_THAY_DOI);
      if (!d.coQuyenHuyMienPhi) return loi('Bạn đã dùng hết lượt hủy miễn phí trong 30 ngày.');
      if (now > d.hanHuyMienPhi) return loi('Đã quá 30 phút hủy miễn phí.');
      ketThuc(d, S.huyTrongAnHan, LY_DO.graceCancel, now);
      const r = kq();
      r.phong = 'available';
      r.tien.push('hoan');
      r.ghiHuyMienPhi = true;
      r.thongBao.push({ toi: 'sv', loai: 'huy_mien_phi_da_hoan' }, { toi: 'chu', loai: 'sv_huy_trong_30_phut' });
      return r;
    }

    case 'SV_KHONG_THUE': {
      if (d.status !== S.dangGiu) return loi(LOI_DA_THAY_DOI);
      if (now >= t) return loi('Đã tới thời điểm nhận phòng, không dùng "Không thuê nữa" được.');
      if (d.coQuyenHuyMienPhi && now <= d.hanHuyMienPhi) {
        return loi('Bạn còn trong 30 phút hủy miễn phí, hãy dùng nút Hủy để được hoàn 100%.');
      }
      ketThuc(d, S.matCoc, LY_DO.studentChangedMind, now);
      const r = kq();
      r.phong = 'available';
      r.tien.push('chuyen');
      r.thongBao.push({ toi: 'sv', loai: 'mat_coc_khong_thue' }, { toi: 'chu', loai: 'sv_khong_thue_da_nhan_tien' });
      return r;
    }

    case 'CT_HUY_COC': {
      if (d.status !== S.dangGiu) return loi(LOI_DA_THAY_DOI);
      if (now >= t) return loi('Chỉ hủy cọc được trước thời điểm nhận phòng.');
      ketThuc(d, S.daHoan, LY_DO.ownerCancelled, now);
      const r = kq();
      r.phong = su.anPhong ? 'hidden' : 'available';
      r.tien.push('hoan');
      r.viPham.push('huy_coc');
      r.thongBao.push({ toi: 'sv', loai: 'chu_huy_coc_da_hoan' }, { toi: 'chu', loai: 'bi_ghi_vi_pham' });
      return r;
    }

    case 'SV_YEU_CAU_DOI': {
      if (d.status !== S.dangGiu) return loi(LOI_DA_THAY_DOI);
      if (d.daDungDoi) return loi('Mỗi khoản cọc chỉ được gửi yêu cầu thay đổi 1 lần.');
      if (!(t - now > p(cfg, 'doiPhaiTruocPhut'))) {
        return loi('Chỉ gửi được yêu cầu khi còn hơn 24 giờ tới thời điểm nhận phòng.');
      }
      const moi = su.thoiDiemMoi;
      if (!Number.isFinite(moi)) return loi('Chọn thời điểm nhận phòng mới.');
      if (moi === t) return loi('Thời điểm mới phải khác thời điểm hiện tại.');
      if (moi < now + p(cfg, 'doiCachLucGuiItNhatPhut')) {
        return loi('Thời điểm mới phải cách bây giờ ít nhất 24 giờ.');
      }
      if (d.ngayVaoO && moi < d.ngayVaoO) return loi('Thời điểm mới không được trước ngày có thể vào ở.');
      if (moi > d.tBanDau + p(cfg, 'doiToiDaSauTBanDauPhut')) {
        return loi('Thời điểm mới không được quá 14 ngày sau thời điểm nhận phòng ban đầu.');
      }
      d.daDungDoi = true;
      d.doi = { guiLuc: now, thoiDiemMoi: moi, tCu: t, hanTraLoi: now + p(cfg, 'chuTraLoiDoiPhut'), ketQua: 'cho' };
      const r = kq();
      r.thongBao.push({ toi: 'chu', loai: 'co_yeu_cau_doi' });
      return r;
    }

    case 'CT_DONG_Y_DOI':
    case 'CT_TU_CHOI_DOI': {
      if (d.status !== S.dangGiu || !d.doi || d.doi.ketQua !== 'cho') return loi(LOI_DA_THAY_DOI);
      if (now >= d.doi.hanTraLoi) return loi('Đã quá 24 giờ trả lời yêu cầu.');
      const dongY = su.loai === 'CT_DONG_Y_DOI';
      d.doi = { ...d.doi, ketQua: dongY ? 'dong_y' : 'tu_choi', traLoiLuc: now };
      if (dongY) d.t = d.doi.thoiDiemMoi;
      const r = kq();
      r.thongBao.push({ toi: 'sv', loai: dongY ? 'chu_dong_y_doi' : 'chu_tu_choi_doi' });
      return r;
    }

    case 'HET_HAN_DOI': {
      if (d.status !== S.dangGiu || !d.doi || d.doi.ketQua !== 'cho') return { boQua: true, d };
      d.doi = { ...d.doi, ketQua: 'qua_han' };
      ketThuc(d, S.daHoan, LY_DO.ownerNoReplyReschedule, now);
      const r = kq();
      r.phong = 'available';
      r.tien.push('hoan');
      r.viPham.push('khong_tra_loi_doi');
      r.thongBao.push({ toi: 'sv', loai: 'doi_qua_han_da_hoan' }, { toi: 'chu', loai: 'bi_ghi_vi_pham' });
      return r;
    }

    case 'SV_DA_NHAN': {
      if (d.status !== S.dangGiu) return loi(LOI_DA_THAY_DOI);
      if (now < t) return loi('Chưa tới thời điểm nhận phòng.');
      if (d.khongDen) return loi('Chủ trọ đã báo bạn không đến, bạn chỉ có thể Phản đối.');
      ketThuc(d, S.daChuyen, LY_DO.studentConfirmed, now);
      moDanhGia(d, { nhan: 'da_thue', tinhDiem: true, han: t + p(cfg, 'danhGiaThoiHanPhut') });
      const r = kq();
      r.phong = 'rented';
      r.tien.push('chuyen');
      r.thongBao.push({ toi: 'sv', loai: 'duoc_viet_danh_gia' }, { toi: 'chu', loai: 'sv_da_nhan_phong' });
      return r;
    }

    case 'SV_KHIEU_NAI': {
      if (d.status !== S.dangGiu) return loi(LOI_DA_THAY_DOI);
      if (now < t) return loi('Chỉ khiếu nại được từ thời điểm nhận phòng.');
      if (now > t + p(cfg, 'khieuNaiDenPhut')) return loi('Đã quá 48 giờ kể từ thời điểm nhận phòng.');
      if (d.khongDen) return loi('Chủ trọ đã báo bạn không đến, hãy dùng nút Phản đối.');
      d.status = S.khieuNai;
      d.khieuNai = moKhieuNai('khieu_nai', su, now, cfg);
      const r = kq();
      r.thongBao.push({ toi: 'chu', loai: 'co_khieu_nai' }, { toi: 'admin', loai: 'khieu_nai_moi' });
      return r;
    }

    case 'CT_BAO_KHONG_DEN': {
      if (d.status !== S.dangGiu) return loi(LOI_DA_THAY_DOI);
      if (d.khongDen) return loi('Bạn đã báo sinh viên không đến.');
      if (now < t + p(cfg, 'anHanKhongDenPhut')) {
        return loi('Chỉ báo được từ 3 giờ sau thời điểm nhận phòng (ân hạn cho sinh viên đến trễ).');
      }
      if (now > t + p(cfg, 'baoKhongDenDenPhut')) return loi('Đã quá 48 giờ kể từ thời điểm nhận phòng.');
      d.khongDen = { luc: now, hanPhanDoi: now + p(cfg, 'phanDoiPhut'), phanDoi: false };
      const r = kq();
      r.thongBao.push({ toi: 'sv', loai: 'chu_bao_khong_den' });
      return r;
    }

    case 'SV_PHAN_DOI': {
      if (d.status !== S.dangGiu || !d.khongDen || d.khongDen.phanDoi) return loi(LOI_DA_THAY_DOI);
      if (now > d.khongDen.hanPhanDoi) return loi('Đã quá 12 giờ phản đối.');
      d.khongDen = { ...d.khongDen, phanDoi: true };
      d.status = S.khieuNai;
      d.khieuNai = moKhieuNai('phan_doi', su, now, cfg);
      const r = kq();
      r.thongBao.push({ toi: 'chu', loai: 'sv_phan_doi_khong_den' }, { toi: 'admin', loai: 'khieu_nai_moi' });
      return r;
    }

    case 'HET_HAN_PHAN_DOI': {
      if (d.status !== S.dangGiu || !d.khongDen || d.khongDen.phanDoi) return { boQua: true, d };
      ketThuc(d, S.matCoc, LY_DO.studentNoShow, now);
      const r = kq();
      r.phong = 'available';
      r.tien.push('chuyen');
      r.thongBao.push({ toi: 'sv', loai: 'bo_coc_khong_den' }, { toi: 'chu', loai: 'bo_coc_da_nhan_tien' });
      return r;
    }

    case 'TU_HOAN_TAT': {
      if (d.status !== S.dangGiu || d.khongDen) return { boQua: true, d };
      ketThuc(d, S.daChuyen, LY_DO.autoComplete, now);
      moDanhGia(d, { nhan: null, tinhDiem: false, han: t + p(cfg, 'danhGiaThoiHanPhut') });
      const r = kq();
      r.phong = 'rented';
      r.tien.push('chuyen');
      r.thongBao.push({ toi: 'sv', loai: 'tu_hoan_tat' }, { toi: 'chu', loai: 'tu_hoan_tat_da_nhan_tien' });
      return r;
    }

    case 'CT_TRA_LOI_KHIEU_NAI': {
      if (d.status !== S.khieuNai || !d.khieuNai) return loi(LOI_DA_THAY_DOI);
      if (d.khieuNai.chuTraLoi) return loi('Bạn đã trả lời khiếu nại này.');
      if (now > d.khieuNai.hanChuTraLoi) return loi('Đã quá 24 giờ trả lời khiếu nại.');
      if (!su.noiDung || String(su.noiDung).trim().length < 10) return loi('Nhập nội dung trả lời (ít nhất 10 ký tự).');
      d.khieuNai = { ...d.khieuNai, chuTraLoi: { luc: now, noiDung: String(su.noiDung).trim(), bangChung: su.bangChung || [] } };
      const r = kq();
      r.thongBao.push({ toi: 'sv', loai: 'chu_tra_loi_khieu_nai' });
      return r;
    }

    case 'ADMIN_QUYET': {
      if (d.status !== S.khieuNai || !d.khieuNai) return loi(LOI_DA_THAY_DOI);
      const loaiKN = d.khieuNai.loai;
      d.khieuNai = { ...d.khieuNai, quyet: { ketLuan: su.ketLuan, lyDo: su.lyDo || '', luc: now } };
      const r = kq();
      if (su.ketLuan === 'chu_vi_pham') {
        ketThuc(d, S.daHoan, LY_DO.ownerViolation, now);
        moDanhGia(d, { nhan: 'khieu_nai_chap_nhan', tinhDiem: true, han: now + p(cfg, 'danhGiaKhieuNaiPhut') });
        r.phong = ['available', 'rented', 'hidden'].includes(su.phongSau) ? su.phongSau : 'available';
        r.tien.push('hoan');
        r.viPham.push('khieu_nai_chap_nhan');
        r.thongBao.push({ toi: 'sv', loai: 'ket_qua_khieu_nai' }, { toi: 'sv', loai: 'duoc_viet_danh_gia' }, { toi: 'chu', loai: 'ket_qua_khieu_nai' }, { toi: 'chu', loai: 'bi_ghi_vi_pham' });
      } else if (su.ketLuan === 'sv_da_nhan') {
        ketThuc(d, S.daChuyen, LY_DO.adminReleased, now);
        moDanhGia(d, { nhan: 'da_thue', tinhDiem: true, han: d.t + p(cfg, 'danhGiaThoiHanPhut') });
        r.phong = 'rented';
        r.tien.push('chuyen');
        // Phản đối "không đến" mà admin kết luận đã nhận phòng: không tính khiếu nại sai.
        r.khieuNaiSai = loaiKN === 'khieu_nai';
        r.thongBao.push({ toi: 'sv', loai: 'ket_qua_khieu_nai' }, { toi: 'sv', loai: 'duoc_viet_danh_gia' }, { toi: 'chu', loai: 'ket_qua_khieu_nai' });
      } else if (su.ketLuan === 'sv_khong_den') {
        ketThuc(d, S.matCoc, LY_DO.studentNoShow, now);
        r.phong = 'available';
        r.tien.push('chuyen');
        r.khieuNaiSai = true;
        r.thongBao.push({ toi: 'sv', loai: 'ket_qua_khieu_nai' }, { toi: 'chu', loai: 'ket_qua_khieu_nai' });
      } else {
        return loi('Kết luận không hợp lệ.');
      }
      return r;
    }

    case 'ADMIN_LUA_DAO': {
      if (d.status !== S.dangGiu && d.status !== S.khieuNai) return { boQua: true, d };
      ketThuc(d, S.daHoan, LY_DO.adminFraud, now);
      const r = kq();
      r.phong = 'hidden';
      r.tien.push('hoan');
      r.thongBao.push({ toi: 'sv', loai: 'chu_lua_dao_da_hoan' }, { toi: 'chu', loai: 'ket_luan_lua_dao' });
      return r;
    }

    case 'CO_KHAN': {
      if (d.status !== S.khieuNai || !d.khieuNai || d.khieuNai.coKhan) return { boQua: true, d };
      d.khieuNai = { ...d.khieuNai, coKhan: true };
      const r = kq();
      r.thongBao.push({ toi: 'admin', loai: 'khieu_nai_co_khan' });
      return r;
    }

    case 'NHAC': {
      // Nhắc chỉ để báo tin, không đổi trạng thái tiền / phòng.
      const r = kq();
      for (const toi of su.toi) r.thongBao.push({ toi, loai: su.loaiNhac });
      return r;
    }

    default:
      return loi('Thao tác không hợp lệ.');
  }
}

function moKhieuNai(loai, su, now, cfg) {
  return {
    loai, // 'khieu_nai' (SV khiếu nại chủ) | 'phan_doi' (SV phản đối "không đến")
    lyDo: su.lyDo || '',
    moTa: su.moTa || '',
    bangChung: su.bangChung || [],
    luc: now,
    hanChuTraLoi: now + p(cfg, 'chuTraLoiKhieuNaiPhut'),
    coKhanLuc: now + p(cfg, 'khieuNaiCoKhanPhut'),
    coKhan: false,
    chuTraLoi: null,
    quyet: null,
  };
}

/**
 * Các việc hệ thống phải tự làm (hạn và nhắc) với khoản cọc ở trạng thái hiện tại.
 * Mỗi việc có `khoa` duy nhất (gồm cả T) để chạy lại nhiều lần không bị làm 2 lần.
 */
function viecHeThong(d, cfg) {
  const ds = [];
  const them = (khoa, at, su, conHieuLucDen) => {
    if (d.daXuLy[khoa]) return;
    ds.push({ khoa, at, su, conHieuLucDen });
  };
  const S = TRANG_THAI;
  const t = d.t;

  if (d.status === S.choThanhToan) {
    them('het_han_tt', d.hanThanhToan, { loai: 'HET_HAN_THANH_TOAN' });
  }

  if (d.status === S.dangGiu) {
    // Nhắc trước thời điểm nhận phòng 1 ngày (cả hai bên).
    them(`nhac_t_${t}`, t - p(cfg, 'nhacTruocNhanPhongPhut'), { loai: 'NHAC', loaiNhac: 'nhac_nhan_phong', toi: ['sv', 'chu'] }, t);
    // Nhắc sinh viên hạn cuối gửi yêu cầu thay đổi (T - 36 giờ), khi chưa dùng quyền.
    if (!d.daDungDoi) {
      const hanGui = t - p(cfg, 'doiPhaiTruocPhut');
      them(`nhac_han_doi_${t}`, hanGui - p(cfg, 'doiNhacSinhVienTruocHanPhut'), { loai: 'NHAC', loaiNhac: 'sap_het_han_gui_doi', toi: ['sv'] }, hanGui);
    }
    if (d.doi && d.doi.ketQua === 'cho') {
      for (const con of cfg.chuTraLoiDoiNhacConPhut) {
        them(`nhac_chu_doi_${con}`, d.doi.hanTraLoi - con * PHUT, { loai: 'NHAC', loaiNhac: 'nhac_tra_loi_doi', toi: ['chu'] }, d.doi.hanTraLoi);
      }
      them('het_han_doi', d.doi.hanTraLoi, { loai: 'HET_HAN_DOI' });
    }
    // Tới thời điểm nhận phòng: nhắc sinh viên bấm "Đã nhận phòng" hoặc báo vấn đề.
    them(`toi_t_${t}`, t, { loai: 'NHAC', loaiNhac: 'toi_thoi_diem_nhan_phong', toi: ['sv'] }, t + p(cfg, 'tuHoanTatPhut'));
    if (d.khongDen && !d.khongDen.phanDoi) {
      them('nhac_phan_doi', d.khongDen.hanPhanDoi - p(cfg, 'phanDoiNhacConPhut'), { loai: 'NHAC', loaiNhac: 'nhac_phan_doi', toi: ['sv'] }, d.khongDen.hanPhanDoi);
      them('het_han_phan_doi', d.khongDen.hanPhanDoi, { loai: 'HET_HAN_PHAN_DOI' });
    }
    if (!d.khongDen) {
      them(`nhac_cuoi_${t}`, t + p(cfg, 'nhacCuoiPhut'), { loai: 'NHAC', loaiNhac: 'nhac_cuoi', toi: ['sv', 'chu'] }, t + p(cfg, 'tuHoanTatPhut'));
      them(`tu_hoan_tat_${t}`, t + p(cfg, 'tuHoanTatPhut'), { loai: 'TU_HOAN_TAT' });
    }
  }

  if (d.status === S.khieuNai && d.khieuNai && !d.khieuNai.coKhan) {
    them('co_khan', d.khieuNai.coKhanLuc, { loai: 'CO_KHAN' });
  }
  return ds.sort((a, b) => a.at - b.at);
}

/** Thời điểm sớm nhất hệ thống cần xử lý khoản cọc này (null nếu không còn gì). */
function hanKeTiep(d, cfg) {
  const ds = viecHeThong(d, cfg);
  return ds.length ? ds[0].at : null;
}

/**
 * Xử lý mọi hạn đã tới (theo thứ tự thời gian). Chạy lại nhiều lần không làm 2 lần.
 * `ngoaiCanh.congDaThu` = kết quả hỏi lại cổng thanh toán (cho hạn chờ thanh toán).
 * Trả về { d, tacDong: [kết quả từng bước] }.
 */
function xuLyHan(dGoc, now, cfg, ngoaiCanh = {}) {
  let d = dGoc;
  const tacDong = [];
  for (let vong = 0; vong < 20; vong++) {
    const den = viecHeThong(d, cfg).filter((v) => v.at <= now);
    if (!den.length) break;
    const v = den[0];
    let r;
    // Nhắc đã quá thời điểm còn ý nghĩa (xử lý trễ) thì bỏ qua, không gửi.
    if (v.su.loai === 'NHAC' && v.conHieuLucDen != null && now >= v.conHieuLucDen) {
      r = { boQua: true, d: sao(d) };
    } else {
      const su = v.su.loai === 'HET_HAN_THANH_TOAN' ? { ...v.su, congDaThu: ngoaiCanh.congDaThu } : v.su;
      r = apDung(d, su, now, cfg);
    }
    const dMoi = r.d || sao(d);
    dMoi.daXuLy = { ...dMoi.daXuLy, [v.khoa]: true };
    if (!r.boQua && !r.loi) tacDong.push({ ...r, d: undefined, khoa: v.khoa, laNhac: v.su.loai === 'NHAC' });
    d = dMoi;
  }
  return { d, tacDong };
}

module.exports = {
  TRANG_THAI,
  DANG_CHAY,
  LY_DO,
  LOI_DA_THAY_DOI,
  kiemTraTaoCoc,
  taoKhoanCoc,
  apDung,
  viecHeThong,
  hanKeTiep,
  xuLyHan,
};
