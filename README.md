# app-sinh-vien
Thiết kế và xây dựng app kết nối sinh viên với các nhà cung cấp dịch vụ (trọ, quán ăn, xe dọn trọ, shop đồ rẻ, vui chơi).

- Tài liệu mô hình & đặc tả: [`docs/mo-hinh-app-sinh-vien.md`](docs/mo-hinh-app-sinh-vien.md) — **nguồn chuẩn của cả nhóm**
- Hướng dẫn làm việc nhóm: [`CONTRIBUTING.md`](CONTRIBUTING.md)

## Có gì trong app
- Đăng ký / đăng nhập (Firebase Auth), hồ sơ cá nhân, thanh điều hướng.
- Shop quần áo và Xe dọn trọ: đăng tin, xem chi tiết, upload ảnh/video, hạn mức chống spam.
- Tìm trọ, Quán ăn, Vui chơi: đang phát triển.

## Chạy thử
```
flutter pub get
flutter analyze && flutter test
flutter run            # cần emulator/thiết bị
flutter run -d chrome  # hoặc chạy bản web
```
