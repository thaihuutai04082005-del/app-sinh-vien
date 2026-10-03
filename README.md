# UniHub — nền tảng tiện ích sinh viên

UniHub gom các nhu cầu thường ngày của sinh viên vào một nền tảng dùng chung. Vị trí được định hướng linh hoạt theo trường và khu vực của từng người dùng, không giới hạn vào một cơ sở giáo dục cụ thể.

## Bản beta cho người dùng thử

Bản Flutter Web công khai dành cho người dùng thử:

**https://huongvip0987.github.io/unihub-beta/**

Bản beta dùng dữ liệu minh họa có gắn nhãn rõ ràng. Nhiều người có thể mở cùng đường link để kiểm thử giao diện. Dữ liệu tài khoản và nội dung dùng chung sẽ được bật sau khi dự án Firebase thật được cấu hình.

- `mobile/`: ứng dụng Flutter chính, bám theo `mo-hinh-app-sinh-vien-1.md`.
- `cloudflare/`: Worker phục vụ web app + API upload ảnh/video và dữ liệu demo (KV).

## Chạy ứng dụng Flutter

Nhấp đúp `start.bat` (lối vào mặc định), hoặc chạy:

```powershell
cd mobile
F:\Apps\flutter\bin\flutter.bat pub get
F:\Apps\flutter\bin\flutter.bat run -d chrome
```

Để chạy Android cần cài thêm Android Studio và Android SDK.

## Demo upload ảnh qua Cloudflare

Bản đang chạy (có đăng sản phẩm, đặt xe kèm ảnh): **https://unihub-beta.unihub-cloudflare.workers.dev**

Nhấp đúp `start-cloudflare-demo.bat` để có link công khai `https://...trycloudflare.com` (không cần tài khoản). Deploy thật lên Cloudflare Workers + R2: xem [`cloudflare/README.md`](cloudflare/README.md).

## Kiểm tra chất lượng

```powershell
cd mobile
F:\Apps\flutter\bin\flutter.bat test
F:\Apps\flutter\bin\flutter.bat analyze
```
