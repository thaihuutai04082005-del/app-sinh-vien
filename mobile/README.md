# UniHub Mobile

Ứng dụng Flutter chính của UniHub, được tổ chức theo module như đặc tả trong `mo-hinh-app-sinh-vien-1.md`.

## Trạng thái hiện tại

- App shell và Material 3 theme dùng chung.
- Trang chủ dành cho sinh viên với 5 module độc lập.
- Bottom navigation: Trang chủ, Khám phá, Đăng tin, Đã lưu, Tài khoản.
- Model và repository riêng cho module Tìm trọ.
- Chế độ beta có dữ liệu minh họa, tìm kiếm, lọc và xem chi tiết phòng.
- Flutter Web/PWA được build, kiểm thử tự động và phát hành tại repo beta công khai.
- Đã khai báo Firebase Core, Auth, Firestore, Storage và Google Maps.

Firebase chưa được khởi tạo vì cần tạo Firebase project thật và sinh `firebase_options.dart` bằng FlutterFire CLI. Không đưa API key hoặc cấu hình giả vào mã nguồn.

## Mở bản beta công khai

https://huongvip0987.github.io/unihub-beta/

## Chạy và kiểm tra

```powershell
$env:Path = 'F:\Apps\flutter\bin;' + $env:Path
flutter pub get
flutter test
flutter analyze
flutter run -d chrome
```

Có thể nhấp đúp `start.bat` ở thư mục gốc để chạy ứng dụng Flutter trên Chrome.

Để chạy Android, cần cài Android Studio/Android SDK, sau đó chạy lại `flutter doctor`.
