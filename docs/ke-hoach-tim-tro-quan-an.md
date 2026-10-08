# Kế hoạch triển khai Tìm trọ và Quán ăn

Đặc tả gốc: [`dac-ta-tim-tro-quan-an.md`](dac-ta-tim-tro-quan-an.md) (v3.16). Người phụ trách: Thái Hữu Tài.

## Các quyết định đã chốt
1. **Thứ tự:** làm xong **Tìm trọ** (4 giai đoạn, mục 2.22) rồi mới sang **Quán ăn**; Quán ăn dùng lại khung đã làm.
2. **Thanh toán / giữ tiền cọc:** làm bằng **cổng thanh toán giả lập** chạy trên Cloud Functions (đủ luồng cọc, giữ tiền, hoàn tiền, hết hạn). Sau này thay bằng PayPal / MoMo sandbox mà không phải sửa luồng. Không để khóa bí mật trong repo (repo public).
3. **Camera / GPS / xác thực CCCD + khuôn mặt:** làm sau (cần máy Android thật). Giai đoạn đầu cho đăng video bằng link / tải lên; xác thực người thật do admin duyệt tay, không lưu ảnh CCCD thật.
4. **Bản đồ:** OpenStreetMap (`flutter_map`) vì Google Maps Platform không bán cho tài khoản thanh toán tại Việt Nam; đặc tả mục 2.19 cho phép phương án này.
5. **Giao diện:** mỗi module có theme riêng (`widgets/tro_theme.dart`), mở bằng `troRoute` trong `screens/tro_routes.dart`.

## Tiến độ Tìm trọ (mục 2.22) — ĐÃ XONG
- [x] TR-1.1 Giao diện riêng của module (màu, chữ, nút, huy hiệu, khung xương / rỗng / lỗi)
- [x] TR-1.2 Tải ảnh / video lên (ảnh + video qua Storage hoặc dán link)
- [x] TR-1.3 Điểm gốc + bản đồ (GPS / tìm địa chỉ, gom cụm, chỉ đường)
- [x] TR-1.4 Tự xử lý hạn (`troDinhKy` mỗi phút + xử lý khi mở màn hình) + chặn thao tác đồng thời (version)
- [x] TR-1.5 Thông báo (trong app, nhóm khóa không tắt được; server gửi FCM nếu máy đã đăng ký)
- [x] TR-1.6 Bộ đếm vi phạm (cửa sổ trượt, tự khóa chức năng)
- [x] TR-1.7 Thanh toán giả lập + giữ tiền (chữ ký HMAC, chống trùng, tiền về trễ tự hoàn)
- [x] Giai đoạn 2: nhà trọ, phòng, sảnh, lọc, bản đồ, chi tiết, đăng tin nhiều bước, quản lý, duyệt
- [x] Giai đoạn 3: cọc, thanh toán, hạn tự động, nhận phòng, đổi thời điểm, khiếu nại, báo không đến, cọc trực tiếp, vi phạm
- [x] Giai đoạn 4: chat (cảnh báo lừa đảo, chặn), đánh giá, lưu nhà trọ, báo cáo, kháng nghị, thông báo, hàng chờ admin, giao diện màn hình rộng

## Tiến độ Quán ăn (mục 3.22) — ĐÃ XONG
- [x] QA-1 Nền của module: giao diện riêng (`quan_an_theme.dart`), tải ảnh, điểm gốc + bản đồ OSM, tự xử lý hạn + chặn thao tác đồng thời (version), thông báo, bộ đếm vi phạm, cổng thanh toán giả lập + giữ tiền
- [x] QA-2 Tìm quán: dữ liệu quán / giờ mở cửa (2 ca, qua nửa đêm, tạm nghỉ) / menu, sảnh + bộ lọc + bản đồ + chi tiết, đăng quán 5 phần (2 loại hình) + admin duyệt + cờ khai sai loại + nâng cấp loại, quản lý menu / giờ / sửa thông tin (bản chỉnh sửa chờ duyệt), khuyến mãi, check-in GPS + "Sinh viên hay ăn" + nhắc 90 ngày
- [x] QA-3 Đặt bàn, đặt món: đặt bàn + bảo vệ bằng check-in, giỏ hàng + tùy chọn món, hệ thống tự tính giá + 7 quy tắc khuyến mãi (combo, giờ vàng), đặt món (càng sớm càng tốt / hẹn giờ, chốt giá, báo giá đổi) + thanh toán + tiền mặt, quản lý đơn (chuông, mã nhận món 4 số, ảnh giao GPS), theo dõi đơn (hủy vì quán chậm, "Chưa nhận được món" từ T_lấy, 24 giờ xác nhận, cờ 6 giờ), khiếu nại + admin hoàn toàn phần / một phần, "Khách không nhận" + phản đối + bom hàng
- [x] QA-4 Tương tác: chat (cảnh báo từ khóa, chặn), đánh giá 4 tiêu chí + nhãn xác minh, lưu ❤️, báo cáo + gắn cờ + ẩn tạm, kháng nghị, admin của module, ẩn / khóa khi còn giao dịch đang chạy, giao diện màn hình rộng

## Cấu trúc code — Tìm trọ
- `functions/` — Cloud Functions (Node 22): `troApi` (mọi thao tác Tìm trọ), `taiKhoanApi` (OTP, xác thực người thật), `troDinhKy` (mỗi phút), `troCongBaoVe` (cổng giả lập báo về).
  - `src/tro/logic/` là phần thuần (không Firebase) — máy trạng thái cọc bảng 2.5h, vi phạm, kiểm tra tin, cảnh báo chat — có unit test.
  - Thời lượng (bảng 2.16) tính bằng phút trong `src/tro/config.js`, admin sửa được ở `tro_cau_hinh/hien_hanh`.
- `lib/features/tro/` — `models/`, `services/` (interface + bản Firebase, gom trong `TroDichVu`), `widgets/`, `screens/{sinh_vien,chu_tro,tuong_tac,admin}`.
- `lib/features/auth/` — xác thực số điện thoại / người thật, duyệt danh tính.
- `firestore.rules`, `storage.rules`, `firestore.indexes.json` — chủ trọ chỉ ghi bản nháp; mọi thứ khác do server ghi.

## Kiểm thử — Tìm trọ
| Phần | Lệnh | Kết quả |
|---|---|---|
| Logic backend | `cd functions && npm test` | 46 qua |
| Luồng đầu-cuối trên emulator | `npx firebase-tools emulators:exec --only auth,firestore,functions --project demo-app-sinh-vien "node functions/test-e2e/tro_luong.e2e.js"` | 29 bước qua |
| Rules | `cd test-rules && npm install && npx firebase-tools emulators:exec --only firestore,storage --project demo-rules "node tro_rules.test.mjs"` | 74 qua |
| Flutter (logic + widget) | `flutter test` | 79 qua |

Chạy e2e cần file `functions/.secret.local` (đã gitignore) chứa 2 dòng `TRO_CONG_BI_MAT=<chuỗi ngẫu nhiên>` và `TK_BI_MAT=<chuỗi ngẫu nhiên>`.

Chạy app với emulator: `flutter run -d chrome --dart-define=EMULATOR=true` (sau khi `npx firebase-tools emulators:start`).

## Hướng dẫn deploy lên Firebase thật
1. `cd functions && npm install`
2. Đặt 2 khóa bí mật (mỗi lệnh sẽ hỏi giá trị — gõ một chuỗi ngẫu nhiên dài, không gửi cho ai, không commit):
   - `firebase functions:secrets:set TRO_CONG_BI_MAT`
   - `firebase functions:secrets:set TK_BI_MAT`
3. `firebase deploy --only functions,firestore:rules,firestore:indexes,storage`
4. Trong Firebase Console → Firestore, tạo document `admins/<uid của bạn>` với `tro: true`, `danhTinh: true` (bool) để vào hàng chờ admin.
5. Xóa các document cũ trong collection `phong_tro` có dạng tin phẳng (dữ liệu thử của bản đầu) — mô hình mới không đọc chúng.
6. OTP đang là bản thử nghiệm: mã luôn là `123456` (chưa gửi SMS thật).

## Khác biệt so với đặc tả (tạm thời)
- Chưa quay video / chụp bằng chứng trong app kèm GPS; video và bằng chứng đăng bằng tải lên hoặc dán link. Ảnh bìa chọn từ ảnh thay vì khung hình video.
- Xác thực người thật: nhập họ tên + số CCCD, chỉ lưu băm + 4 số cuối, admin duyệt tay; không lưu ảnh CCCD / khuôn mặt, không lưu bản mã hóa số CCCD.
- Thanh toán là cổng giả lập (không có tiền thật); thay cổng thật chỉ cần sửa `functions/src/tro/cong_gia_lap.js`.
- Thông báo đẩy: server đã gửi FCM tới máy trong `thiet_bi`, nhưng app chưa đăng ký token (web cần VAPID key) — hiện xem trong mục Thông báo của module.
- Khách chưa đăng nhập: app bắt đăng nhập từ đầu nên không có chế độ khách.
- Giới hạn tải lên dùng chung `DailyQuota` (30 lượt/ngày) của app.

## Khác biệt so với bản đầu của app
- `phong_tro` phẳng cũ đã được thay bằng `nha_tro` + `phong_tro` (+ `tro_dat_coc`, …) theo mục 2.17. Màn hình cũ (`phong_tro_list_screen`, `dang_phong_tro_screen`, …) đã xóa.
