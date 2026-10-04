# UniHub — nền tảng tiện ích sinh viên

UniHub gom các nhu cầu thường ngày của sinh viên vào một nền tảng dùng chung. Vị trí được định hướng linh hoạt theo trường và khu vực của từng người dùng, không giới hạn vào một cơ sở giáo dục cụ thể.

## Bản beta cho người dùng thử

Bản Flutter Web công khai dành cho người dùng thử:

**https://huongvip0987.github.io/unihub-beta/**

Bản beta dùng dữ liệu minh họa có gắn nhãn rõ ràng. Nhiều người có thể mở cùng đường link để kiểm thử giao diện. Dữ liệu tài khoản và nội dung dùng chung sẽ được bật sau khi dự án Firebase thật được cấu hình.

- `mobile/`: ứng dụng Flutter chính, bám theo `mo-hinh-app-sinh-vien-1.md`.
- Backend: Firebase project `appsinhvien-810a2` (Firestore ở `asia-southeast1`). Quy tắc bảo mật nằm ở `firestore.rules` và `storage.rules`.

## Cập nhật quy tắc Firebase

```powershell
npx firebase-tools deploy --only firestore
npx firebase-tools deploy --only storage   # sau khi đã bật Storage (cần gói Blaze)
```

## Chạy ứng dụng Flutter

Nhấp đúp `start.bat` (lối vào mặc định), hoặc chạy:

```powershell
cd mobile
flutter pub get
flutter run -d chrome
```

Để chạy Android cần cài thêm Android Studio và Android SDK.

## Kiểm tra chất lượng

```powershell
cd mobile
flutter test
flutter analyze
```
