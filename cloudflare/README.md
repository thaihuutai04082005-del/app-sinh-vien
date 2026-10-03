# UniHub trên Cloudflare

Một Worker (`src/index.js`) phục vụ cùng lúc:

- web app Flutter (`mobile/build/web`) dưới dạng static assets;
- `POST /api/upload`: nhận ảnh (JPG/PNG/WEBP/GIF, tối đa 5 MB), lưu vào Workers KV, trả về `{ url, key }`;
- `GET /images/<key>`: trả ảnh từ KV, cache 1 năm.
- Video MP4/MOV/WEBM tối đa 25 MB (giới hạn 1 giá trị KV) cũng qua `/api/upload`, phát tại `GET /videos/<key>` có hỗ trợ Range để tua. Lưu trong field bổ sung `videos` (chưa có trong mục 7.3).
- `GET/POST /api/products`, `GET/POST /api/booking_xe`, `GET /api/<collection>/<id>`: lưu và đọc bài đăng. Mỗi bài là 1 giá trị JSON trên KV, tên field khớp mục 7.3. Đây là chỗ lưu tạm cho bản demo cho đến khi có Firestore.

Thư mục ảnh hợp lệ: `products` (mục 3.4, `products.images`) và `booking_xe` (mục 3.3, `booking_xe.itemPhotos`).

## Demo nhanh, không cần tài khoản Cloudflare

Nhấp đúp `start-cloudflare-demo.bat` ở thư mục gốc. Script sẽ build web, chạy Worker cục bộ (KV giả lập bằng Miniflare) và mở Cloudflare Quick Tunnel. Link `https://<tên-ngẫu-nhiên>.trycloudflare.com` hiện trong cửa sổ tunnel, gửi link đó cho mọi người.

Giới hạn: máy bạn phải bật, ảnh nằm trên ổ cứng máy bạn (`.wrangler/`), link đổi mỗi lần chạy.

## Deploy thật (link cố định, miễn phí, không cần thẻ)

Dùng Workers KV thay vì R2 vì KV có trong gói Free không cần phương thức thanh toán. Hạn mức Free: 1 GB, 1.000 lượt ghi/ngày (mỗi ảnh hoặc bài đăng là 1 lượt), 100.000 lượt đọc/ngày.

```powershell
cd cloudflare
npm install
npx wrangler login
npx wrangler kv namespace create STORE   # dán id in ra vào wrangler.jsonc
npm run build:web
npm run deploy
```

Link sẽ có dạng `https://unihub-beta.<tài-khoản>.workers.dev`.

KV đồng bộ giữa các vùng có thể trễ tới khoảng 60 giây: bài vừa đăng có thể chưa hiện ngay trong danh sách của người ở nơi khác.

## Chuyển sang Firebase Storage sau này

Giao diện chỉ dùng các interface `ImageStorageService`, `ProductService`, `BookingXeService`. Viết thêm bản Firebase của từng interface rồi thay ở `home_page.dart`, không phải sửa màn hình.
