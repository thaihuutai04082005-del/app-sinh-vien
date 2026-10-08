# Hợp đồng dữ liệu và API của module Quán ăn

Tài liệu kỹ thuật nối **backend** (`functions/src/quan_an/`) và **app** (`lib/features/quan_an/`). Luật nghiệp vụ nằm ở đặc tả Phần 3 (`dac-ta-tim-tro-quan-an.md`); đây chỉ chốt **tên collection, trường, hành động API**. Quy ước giống module Tìm trọ (xem `functions/src/tro/` và `lib/features/tro/`).

## Quy ước chung

- Mọi collection của module có tiền tố **`qa_`** (tách khỏi module khác).
- Thời điểm: Firestore `Timestamp`. Tiền: số nguyên VND. Vị trí: `GeoPoint`.
- Giờ mở cửa: số **phút từ 00:00 giờ Việt Nam** (0–1439). Ca qua nửa đêm: `den < tu` (ví dụ 18:00–02:00 = `{tu: 1080, den: 120}`), thuộc ngày bắt đầu ca. Ngày trong tuần: `"1"`=Thứ hai … `"7"`=Chủ nhật.
- Mọi thao tác ghi quan trọng đi qua callable **`quanAnApi({hanhDong, ...thamSo})`** (giống `troApi`). Chủ quán chỉ ghi trực tiếp **bản nháp quán** (`qa_quan`, trạng thái `draft` / `rejected`) và **lưu ❤️** (`qa_luu`).
- Lỗi nghiệp vụ trả `HttpsError` với `message` tiếng Việt hiển thị thẳng cho người dùng; thao tác trên dữ liệu cũ: `aborted` + "Thông tin đã thay đổi, vui lòng tải lại."
- Cổng thanh toán: **giả lập** (như Tìm trọ), secret `QA_CONG_BI_MAT`; webhook `quanAnCongBaoVe`; lịch `quanAnDinhKy` mỗi phút.
- Giá trị cố định (mã): xem từng bảng dưới đây.

## Mã dùng chung

| Nhóm | Mã |
|---|---|
| Loại quán | `ho_kinh_doanh`, `ban_le` |
| Loại món (1–3) | `com`, `bun_pho_mi`, `banh_mi`, `an_vat`, `lau_nuong`, `chay`, `do_uong`, `tra_sua`, `ca_phe`, `trang_mien`, `khac` |
| Tiện ích | `trong_nha`, `ngoai_troi`, `may_lanh`, `wifi`, `o_cam`, `do_xe`, `hoc_nhom` |
| Trạng thái quán | `draft`, `pending_review`, `rejected`, `active`, `hidden`, `suspended`, `closed` |
| Trạng thái mở cửa (tính, không lưu) | `mo`, `sap_dong`, `dong`, `tam_nghi` |
| Khuyến mãi | `giam_phan_tram`, `giam_tien`, `combo`, `gio_vang`, `sinh_vien`; trạng thái `chay`, `dung`, `het_han` |
| Trạng thái đơn | `pending_payment`, `expired`, `placed`, `cancelled_student`, `rejected`, `expired_accept`, `accepted`, `cancelled_restaurant`, `ready`, `delivering`, `delivered`, `completed`, `not_received`, `disputed`, `refunded`, `partially_refunded` |
| Trạng thái đặt bàn | `pending`, `confirmed`, `rejected`, `expired`, `cancelled_student`, `cancelled_restaurant`, `arrived`, `no_show` |
| Cách nhận / giờ / cách trả | `den_lay`·`giao` / `asap`·`hen` / `app`·`tien_mat` |
| Trạng thái tiền | `cho_tra`, `dang_giu`, `da_chuyen`, `da_hoan`, `hoan_mot_phan`, `het_han`, `that_bai` |
| Nhãn đánh giá | `dat_mon` (🛵), `dat_ban` (🍽), `check_in` (📍), `null` = chưa xác minh |
| Lý do khiếu nại đơn | `khong_nhan_duoc`, `thieu_mon`, `sai_mon`, `mon_hu`, `khac` |
| Lý do báo cáo riêng | `quan_khong_ton_tai`, `sai_gio`, `sai_gia`, `khuyen_mai_sai`, `khai_sai_loai`, `mat_ve_sinh`, `chuyen_khoan_ngoai_app` (+ các lý do chung của Tìm trọ: lừa đảo, xúc phạm / lộ thông tin, spam, khác) |

## Collection

### `qa_quan/{quanId}` — quán
`chuQuanId`, `ten`, `loaiQuan`, `loaiMon[]`, `moTa`, `sdt`, `diaChi`, `phuong`, `viTri`, `luuDong` (bool), `ghiChuViTri`, `searchText` (không dấu: tên quán + tên món + đường + phường),
`gioMoCua` `{ "1": [{tu, den}], … "7": [...] }` (mảng rỗng = nghỉ, tối đa 2 ca),
`tamNghiDen` (Timestamp|null) + `tamNghiLoai` (`hom_nay`|`dai_ngay`|null), `tamNgungNhanDon` (bool, chủ bật tay), `tamNgungDen` (Timestamp|null, hệ thống tự tạm ngưng tới hết ngày),
`phucVu` `{anTaiQuan, mangDi}`, `tienIch[]`, `nhanDatBan` (bool),
`datMon` `{bat, denLay, giaoTanNoi, banKinhKm, phiGiaoKieu ('co_dinh'|'theo_km'), phiGiao, phiMoiKm, donToiThieu, chuanBiPhut, tienMat}`,
`anhMatTien[]` (1–3, ảnh đầu là bìa), `anhBia`, `anhKhac[]` (0–10), `viTriAnh` (GeoPoint lúc chụp, nếu có), `camKet`, `daDoiChieuMst` (bool, admin ghi),
`trangThai`, `lyDoTuChoi`, `banChinhSua` (map các trường đổi chờ duyệt + `guiLuc`, `loai`: `sua`|`nang_cap`), `khaiSaiLoai` `{lyDo[], hanChuyen (Timestamp|null)}`|null,
`anBoi` (`admin`|null), `khoaBan` (bool, khóa bán vĩnh viễn), `hoatDongLuc`, `hanXacNhanHoatDong` (Timestamp|null), `duyetLuc`, `taoLuc`, `capNhatLuc`,
`soLieu` `{soMon, giaP25, giaTrungVi, giaP75, diemTong, soDanhGia, diemChuaXm, soDanhGiaChuaXm, diemTieuChi {monAn, giaCa, veSinh, phucVu}, soNguoi30Ngay, hayAn (bool), tyLeNhanDon, tyLeGiuBan, coKhuyenMai (bool), moiMo (bool)}`.
Phụ: `qa_quan/{id}/rieng/giay_to` `{maSoThue, anhGiayChungNhan[], anhAttp[]}` — chỉ chủ quán và admin Quán ăn đọc.

### `qa_nhom_mon/{id}`
`quanId`, `chuQuanId`, `ten`, `thuTu`, `laDoUong` (bool: nhóm đồ uống / món thêm → không tính mức giá).

### `qa_mon/{id}`
`quanId`, `nhomId`, `chuQuanId`, `ten`, `moTa`, `gia`, `anh`, `noiBat`, `conHang`, `thuTu`, `laDoUong` (sao từ nhóm), `daXoa`,
`tuyChon[]` = `[{ten, batBuoc, toiDa (1 = chọn 1; n>1 = chọn nhiều), lua: [{ten, giaThem}]}]`.

### `qa_khuyen_mai/{id}`
`quanId`, `chuQuanId`, `loai`, `tieuDe`, `phanTram`, `giamToiDa`, `giamTien`, `donToiThieu`,
`combo` `{mon: [{monId, soLuong}], gia}`, `gioVang` `{tu, den, ngay[], phanTram, giamToiDa}`, `batDau`, `ketThuc` (≤ 90 ngày), `trangThai`.

### `qa_check_in/{svId}_{quanId}_{yyyyMMdd}`
`svId`, `quanId`, `viTri`, `khoangCachM`, `anh`, `camNghi`, `congKhai`, `tinhHayAn`, `luc`.

### `qa_dat_ban/{id}`
`quanId`, `chuQuanId`, `svId`, `svSdt`, `tenQuan`, `gio`, `soNguoi`, `ghiChu`, `status`, `version`, `taoLuc`, `hanXacNhan`, `hanGiuBan`, `hanTuDong` (hết giờ giữ + 24 giờ), `huySatGio` (bool), `ghiNhanDen` (`quan`|`check_in`|`tu_dong`|null), `checkInId`, `xacNhanLuc`, `nhacLuc` (đã nhắc 1 giờ trước), `daXuLy {}`, `lichSu[]`.

### `qa_don/{id}` — đơn món
`quanId`, `chuQuanId`, `svId`, `svSdt`, `tenQuan`, `anhBia`,
`monAn[]` = `[{monId, ten, gia, soLuong, tuyChon: [{nhom, ten, giaThem}], ghiChu, thanhTien}]` (đã chốt giá),
`cachNhan`, `diaChiGiao` `{dong, viTri, khoangCachKm}`|null, `gio`, `gioHen`|null, `sdtNhan`, `ghiChuQuan`,
`tienMon`, `giamCombo`, `giamGia`, `khuyenMaiApDung[]` (`[{id, tieuDe, loai, giam}]`), `phiGiao`, `tong`, `cachTra`,
`status`, `version`, `lyDoHuy`, `taoLuc`, `hanThanhToan`, `hanQuanNhan`, `gioDuKienSanSang`, `moHuyChamLuc`, `batDauGiaoLuc`, `tNhanMonDuKien` (đến lấy),
`maNhanMonDaNhapLuc`, `anhGiao` `{url, viTri, khoangCachM}`, `bangChungLuc`, `bangChungLoai` (`ma`|`anh`), `hanKhieuNai` (bằng chứng + 24 giờ), `hanQuaHan6h`, `coQuaHan` (bool), `ruaSoatLuaDao` (bool),
`khongNhan` `{anh, viTri, luc, hanPhanDoi, phanDoi (bool), phanDoiLuc, moTaPhanDoi}`|null,
`khieuNai` `{loai: 'khieu_nai'|'chua_nhan_mon'|'phan_doi_khong_nhan'|'xac_minh', lyDo, moTa, anh[], luc, hanChuTraLoi, coKhanLuc, chuTraLoi, deNghiHoan, quyetDinh, soTienHoan, tinhBomHang (bool), lyDoQuyet, chuTraLoiLuc}`|null,
`daXacMinh` (bool: đủ điều kiện nhãn 🛵), `danhGia` `{han}`|null (mở đánh giá sau hoàn tất), `ketThucLuc`, `lyDoKetThuc`, `daXuLy {}`, `hanKeTiep`, `lichSu[]`, `capNhatLuc`.
Phụ: `qa_don/{id}/rieng/ma` `{ma}` — mã nhận món 4 số, **chỉ sinh viên của đơn đọc**; chủ quán không đọc được (chỉ nhập mã qua API).

### Thanh toán / tiền
`qa_khoan_tien/{donId}`, `qa_cong_gia_lap/{donId}`, `qa_vi/{chuQuanId}` `{dangGiu, daNhan}` — cùng dạng `tro_khoan_tien`, `tro_cong_gia_lap`, `tro_vi`.

### Hồ sơ, khóa, vi phạm
`qa_ho_so/{uid}` `{diaChi: [{ten, dong, viTri}], diemGoc, caiDatThongBao{}}` ·
`qa_khoa/{sdt|uid}` `{khoaDatMonDen, khoaDatBanDen, khoaTienMatDen, khoaBaoCaoDen, khoaDatMonAppDen}` ·
`qa_vi_pham/{id}` `{uid, sdt, vaiTro, loai: 'bo_hen_dat_ban'|'bom_hang'|'bao_cao_sai'|'khieu_nai_sai'|'quan_cham_xac_nhan', nguon, luc, daGo}` ·
`qa_chi_so_chu/{chuQuanId}` `{tyLePhanHoi, tyLeNhanDon, tyLeGiuBan, soCanhCao, hoTen, daXacThucDanhTinh}`.

### Tương tác
`qa_chat/{chatId}` (+ `tin_nhan`) · `qa_danh_gia/{loai}_{id}` — `loai`: `don` | `ban` | `check_in` | `khong` (id đánh giá = `{svId}_{quanId}` vì **mỗi người 1 đánh giá / quán**; nhãn nằm trong trường `nhan`) · `qa_luu/{uid}_{quanId}` · `qa_bao_cao` · `qa_khang_nghi` · `qa_thong_bao` · `qa_nhat_ky_admin` · `qa_cau_hinh/hien_hanh` — như các collection `tro_*` tương ứng.
Đánh giá: `{quanId, svId, diem: {monAn, giaCa, veSinh, phucVu}, diemTong (hệ thống tính), the[], nhanXet, anh[], nhan, tinhDiem, chuTraLoi, daCapNhat, trangThaiHienThi}`.

## API `quanAnApi`

> Trả về `{ok: true, …}` hoặc ném `HttpsError`. Mọi hành động tự kiểm tra quyền, không tin app.

**Chung:** `cauHinh` → bảng 3.16 (con số) · `thongTinSinhVien` → `{khoa: {...}, soLanBomHang, coTienMat, khoaDatMon…}`.

**Quán (chủ quán):** `guiDuyetQuan{quanId}` · `suaQuan{quanId, …trường}` (trường hiện ngay ghi luôn; trường cần duyệt → `banChinhSua`) · `nangCapLoaiQuan{quanId, maSoThue, anhGiayChungNhan[]}` · `caiDatDatMon{quanId, datMon}` · `tamNghi{quanId, kieu: 'hom_nay'|'dai_ngay'|'mo_lai', den?, xacNhan?}` (có đơn / bàn bị ảnh hưởng mà chưa `xacNhan` → trả `{canXacNhan: true, donAnhHuong, banAnhHuong}`) · `tamNgungNhanDon{quanId, bat}` · `anHienQuan{quanId, an}` · `ngungKinhDoanh{quanId}` · `xacNhanConHoatDong{quanId}` · `chuyenLoaiQuan{quanId}` (bán lẻ → hộ KD sau khi được yêu cầu) · `layGiayToQuan{quanId}` (chủ / admin).

**Menu:** `luuNhomMon{quanId, nhomId?, ten, laDoUong, thuTu}` · `xoaNhomMon{nhomId}` · `luuMon{quanId, monId?, nhomId, ten, moTa, gia, anh, noiBat, conHang, thuTu, tuyChon[]}` · `xoaMon{monId}` · `batTatMon{monId, conHang}`.

**Khuyến mãi:** `luuKhuyenMai{quanId, khuyenMaiId?, …}` · `dungKhuyenMai{khuyenMaiId}`.

**Check-in:** `checkIn{quanId, lat, lng, anh?, camNghi?, congKhai?}` → `{ok, khoangCachM}`.

**Đặt bàn:** `datBan{quanId, gio (ms), soNguoi, ghiChu}` · `thaoTacBan{banId, version, loai}` với `loai` ∈ `QUAN_XAC_NHAN`, `QUAN_TU_CHOI`, `QUAN_HUY`, `QUAN_KHACH_DEN`, `QUAN_KHONG_DEN`, `SV_HUY`, `SV_CHECK_IN` · `xuLyHanBan{banId}`.

**Đặt món:**
- `baoGiaDon{quanId, items[{monId, soLuong, tuyChon[{nhom, lua}], ghiChu}], cachNhan, diaChi?{lat, lng, dong}, gio{loai, hen?}}` → `{ok, monAn[], tienMon, giamCombo, giamGia, khuyenMaiApDung[], phiGiao, tong, gioDuKienSanSang, tienMatDuocKhong}`; không đặt được thì `{ok: false, ma, thongDiep}` (ví dụ `mon_het`, `quan_dong`, `ngoai_ban_kinh`, `chua_du_don_toi_thieu`, `gio_hen_sai`).
- `datMon{…như baoGiaDon, cachTra, sdtNhan, ghiChuQuan, tongDaThay}` → `{ok: true, donId}` hoặc `{ok: false, giaDoi: true, tong, …}` (không tạo gì).
- `thanhToanGiaLap{donId, ketQua: 'thanh_cong'|'that_bai'}` · `xemPhienThanhToan{donId}`.
- `thaoTacDon{donId, version, su}` với `su.loai` ∈:
  - Sinh viên: `SV_HUY`, `SV_HUY_QUAN_CHAM`, `SV_DA_NHAN`, `SV_CHUA_NHAN_MON`, `SV_KHIEU_NAI{lyDo, moTa, anh[]}`, `SV_PHAN_DOI{moTa, anh[]}`.
  - Quán: `QUAN_NHAN{chuanBiPhut?}`, `QUAN_TU_CHOI`, `QUAN_HUY`, `QUAN_SAN_SANG`, `QUAN_DANG_GIAO`, `QUAN_NHAP_MA{ma}`, `QUAN_DA_GIAO{anh, lat, lng}`, `QUAN_KHONG_NHAN{anh, lat, lng}`, `QUAN_TRA_LOI_KHIEU_NAI{noiDung, deNghiHoan?}`.
  - Admin: `ADMIN_QUYET{quyetDinh: 'hoan_toan'|'hoan_mot_phan'|'chuyen_cho_quan'|'da_giao'|'khong_giao', soTienHoan?, tinhBomHang?, lyDo}`, `ADMIN_QUA_HAN{quyetDinh, lyDo}`, `ADMIN_LUA_DAO{quyetDinh, lyDo}`.
- `xuLyHanDon{donId}` (mở lại đơn → xử lý hạn đã tới).

**Chat / đánh giá / báo cáo / kháng nghị** (giống Tìm trọ): `guiTin`, `daXemChat`, `chanChat`, `guiDanhGia{quanId, diem{monAn, giaCa, veSinh, phucVu}, the[], nhanXet, anh[]}`, `traLoiDanhGia`, `guiBaoCao`, `guiKhangNghi`.

**Admin Quán ăn** (`admins/{uid}.quanAn == true`): `adminDuyet{loai: 'quan'|'chinh_sua'|'nang_cap', id, dongY, lyDo, daDoiChieuMst?}` · `adminYeuCauChuyenLoai{quanId, lyDo}` · `adminAnHien{quanId, an, lyDo}` · `adminDinhChi{quanId, dinhChi, lyDo}` · `adminKhoaBan{quanId, lyDo}` · `adminKhoaChucNang{uid|sdt, chucNang, den, lyDo}` · `adminXuLyBaoCao` · `adminXuLyKhangNghi` · `adminCauHinh{ghiDe}` · `adminLuaDao{quanId, lyDo}` (kết luận lừa đảo → gắn cờ rà soát mọi đơn đang chạy, hủy bàn đã xác nhận, gửi đề nghị khóa tài khoản).

## Thông báo (nhóm)
Nhóm khóa (không tắt được): `giao_dich`, `don_hang`, `dat_ban`, `khieu_nai`, `khang_nghi`. Nhóm tắt được: `tin_nhan`, `quan_da_luu`, `danh_gia`, `nhac_danh_gia`.
