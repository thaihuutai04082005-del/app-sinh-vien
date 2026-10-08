'use strict';

/**
 * Máy trạng thái đơn món (đặc tả mục 3.5a–3.5d, 3.5i, 3.5k, 3.14).
 *
 * Logic THUẦN: không đọc / ghi Firestore, không gọi mạng. Nhận đơn (thời điểm là mili giây),
 * sự kiện và giờ hiện tại; trả về đơn mới và các "tác động" (tiền, vi phạm, thông báo) để lớp
 * Cloud Functions ghi trong cùng một transaction. Nhờ vậy mọi dòng của bảng 3.5i test được.
 *
 * Nguyên tắc: không có bằng chứng giao / nhận thì KHÔNG BAO GIỜ tự coi là đã giao; đơn tiền mặt
 * không có khoản tiền nào qua app (chỉ đơn `cachTra: 'app'` mới có giữ / chuyển / hoàn tiền).
 */

const { PHUT } = require('../config');

const TT = Object.freeze({
  choThanhToan: 'pending_payment',
  hetHan: 'expired',
  choQuanXacNhan: 'placed',
  svHuy: 'cancelled_student',
  quanTuChoi: 'rejected',
  quanKhongXacNhan: 'expired_accept',
  dangChuanBi: 'accepted',
  quanHuy: 'cancelled_restaurant',
  sanSang: 'ready',
  dangGiao: 'delivering',
  choXacNhanNhan: 'delivered',
  hoanTat: 'completed',
  khachKhongNhan: 'not_received',
  khieuNai: 'disputed',
  daHoan: 'refunded',
  hoanMotPhan: 'partially_refunded',
});

/** Đơn còn "đang chạy" (mục 3.14): từ chờ quán xác nhận tới trước hoàn tất. */
const DANG_CHAY = new Set([TT.choThanhToan, TT.choQuanXacNhan, TT.dangChuanBi, TT.sanSang, TT.dangGiao, TT.choXacNhanNhan, TT.khachKhongNhan, TT.khieuNai]);
const DA_NHAN_BOI_QUAN = new Set([TT.dangChuanBi, TT.sanSang, TT.dangGiao, TT.choXacNhanNhan, TT.khachKhongNhan, TT.khieuNai]);

const LY_DO = Object.freeze({
  svHuy: 'student_cancelled',
  quanTuChoi: 'restaurant_rejected',
  quanKhongXacNhan: 'restaurant_no_accept',
  quanHuy: 'restaurant_cancelled',
  quanCham: 'restaurant_late',
  quanNgungNhan: 'restaurant_stopped',
  quanLuaDao: 'restaurant_fraud',
  svDaNhan: 'student_confirmed',
  tuHoanTat: 'auto_complete',
  khongNhan: 'not_received',
  adminHoanToan: 'admin_refund_full',
  adminHoanMotPhan: 'admin_refund_partial',
  adminChuyenQuan: 'admin_released',
  adminDaGiao: 'admin_delivered',
  adminKhongGiao: 'admin_not_delivered',
  quanTraLoiHoan: 'restaurant_agreed_refund',
  heThongTreHan: 'system_late_payment',
});

const LY_DO_KHIEU_NAI = ['khong_nhan_duoc', 'thieu_mon', 'sai_mon', 'mon_hu', 'khac'];
const LOI_DA_THAY_DOI = 'Thông tin đã thay đổi, vui lòng tải lại.';

const p = (cfg, khoa) => cfg[khoa] * PHUT;
const laApp = (d) => d.cachTra === 'app';

function sao(d) {
  return {
    ...d,
    khongNhan: d.khongNhan ? { ...d.khongNhan } : null,
    khieuNai: d.khieuNai ? { ...d.khieuNai } : null,
    danhGia: d.danhGia ? { ...d.danhGia } : null,
    daXuLy: { ...(d.daXuLy || {}) },
  };
}

function ketQuaRong(d) {
  return {
    d,
    tien: [], // 'giu' | 'chuyen' | 'hoan' | 'hoan_mot_phan' | 'het_han' | 'that_bai' — chỉ đơn trả trên app
    soTienHoan: null, // dùng cho 'hoan_mot_phan'
    viPham: [], // vi phạm của sinh viên: 'bom_hang'
    viPhamQuan: [], // vi phạm của quán: 'quan_cham_xac_nhan'
    khieuNaiSai: false, // ghi 1 lần khiếu nại sai của sinh viên
    thongBao: [], // { toi: 'sv' | 'chu' | 'admin', loai }
    laNhac: false, // chỉ nhắc, không đổi trạng thái
  };
}

const loi = (thongDiep) => ({ loi: thongDiep });

function tienApp(d, kq, loaiTien) {
  if (laApp(d)) kq.tien.push(loaiTien);
}

function ketThuc(d, status, lyDo, now) {
  d.status = status;
  d.lyDoKetThuc = lyDo;
  d.ketThucLuc = now;
  if (d.khieuNai && !d.khieuNai.quyetDinh) d.khieuNai = { ...d.khieuNai, daDong: true };
  d.coQuaHan = false;
  d.ruaSoatLuaDao = false;
}

/** Hoàn tất hợp lệ: chuyển tiền cho quán (đơn app), mở đánh giá nếu đơn đã được xác minh. */
function hoanTat(d, kq, now, lyDo, { daXacMinh }) {
  ketThuc(d, TT.hoanTat, lyDo, now);
  d.daXacMinh = !!daXacMinh;
  if (d.daXacMinh) d.danhGia = { nhan: 'dat_mon', tinhDiem: true, moLuc: now };
  tienApp(d, kq, 'chuyen');
}

/** Ghi nhận bằng chứng giao / nhận hợp lệ: mở 24 giờ phản đối / khiếu nại. */
function ghiBangChung(d, now, loai, cfg) {
  d.bangChungLuc = now;
  d.bangChungLoai = loai;
  d.hanKhieuNai = now + p(cfg, 'khieuNaiPhut');
  d.coQuaHan = false;
}

function moKhieuNai(d, now, cfg, { loai, lyDo = null, moTa = '', anh = [] }) {
  d.truocKhiKhieuNai = d.status;
  d.status = TT.khieuNai;
  d.khieuNai = {
    loai, lyDo, moTa, anh, luc: now,
    hanChuTraLoi: now + p(cfg, 'quanTraLoiKhieuNaiPhut'),
    coKhanLuc: now + p(cfg, 'khieuNaiCoKhanPhut'),
    chuTraLoi: null, deNghiHoan: null, quyetDinh: null, soTienHoan: null,
    chuyenAdmin: false, coKhan: false,
  };
}

// ---------------------------------------------------------------- Tạo đơn

/** Giờ nhận món sinh viên chọn có hợp lệ không (mục 3.4 Bước 5b). Trả về lỗi hoặc null. */
function kiemTraGioNhan({ gio, gioHen, now, caDangMoDenLuc, dangTamNghi }, cfg) {
  if (gio === 'asap') return null;
  if (gio !== 'hen') return 'Chọn "Càng sớm càng tốt" hoặc hẹn giờ.';
  if (dangTamNghi) return 'Quán đang tạm nghỉ hoặc tạm ngưng nhận đơn nên không hẹn giờ được.';
  if (!Number.isFinite(gioHen)) return 'Chọn giờ hẹn.';
  if (gioHen < now + p(cfg, 'henGioToiThieuPhut')) return 'Giờ hẹn phải cách bây giờ ít nhất 30 phút.';
  if (gioHen > now + p(cfg, 'henGioToiDaPhut')) return 'Giờ hẹn không quá 2 giờ kể từ bây giờ.';
  if (caDangMoDenLuc == null || gioHen >= caDangMoDenLuc) return 'Giờ hẹn phải trước giờ đóng cửa của ca đang mở.';
  return null;
}

/** Tạo đơn mới: trả trên app → chờ thanh toán; tiền mặt → gửi quán ngay. */
function taoDon({ now, cachNhan, cachTra, gio, gioHen, tong }, cfg) {
  const app = cachTra === 'app';
  return {
    status: app ? TT.choThanhToan : TT.choQuanXacNhan,
    version: 1,
    cachNhan, cachTra, gio, gioHen: gio === 'hen' ? gioHen : null, tong,
    taoLuc: now,
    hanThanhToan: app ? now + p(cfg, 'choThanhToanPhut') : null,
    datLuc: app ? null : now, // lúc đơn tới quán (chờ xác nhận)
    hanQuanNhan: app ? null : now + p(cfg, 'quanXacNhanDonPhut'),
    gioDuKienSanSang: null, moHuyChamLuc: null, batDauGiaoLuc: null, tNhanMonDuKien: null, sanSangLuc: null,
    bangChungLuc: null, bangChungLoai: null, hanKhieuNai: null, hanQuaHan6h: null, coQuaHan: false,
    ruaSoatLuaDao: false, khongNhan: null, khieuNai: null, daXacMinh: false, danhGia: null,
    lyDoKetThuc: null, ketThucLuc: null, daNhanTien: false, daXuLy: {},
  };
}

// ---------------------------------------------------------------- Thanh toán

function nhanThanhToan(d, ghiNhanLuc, now, cfg) {
  const trongHan = ghiNhanLuc <= d.hanThanhToan + cfg.congChenhGiay * 1000;
  if (d.status === TT.choThanhToan || (d.status === TT.hetHan && trongHan && !d.daNhanTien)) {
    const kq = ketQuaRong(d);
    if (trongHan) {
      d.status = TT.choQuanXacNhan;
      d.daNhanTien = true;
      d.datLuc = now;
      d.hanQuanNhan = now + p(cfg, 'quanXacNhanDonPhut');
      kq.tien.push('giu');
      kq.thongBao.push({ toi: 'sv', loai: 'thanh_toan_thanh_cong' }, { toi: 'chu', loai: 'don_moi' });
      return kq;
    }
    // Cổng ghi nhận sau hạn: không nhận, hoàn 100%.
    d.daNhanTien = true;
    ketThuc(d, TT.daHoan, LY_DO.heThongTreHan, now);
    kq.tien.push('hoan');
    kq.thongBao.push({ toi: 'sv', loai: 'tien_den_muon_da_hoan' });
    return kq;
  }
  if (d.status === TT.hetHan && !d.daNhanTien) {
    const kq = ketQuaRong(d);
    d.daNhanTien = true;
    ketThuc(d, TT.daHoan, LY_DO.heThongTreHan, now);
    kq.tien.push('hoan');
    kq.thongBao.push({ toi: 'sv', loai: 'tien_den_muon_da_hoan' });
    return kq;
  }
  return { boQua: true, d }; // cổng báo "đã trả" lần 2: chỉ ghi nhận lần đầu
}

// ---------------------------------------------------------------- Áp một sự kiện

/**
 * Áp một sự kiện lên đơn. `su` = { loai, ...tham số }.
 * Trả về { loi } nếu không hợp lệ, { boQua } nếu không có gì đổi, hoặc kết quả có tác động.
 */
function apDung(dGoc, su, now, cfg) {
  const d = sao(dGoc);
  const kq = () => ketQuaRong(d);
  const S = TT;

  switch (su.loai) {
    case 'THANH_TOAN_OK':
      return nhanThanhToan(d, su.ghiNhanLuc, now, cfg);

    case 'THANH_TOAN_LOI': {
      if (d.status !== S.choThanhToan) return { boQua: true, d };
      d.status = S.hetHan;
      d.ketThucLuc = now;
      const r = kq();
      r.tien.push('that_bai');
      r.thongBao.push({ toi: 'sv', loai: 'thanh_toan_that_bai' });
      return r;
    }

    case 'HET_HAN_THANH_TOAN': {
      if (d.status !== S.choThanhToan) return { boQua: true, d };
      if (su.congDaThu && su.congDaThu.ghiNhanLuc != null) return nhanThanhToan(d, su.congDaThu.ghiNhanLuc, now, cfg);
      d.status = S.hetHan;
      d.ketThucLuc = now;
      const r = kq();
      r.tien.push('het_han');
      r.thongBao.push({ toi: 'sv', loai: 'thanh_toan_het_han' });
      return r;
    }

    // ---- Sinh viên ----
    case 'SV_HUY': {
      if (d.status === S.choQuanXacNhan) {
        ketThuc(d, S.svHuy, LY_DO.svHuy, now);
        const r = kq();
        tienApp(d, r, 'hoan');
        r.thongBao.push({ toi: 'sv', loai: 'sv_huy_da_hoan' }, { toi: 'chu', loai: 'sv_huy_don' });
        return r;
      }
      if (DA_NHAN_BOI_QUAN.has(d.status)) return loi('Quán đã nhận đơn nên bạn không hủy được nữa.');
      return loi('Đơn này không hủy được.');
    }

    case 'SV_HUY_QUAN_CHAM': {
      if (d.status !== S.dangChuanBi) return loi('Đơn này không hủy vì quán chậm được.');
      if (d.moHuyChamLuc == null || now < d.moHuyChamLuc) return loi('Chưa tới thời điểm hủy vì quán chậm.');
      ketThuc(d, S.quanHuy, LY_DO.quanCham, now);
      const r = kq();
      tienApp(d, r, 'hoan');
      r.thongBao.push({ toi: 'sv', loai: 'huy_quan_cham_da_hoan' }, { toi: 'chu', loai: 'sv_huy_quan_cham' });
      return r;
    }

    case 'SV_CHUA_NHAN_MON': {
      let hopLe = false;
      let thongDiep = 'Đơn này chưa báo "Chưa nhận được món" được.';
      if (d.cachNhan === 'den_lay' && d.status === S.sanSang) {
        hopLe = d.tNhanMonDuKien != null && now >= d.tNhanMonDuKien;
        if (!hopLe) thongDiep = 'Bạn có thể báo chưa nhận được món từ thời điểm nhận món dự kiến.';
      } else if (d.cachNhan === 'giao' && d.status === S.dangGiao) {
        hopLe = d.batDauGiaoLuc != null && now >= d.batDauGiaoLuc + p(cfg, 'giaoLauPhut');
        if (!hopLe) thongDiep = 'Đơn đang giao quá 60 phút mới báo chưa nhận được món được.';
      } else if (d.status === S.choXacNhanNhan) {
        hopLe = d.hanKhieuNai != null && now <= d.hanKhieuNai;
        if (!hopLe) thongDiep = 'Đã hết thời hạn báo chưa nhận được món.';
      }
      if (!hopLe) return loi(thongDiep);
      moKhieuNai(d, now, cfg, { loai: 'chua_nhan_mon', lyDo: 'khong_nhan_duoc' });
      const r = kq(); // đơn app: tiền tiếp tục giữ, KHÔNG tự hoàn; đơn tiền mặt: admin xác minh giao nhận
      r.thongBao.push({ toi: 'chu', loai: 'co_khieu_nai' }, { toi: 'admin', loai: 'khieu_nai_moi' });
      return r;
    }

    case 'SV_KHIEU_NAI': {
      if (!laApp(d)) return loi('Đơn tiền mặt không có khiếu nại tiền. Hãy dùng nút "Báo cáo", hoặc "Chưa nhận được món" nếu chưa nhận món.');
      if (d.status !== S.choXacNhanNhan) return loi('Chỉ khiếu nại được khi quán đã ghi nhận giao / lấy món.');
      if (now > d.hanKhieuNai) return loi('Đã hết 24 giờ khiếu nại.');
      if (!LY_DO_KHIEU_NAI.includes(su.lyDo)) return loi('Chọn lý do khiếu nại.');
      const anh = su.anh || [];
      if (su.lyDo !== 'khong_nhan_duoc' && anh.length < 1) return loi('Cần ít nhất 1 ảnh chụp trong app làm bằng chứng.');
      moKhieuNai(d, now, cfg, { loai: 'khieu_nai', lyDo: su.lyDo, moTa: su.moTa || '', anh });
      const r = kq();
      r.thongBao.push({ toi: 'chu', loai: 'co_khieu_nai' }, { toi: 'admin', loai: 'khieu_nai_moi' });
      return r;
    }

    case 'SV_PHAN_DOI': {
      if (d.status !== S.khachKhongNhan || !d.khongNhan) return loi('Đơn này không có báo "Khách không nhận" để phản đối.');
      if (d.khongNhan.phanDoi) return { boQua: true, d };
      if (now > d.khongNhan.hanPhanDoi) return loi('Đã hết 24 giờ phản đối.');
      d.khongNhan = { ...d.khongNhan, phanDoi: true, phanDoiLuc: now, moTaPhanDoi: su.moTa || '' };
      moKhieuNai(d, now, cfg, { loai: 'phan_doi_khong_nhan', lyDo: null, moTa: su.moTa || '', anh: su.anh || [] });
      const r = kq();
      r.thongBao.push({ toi: 'chu', loai: 'sv_phan_doi_khong_nhan' }, { toi: 'admin', loai: 'phan_doi_khong_nhan_moi' });
      return r;
    }

    case 'SV_DA_NHAN': {
      if (![S.sanSang, S.dangGiao, S.choXacNhanNhan, S.khachKhongNhan].includes(d.status)) return loi('Đơn này chưa xác nhận nhận món được.');
      // Bấm "Đã nhận món" là chốt: hoàn tất, không khiếu nại được nữa (kể cả khi quán đã báo "Khách không nhận").
      hoanTat(d, kq(), now, LY_DO.svDaNhan, { daXacMinh: true });
      const r = kq();
      tienApp(d, r, 'chuyen');
      r.thongBao.push({ toi: 'chu', loai: 'sv_da_nhan_mon' }, { toi: 'sv', loai: 'duoc_viet_danh_gia' });
      return r;
    }

    // ---- Quán ----
    case 'QUAN_NHAN': {
      if (d.status !== S.choQuanXacNhan) return loi('Đơn này không còn chờ xác nhận.');
      if (d.hanQuanNhan != null && now > d.hanQuanNhan) return loi('Đơn đã quá hạn xác nhận.');
      const chuanBi = Number.isInteger(su.chuanBiPhut) && su.chuanBiPhut >= 1 && su.chuanBiPhut <= 240 ? su.chuanBiPhut : 15;
      d.status = S.dangChuanBi;
      d.gioDuKienSanSang = d.gio === 'hen' ? d.gioHen : now + chuanBi * PHUT;
      d.moHuyChamLuc = d.gioDuKienSanSang + p(cfg, 'quanChamPhut');
      d.tNhanMonDuKien = d.cachNhan === 'den_lay' ? d.gioDuKienSanSang : null;
      const r = kq();
      r.thongBao.push({ toi: 'sv', loai: 'quan_da_nhan' });
      return r;
    }

    case 'QUAN_TU_CHOI': {
      if (d.status !== S.choQuanXacNhan) return loi('Đơn này không còn chờ xác nhận.');
      ketThuc(d, S.quanTuChoi, LY_DO.quanTuChoi, now);
      const r = kq();
      tienApp(d, r, 'hoan');
      r.thongBao.push({ toi: 'sv', loai: 'quan_tu_choi_da_hoan' });
      return r;
    }

    case 'QUAN_HUY': {
      if (d.status !== S.dangChuanBi) return loi('Chỉ hủy được đơn đang chuẩn bị.');
      ketThuc(d, S.quanHuy, LY_DO.quanHuy, now);
      const r = kq();
      tienApp(d, r, 'hoan');
      r.thongBao.push({ toi: 'sv', loai: 'quan_huy_don_da_hoan' });
      return r;
    }

    case 'QUAN_SAN_SANG': {
      if (d.status !== S.dangChuanBi) return loi('Đơn này chưa ở bước chuẩn bị.');
      if (d.cachNhan !== 'den_lay') return loi('Đơn giao tận nơi dùng nút "Đang giao".');
      d.status = S.sanSang;
      d.sanSangLuc = now;
      d.hanQuaHan6h = now + p(cfg, 'quaHanBangChungPhut');
      const r = kq();
      r.thongBao.push({ toi: 'sv', loai: 'don_san_sang_lay' });
      return r;
    }

    case 'QUAN_DANG_GIAO': {
      if (d.status !== S.dangChuanBi) return loi('Đơn này chưa ở bước chuẩn bị.');
      if (d.cachNhan !== 'giao') return loi('Đơn đến lấy dùng nút "Sẵn sàng".');
      d.status = S.dangGiao;
      d.batDauGiaoLuc = now;
      d.hanQuaHan6h = now + p(cfg, 'quaHanBangChungPhut');
      const r = kq();
      r.thongBao.push({ toi: 'sv', loai: 'don_dang_giao' });
      return r;
    }

    case 'QUAN_NHAP_MA': {
      if (d.status !== S.sanSang || d.cachNhan !== 'den_lay') return loi('Đơn này không nhập mã nhận món được.');
      if (!su.maDung || String(su.maNhap || '').trim() !== String(su.maDung)) return loi('Mã nhận món không đúng.');
      ghiBangChung(d, now, 'ma', cfg);
      const r = kq();
      if (laApp(d)) {
        d.status = S.choXacNhanNhan; // tiền vẫn giữ, mở 24 giờ khiếu nại
        r.thongBao.push({ toi: 'sv', loai: 'quan_ghi_nhan_da_giao' });
      } else {
        hoanTat(d, r, now, LY_DO.svDaNhan, { daXacMinh: true }); // tiền mặt đến lấy: mã đúng = hoàn tất
        r.thongBao.push({ toi: 'sv', loai: 'duoc_viet_danh_gia' });
      }
      return r;
    }

    case 'QUAN_DA_GIAO': {
      if (d.status !== S.dangGiao || d.cachNhan !== 'giao') return loi('Đơn này chưa ở bước đang giao.');
      if (!su.coAnh || !Number.isFinite(su.khoangCachM) || su.khoangCachM > cfg.gpsLechMet) {
        return loi('Cần ảnh giao hàng chụp trong app, đúng tại điểm giao (GPS hợp lệ).');
      }
      ghiBangChung(d, now, 'anh', cfg);
      d.status = S.choXacNhanNhan; // cả đơn app và tiền mặt: chờ 24 giờ, KHÔNG hoàn tất ngay
      d.anhGiao = { khoangCachM: su.khoangCachM, url: su.anhUrl || null };
      const r = kq();
      r.thongBao.push({ toi: 'sv', loai: 'quan_ghi_nhan_da_giao' });
      return r;
    }

    case 'QUAN_KHONG_NHAN': {
      const denLay = d.cachNhan === 'den_lay' && d.status === S.sanSang;
      const giao = d.cachNhan === 'giao' && d.status === S.dangGiao;
      if (!denLay && !giao) return loi('Đơn này không báo "Khách không nhận" được.');
      if (denLay && now < (d.sanSangLuc || 0) + p(cfg, 'khachKhongToiLayPhut')) return loi('Chờ quá 30 phút kể từ lúc "Sẵn sàng" mới báo khách không tới lấy được.');
      if (!su.coAnh || !Number.isFinite(su.khoangCachM) || su.khoangCachM > cfg.gpsLechMet) {
        return loi('Cần ảnh chụp trong app có GPS (đơn giao: tại điểm giao; đơn đến lấy: tại quán).');
      }
      d.status = S.khachKhongNhan;
      d.khongNhan = { luc: now, hanPhanDoi: now + p(cfg, 'khongNhanPhanDoiPhut'), phanDoi: false, khoangCachM: su.khoangCachM, anhUrl: su.anhUrl || null };
      const r = kq(); // đơn app: tiền giữ thêm 24 giờ
      r.thongBao.push({ toi: 'sv', loai: 'chu_bao_khong_nhan' });
      return r;
    }

    case 'QUAN_TRA_LOI_KHIEU_NAI': {
      if (d.status !== S.khieuNai || !d.khieuNai) return loi('Đơn này không có khiếu nại cần trả lời.');
      if (d.khieuNai.chuTraLoi) return loi('Bạn đã trả lời rồi.');
      const nd = String(su.noiDung || '').trim();
      if (nd.length < 2) return loi('Nhập nội dung trả lời.');
      d.khieuNai = { ...d.khieuNai, chuTraLoi: nd, chuTraLoiLuc: now };
      const r = kq();
      const dn = su.deNghiHoan;
      if (dn && laApp(d) && d.khieuNai.loai === 'khieu_nai') {
        if (dn.loai === 'toan_phan') {
          d.khieuNai = { ...d.khieuNai, deNghiHoan: dn, quyetDinh: 'quan_dong_y_hoan', soTienHoan: d.tong };
          ketThuc(d, S.daHoan, LY_DO.quanTraLoiHoan, now);
          r.tien.push('hoan');
        } else if (dn.loai === 'mot_phan' && Number.isInteger(dn.soTien) && dn.soTien > 0 && dn.soTien < d.tong) {
          d.khieuNai = { ...d.khieuNai, deNghiHoan: dn, quyetDinh: 'quan_dong_y_hoan', soTienHoan: dn.soTien };
          ketThuc(d, S.hoanMotPhan, LY_DO.quanTraLoiHoan, now);
          r.tien.push('hoan_mot_phan');
          r.soTienHoan = dn.soTien;
        } else {
          return loi('Số tiền hoàn không hợp lệ.');
        }
        r.thongBao.push({ toi: 'sv', loai: 'ket_qua_khieu_nai' });
      } else {
        r.thongBao.push({ toi: 'sv', loai: 'chu_tra_loi_khieu_nai' });
      }
      return r;
    }

    // ---- Hệ thống: quán ngừng nhận (tạm nghỉ / ẩn / đình chỉ), kết luận lừa đảo ----
    case 'QUAN_NGUNG_NHAN': {
      if (d.status !== S.choQuanXacNhan) return { boQua: true, d };
      ketThuc(d, S.quanHuy, LY_DO.quanNgungNhan, now);
      const r = kq();
      tienApp(d, r, 'hoan');
      r.thongBao.push({ toi: 'sv', loai: 'quan_ngung_nhan_da_hoan' });
      return r;
    }

    case 'LUA_DAO_GAN_CO': {
      if (d.status === S.choQuanXacNhan) {
        ketThuc(d, S.quanHuy, LY_DO.quanLuaDao, now);
        const r = kq();
        tienApp(d, r, 'hoan');
        r.thongBao.push({ toi: 'sv', loai: 'quan_ngung_nhan_da_hoan' });
        return r;
      }
      if ([S.dangChuanBi, S.sanSang, S.dangGiao, S.choXacNhanNhan, S.khachKhongNhan].includes(d.status)) {
        if (d.ruaSoatLuaDao) return { boQua: true, d };
        d.ruaSoatLuaDao = true; // giữ nguyên trạng thái và tiền; admin xét từng đơn
        const r = kq();
        r.thongBao.push({ toi: 'admin', loai: 'don_ra_soat_lua_dao' }, { toi: 'sv', loai: 'don_dang_ra_soat' });
        return r;
      }
      return { boQua: true, d };
    }

    // ---- Admin ----
    case 'ADMIN_QUYET':
    case 'ADMIN_QUA_HAN':
    case 'ADMIN_LUA_DAO':
      return adminQuyet(d, su, now, cfg);

    default:
      return loi('Thao tác không hợp lệ.');
  }
}

/**
 * Admin quyết một đơn đang tranh chấp / quá 6 giờ chưa có bằng chứng / cần rà soát do quán lừa đảo.
 * `quyetDinh`: hoan_toan · hoan_mot_phan · chuyen_cho_quan · da_giao · khong_giao ·
 *              chap_nhan_phan_doi · bac_phan_doi · giu_tranh_chap
 */
function adminQuyet(d, su, now, cfg) {
  const S = TT;
  const choPhep =
    d.status === S.khieuNai ||
    ([S.sanSang, S.dangGiao].includes(d.status) && d.coQuaHan) ||
    (d.ruaSoatLuaDao && DANG_CHAY.has(d.status));
  if (!choPhep) return loi('Đơn này không ở trạng thái cần admin quyết.');
  const qd = su.quyetDinh;
  const r = ketQuaRong(d);
  const app = laApp(d);
  const kn = d.khieuNai;
  const ghiQuyet = (soTienHoan = null) => {
    d.khieuNai = { ...(d.khieuNai || { loai: 'xac_minh', luc: now }), quyetDinh: qd, soTienHoan, lyDoQuyet: su.lyDo || '', quyetLuc: now };
  };
  const khongGiao = () => {
    ghiQuyet(app ? d.tong : null);
    if (app) { ketThuc(d, S.daHoan, LY_DO.adminKhongGiao, now); r.tien.push('hoan'); } else ketThuc(d, S.quanHuy, LY_DO.adminKhongGiao, now);
  };

  switch (qd) {
    case 'hoan_toan':
      if (!app) { khongGiao(); break; }
      ghiQuyet(d.tong);
      ketThuc(d, S.daHoan, LY_DO.adminHoanToan, now);
      r.tien.push('hoan');
      break;
    case 'hoan_mot_phan':
      if (!app) return loi('Đơn tiền mặt không có hoàn tiền.');
      if (!Number.isInteger(su.soTienHoan) || su.soTienHoan <= 0 || su.soTienHoan >= d.tong) return loi('Số tiền hoàn một phần phải nhỏ hơn tổng tiền đơn.');
      ghiQuyet(su.soTienHoan);
      ketThuc(d, S.hoanMotPhan, LY_DO.adminHoanMotPhan, now);
      r.tien.push('hoan_mot_phan');
      r.soTienHoan = su.soTienHoan;
      break;
    case 'chuyen_cho_quan': {
      const daCoBangChung = d.bangChungLuc != null;
      ghiQuyet();
      if (kn && kn.loai === 'khieu_nai') r.khieuNaiSai = true; // khiếu nại bị bác
      hoanTat(d, r, now, LY_DO.adminChuyenQuan, { daXacMinh: daCoBangChung });
      break;
    }
    case 'da_giao':
      ghiQuyet();
      hoanTat(d, r, now, LY_DO.adminDaGiao, { daXacMinh: true });
      break;
    case 'khong_giao':
      khongGiao();
      break;
    case 'chap_nhan_phan_doi':
      if (!kn || kn.loai !== 'phan_doi_khong_nhan') return loi('Đơn này không có phản đối "khách không nhận".');
      khongGiao(); // hoàn cho sinh viên (đơn tiền mặt: hủy), KHÔNG tính bom hàng
      break;
    case 'bac_phan_doi':
      if (!kn || kn.loai !== 'phan_doi_khong_nhan') return loi('Đơn này không có phản đối "khách không nhận".');
      ghiQuyet();
      hoanTat(d, r, now, LY_DO.khongNhan, { daXacMinh: false });
      r.viPham.push('bom_hang'); // lúc này mới tính 1 lần bom hàng
      break;
    case 'giu_tranh_chap':
      if (d.status === S.khieuNai) return loi('Đơn đang tranh chấp rồi.');
      d.ruaSoatLuaDao = false;
      d.coQuaHan = false;
      moKhieuNai(d, now, cfg, { loai: 'xac_minh', lyDo: null, moTa: su.lyDo || 'Chưa đủ căn cứ, giữ tiền xử lý như tranh chấp.' });
      r.thongBao.push({ toi: 'chu', loai: 'co_khieu_nai' });
      return r;
    default:
      return loi('Chọn quyết định của admin.');
  }
  r.thongBao.push({ toi: 'sv', loai: 'ket_qua_khieu_nai' }, { toi: 'chu', loai: 'ket_qua_khieu_nai' });
  if (d.danhGia) r.thongBao.push({ toi: 'sv', loai: 'duoc_viet_danh_gia' });
  return r;
}

// ---------------------------------------------------------------- Hạn tự động

/**
 * Xử lý MỌI hạn đã tới tại `now` (mục 3.18 quy tắc 6). Mỗi hạn chỉ xử lý 1 lần (khóa trong
 * `daXuLy`); chạy lại hay chạy trễ không hoàn tiền / chuyển tiền / ghi vi phạm 2 lần.
 * `congDaThu` = { ghiNhanLuc } nếu cổng đã ghi nhận thanh toán thành công (hỏi lại cổng trước khi hết hạn).
 */
function xuLyHan(dGoc, now, cfg, { congDaThu = null } = {}) {
  let d = sao(dGoc);
  const tacDong = [];
  const S = TT;
  const dua = (kq, khoa, laNhac = false) => {
    d = kq.d;
    tacDong.push({ ...kq, d: undefined, khoa, laNhac: laNhac || kq.laNhac, status: d.status });
  };

  for (let vong = 0; vong < 10; vong++) {
    let doi = false;

    if (d.status === S.choThanhToan && now >= d.hanThanhToan) {
      const r = apDung(d, { loai: 'HET_HAN_THANH_TOAN', congDaThu }, now, cfg);
      if (!r.loi && !r.boQua) { dua(r, 'HET_HAN_THANH_TOAN'); doi = true; }
    } else if (d.status === S.choQuanXacNhan) {
      if (now > d.hanQuanNhan) {
        ketThuc(d, S.quanKhongXacNhan, LY_DO.quanKhongXacNhan, now);
        const r = ketQuaRong(d);
        tienApp(d, r, 'hoan');
        r.viPhamQuan.push('quan_cham_xac_nhan');
        r.thongBao.push({ toi: 'sv', loai: 'quan_khong_xac_nhan_da_hoan' }, { toi: 'chu', loai: 'don_het_han_xac_nhan' });
        dua(r, 'HET_HAN_XAC_NHAN');
        doi = true;
      } else if (d.datLuc != null && now >= d.datLuc + p(cfg, 'nhacChuongLaiPhut') && !d.daXuLy.nhacDonMoi) {
        d.daXuLy.nhacDonMoi = true;
        const r = ketQuaRong(d);
        r.laNhac = true;
        r.thongBao.push({ toi: 'chu', loai: 'nhac_don_moi' });
        dua(r, 'NHAC_DON_MOI', true);
      }
    } else if (d.status === S.choXacNhanNhan) {
      if (now >= d.hanKhieuNai) {
        const r = ketQuaRong(d);
        hoanTat(d, r, now, LY_DO.tuHoanTat, { daXacMinh: d.bangChungLuc != null });
        r.thongBao.push({ toi: 'sv', loai: 'don_tu_hoan_tat' }, { toi: 'chu', loai: laApp(d) ? 'don_tu_hoan_tat_da_nhan_tien' : 'don_tu_hoan_tat' });
        if (d.danhGia) r.thongBao.push({ toi: 'sv', loai: 'duoc_viet_danh_gia' });
        dua(r, 'TU_HOAN_TAT');
        doi = true;
      } else {
        const sau1h = d.bangChungLuc + p(cfg, 'nhacNhanMonSauPhut');
        const con1h = d.hanKhieuNai - p(cfg, 'nhacNhanMonConPhut');
        for (const [khoa, moc] of [[`nhacSau_${d.bangChungLuc}`, sau1h], [`nhacCon_${d.bangChungLuc}`, con1h]]) {
          if (now >= moc && !d.daXuLy[khoa]) {
            d.daXuLy[khoa] = true;
            const r = ketQuaRong(d);
            r.laNhac = true;
            r.thongBao.push({ toi: 'sv', loai: 'nhac_xac_nhan_nhan_mon' });
            dua(r, `NHAC_${khoa}`, true);
          }
        }
      }
    } else if (d.status === S.khachKhongNhan && d.khongNhan && !d.khongNhan.phanDoi && now >= d.khongNhan.hanPhanDoi) {
      const r = ketQuaRong(d);
      hoanTat(d, r, now, LY_DO.khongNhan, { daXacMinh: false });
      r.viPham.push('bom_hang'); // hết 24 giờ không phản đối: lúc này mới tính 1 lần bom hàng
      r.thongBao.push({ toi: 'sv', loai: 'bi_tinh_bom_hang' }, { toi: 'chu', loai: laApp(d) ? 'don_tu_hoan_tat_da_nhan_tien' : 'don_tu_hoan_tat' });
      dua(r, 'HET_HAN_PHAN_DOI');
      doi = true;
    } else if ([S.sanSang, S.dangGiao].includes(d.status) && d.hanQuaHan6h != null && now >= d.hanQuaHan6h && !d.coQuaHan) {
      d.coQuaHan = true; // KHÔNG tự hoàn, KHÔNG tự giải ngân: chuyển admin
      const r = ketQuaRong(d);
      r.thongBao.push({ toi: 'admin', loai: 'don_qua_han_6h' }, { toi: 'sv', loai: 'don_qua_han_chuyen_admin' }, { toi: 'chu', loai: 'don_qua_han_chuyen_admin' });
      dua(r, 'QUA_HAN_6H');
      doi = true;
    } else if (d.status === S.khieuNai && d.khieuNai) {
      if (!d.khieuNai.chuyenAdmin && !d.khieuNai.chuTraLoi && now >= d.khieuNai.hanChuTraLoi) {
        d.khieuNai = { ...d.khieuNai, chuyenAdmin: true };
        const r = ketQuaRong(d);
        r.thongBao.push({ toi: 'admin', loai: 'khieu_nai_moi' });
        dua(r, 'KHIEU_NAI_CHUYEN_ADMIN');
        doi = true;
      }
      if (d.status === S.khieuNai && !d.khieuNai.coKhan && now >= d.khieuNai.coKhanLuc) {
        d.khieuNai = { ...d.khieuNai, coKhan: true }; // treo quá 72 giờ → cờ khẩn
        const r = ketQuaRong(d);
        r.thongBao.push({ toi: 'admin', loai: 'khieu_nai_co_khan' });
        dua(r, 'KHIEU_NAI_CO_KHAN');
        doi = true;
      }
    }
    if (!doi) break;
  }
  return { d, tacDong };
}

/** Thời điểm sớm nhất cần xử lý lại (để tìm đơn tới hạn). null nếu không còn hạn. */
function hanKeTiep(d) {
  const S = TT;
  const ds = [];
  const them = (x) => { if (x != null) ds.push(x); };
  if (d.status === S.choThanhToan) them(d.hanThanhToan);
  if (d.status === S.choQuanXacNhan) {
    them(d.hanQuanNhan + 1);
    if (!(d.daXuLy || {}).nhacDonMoi && d.datLuc != null) them(d.datLuc + 2 * PHUT);
  }
  if (d.status === S.choXacNhanNhan) {
    them(d.hanKhieuNai);
    const dx = d.daXuLy || {};
    if (!dx[`nhacSau_${d.bangChungLuc}`]) them(d.bangChungLuc + 60 * PHUT);
    if (!dx[`nhacCon_${d.bangChungLuc}`]) them(d.hanKhieuNai - 60 * PHUT);
  }
  if (d.status === S.khachKhongNhan && d.khongNhan && !d.khongNhan.phanDoi) them(d.khongNhan.hanPhanDoi);
  if ([S.sanSang, S.dangGiao].includes(d.status) && !d.coQuaHan) them(d.hanQuaHan6h);
  if (d.status === S.khieuNai && d.khieuNai) {
    if (!d.khieuNai.chuyenAdmin && !d.khieuNai.chuTraLoi) them(d.khieuNai.hanChuTraLoi);
    if (!d.khieuNai.coKhan) them(d.khieuNai.coKhanLuc);
  }
  return ds.length ? Math.min(...ds) : null;
}

module.exports = {
  TT, DANG_CHAY, DA_NHAN_BOI_QUAN, LY_DO, LY_DO_KHIEU_NAI, LOI_DA_THAY_DOI,
  kiemTraGioNhan, taoDon, apDung, xuLyHan, hanKeTiep,
};
