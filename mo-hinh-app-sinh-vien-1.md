# MÔ HÌNH APP TỔNG HỢP CHO SINH VIÊN
> Lấy cảm hứng từ mô hình marketplace của Shopee — nhiều "gian hàng dịch vụ" trong 1 nền tảng, dễ mở rộng thêm module mới.

---

## 1. Ý tưởng cốt lõi

Một nền tảng (app/web) tạo môi trường tiện ích tập trung các nhu cầu thiết yếu của sinh viên. Nội dung và vị trí được cá nhân hóa theo trường hoặc khu vực của người dùng, không giới hạn vào một trường hay thành phố cụ thể:
- Tìm trọ
- Tìm quán ăn
- Tìm xe dọn trọ (chuyển nhà)
- Shop quần áo giá rẻ
- Điểm vui chơi, giải trí
- ...và mở rộng thêm theo thời gian

Giống Shopee: **1 tài khoản, nhiều "ngành hàng"**, mỗi ngành hàng là 1 module độc lập nhưng dùng chung hạ tầng (tài khoản, thanh toán, chat, đánh giá, bản đồ).

---

## 2. Kiến trúc tổng thể (giống mô hình Shopee thu nhỏ)

```
┌─────────────────────────────────────┐
│           TÀI KHOẢN CHUNG            │
│   (đăng nhập 1 lần, dùng mọi module)  │
└───────────────┬───────────────────────┘
                │
   ┌────────────┼────────────┬────────────┬────────────┐
   ▼            ▼            ▼            ▼            ▼
 TÌM TRỌ     QUÁN ĂN     XE DỌN TRỌ    SHOP ĐỒ      VUI CHƠI
                                         RẺ
   │            │            │            │            │
   └────────────┴──────┬─────┴────────────┴────────────┘
                        ▼
        HẠ TẦNG DÙNG CHUNG:
        - Bản đồ / vị trí
        - Chat mua-bán / liên hệ
        - Đánh giá & review
        - Thông báo
        - (sau này) Thanh toán trong app
```

**Nguyên tắc thiết kế:** mỗi module là 1 "mini app" độc lập, có thể build/launch riêng, không phụ thuộc module khác — để sau này thêm module mới không phải sửa lại toàn bộ hệ thống.

---

## 3. Chi tiết từng module (theo mô hình Shopee)

> Mỗi module dưới đây được thiết kế theo đúng logic 2 vai trò của Shopee: **Người bán/Người đăng tin** (seller) và **Người mua/Người tìm** (buyer) — cùng với quy trình, trạng thái đơn, và hệ thống đánh giá riêng cho từng loại hình.

### 3.1 Tìm trọ
> Tham khảo thêm từ **SpareRoom** (Anh) và **Uniplaces/Student.com** (chuyên trọ sinh viên quốc tế) — 2 điểm họ làm tốt hơn các app trọ Việt Nam thông thường: **xác thực danh tính** để chống lừa đảo, và **lọc theo phong cách sống** chứ không chỉ lọc theo giá/tiện ích.

**Vai trò Chủ trọ (người đăng tin — giống "Shop" trên Shopee):**
- Tạo hồ sơ chủ trọ (tên, SĐT, xác thực giấy tờ nhà đất — tăng độ tin cậy)
- **Xác thực danh tính (ID verification)** — như SpareRoom, tin đăng có huy hiệu "Đã xác thực" sẽ được ưu tiên hiển thị, chống tin ảo/lừa cọc
- Đăng tin: ảnh/video phòng, giá thuê, giá điện nước, diện tích, số người ở tối đa
- Chọn tiện ích: máy lạnh, gác lửng, wifi, chỗ để xe, an ninh, giờ giấc tự do...
- Gắn vị trí trên bản đồ (tọa độ chính xác)
- **Cho phép đặt cọc giữ chỗ online** (tùy chọn) — như Uniplaces/Student.com, giảm tình trạng "đến nơi mới biết đã có người thuê"
- Quản lý trạng thái tin: Còn trống / Đã cho thuê / Tạm ẩn
- Trả lời tin nhắn, duyệt yêu cầu xem phòng, **có thể trả lời hàng loạt (bulk reply)** khi nhiều người cùng hỏi 1 tin

**Vai trò Sinh viên tìm trọ (người mua — giống "Buyer"):**
- Danh mục lọc: khu vực, khoảng cách tới trường (bán kính km), mức giá, loại phòng (ở ghép/ở riêng), tiện ích
- **Lọc theo phong cách sống nếu ở ghép** (như SpareRoom): ăn chay/mặn, có nuôi thú cưng không, giờ giấc sinh hoạt, hút thuốc hay không — để tránh mâu thuẫn khi ở chung
- Xem trên bản đồ dạng "giá hiển thị ngay trên từng điểm" (giống bản đồ SpareRoom) để so sánh nhanh, không cần bấm vào từng tin
- Lưu tin yêu thích ("Đã lưu" giống giỏ hàng)
- Đặt lịch hẹn xem phòng trực tiếp qua chat
- Đánh giá 5 sao + bình luận sau khi đã ở (chỉ người từng thuê mới được đánh giá — giống Shopee chỉ mua hàng mới review)

**Trạng thái/Quy trình:**
`Đăng tin → Duyệt tin (kiểm duyệt chống lừa đảo) → Hiển thị công khai → Có người hẹn xem → Đã cho thuê`

---

### 3.2 Tìm quán ăn
> Tham khảo **Yelp** (Mỹ) — nền tảng review địa điểm ăn uống lớn nhất thế giới. Điểm mạnh: **bộ lọc rất chi tiết** và **review có cấu trúc** (không chỉ chấm sao chung chung).

**Vai trò Quán ăn (người đăng — giống "Shop"):**
- Tạo trang quán: tên, ảnh, địa chỉ, giờ mở cửa
- Đăng menu (món ăn + giá) — giống đăng sản phẩm trên Shopee
- Cập nhật khuyến mãi (giảm giá giờ vàng, combo sinh viên...)
- Trả lời đánh giá của khách

**Vai trò Sinh viên tìm quán (người mua):**
- Danh mục: theo món (cơm, bún/phở, đồ ăn vặt, trà sữa...), theo giá (dưới 20k, 20-50k...), theo khoảng cách
- **Bộ lọc chi tiết như Yelp:** đang mở cửa lúc này, có chỗ ngồi ngoài trời, nhận đặt bàn trước, có ship hay không, phù hợp học nhóm/đi đông người
- **Check-in** khi đến quán (tùy chọn, kèm ảnh) — vừa là cách "sống ảo", vừa giúp app biết quán nào đang đông sinh viên ghé
- Xem menu, ảnh món, đánh giá sao + review kèm ảnh (giống review có ảnh trên Shopee)
- **Viết review có cấu trúc** (giống Yelp): chọn tag "món ngon", "phục vụ nhanh", "giá hợp lý"... thay vì chỉ viết tự do — giúp người đọc lướt nhanh, không phải đọc hết
- Lọc "Quán sinh viên hay ăn" / "Mới mở" / "Đánh giá cao nhất"
- (Mở rộng sau) Đặt món trước, giữ chỗ

**Trạng thái/Quy trình:**
`Quán đăng ký → Duyệt → Hiển thị trong danh sách khu vực → Khách xem/đến ăn → Đánh giá sau khi ăn`

---

### 3.3 Tìm xe dọn trọ
> Tham khảo **TaskRabbit** (Mỹ/Anh) — nền tảng đặt người làm việc lặt vặt/chuyển đồ theo giờ. Điểm mạnh của họ: **báo giá rõ ràng trước khi đặt** (không phát sinh chi phí ẩn), và **cam kết bồi thường nếu hư hỏng đồ**.

**Vai trò Nhà xe/Tài xế (người cung cấp dịch vụ — giống "Shop dịch vụ"):**
- Đăng ký hồ sơ: loại xe (xe tải nhỏ, ba gác, xe máy chở hàng), khu vực hoạt động
- **Xác thực danh tính (ID-checked)** trước khi được duyệt hoạt động trên app — tăng độ an toàn cho sinh viên
- Đăng bảng giá tham khảo (theo km hoặc theo chuyến, theo giờ nếu chỉ cần khuân vác)
- Nhận yêu cầu đặt xe, xem ảnh đồ đạc khách gửi kèm để báo giá chính xác, xác nhận lịch
- Đánh dấu hoàn thành chuyến

**Vai trò Sinh viên cần chuyển trọ (người đặt dịch vụ):**
- Nhập điểm đi – điểm đến, ngày giờ cần chuyển, mô tả/chụp ảnh số lượng đồ đạc
- **Nhận báo giá trọn gói trước khi xác nhận đặt** (giống TaskRabbit) — biết chính xác giá phải trả, tránh bị "chặt chém" giữa chừng
- Xem danh sách xe khả dụng gần đó, so sánh giá và đánh giá (giống so sánh shop trên Shopee)
- Đặt lịch, xác nhận qua chat/gọi điện
- **Theo dõi vị trí tài xế theo thời gian thực** khi chuyến đang diễn ra
- Đánh giá tài xế sau chuyến (thái độ, đúng giờ, giá đúng như báo)

**Trạng thái/Quy trình:**
`Đặt yêu cầu (kèm báo giá) → Tài xế xác nhận → Đang thực hiện (theo dõi realtime) → Hoàn thành → Đánh giá`

**Chính sách nên có:** cam kết hỗ trợ/bồi thường một phần nếu tài xế làm hư hỏng đồ trong quá trình vận chuyển — tăng độ tin cậy để sinh viên yên tâm đặt dịch vụ.

---

### 3.4 Shop quần áo giá rẻ

> Đây là module **giống Shopee gốc nhất** — áp dụng gần như nguyên bản mô hình marketplace. Tham khảo thêm **Depop/Vinted** (Anh/Mỹ, chuyên đồ secondhand — rất hợp với "quần áo giá rẻ" cho sinh viên): họ có **hệ thống trả giá** và **giữ tiền đến khi khách xác nhận nhận hàng** để tránh lừa đảo.

**Vai trò Người bán (Shop):**
- Đăng ký gian hàng, đăng sản phẩm: ảnh, size, giá, số lượng tồn kho, mô tả
- Trang "Quản lý đơn hàng" theo từng tab trạng thái (giống Kênh Người Bán Shopee): *Chờ xác nhận → Chờ lấy hàng → Đang giao → Đã giao → Trả hàng/Hoàn tiền*
- **Thời hạn xử lý đơn:** phải xác nhận + chuẩn bị hàng trong khoảng thời gian quy định (ví dụ 2 ngày làm việc) — quá hạn hệ thống tự hủy đơn, ảnh hưởng điểm uy tín shop
- Chương trình giảm giá, mã voucher riêng của shop, có thể làm "Flash sale" theo khung giờ
- **Nhận và phản hồi đề nghị trả giá (Make an offer)** từ khách — như Depop/Vinted, đặc biệt hợp với đồ secondhand/giá rẻ, khách hay muốn thương lượng
- Trả lời tin nhắn khách (mục tiêu phản hồi nhanh — Shopee tính cả "tỷ lệ phản hồi chat" vào điểm hiệu suất shop)
- Xử lý yêu cầu đổi trả/hoàn tiền khi khách khiếu nại
- **Điểm hiệu suất shop:** tỷ lệ đơn hủy, tỷ lệ phản hồi chat, thời gian xử lý đơn — hiển thị công khai để tăng độ tin cậy

**Vai trò Sinh viên mua hàng (Buyer):**
- Duyệt theo danh mục: áo, quần, phụ kiện, giá dưới 100k/150k...
- Giỏ hàng, đặt hàng, chọn phương thức nhận (giao tận trọ/hẹn lấy trực tiếp), chọn phương thức thanh toán
- **Gửi đề nghị trả giá thấp hơn giá niêm yết** (như Depop/Vinted) — phù hợp văn hóa mặc cả khi mua đồ giá rẻ/secondhand
- Áp mã voucher/giảm giá lúc thanh toán
- **Tiền thanh toán được "giữ" trên hệ thống, chỉ chuyển cho shop sau khi khách xác nhận đã nhận hàng đúng như mô tả** (giống Buyer Protection của Depop/Vinted) — bảo vệ sinh viên khỏi bị lừa chuyển khoản trước rồi không nhận được hàng
- Theo dõi trạng thái đơn hàng theo từng tab (giống mục "Đơn mua" trên app Shopee)
- **Chỉ được hủy đơn khi đơn còn ở trạng thái "Chờ thanh toán"/"Chờ xác nhận"** — sau khi shop đã chuẩn bị hàng thì không hủy được nữa, chỉ có thể yêu cầu trả hàng/hoàn tiền sau khi nhận
- Đánh giá sản phẩm + shop sau khi nhận hàng: **chấm sao theo 3 tiêu chí** (chất lượng sản phẩm, đúng mô tả, dịch vụ/thái độ shop) kèm ảnh thực tế
- Danh sách yêu thích, mua lại nhanh, **theo dõi (follow) shop yêu thích** để nhận thông báo khi có sản phẩm mới

**Trạng thái/Quy trình đơn hàng (bám sát đúng Shopee + cơ chế giữ tiền của Depop/Vinted):**
`Chờ thanh toán → Chờ xác nhận (shop xác nhận trong thời hạn quy định) → Chờ lấy hàng (đang chuẩn bị/đóng gói) → Đang giao → Đã giao (tiền vẫn được giữ) → Khách xác nhận nhận hàng đúng mô tả → Tiền chuyển cho shop → Đánh giá`
*(Nhánh phụ: Đơn có thể chuyển sang "Đã hủy" nếu quá hạn/2 bên đồng ý hủy, hoặc "Trả hàng/Hoàn tiền" nếu khách khiếu nại sau khi nhận hàng)*

---

### 3.5 Điểm vui chơi
> Tham khảo **Eventbrite** (Mỹ) — nền tảng khám phá sự kiện/địa điểm. Điểm mạnh: **yếu tố xã hội** — thấy bạn bè đã lưu/đã đi đâu, giúp rủ nhau đi chơi dễ hơn là chỉ xem review một mình.

**Vai trò Địa điểm (người đăng — quán cà phê, rạp phim, khu vui chơi...):**
- Tạo trang địa điểm: ảnh, mô tả, giờ hoạt động, giá vé/giá dịch vụ (nếu có)
- Cập nhật sự kiện/ưu đãi theo dịp (Giáng sinh, khai giảng...)
- Trả lời đánh giá

**Vai trò Sinh viên tìm chỗ chơi (người tìm kiếm):**
- Lọc theo loại hình: cà phê, rạp phim, công viên, khu giải trí, quán nhậu...
- Lọc theo dịp: học nhóm, hẹn hò, đi nhóm bạn, giá rẻ
- Xem đánh giá, ảnh thực tế từ người đã đến
- Lưu địa điểm yêu thích để rủ bạn đi sau
- **Theo dõi bạn bè trong app** (như Eventbrite) — thấy bạn bè đã lưu/định đi địa điểm nào, dễ rủ nhau đi chung thay vì đi một mình
- **Feed gợi ý cá nhân hóa** theo lịch sử tìm kiếm/lưu trước đó (VD: hay lưu quán cà phê yên tĩnh thì gợi ý thêm chỗ tương tự)

**Trạng thái/Quy trình:**
`Địa điểm đăng ký → Duyệt → Hiển thị → Sinh viên xem/ghé thăm → Đánh giá`

---

### 3.6 Nguyên tắc chung áp dụng cho MỌI module mới (để dễ mở rộng)

Khi thêm module mới, chỉ cần trả lời 3 câu hỏi theo đúng khung Shopee:
1. **Ai là "người bán"** (người cung cấp: chủ trọ, quán ăn, tài xế, shop, địa điểm...)?
2. **Ai là "người mua"** (sinh viên) và họ cần **lọc/tìm theo tiêu chí gì**?
3. **Quy trình từ lúc đăng tin/đặt dịch vụ đến lúc hoàn thành + đánh giá** diễn ra như thế nào?

Trả lời xong 3 câu này là có thể viết thành 1 mục mới trong phần 3, không cần thiết kế lại hệ thống.

---

## 4. Tính năng dùng chung (Core Platform)

| Tính năng | Mô tả |
|---|---|
| Đăng ký/Đăng nhập | Ưu tiên xác thực qua email trường để tăng độ tin cậy |
| Bản đồ | Hiển thị tất cả (trọ, quán ăn, điểm vui chơi...) gần vị trí người dùng |
| Tìm kiếm & lọc | Tìm theo từ khóa, khu vực, giá |
| Chat | Nhắn tin giữa người dùng và người đăng tin/bán hàng |
| Đánh giá | Review sao + bình luận cho mọi loại tin đăng |
| Thông báo | Tin mới, tin nhắn mới, khuyến mãi |
| Quản lý tin đăng | Cho người đăng (chủ trọ, quán ăn, shop...) quản lý tin của mình |

---

## 5. Công nghệ đề xuất

- **App di động:** Flutter (1 codebase cho Android + iOS)
- **Backend:** Firebase (MVP nhanh: Auth, Firestore, Storage) → nâng cấp lên Node.js/PostgreSQL khi scale
- **Bản đồ:** Google Maps Platform
- **Chat:** Firebase Realtime Database hoặc dịch vụ chat có sẵn (Stream, Sendbird...)

---

## 6. Lộ trình phát triển — chia theo từng task nhỏ

> Mỗi task dưới đây đủ nhỏ để giao trực tiếp cho Claude Code từng cái một (1 task ≈ 1 buổi code). Làm xong task nào, test task đó, rồi mới sang task tiếp theo — không nhảy cóc.

### GIAI ĐOẠN 0 — Chuẩn bị môi trường
- [ ] 0.1. Cài Flutter SDK + kiểm tra `flutter doctor` chạy sạch (không lỗi)
- [ ] 0.2. Cài Android Studio/VS Code + emulator để test app
- [ ] 0.3. Tạo tài khoản Firebase, tạo project mới trên Firebase Console
- [ ] 0.4. Tạo tài khoản Google Cloud, bật Google Maps Platform (lấy API key)
- [ ] 0.5. Cài Claude Code, mở thư mục project rỗng, khởi tạo project Flutter (`flutter create`)
- [x] 0.6. Đẩy code lên GitHub (tạo repo riêng) để lưu lịch sử, tránh mất code

### GIAI ĐOẠN 1 — Khung app + Đăng nhập (Core Platform)
- [x] 1.1. Dựng cấu trúc thư mục project (theo module: `features/tro`, `features/quan_an`, `core/`...)
- [ ] 1.2. Thiết kế màn hình splash + onboarding (giới thiệu app ngắn gọn)
- [ ] 1.3. Kết nối Firebase Auth: đăng ký/đăng nhập bằng email
- [ ] 1.4. Xác thực email trường (kiểm tra đuôi email @...edu.vn nếu có)
- [ ] 1.5. Màn hình hồ sơ cá nhân cơ bản (tên, ảnh đại diện, SĐT)
- [x] 1.6. Dựng bottom navigation bar (thanh điều hướng chính giữa các module)
- [x] 1.7. Tạo màn hình Trang chủ rỗng — nơi sẽ nhúng các module vào sau

### GIAI ĐOẠN 2 — Module Tìm trọ (module đầu tiên, làm mẫu cho các module sau)
- [ ] 2.1. Thiết kế model dữ liệu "Phòng trọ" (giá, ảnh, vị trí, tiện ích...) trên Firestore
- [ ] 2.2. Màn hình danh sách phòng trọ (dạng list/card, load dữ liệu mẫu)
- [ ] 2.3. Màn hình chi tiết 1 phòng trọ (ảnh, mô tả, giá, tiện ích)
- [ ] 2.4. Tích hợp Google Maps: hiển thị vị trí phòng trọ trên bản đồ
- [ ] 2.5. Chức năng đăng tin cho thuê (form nhập liệu + upload ảnh lên Firebase Storage)
- [ ] 2.6. Bộ lọc/tìm kiếm: theo giá, khoảng cách, tiện ích
- [ ] 2.7. Chức năng lưu tin yêu thích
- [ ] 2.8. Chat cơ bản giữa người thuê và chủ trọ (dùng Firestore realtime)
- [ ] 2.9. Chức năng đánh giá (sao + bình luận) sau khi đã thuê

> Khi xong Giai đoạn 2, bạn đã có 1 module hoàn chỉnh từ A-Z. Các module sau lặp lại đúng cấu trúc này nên sẽ nhanh hơn nhiều.

### GIAI ĐOẠN 3 — Module Tìm quán ăn
- [ ] 3.1. Model dữ liệu "Quán ăn" + "Món ăn" (menu)
- [ ] 3.2. Màn hình danh sách quán ăn (lọc theo món/giá/khoảng cách)
- [ ] 3.3. Màn hình chi tiết quán (menu, ảnh, giờ mở cửa)
- [ ] 3.4. Chức năng đăng ký quán mới (dành cho chủ quán)
- [ ] 3.5. Đánh giá quán ăn (sao + ảnh)

### GIAI ĐOẠN 4 — Module Xe dọn trọ
- [ ] 4.1. Model dữ liệu "Dịch vụ xe" (loại xe, khu vực, giá tham khảo)
- [ ] 4.2. Màn hình danh sách xe khả dụng gần khu vực người dùng
- [ ] 4.3. Form đặt lịch (điểm đi, điểm đến, ngày giờ)
- [ ] 4.4. Trạng thái đơn: chờ xác nhận → đang thực hiện → hoàn thành
- [ ] 4.5. Đánh giá tài xế sau chuyến

### GIAI ĐOẠN 5 — Module Shop quần áo rẻ
- [ ] 5.1. Model dữ liệu "Sản phẩm" + "Đơn hàng"
- [ ] 5.2. Màn hình danh sách sản phẩm theo danh mục
- [ ] 5.3. Giỏ hàng + đặt hàng
- [ ] 5.4. Trang quản lý gian hàng cho người bán (thêm/sửa/xóa sản phẩm)
- [ ] 5.5. Theo dõi trạng thái đơn hàng (xác nhận → giao → đã giao)
- [ ] 5.6. Đánh giá sản phẩm sau khi nhận hàng

### GIAI ĐOẠN 6 — Module Điểm vui chơi
- [ ] 6.1. Model dữ liệu "Địa điểm"
- [ ] 6.2. Màn hình danh sách + lọc theo loại hình/dịp
- [ ] 6.3. Trang chi tiết địa điểm + đánh giá

### GIAI ĐOẠN 7 — Hoàn thiện & phát hành
- [ ] 7.1. Gộp tất cả module vào trang chủ (dạng lưới icon giống Shopee)
- [ ] 7.2. Hệ thống thông báo đẩy (push notification)
- [ ] 7.3. Kiểm duyệt nội dung (chống tin rác/lừa đảo) — có thể duyệt thủ công lúc đầu
- [ ] 7.4. Test toàn bộ app trên nhiều thiết bị
- [ ] 7.5. Đăng ký tài khoản nhà phát triển (Google Play/App Store)
- [ ] 7.6. Đóng gói app, viết mô tả, chụp ảnh màn hình, phát hành bản thử nghiệm (beta)

---

### Cách dùng lộ trình này với Claude Code
Mỗi lần làm việc, bạn chỉ cần copy đúng 1 dòng task (ví dụ *"2.3. Màn hình chi tiết 1 phòng trọ"*) và nói với Claude Code: *"Làm task này: [dán task vào]"*. Không cần giao nhiều task cùng lúc — làm từng cái, test chạy được rồi mới sang task kế tiếp.

---

## 7. Đặc tả kỹ thuật chi tiết (để lập trình đúng ngay từ đầu, tránh làm sai/làm lại)

> Phần này quy định rõ **tên gọi, cấu trúc dữ liệu, quy ước code** — để bất kỳ ai (kể cả Claude Code) code vào cũng ra kết quả thống nhất, không tự đặt tên tùy tiện.

### 7.1 Cấu trúc thư mục project (Flutter)

```
lib/
├── main.dart
├── core/                      # Dùng chung toàn app
│   ├── constants/             # Màu sắc, kích thước, chuỗi cố định
│   ├── theme/                 # Theme sáng/tối
│   ├── widgets/                # Nút, ô nhập liệu, card... dùng chung
│   ├── services/               # Kết nối Firebase, Maps, Storage
│   └── utils/                  # Hàm tiện ích (định dạng giá tiền, ngày...)
├── features/                  # Mỗi module 1 thư mục riêng, độc lập
│   ├── auth/                   # Đăng nhập/đăng ký
│   ├── tro/                     # Tìm trọ
│   ├── quan_an/                 # Tìm quán ăn
│   ├── xe_don_tro/               # Xe dọn trọ
│   ├── shop/                     # Shop quần áo rẻ
│   └── vui_choi/                 # Điểm vui chơi
└── shared/                     # Model/logic dùng chung (User, Review, Chat)
```

**Bên trong mỗi module** (ví dụ `features/tro/`), luôn theo đúng 4 thư mục con:
```
tro/
├── models/         # Định nghĩa dữ liệu (class PhongTro...)
├── screens/         # Các màn hình giao diện
├── widgets/          # Component nhỏ dùng riêng trong module này
└── services/          # Hàm gọi Firestore (thêm/sửa/xóa/lấy dữ liệu)
```

### 7.2 Quy ước đặt tên (Naming Convention)

| Loại | Quy tắc | Ví dụ |
|---|---|---|
| Tên file | chữ thường, gạch dưới | `phong_tro_detail_screen.dart` |
| Tên class | PascalCase | `PhongTroDetailScreen` |
| Tên biến/hàm | camelCase | `getDanhSachPhongTro()` |
| Tên collection Firestore | chữ thường, số nhiều | `phong_tro`, `quan_an`, `don_hang` |
| Tên field trong document | camelCase, tiếng Anh | `title`, `price`, `location`, `ownerId` |

> Lưu ý: tên **field dữ liệu** nên viết bằng tiếng Anh (chuẩn lập trình quốc tế, dễ maintain), còn **nội dung hiển thị cho user** thì tiếng Việt.

### 7.3 Data model chi tiết từng module (Firestore collections)

**Collection `users`** (dùng chung mọi module)
```
{
  uid: string,
  name: string,
  email: string,
  phone: string,
  avatarUrl: string,
  role: string,        // "student" | "landlord" | "shop_owner" | "driver"...
  schoolEmail: string,  // để xác thực sinh viên
  createdAt: timestamp
}
```

**Collection `phong_tro`** (module Tìm trọ)
```
{
  id: string,
  ownerId: string,       // trỏ tới users.uid
  ownerVerified: boolean,   // chủ trọ đã xác thực giấy tờ chưa
  title: string,
  images: array<string>,
  price: number,
  electricPrice: number,
  waterPrice: number,
  area: number,           // diện tích m2
  maxPeople: number,
  amenities: array<string>, // ["may_lanh","gac_lung","wifi"...]
  lifestylePrefs: array<string>, // ["an_chay","co_nuoi_thu_cung","khong_hut_thuoc"...] — cho tin ở ghép
  depositEnabled: boolean,  // chủ trọ có nhận đặt cọc giữ chỗ online không
  location: geopoint,
  address: string,
  status: string,         // "available" | "rented" | "hidden"
  createdAt: timestamp
}
```

**Collection `quan_an`** (module Tìm quán ăn)
```
{
  id: string,
  ownerId: string,
  name: string,
  images: array<string>,
  address: string,
  location: geopoint,
  openHour: string,
  closeHour: string,
  category: string,        // "com","bun_pho","tra_sua"...
  status: string,           // "active" | "hidden"
}
```
**Sub-collection `quan_an/{id}/menu_items`**
```
{
  id: string,
  name: string,
  price: number,
  image: string
}
```

**Collection `xe_don_tro`** (module Xe dọn trọ)
```
{
  id: string,
  driverId: string,
  driverVerified: boolean,    // đã xác thực danh tính (ID-checked) chưa
  vehicleType: string,      // "xe_tai_nho","xe_ba_gac","xe_may"
  area: string,
  priceReference: string,
  status: string             // "available" | "busy"
}
```
**Collection `booking_xe`** (đơn đặt xe)
```
{
  id: string,
  userId: string,
  driverId: string,
  fromAddress: string,
  toAddress: string,
  itemPhotos: array<string>,    // ảnh đồ đạc để tài xế báo giá chính xác
  quotedPrice: number,            // giá báo trọn gói trước khi khách xác nhận đặt
  scheduledAt: timestamp,
  status: string,             // "pending" | "confirmed" | "in_progress" | "done"
  driverLastLocation: geopoint  // vị trí tài xế cập nhật realtime khi đang thực hiện
}
```

**Collection `products`** (module Shop quần áo rẻ)
```
{
  id: string,
  shopId: string,
  name: string,
  images: array<string>,
  price: number,
  sizes: array<string>,
  stock: number,
  category: string,
  status: string               // "active" | "out_of_stock"
}
```
**Collection `orders`**
```
{
  id: string,
  buyerId: string,
  shopId: string,
  items: array<{productId, quantity, price, size}>,
  totalPrice: number,
  voucherCode: string,           // mã giảm giá áp dụng (nếu có)
  discountAmount: number,
  offerPrice: number,              // giá đã thương lượng, nếu khách trả giá và shop đồng ý
  paymentMethod: string,          // "cod" | "transfer"...
  status: string,                  // "pending_payment" | "pending_confirmation" |
                                    // "to_ship" | "shipping" | "delivered" |
                                    // "buyer_confirmed" | "cancelled" | "return_refund"
  fundsReleased: boolean,           // tiền đã chuyển cho shop chưa (chỉ true sau khi buyer_confirmed)
  cancelReason: string,             // lý do hủy (nếu có)
  confirmDeadline: timestamp,        // hạn shop phải xác nhận (VD: +2 ngày làm việc)
  createdAt: timestamp
}
```
**Collection `vouchers`** (mã giảm giá riêng từng shop)
```
{
  id: string,
  shopId: string,
  code: string,
  discountType: string,     // "percent" | "fixed"
  discountValue: number,
  minOrderValue: number,
  expiredAt: timestamp
}
```
**Collection `follows`** (dùng chung: follow shop, follow bạn bè, follow địa điểm)
```
{
  id: string,
  followerId: string,       // ai đang follow
  targetId: string,          // id của shop/user/địa điểm được follow
  targetType: string,         // "shop" | "user" | "vui_choi"
  createdAt: timestamp
}
```

**Collection `vui_choi`** (module Điểm vui chơi)
```
{
  id: string,
  name: string,
  images: array<string>,
  category: string,           // "cafe","rap_phim","cong_vien"...
  location: geopoint,
  address: string,
  openHour: string,
  closeHour: string,
  ticketPrice: number
}
```

**Collection `reviews`** (dùng chung mọi module)
```
{
  id: string,
  targetId: string,      // id của phong_tro/quan_an/product/vui_choi...
  targetType: string,     // "phong_tro" | "quan_an" | "product"...
  userId: string,
  rating: number,          // 1-5 (điểm tổng, hiển thị dạng sao)
  ratingDetail: {           // riêng cho module Shop, chấm 3 tiêu chí như Shopee
    quality: number,          // chất lượng sản phẩm
    accuracy: number,          // đúng như mô tả
    service: number            // dịch vụ/thái độ người bán
  },
  tags: array<string>,        // riêng module quán ăn/vui chơi, kiểu Yelp: ["mon_ngon","phuc_vu_nhanh","gia_hop_ly"]
  comment: string,
  images: array<string>,
  createdAt: timestamp
}
```
**Collection `checkins`** (riêng module quán ăn/vui chơi, tham khảo Yelp)
```
{
  id: string,
  userId: string,
  targetId: string,
  targetType: string,      // "quan_an" | "vui_choi"
  image: string,
  createdAt: timestamp
}
```
> Lưu ý: chỉ cho phép tạo review khi `orders.status == "delivered"` (hoặc trạng thái tương đương ở module khác, VD đã thuê/đã ở/đã đến) — đúng nguyên tắc "chỉ người mua/dùng thật mới được đánh giá" của Shopee.

**Collection `chats` / `messages`** (dùng chung)
```
chats: { id, participantIds: array<string>, lastMessage, updatedAt }
messages (sub-collection của chats): { id, senderId, text, createdAt }
```

### 7.4 Quy tắc bắt buộc khi code (để không sai)

1. **Không viết cứng (hardcode) dữ liệu mẫu vào giao diện** — luôn lấy từ Firestore qua tầng `services/`, kể cả lúc test.
2. **Mỗi module không được import trực tiếp code của module khác** — nếu cần dùng chung thì đưa vào `shared/` hoặc `core/`.
3. **Mọi màn hình danh sách phải có 3 trạng thái:** đang tải (loading), rỗng (không có dữ liệu), lỗi (error) — không chỉ code mỗi trường hợp có dữ liệu.
4. **Giá tiền luôn lưu dạng số (number)** trong Firestore, chỉ định dạng "100.000đ" khi hiển thị ra giao diện.
5. **Ảnh luôn upload lên Firebase Storage trước, chỉ lưu URL (string) vào Firestore** — không lưu ảnh trực tiếp vào document.
6. **Tên field trong Firestore phải khớp 100% với tên trong bảng ở mục 7.3** — không tự ý đổi tên (VD: không được viết `gia` thay vì `price`).

---

## 8. Ý tưởng mở rộng trong tương lai
> Ghi chú lại đây mỗi khi có ý tưởng mới, để không quên và dễ đánh giá độ ưu tiên.

- [ ] (thêm ý tưởng ở đây)
- [ ] ...

---

*File này được thiết kế để cập nhật liên tục — mỗi module mới chỉ cần thêm 1 mục ở phần 3 (mô tả nghiệp vụ), 1 khối data model ở phần 7.3 (kỹ thuật), và 1 dòng ở phần 8 khi mới nảy ra ý tưởng.*
