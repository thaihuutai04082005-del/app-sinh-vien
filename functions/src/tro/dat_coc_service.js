'use strict';

/**
 * Lớp Firestore cho khoản cọc: đọc đủ dữ liệu trong 1 transaction, chạy logic thuần
 * (logic/dat_coc.js), rồi ghi mọi tác động (khoản cọc, phòng, tiền, ví, vi phạm, thông báo).
 * Mọi thao tác đều tự xử lý hạn đã tới trước (mục 2.18 quy tắc 6).
 */

const { db, FieldValue, Timestamp, ms, ts } = require('../chung/firebase');
const { loiNguoiDung, khongTimThay, khongCoQuyen } = require('../chung/loi');
const { docAdmin } = require('../chung/tai_khoan');
const { layCauHinh } = require('./cau_hinh');
const L = require('./logic/dat_coc');
const V = require('./logic/vi_pham');
const { ghiThongBao, dayThongBao } = require('./thong_bao');
const { PHUT } = require('./config');

const COL = Object.freeze({
  datCoc: 'tro_dat_coc',
  phong: 'phong_tro',
  nhaTro: 'nha_tro',
  khoanTien: 'tro_khoan_tien',
  cong: 'tro_cong_gia_lap',
  vi: 'tro_vi',
  viPham: 'tro_vi_pham',
  huyMienPhi: 'tro_huy_mien_phi',
  khieuNaiSai: 'tro_khieu_nai_sai',
  khoa: 'tro_khoa',
  hoSo: 'tro_ho_so',
});

// Các khóa thời gian của khoản cọc (lưu Timestamp trong Firestore, mili giây trong logic).
const KHOA_THOI_GIAN = new Set([
  'taoLuc', 'hanThanhToan', 'heldAt', 'hanHuyMienPhi', 'tBanDau', 't', 'ngayVaoO', 'ketThucLuc',
  'guiLuc', 'thoiDiemMoi', 'tCu', 'hanTraLoi', 'traLoiLuc', 'luc', 'hanPhanDoi', 'hanChuTraLoi',
  'coKhanLuc', 'han', 'hanKeTiep',
]);

function doiThoiGian(v, ham) {
  if (Array.isArray(v)) return v.map((x) => doiThoiGian(x, ham));
  if (v && typeof v === 'object' && !(v instanceof Timestamp)) {
    const kq = {};
    for (const [k, x] of Object.entries(v)) {
      kq[k] = KHOA_THOI_GIAN.has(k) && (typeof x === 'number' || x instanceof Timestamp || x == null)
        ? ham(x)
        : doiThoiGian(x, ham);
    }
    return kq;
  }
  return v;
}

const LOGIC_KHOA = [
  'status', 'version', 'soTien', 'coQuyenHuyMienPhi', 'taoLuc', 'hanThanhToan', 'heldAt',
  'hanHuyMienPhi', 'tBanDau', 't', 'ngayVaoO', 'daDungDoi', 'doi', 'khongDen', 'khieuNai',
  'danhGia', 'daXuLy', 'lyDoKetThuc', 'ketThucLuc', 'daNhanTien',
];

function tuDoc(data) {
  const d = {};
  for (const k of LOGIC_KHOA) d[k] = data[k] === undefined ? null : data[k];
  d.daXuLy = d.daXuLy || {};
  d.daDungDoi = !!d.daDungDoi;
  return doiThoiGian(d, ms);
}

function raDoc(d, cfg) {
  const kq = {};
  for (const k of LOGIC_KHOA) kq[k] = d[k] === undefined ? null : d[k];
  kq.hanKeTiep = L.hanKeTiep(d, cfg);
  return doiThoiGian(kq, ts);
}

/** Vai trò được làm từng thao tác. */
const VAI_TRO = Object.freeze({
  SV_HUY: 'sv', SV_KHONG_THUE: 'sv', SV_YEU_CAU_DOI: 'sv', SV_DA_NHAN: 'sv', SV_KHIEU_NAI: 'sv', SV_PHAN_DOI: 'sv',
  CT_HUY_COC: 'chu', CT_DONG_Y_DOI: 'chu', CT_TU_CHOI_DOI: 'chu', CT_BAO_KHONG_DEN: 'chu', CT_TRA_LOI_KHIEU_NAI: 'chu',
  ADMIN_QUYET: 'admin', ADMIN_LUA_DAO: 'admin',
});

const TIEN_SANG = Object.freeze({ giu: 'dang_giu', chuyen: 'da_chuyen', hoan: 'da_hoan', het_han: 'het_han', that_bai: 'that_bai' });

/**
 * Chạy một sự kiện (hoặc chỉ xử lý hạn nếu `su` null) trên khoản cọc trong transaction.
 * `nguoiLam` = { uid, vaiTro } (vaiTro: 'sv' | 'chu' | 'admin' | 'he_thong').
 * `versionDaThay` = version khoản cọc người dùng đã thấy khi bấm (chống thao tác trên dữ liệu cũ).
 */
async function chayTrenKhoanCoc(datCocId, { su = null, nguoiLam = { vaiTro: 'he_thong' }, versionDaThay = null, now = Date.now() } = {}) {
  const cfg = await layCauHinh();
  const refCoc = db.collection(COL.datCoc).doc(datCocId);
  const thongBaoIds = [];

  const ketQua = await db.runTransaction(async (tx) => {
    thongBaoIds.length = 0;
    const snap = await tx.get(refCoc);
    if (!snap.exists) throw khongTimThay('Khoản cọc');
    const goc = snap.data();

    if (su) {
      const vaiTro = VAI_TRO[su.loai];
      if (vaiTro === 'sv' && nguoiLam.uid !== goc.sinhVienId) throw khongCoQuyen();
      if (vaiTro === 'chu' && nguoiLam.uid !== goc.chuTroId) throw khongCoQuyen();
      if (vaiTro === 'admin' && nguoiLam.vaiTro !== 'admin') throw khongCoQuyen();
      if (!vaiTro && nguoiLam.vaiTro !== 'he_thong') throw khongCoQuyen();
      if (versionDaThay != null && versionDaThay !== goc.version) throw loiNguoiDung(L.LOI_DA_THAY_DOI, 'aborted');
    }

    // ---- Đọc trước mọi thứ có thể cần (transaction: đọc hết rồi mới ghi) ----
    const refPhong = db.collection(COL.phong).doc(goc.phongId);
    const refTien = db.collection(COL.khoanTien).doc(datCocId);
    const refCong = db.collection(COL.cong).doc(datCocId);
    const refNha = db.collection(COL.nhaTro).doc(goc.nhaTroId);
    const [phongSnap, tienSnap, congSnap, nhaSnap, hoSoSv, hoSoChu, xtChu] = await Promise.all([
      tx.get(refPhong), tx.get(refTien), tx.get(refCong), tx.get(refNha),
      tx.get(db.collection(COL.hoSo).doc(goc.sinhVienId)),
      tx.get(db.collection(COL.hoSo).doc(goc.chuTroId)),
      tx.get(db.collection('xac_thuc').doc(goc.chuTroId)),
    ]);
    const sdtChu = xtChu.exists ? xtChu.get('sdt') : null;
    const [viPhamChu, khieuNaiSaiSv, admins] = await Promise.all([
      sdtChu ? tx.get(db.collection(COL.viPham).where('sdt', '==', sdtChu).where('vaiTro', '==', 'chu')) : null,
      tx.get(db.collection(COL.khieuNaiSai).where('sdt', '==', goc.sinhVienSdt)),
      tx.get(db.collection('admins').where('tro', '==', true)),
    ]);

    const cong = congSnap.exists ? congSnap.data() : null;
    const congDaThu = cong && cong.trangThai === 'thanh_cong' ? { ghiNhanLuc: ms(cong.ghiNhanLuc) } : null;

    // ---- Chạy logic: xử lý hạn trước, rồi sự kiện ----
    let d = tuDoc(goc);
    const hanDaToi = L.xuLyHan(d, now, cfg, { congDaThu });
    d = hanDaToi.d;
    const cacTacDong = hanDaToi.tacDong.map((t) => ({ ...t, khoaTB: t.khoa }));
    let loiSuKien = null;
    if (su) {
      const phong = phongSnap.exists ? phongSnap.data() : {};
      const khoaKhac = phong.khoaThanhToan && phong.khoaThanhToan.datCocId !== datCocId && ms(phong.khoaThanhToan.den) > now;
      const phongConTrong = phong.trangThai === 'available' && !phong.dangGiu && !khoaKhac;
      const r = L.apDung(d, { ...su, phongConTrong }, now, cfg);
      if (r.loi) {
        loiSuKien = r.loi;
      } else if (!r.boQua) {
        d = r.d;
        cacTacDong.push({ ...r, d: undefined, khoaTB: `${su.loai}_${(goc.version || 0) + 1}` });
      } else {
        d = r.d;
      }
    }

    // Chỉ tăng version khi trạng thái thật sự đổi (nhắc không tính).
    d.version = cacTacDong.some((t) => !t.laNhac) ? (goc.version || 0) + 1 : goc.version || 1;

    // ---- Ghi ----
    const capNhat = { ...raDoc(d, cfg), capNhatLuc: Timestamp.fromMillis(now) };
    const lichSuMoi = cacTacDong.filter((t) => !t.laNhac).map((t) => ({
      luc: Timestamp.fromMillis(now),
      su: t.khoaTB,
      nguoiLam: su && t.khoaTB.startsWith(su.loai) ? nguoiLam.vaiTro : 'he_thong',
    }));
    if (lichSuMoi.length) capNhat.lichSu = FieldValue.arrayUnion(...lichSuMoi);

    const caiDat = {
      sv: (hoSoSv.exists && hoSoSv.get('caiDatThongBao')) || {},
      chu: (hoSoChu.exists && hoSoChu.get('caiDatThongBao')) || {},
    };
    const bien = { phong: `${goc.tenPhong || 'phòng'} (${goc.tenNhaTro || 'nhà trọ'})` };
    const moTrang = { loai: 'dat_coc', id: datCocId };
    const phongCapNhat = {};
    const tien = tienSnap.exists ? tienSnap.data() : null;
    let trangThaiTien = tien ? tien.trangThai : null;
    const viCapNhat = { dangGiu: 0, daNhan: 0 };
    const lichSuTien = [];

    for (const t of cacTacDong) {
      if (t.phong) {
        // Admin đã ẩn phòng khi còn cọc: cọc kết thúc thì phòng ẩn luôn thay vì mở lại.
        const anSau = phongSnap.exists && phongSnap.get('anSauKhiXong');
        phongCapNhat.trangThai = t.phong === 'available' && anSau ? 'hidden' : t.phong;
        if (t.phong === 'reserved') phongCapNhat.dangGiu = { loai: 'app', datCocId };
        else phongCapNhat.dangGiu = null;
      }
      if (t.goKhoa) phongCapNhat.khoaThanhToan = null;
      if (t.chupThongTin) capNhat.chupThongTin = chupThongTin(phongSnap, nhaSnap);
      for (const loaiTien of t.tien) {
        const truoc = trangThaiTien;
        const sau = TIEN_SANG[loaiTien];
        if (loaiTien === 'giu') viCapNhat.dangGiu += goc.soTien;
        if (loaiTien === 'chuyen' && truoc === 'dang_giu') { viCapNhat.dangGiu -= goc.soTien; viCapNhat.daNhan += goc.soTien; }
        if (loaiTien === 'hoan' && truoc === 'dang_giu') viCapNhat.dangGiu -= goc.soTien;
        trangThaiTien = sau;
        lichSuTien.push({ trangThai: sau, luc: Timestamp.fromMillis(now) });
      }
      for (const loaiViPham of t.viPham) {
        tx.set(db.collection(COL.viPham).doc(`${datCocId}_${loaiViPham}`), {
          uid: goc.chuTroId, sdt: sdtChu, vaiTro: 'chu', loai: loaiViPham,
          nguon: { loai: 'dat_coc', id: datCocId }, luc: Timestamp.fromMillis(now), daGo: false,
        });
        const ds = (viPhamChu ? viPhamChu.docs.map((x) => ({ luc: ms(x.get('luc')), daGo: x.get('daGo') })) : [])
          .concat([{ luc: now }]);
        const han = V.hanKhoaMoi(ds, now, { soLan: cfg.viPhamChuSoLan, cuaSoPhut: cfg.viPhamChuCuaSoPhut, khoaPhut: cfg.khoaDangTinPhut });
        if (han && sdtChu) {
          tx.set(db.collection(COL.khoa).doc(sdtChu), { khoaDangTinDen: Timestamp.fromMillis(han), uidChu: goc.chuTroId }, { merge: true });
        }
      }
      if (t.khieuNaiSai) {
        tx.set(db.collection(COL.khieuNaiSai).doc(datCocId), {
          uid: goc.sinhVienId, sdt: goc.sinhVienSdt, luc: Timestamp.fromMillis(now), daGo: false, datCocId,
        });
        const ds = khieuNaiSaiSv.docs.map((x) => ({ luc: ms(x.get('luc')), daGo: x.get('daGo') })).concat([{ luc: now }]);
        const han = V.hanKhoaMoi(ds, now, { soLan: cfg.khieuNaiSaiSoLan, cuaSoPhut: cfg.khieuNaiSaiCuaSoPhut, khoaPhut: cfg.khoaCocPhut });
        if (han) tx.set(db.collection(COL.khoa).doc(goc.sinhVienSdt), { khoaCocDen: Timestamp.fromMillis(han), uidSv: goc.sinhVienId }, { merge: true });
      }
      if (t.ghiHuyMienPhi) {
        tx.set(db.collection(COL.huyMienPhi).doc(datCocId), { sdt: goc.sinhVienSdt, uid: goc.sinhVienId, luc: Timestamp.fromMillis(now) });
      }
      for (const tb of t.thongBao) {
        const nguoiNhan = tb.toi === 'sv' ? [goc.sinhVienId] : tb.toi === 'chu' ? [goc.chuTroId] : admins.docs.map((a) => a.id);
        for (const uidNhan of nguoiNhan) {
          const id = ghiThongBao(tx, {
            khoa: `${datCocId}_${t.khoaTB}_${tb.loai}`,
            nguoiNhan: uidNhan,
            loai: tb.loai,
            bien,
            moTrang,
            caiDat: tb.toi === 'admin' ? {} : caiDat[tb.toi],
          });
          if (id) thongBaoIds.push(id);
        }
      }
    }

    tx.update(refCoc, capNhat);
    if (Object.keys(phongCapNhat).length) {
      tx.update(refPhong, { ...phongCapNhat, capNhatLuc: Timestamp.fromMillis(now) });
    }
    if (tien && lichSuTien.length) {
      tx.update(refTien, { trangThai: trangThaiTien, lichSu: FieldValue.arrayUnion(...lichSuTien) });
    }
    if (viCapNhat.dangGiu || viCapNhat.daNhan) {
      tx.set(db.collection(COL.vi).doc(goc.chuTroId), {
        dangGiu: FieldValue.increment(viCapNhat.dangGiu),
        daNhan: FieldValue.increment(viCapNhat.daNhan),
      }, { merge: true });
    }
    return {
      loi: loiSuKien, status: d.status, version: d.version, nhaTroId: goc.nhaTroId, chuTroId: goc.chuTroId,
      doiPhong: !!phongCapNhat.trangThai, ketThuc: !L.DANG_CHAY.has(d.status) && L.DANG_CHAY.has(goc.status),
    };
  });

  await dayThongBao(thongBaoIds);
  if (ketQua.doiPhong) {
    const { capNhatSoLieuNhaTro } = require('./nha_tro_service');
    await capNhatSoLieuNhaTro(ketQua.nhaTroId);
  }
  if (ketQua.ketThuc) {
    const { capNhatChiSoChu } = require('./admin_service');
    await capNhatChiSoChu(ketQua.chuTroId).catch((e) => console.warn('Không cập nhật chỉ số chủ', e.message));
  }
  if (ketQua.loi) throw loiNguoiDung(ketQua.loi);
  return ketQua;
}

/** Bản chụp thông tin phòng lúc cọc (mục 2.4 Bước 3, 2.5k): không đổi khi chủ sửa tin. */
function chupThongTin(phongSnap, nhaSnap) {
  const p = phongSnap.exists ? phongSnap.data() : {};
  const n = nhaSnap.exists ? nhaSnap.data() : {};
  return {
    luc: Timestamp.now(),
    phong: {
      ten: p.ten || '', khu: p.khu || '', tang: p.tang ?? null, coGac: p.coGac ?? null,
      dienTich: p.dienTich ?? null, dienTichGac: p.dienTichGac ?? null, soNguoiToiDa: p.soNguoiToiDa ?? null,
      soPhongNgu: p.soPhongNgu ?? null, soWc: p.soWc ?? null, coBep: p.coBep ?? null,
      tienIch: p.tienIch || [], giaThue: p.giaThue ?? null, tienCoc: p.tienCoc ?? null,
      tienDien: p.tienDien || null, tienNuoc: p.tienNuoc || null, phiKhac: p.phiKhac || [],
      hopDongToiThieu: p.hopDongToiThieu ?? null, moTa: p.moTa || '', anh: p.anh || [], video: p.video || [],
    },
    nhaTro: {
      ten: n.ten || '', loaiHinh: n.loaiHinh || '', diaChi: n.diaChi || '',
      tienIchChung: n.tienIchChung || [], noiQuy: n.noiQuy || null,
    },
  };
}

/**
 * Sinh viên bấm "Đặt cọc giữ phòng": khóa thanh toán phòng cho riêng mình 15 phút
 * rồi tạo khoản cọc `pending_payment`, khoản tiền và phiên cổng thanh toán giả lập.
 * Người bấm sau khi phòng đang khóa: báo "Đang có người thanh toán", KHÔNG tạo giao dịch.
 */
async function taoCoc({ uid, sdt }, { phongId, t, dongYChinhSach, dongYDieuKhoan }) {
  if (!dongYChinhSach || !dongYDieuKhoan) {
    throw loiNguoiDung('Bạn cần đồng ý chính sách cọc và điều khoản nhận phòng.');
  }
  const cfg = await layCauHinh();
  const now = Date.now();
  const refPhong = db.collection(COL.phong).doc(phongId);

  return db.runTransaction(async (tx) => {
    const [phongSnap, khoaSv, cuDangCho, lanHuy] = await Promise.all([
      tx.get(refPhong),
      tx.get(db.collection(COL.khoa).doc(sdt)),
      tx.get(db.collection(COL.datCoc).where('phongId', '==', phongId).where('sinhVienId', '==', uid).where('status', '==', 'pending_payment')),
      tx.get(db.collection(COL.huyMienPhi).where('sdt', '==', sdt)),
    ]);
    if (!phongSnap.exists) throw khongTimThay('Phòng');
    const phong = phongSnap.data();

    // Bấm 2 lần: trả lại đúng giao dịch đang chờ, không tạo thêm.
    const dangCho = cuDangCho.docs.find((x) => ms(x.get('hanThanhToan')) > now);
    if (dangCho) return { datCocId: dangCho.id, daCo: true };

    if (phong.chuTroId === uid) throw loiNguoiDung('Bạn không thể đặt cọc phòng của chính mình.');
    if (khoaSv.exists && ms(khoaSv.get('khoaCocDen')) > now) {
      throw loiNguoiDung('Bạn đang bị khóa đặt cọc trên app tới ' + new Date(ms(khoaSv.get('khoaCocDen'))).toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' }) + '.');
    }
    const nhaSnap = await tx.get(db.collection(COL.nhaTro).doc(phong.nhaTroId));
    const nha = nhaSnap.exists ? nhaSnap.data() : {};
    const xtChu = await tx.get(db.collection('xac_thuc').doc(phong.chuTroId));
    const sdtChu = xtChu.exists ? xtChu.get('sdt') : null;
    const khoaChu = sdtChu ? await tx.get(db.collection(COL.khoa).doc(sdtChu)) : null;
    if (khoaChu && khoaChu.exists && ms(khoaChu.get('khoaDangTinDen')) > now) {
      throw loiNguoiDung('Chủ trọ đang tạm bị khóa nhận cọc. Bạn vẫn có thể nhắn tin cho chủ trọ.');
    }
    if (nha.trangThai !== 'active' || phong.daXoa) throw loiNguoiDung('Nhà trọ này hiện không nhận cọc.');
    const khoa = phong.khoaThanhToan;
    if (khoa && ms(khoa.den) > now) throw loiNguoiDung('Đang có người thanh toán, thử lại sau ít phút.', 'aborted');
    if (phong.trangThai !== 'available' || phong.dangGiu) throw loiNguoiDung('Phòng không còn trống.', 'aborted');

    const loi = L.kiemTraTaoCoc({ now, t, ngayVaoO: ms(phong.ngayVaoO), soTien: phong.tienCoc, giaThue: phong.giaThue }, cfg);
    if (loi) throw loiNguoiDung(loi, 'invalid-argument');

    const coQuyen = V.conQuyenHuyMienPhi(lanHuy.docs.map((x) => ({ luc: ms(x.get('luc')) })), now, cfg);
    const d = L.taoKhoanCoc({ now, t, ngayVaoO: ms(phong.ngayVaoO), soTien: phong.tienCoc, coQuyenHuyMienPhi: coQuyen }, cfg);
    const refCoc = db.collection(COL.datCoc).doc();
    tx.set(refCoc, {
      ...raDoc(d, cfg),
      phongId, nhaTroId: phong.nhaTroId, chuTroId: phong.chuTroId,
      sinhVienId: uid, sinhVienSdt: sdt,
      tenPhong: phong.ten || '', tenNhaTro: nha.ten || '', anhBia: phong.anhBia || nha.anhBia || '',
      dongYChinhSachLuc: Timestamp.fromMillis(now), dongYDieuKhoanLuc: Timestamp.fromMillis(now),
      lichSu: [{ luc: Timestamp.fromMillis(now), su: 'TAO', nguoiLam: 'sv' }],
      chupThongTin: null,
    });
    tx.set(db.collection(COL.khoanTien).doc(refCoc.id), {
      nguoiTra: uid, nguoiNhan: phong.chuTroId, datCocId: refCoc.id, cong: 'gia_lap',
      maGiaoDichCong: null, maChongTrung: refCoc.id, soTienVnd: phong.tienCoc, trangThai: 'cho_tra',
      soDaHoan: 0, hetHanLuc: Timestamp.fromMillis(d.hanThanhToan),
      lichSu: [{ trangThai: 'cho_tra', luc: Timestamp.fromMillis(now) }],
    });
    tx.set(db.collection(COL.cong).doc(refCoc.id), {
      datCocId: refCoc.id, nguoiTra: uid, soTien: phong.tienCoc, trangThai: 'cho', taoLuc: Timestamp.fromMillis(now),
    });
    tx.update(refPhong, { khoaThanhToan: { datCocId: refCoc.id, uid, den: Timestamp.fromMillis(d.hanThanhToan) } });
    return { datCocId: refCoc.id, daCo: false, coQuyenHuyMienPhi: coQuyen };
  });
}

/** Sinh viên còn bao nhiêu lần hủy miễn phí (hiện ở màn hình đặt cọc). */
async function soLanHuyMienPhiConLai(sdt) {
  const cfg = await layCauHinh();
  const now = Date.now();
  const snap = await db.collection(COL.huyMienPhi).where('sdt', '==', sdt).get();
  const daDung = V.demTrongCuaSo(snap.docs.map((x) => ({ luc: ms(x.get('luc')) })), now, cfg.huyMienPhiCuaSoPhut);
  return Math.max(0, cfg.huyMienPhiSoLan - daDung);
}

/** Admin kết luận chủ trọ lừa đảo: hoàn mọi khoản cọc app còn giữ của chủ (mục 2.14). */
async function hoanTatCaCuaChu(chuTroId, adminUid) {
  const snap = await db.collection(COL.datCoc).where('chuTroId', '==', chuTroId).where('status', 'in', ['held', 'disputed']).get();
  for (const doc of snap.docs) {
    await chayTrenKhoanCoc(doc.id, { su: { loai: 'ADMIN_LUA_DAO' }, nguoiLam: { uid: adminUid, vaiTro: 'admin' } });
  }
  return snap.size;
}

async function laAdminTro(uid) {
  const a = await docAdmin(uid);
  return !!a.tro;
}

module.exports = {
  COL, chayTrenKhoanCoc, taoCoc, soLanHuyMienPhiConLai, hoanTatCaCuaChu, laAdminTro, tuDoc, raDoc, VAI_TRO, PHUT,
};
