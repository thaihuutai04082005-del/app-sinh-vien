# Tích hợp phần của Hướng vào sườn develop

## Phạm vi đối chiếu

Mốc `develop`: `c8de772d249df3152a001e36d482cb7fba5d84f8`.
Đã lấy danh sách nhánh và lịch sử commit từ GitHub trước khi tích hợp.

| Nhánh của Hướng | Cách xử lý |
| --- | --- |
| `feat/xe-shop` (`68dddc4`) | Gộp toàn bộ lịch sử vào nhánh tích hợp, kèm sửa các lỗi hợp đồng API bên dưới. |
| `feat/khung-app-v2` (`80a2f59`) | Đã nằm trong lịch sử `feat/xe-shop`: quên mật khẩu, xác nhận email, trang chủ và theme. |
| `feat/khung-app` (`00ff8f0`) | Nhánh app cũ trong `mobile/`. Phần đăng/upload, retry, cache, quota, Shop/Xe đã có bản tương ứng ở sườn hiện tại hoặc bản mới trong `feat/xe-shop`. Không đưa lại app thứ hai, demo Cloudflare hay workflow chạy từ `mobile/`. Giữ bản sửa quota hiện tại của develop. |
| `docs/mo-hinh-app` (`5449735`) | Tài liệu mô hình đã được đưa vào `docs/mo-hinh-app-sinh-vien.md` và cập nhật trên develop. Không tạo lại bản đặc tả cũ ở thư mục gốc. |
| `feat/chuyen-web` (`d5519a0`) | Phần tính năng trước commit cuối đã có trong `feat/xe-shop`. **Không gộp commit xóa Android/iOS** vì trái với sườn đa nền tảng của develop. |

Các nhánh khác được đối chiếu theo tên và email tác giả; không tìm thấy commit bổ sung của Trần Chí Hướng ngoài các nhóm trên tại thời điểm kiểm tra. Ngày commit không phải bằng chứng về thời điểm push hoặc deploy.

## Giữ tương thích với develop

- Giữ `lib/features/{auth,home,tro,quan_an,xe_don_tro,shop,vui_choi}` và thư viện dùng chung trong `core/`, `shared/`.
- Không thay code nghiệp vụ Tìm trọ, Quán ăn, Vui chơi hay `functions/src/` hiện tại.
- Giữ Android/iOS, `pubspec.yaml`, `pubspec.lock`, codebase Functions `default`, cấu hình Emulator và mọi Firestore index có sẵn.
- Thêm hai codebase `xe-shop` và `xac-nhan-email`; không thay thế backend chung.
- Giữ thanh điều hướng chung; trang chủ mở Shop/Xe qua `ShopDichVu`/`XeDichVu`. Mục Hợp tác ở Cá nhân vẫn có lối vào Tìm trọ/Quán ăn và bổ sung Shop/Xe.
- Rules cho Shop/Xe chuyển việc ghi nghiệp vụ sang server; rules của các module khác được giữ. Cần phát hành backend, rules và client đồng bộ khi triển khai thực tế.

## Các lỗi sửa trong lúc tích hợp

1. **Lệnh callable bị ghi đè:** trước đây `hanhDong` vừa là lệnh định tuyến (`thaoTacDon`, `phanHoiTraGia`) vừa là thao tác nghiệp vụ (`xacNhan`, `baoGia`, `chapNhan`). Client mới dùng `thaoTac` cho thao tác con; backend đọc cùng trường này. Tên lệnh định tuyến luôn được đặt sau tham số trong `FirebaseCallableApi` để không bị ghi đè.
2. **Emulator sai region:** cấu hình dùng chung nay nối cả Functions vùng mặc định và `asia-southeast1`, nơi backend email và Xe/Shop được khai báo.
3. **Thẻ trang chủ trên màn hẹp:** dùng chiều cao thẻ 180 px thay cho tỷ lệ dễ thiếu chỗ cho biểu tượng và hai dòng chữ. Bổ sung kiểm thử ở 390/1300 px.
4. **CI:** giữ Flutter 3.47.6 của Hướng (đã xác minh tag SDK tồn tại), dùng lockfile; thêm job Node 22 cho cả hai backend và kiểm thử rules cũ/mới.

## Xác minh

- `functions`: 147 kiểm thử đạt dưới Node 22.
- `functions-xe-shop`: 37 kiểm thử đạt, gồm 4 kiểm thử đi qua callable handler thật với Firestore được thay bằng bản giả; kiểm tra xác nhận đơn, báo giá, chấp nhận trả giá và từ chối người không có quyền.
- `functions-xac-nhan-email`: nạp module và kiểm tra cú pháp đạt; **chưa kiểm tra gửi email**.
- Đã kiểm tra không mất code module cũ, nền tảng, dependency, codebase Functions và index; `git diff --check` đạt.
- **Chưa chạy được:** `flutter analyze`, `flutter test`, build web và các kiểm thử Firebase Emulator. Máy chưa có Flutter và proxy từ chối `storage.googleapis.com` (HTTP 403). Các test Flutter mới và `test-rules/xe_shop_rules.test.mjs` chưa được xác minh bằng runner tương ứng. Phải chạy các kiểm tra này trước khi công bố bản gộp đã đạt kiểm thử đầy đủ.

## Chạy kiểm tra sau khi có Flutter và quyền mạng

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build web --release
(cd functions && npm ci && npm test)
(cd functions-xe-shop && npm ci && npm test)
(cd functions-xac-nhan-email && npm ci && node --check index.js)
(cd test-rules && npm ci)
npx --yes firebase-tools@15.35.0 emulators:exec --only firestore,storage --project demo-rules \
  "node test-rules/tro_rules.test.mjs && node test-rules/quan_an_rules.test.mjs && node --test test-rules/xe_shop_rules.test.mjs"
```

Backend email sử dụng secret Firebase `SMTP_PASS` và tài khoản gửi đã khai báo trong `functions-xac-nhan-email/index.js`. Luồng mới yêu cầu email được xác nhận trước khi vào app. Cần xác minh các callable email đã được triển khai và SMTP hoạt động trước khi phát hành client; không tự tạo, sao chép hoặc ghi secret vào repository. Không deploy Firebase trong tác vụ tích hợp mã nguồn này.
