# ĐẶC TẢ ỨNG DỤNG — TÌM TRỌ & QUÁN ĂN

> **Dự án:** App kết nối sinh viên với các nhà cung cấp dịch vụ (`app-sinh-vien`)
> **Phiên bản:** 3.16 (lịch sử ở mục 5.4)
> **Giờ hệ thống:** mọi mốc giờ, hạn, "giờ hệ thống" trong tài liệu đều tính theo **giờ Việt Nam (UTC+7)**.

# PHẦN 1. TỔNG QUAN

## 1.1 Bối cảnh và vấn đề

### Ý tưởng cốt lõi

Một nền tảng tập trung các **nhu cầu thiết yếu của sinh viên tại 1 khu vực / thành phố**:
- **Tìm trọ** ← tài liệu này
- **Tìm quán ăn** ← tài liệu này
- Tìm xe dọn trọ (chuyển nhà)
- Shop quần áo giá rẻ
- Điểm vui chơi, giải trí
- …và mở rộng thêm theo thời gian

Hiện nay mỗi nhu cầu lại phải tìm ở một nơi khác nhau: lướt các nhóm Facebook, Zalo, hỏi bạn bè, mở nhiều app, gọi điện từng nơi. Thông tin **rời rạc, thiếu, không kiểm chứng được**, nên vừa **mất nhiều thời gian** vừa **dễ gặp rủi ro**.

App là **nền tảng trung gian** kết nối sinh viên với những người cung cấp dịch vụ (chủ trọ, chủ quán…), theo mô hình giống Shopee: **1 tài khoản, nhiều module**, mỗi module lo một nhu cầu như một **"mini app" độc lập**, có thương hiệu, thanh toán, chat, đánh giá, giao diện **riêng**. Thứ duy nhất dùng chung là **1 tài khoản** và **1 lần xác nhận người thật**.

Tài liệu này đặc tả chi tiết **2 module: Tìm trọ và Quán ăn** (trong file mô hình chung của nhóm `mo-hinh-app-sinh-vien.md`, đây là hai module **Tìm trọ** và **Quán ăn** ở mục 3.1 và 3.2 của file đó; còn **trong tài liệu này** chúng là **Phần 2** và **Phần 3**, hai module **riêng biệt, độc lập** với nhau). Các module còn lại (dọn trọ, shop, vui chơi) do **các thành viên khác trong nhóm phụ trách**, có đặc tả riêng, không nằm trong tài liệu này.

### Vấn đề khi tìm trọ

**Bất tiện, mất thời gian:**
- Tin đăng nằm rải rác ở nhiều hội nhóm, phải lướt từng bài, tin trôi rất nhanh.
- Tin thiếu thông tin quan trọng: giá điện nước, có gác không, giờ giấc, có cho nuôi thú cưng không, còn phòng không — phải nhắn hỏi từng chủ trọ.
- Không lọc được theo khoảng cách tới nơi mình cần (chỗ đang đứng, chỗ làm, chỗ học…), theo giá, theo tiện ích; khó so sánh các phòng với nhau.
- Phải đi xem nhiều nơi, không có luật rõ ràng ai được giữ phòng.

**Rủi ro:**
- Tin ảo, ảnh không đúng thực tế, lừa đặt cọc trước.
- Tin cũ, phòng đã cho thuê mà vẫn đăng.
- Đã hẹn miệng giữ phòng nhưng chủ trọ cho người khác thuê / cọc mất.
- Đặt cọc rồi tới nơi phòng sai mô tả, khó đòi lại tiền.
- Đánh giá không biết thật hay giả.

### Vấn đề khi tìm quán ăn

**Bất tiện, mất thời gian:**
- Không biết quanh chỗ mình đang ở có những quán nào, nhất là quán bình dân, quán vỉa hè, xe đẩy — những quán này thường không có trên các app giao đồ ăn.
- Không biết quán **đang mở hay đã đóng**, giá khoảng bao nhiêu, có món gì — phải đi tới nơi mới biết.
- Muốn đặt bàn đi nhóm, đặt món mang về thì phải gọi điện, nhắn tin riêng từng quán.

**Rủi ro:**
- Đánh giá ảo, không biết người viết có thật sự ăn ở quán không.
- Đặt món trả tiền trước nhưng không biết quán có uy tín không, giao thiếu / sai món thì khó đòi lại tiền.

### App giải quyết thế nào

- **Gom về một chỗ:** nhà trọ và quán ăn nằm chung một app, tìm theo khoảng cách tới **vị trí hiện tại** hoặc **một điểm tự chọn trên bản đồ** (mục 2.7, 3.7), lọc theo giá, tiện ích, xem trên bản đồ; thông tin bắt buộc đủ (giá điện nước, giờ mở cửa, menu…).
- **Làm các việc chính ngay trong app:** đặt cọc giữ phòng; xem menu, đặt bàn, đặt món — có trạng thái, thời hạn rõ ràng thay vì hẹn miệng qua tin nhắn.
- **Liên hệ dễ dàng:** **chat trong app** với chủ trọ, chủ quán (có câu hỏi nhanh, thẻ tin của phòng / quán), và **số điện thoại** hiện ở trang chi tiết (cần đăng nhập) để gọi khi cần — không phải đi tìm thông tin liên hệ ở nhiều nơi.
- **Tập trung vào độ tin cậy:** người bán phải xác thực, hình ảnh dùng để chứng minh phải chụp tại chỗ, tiền của sinh viên được app giữ cho tới khi nhận đúng phòng, đúng món, đánh giá có nhãn xác minh (mục 1.3).

## 1.2 Ai dùng app

|Vai trò|Là ai|Làm gì chính|
|---|---|---|
|**Khách**|Chưa đăng nhập|Chỉ xem|
|**Sinh viên**|Người tìm trọ, tìm quán|Tìm, liên hệ, đặt cọc, đặt món, đặt bàn, đánh giá|
|**Chủ trọ**|Người cho thuê phòng|Đăng nhà trọ, phòng; nhận cọc, trả lời yêu cầu thay đổi, cập nhật cọc trực tiếp|
|**Chủ quán**|Người bán đồ ăn|Đăng quán, menu; nhận đơn, nhận đặt bàn|
|**Admin danh tính**|Thành viên nhóm quản trị|Duyệt xác nhận người thật, khóa cả tài khoản|
|**Admin Tìm trọ / Admin Quán ăn**|Thành viên nhóm quản trị, mỗi module riêng|Duyệt hồ sơ, xử lý báo cáo, khiếu nại, kháng nghị **trong module của mình**|

Một người có thể có nhiều vai trò cùng lúc, ví dụ vừa là sinh viên vừa cho thuê lại phòng. Nhưng **không ai được giao dịch với nhà trọ / quán của chính mình** (mục 2.18, 3.18).

## 1.3 Ba nguyên tắc uy tín

1. **Người bán phải là người thật, đã xác thực.** Chủ trọ, chủ quán bắt buộc xác thực số điện thoại, CCCD và khuôn mặt.
2. **Hình ảnh dùng để chứng minh phải chụp tại chỗ.** **Video khu trọ, video phòng, ảnh mặt tiền quán, ảnh giấy tờ, ảnh / video bằng chứng khiếu nại** phải chụp / quay **trực tiếp bằng camera trong app** và có vị trí GPS. **Ảnh bìa hiện ở danh sách cũng lấy từ các hình chụp tại chỗ này.** Ảnh minh họa khác (ảnh phòng, ảnh món, ảnh không gian) được chọn từ thư viện và chỉ hiện ở trang chi tiết.
3. **Tiền được app giữ.** Sinh viên trả tiền (cọc trọ, đặt món trả trên app) thì app giữ tạm, **chỉ chuyển cho người bán khi giao dịch hoàn tất**. Người bán sai thì sinh viên được hoàn tiền.

## 1.4 Phạm vi tài liệu này

|Phần|Nội dung đặc tả|
|---|---|
|**Module Tìm trọ** (Phần 2)|Đăng nhà trọ, phòng · tìm, lọc, bản đồ · liên hệ chủ trọ (chat, gọi) · **đặt cọc trên app giữ phòng** (ai cọc trước người đó giữ) · yêu cầu thay đổi, nhận phòng (ân hạn 3 giờ, 12 / 24 / 48 giờ), khiếu nại · cọc trực tiếp ngoài app · thanh toán, chat, đánh giá, báo cáo, thông báo, kháng nghị, admin, giao diện **riêng**|
|**Module Quán ăn** (Phần 3)|Đăng quán, menu, khuyến mãi · tìm, lọc, bản đồ · check-in · đặt bàn · đặt món · thanh toán, chat, đánh giá, báo cáo, thông báo, kháng nghị, admin, giao diện **riêng**|
|**Tài khoản và xác nhận người thật** (Phần 4) — phần chung duy nhất|1 tài khoản cho mọi module (đăng ký, đăng nhập, OTP, quên mật khẩu, xóa tài khoản) · xác nhận người thật 1 lần (CCCD + khuôn mặt, admin duyệt bằng tay) · khóa cả tài khoản khi lừa đảo|
|Nền tảng|App Flutter cho **điện thoại** (đầy đủ chức năng) và **máy tính** (xem, quản lý, admin — giới hạn ở mục 2.19, 3.19), giao diện sáng|

- **Nguyên tắc thiết kế:** mỗi module là 1 **"mini app" độc lập**, có thể build / chạy riêng, **không phụ thuộc** module khác — để sau này thêm module mới không phải sửa lại toàn bộ hệ thống.
- **Riêng hoàn toàn:** đăng ký nhà trọ / quán, luồng, thanh toán, ví người bán, chat, đánh giá, báo cáo, thông báo, kháng nghị, admin, dữ liệu, giao diện, thư mục code, thứ tự làm, nghiệm thu. Đánh giá quán không dính gì tới trọ, tin nhắn bên trọ không hiện bên quán.
- **Chung duy nhất:** 1 tài khoản + 1 lần xác nhận người thật (Phần 4). Một người vừa cho thuê trọ vừa bán quán thì xác nhận người thật 1 lần, nhưng **đăng ký và được duyệt riêng** ở từng module.
- Các module **Dọn trọ, Shop, Vui chơi** vẫn thuộc dự án nhưng do thành viên khác làm, nên tài liệu này không đặc tả.
- Các tính năng để làm sau đồ án: mục 2.24 (Tìm trọ), 3.24 (Quán ăn), 4.10 (tài khoản).

---
# PHẦN 2. MODULE TÌM TRỌ

> Module **độc lập**: có luồng, thanh toán, chat, đánh giá, báo cáo, thông báo, kháng nghị, admin, dữ liệu, giao diện, thư mục code **riêng**. Chỉ dùng chung **tài khoản và xác nhận người thật** (Phần 4).

> **🌟 Điểm nổi bật**
> - **Ai cọc trước người đó giữ phòng** — tiền cọc **được app giữ cho tới khi sinh viên xác nhận đã nhận phòng rồi mới giải ngân cho chủ trọ** (hoặc hết 48 giờ không ai báo vấn đề); chủ trọ sai thì sinh viên được hoàn 100%.
> - **Khác biệt (ngách):** tham khảo SpareRoom, Uniplaces / Student.com, nhóm thấy hai điều app trọ Việt Nam thường chưa có và **tự triển khai theo mô hình của app**: **xác minh chủ trọ** (CCCD + khuôn mặt, giấy tờ nhà, video có GPS) và **lọc theo phong cách sống** qua nội quy nhà trọ (🕐 giờ giấc · 🐶 thú cưng · 🛏️ ở qua đêm · 📅 báo trước khi trả phòng).

## 2.1 Module làm gì

Giúp sinh viên tìm **phòng thật, đúng mô tả, còn trống**, liên hệ chủ trọ ngay trên app, và **đặt cọc trên app để giữ phòng** với tiền cọc được app giữ tới khi nhận phòng — **không bị mất cọc** vì phòng ảo, phòng sai mô tả hay chủ trọ cho người khác thuê.

Giúp chủ trọ tiếp cận đúng khách là sinh viên, quản lý phòng và tiền cọc gọn trong một chỗ.

**Nguyên tắc xuyên suốt:** **"Chưa cọc thì chưa giữ phòng — ai hoàn tất đặt cọc hợp lệ trước thì người đó được giữ phòng."**

- App **không quản lý việc đi xem phòng**. Sinh viên muốn xem tận mắt thì dùng chat, số điện thoại, địa chỉ, bản đồ trên app để **tự liên hệ chủ trọ** và thỏa thuận giờ xem. Việc này không tạo lịch hẹn và **không giữ phòng**.
- Sinh viên muốn chắc chắn giữ phòng thì **đặt cọc**.

## 2.2 Khái niệm cần hiểu trước

### Nhà trọ và Phòng

```
NHÀ TRỌ   ← hiện ở danh sách và bản đồ (ví dụ: "Nhà trọ Hoàng Anh")
  └── PHÒNG   ← mỗi phòng là 1 tin riêng (ví dụ: P.101, P.102…)
```

- **1 tin = 1 phòng.** Sinh viên đặt cọc cho **đúng một phòng cụ thể**.
- Phòng có thể ghi thêm **"Khu/Dãy"** (ví dụ Dãy A, Tầng 2). Có ghi thì danh sách phòng tự gom theo khu.
- Số phòng còn trống, giá thấp nhất – cao nhất, điểm đánh giá của nhà trọ: **app tự tính** từ các phòng.

### Hai loại hình cho thuê

||Cho thuê phòng|Cho thuê nguyên căn|
|---|---|---|
|Cấu trúc|1 nhà trọ có nhiều phòng|1 nhà = 1 căn duy nhất (app tự tạo)|
|Ở danh sách hiện|Khoảng giá + "Còn 3 phòng" / "Hết phòng"|Một mức giá + "Còn trống" / "Đã cho thuê"|
|Video khu trọ / video phòng|Khu chung / bên trong từng phòng|**Bên ngoài** (cổng, lối vào, xung quanh) / **bên trong** căn nhà|
|Cọc, đánh giá|Theo từng phòng|Theo cả căn, cùng cách làm|

### Hai cách phòng được cọc

||**Cọc qua app** (`online`)|**Cọc trực tiếp ngoài app** (`offline`)|
|---|---|---|
|Ai làm|Sinh viên bấm "Đặt cọc giữ phòng" và thanh toán|Chủ trọ bấm **"Xác nhận phòng đã có người cọc trực tiếp / ngoài ứng dụng"**|
|Áp dụng|**Mọi phòng "Còn trống"** đều nhận cọc qua app (không có công tắc tắt)|Khi có người cọc tiền mặt trực tiếp, kể cả người không dùng app|
|Tiền|Đi qua app, app **giữ** tới khi nhận phòng (mô phỏng bằng cổng thanh toán **thử nghiệm**, không phải dịch vụ ký quỹ thật)|**Không** đi qua app; app không giữ, không hoàn|
|Phòng|Còn trống → **Đã cọc** → Đã cho thuê|Còn trống → **Đã cọc** → Đã cho thuê|
|Trách nhiệm|Hai bên theo cam kết ở mục 2.5|**Chủ trọ phải cập nhật ngay**: app không tự biết có giao dịch tiền mặt ngoài đời (mục 2.5d)|

Tiền cọc trên app là **số tiền cụ thể**, **không vượt quá 1 tháng tiền thuê** của phòng.

**Cọc là cam kết hai chiều:**
- **Chủ trọ** phải giữ đúng phòng cho sinh viên tới **thời điểm nhận phòng** đã cam kết.
- **Sinh viên** phải tới nhận phòng đúng thời điểm đã cam kết (hoặc thời điểm mới nếu chủ đồng ý yêu cầu thay đổi).

### Trạng thái nhà trọ

|Tên|Mã|Nghĩa|Hiện ở danh sách|
|---|---|---|---|
|Nháp|`draft`|Chủ trọ đang soạn|Không|
|Chờ duyệt|`pending_review`|Đã gửi, chờ admin|Không|
|Bị từ chối|`rejected`|Admin không duyệt, có lý do; sửa rồi gửi lại|Không|
|Đang hiển thị|`active`|Đã duyệt|**Có**|
|Tạm ẩn|`hidden`|Chủ tự ẩn, hoặc admin ẩn sau khi xử lý báo cáo|Không|
|Hết hạn|`expired`|Quá hạn không bấm "Vẫn còn cho thuê"|Không|

- "Hết phòng" **không phải trạng thái**: là nhà trọ `active` không có phòng `available` nào.
- Nhà trọ còn phòng đang có **khoản cọc qua app** chưa kết thúc **không bị hết hạn** (mục 2.14). Phòng chỉ có **cọc trực tiếp ngoài app** thì **không** được miễn: nhà trọ vẫn hết hạn bình thường, chủ trọ phải bấm "Vẫn còn cho thuê".
- Sửa ảnh, video, địa chỉ của nhà trọ đang `active` tạo một **bản chỉnh sửa chờ duyệt**; trong lúc chờ, bản cũ vẫn hiện (mục 2.3 Bước 4).

### Trạng thái phòng

|Tên|Mã|Nghĩa|
|---|---|---|
|Nháp|`draft`|Chủ trọ đang soạn|
|Chờ duyệt|`pending_review`|Đã gửi, chờ admin|
|Bị từ chối|`rejected`|Admin không duyệt, có lý do|
|**Còn trống**|`available`|Đang hiện, **ai cũng xem, liên hệ và đặt cọc được**|
|**Đã cọc**|`reserved`|Đã có cọc (qua app hoặc trực tiếp), **chưa nhận phòng**. Không ai cọc thêm được|
|**Đã cho thuê**|`rented`|Sinh viên bấm "Đã nhận phòng", tự hoàn tất sau 48 giờ, hoặc chủ trọ cho thuê ngoài app / bấm "Đã cho thuê" với cọc trực tiếp|
|Tạm ẩn|`hidden`|Chủ trọ tự ẩn, hoặc admin ẩn sau khi xử lý báo cáo|

**Khóa thanh toán** (không phải trạng thái): khi có người đang ở trang thanh toán cọc, phòng có thêm **khóa thanh toán** trong thời hạn chờ thanh toán (15 phút). Trong lúc khóa: trang phòng hiện 🟠 **"Đang có người thanh toán"**, nút cọc mờ; chủ trọ chưa bấm được "đã có người cọc trực tiếp" hay "Đã cho thuê ngoài app". Khóa tự gỡ khi thanh toán thành công, thất bại hoặc hết hạn.

**Sơ đồ chuyển trạng thái phòng:**
```
draft → pending_review → available
             ↘ rejected → (sửa) → pending_review

available → reserved       cọc qua app thành công, hoặc chủ trọ xác nhận có người cọc trực tiếp
reserved  → rented         sinh viên bấm "Đã nhận phòng", hoặc tự hoàn tất sau 48 giờ;
                           cọc trực tiếp: chủ trọ bấm "Đã cho thuê";
                           khiếu nại được chấp nhận mà phòng đã cho người khác thuê (admin chọn)
reserved  → available      hủy trong 30 phút · "Không thuê nữa" · bỏ cọc (không đến nhận phòng) ·
                           chủ trọ "Hủy cọc" · chủ không trả lời yêu cầu thay đổi · khiếu nại được chấp nhận ·
                           cọc trực tiếp: chủ bấm "Người cọc không thuê nữa"
reserved  → hidden         chủ trọ "Hủy cọc" và chọn ẩn phòng; admin kết luận lừa đảo;
                           khiếu nại được chấp nhận mà phòng có vấn đề (admin chọn)
available → rented         chủ trọ bấm "Đã cho thuê ngoài app"
available ⇄ hidden         chủ trọ ẩn / hiện (chặn khi phòng reserved)
rented    → available      đăng lại khi video còn mới
rented    → pending_review đăng lại khi video quá cũ (phải quay video mới)
```

## 2.3 Phía chủ trọ — từ đầu đến cuối

### Bước 1. Xác thực người thật
Làm theo **mục 4.2** (xác thực người thật). Chưa xác thực thì chỉ soạn nháp được, chưa gửi duyệt được. Nhà trọ vẫn phải đăng ký và duyệt riêng (Bước 2).

### Bước 2. Tạo nhà trọ (làm 1 lần cho mỗi nhà trọ)

Form 5 phần, có thanh tiến trình, quay lại không mất dữ liệu, **tự lưu nháp**.

|Phần|Điền gì|Quy định|
|---|---|---|
|**(1) Thông tin chung**|Tên nhà trọ · Loại hình · Tổng số phòng, số tầng · Tiện ích chung · **Nội quy** (4 tiêu chí, bảng bên dưới) · Mô tả|Tên 5–80 ký tự. Mô tả ≥ 30 ký tự. **Bắt buộc chọn đủ 4 tiêu chí nội quy.** Ở chung với chủ hay không thì ghi trong mô tả|
|**(2) Vị trí**|Địa chỉ đầy đủ + **ghim trên bản đồ**|Bắt buộc ghim đúng cổng|
|**(3) Ảnh khu trọ**|Ảnh cổng, lối đi, chỗ để xe…|3–10 ảnh, **được chọn từ thư viện**, chỉ hiện ở trang chi tiết|
|**(4) Video khu trọ**|Quay khu trọ (nguyên căn: quay bên ngoài)|**Bắt buộc 1–2 video, chỉ quay trong app.** Chọn 1 khung hình trong video làm **ảnh bìa**|
|**(5) Giấy tờ và gửi**|Chụp giấy tờ nhà (hoặc hợp đồng thuê nếu cho thuê lại) → tick cam kết → xem trước → gửi duyệt|Giấy tờ **chỉ chụp trong app**|

**Tiện ích chung:** Wifi · Chỗ để xe · Camera an ninh · Máy giặt chung · Khóa vân tay / thẻ.

**Nội quy** (áp cho mọi phòng trong nhà trọ, dùng cho bộ lọc ở mục 2.4 Bước 1):

|#|Tiêu chí|Lựa chọn|
|---|---|---|
|🕐 1|**Giờ giấc ra vào**|Tự do 24/24 · Có giới hạn → chủ nhập giờ đóng cửa (ví dụ 22:00, 23:00)|
|🐶 2|**Nuôi thú cưng**|Cho phép · Không cho phép|
|🛏️ 3|**Bạn bè / người thân ở qua đêm**|Cho phép · Không cho phép|
|📅 4|**Thời gian báo trước khi trả phòng**|1 tuần · 2 tuần · 3 tuần|

Admin duyệt xong → nhà trọ có huy hiệu **"Đã xác thực nhà"** và **mới được thêm phòng**.

### Bước 3. Thêm phòng (làm nhiều lần)

Form 4 phần.

**(1) Thông tin phòng**

|Nhóm|Thông tin|Quy định|
|---|---|---|
|Phòng|Tên / số phòng · Khu/Dãy (tùy chọn) · Tầng|Tên không trùng trong cùng nhà trọ|
||Loại phòng: **Có gác / Không gác**|Chỉ với loại "cho thuê phòng"|
||Diện tích sàn (m², **không tính gác**) · Diện tích gác (nếu có)|> 0|
||Số người ở tối đa|≥ 1|
||Số phòng ngủ, số WC, có bếp không|**Chỉ với nguyên căn**|
||Tiện ích trong phòng: Máy lạnh · WC riêng · Máy nước nóng · Tủ lạnh · Nội thất cơ bản · Ban công/cửa sổ||
|Chi phí|Giá thuê / tháng|> 0|
||Tiền cọc|**Số tiền cụ thể**, tối đa 1 tháng tiền thuê (dùng cho cọc qua app)|
||Tiền điện|Theo số (đ/kWh) hoặc cố định|
||Tiền nước|Theo khối, theo người, hoặc cố định|
||Phí khác (wifi, rác, gửi xe…)|Tùy chọn, nhiều dòng|
||Hợp đồng tối thiểu (tháng)|Tùy chọn|
|Khác|Ngày có thể vào ở · Mô tả phòng||

**(2) Ảnh phòng:** 3–10 ảnh, được chọn từ thư viện, chỉ hiện ở trang chi tiết.

**(3) Video phòng:** **bắt buộc 1–2 video, chỉ quay trong app** (nguyên căn: quay bên trong căn). Chọn 1 khung hình làm **ảnh bìa phòng**.

**(4) Xem trước và gửi duyệt.** Phòng được duyệt sẽ **nhận cọc qua app** (mọi phòng đều vậy, không có công tắc tắt). Chủ trọ đổi tiền cọc được trong trang quản lý, **trừ khi** phòng đang `reserved`.

**Nút "Nhân bản phòng":** tạo phòng mới giống phòng cũ. App copy hết thông tin, **trừ tên phòng, ảnh và video — phải làm lại cho đúng phòng mới**.

**Quy định video** (cho cả video khu trọ và video phòng):
- Chỉ quay bằng camera trong app, **không có nút lấy video có sẵn**.
- Mỗi video dài **15–60 giây**.
- Màn hình quay có gợi ý: *khu trọ:* cổng → lối đi → chỗ để xe → khu chung; *phòng:* toàn cảnh → nhà vệ sinh → cửa sổ, gác.
- App ghi thời gian và vị trí GPS lúc quay. **Lệch quá ngưỡng** (mục 2.16) so với vị trí nhà trọ → cảnh báo chủ trọ, vẫn gửi được, admin kiểm tra kỹ. Điện thoại báo vị trí giả lập → gắn cờ.
- App tự nén video, có thanh % khi tải lên, mất mạng thì thử lại.

### Bước 4. Quản lý hằng ngày

|Mục|Làm gì|
|---|---|
|**Tổng quan**|Phòng sắp tới thời điểm nhận phòng, yêu cầu thay đổi chờ trả lời, tiền cọc đang giữ, khiếu nại cần trả lời, cọc trực tiếp chưa cập nhật, tin sắp hết hạn, tin bị từ chối, chỉ số uy tín|
|**Nhà trọ của tôi**|Xem nhà trọ → phòng. Thêm phòng · Nhân bản · Sửa · Ẩn/Hiện · Đăng lại · Gia hạn · **"Xác nhận phòng đã có người cọc trực tiếp / ngoài ứng dụng"** · **"Đã cho thuê ngoài app"**|
|**Tiền cọc**|Khoản đang giữ (đếm ngược tới thời điểm nhận phòng) · đang khiếu nại (trả lời trong 24 giờ) · đã nhận · đã hoàn. Nút: **"Hủy cọc"** (trước thời điểm nhận phòng) · **Đồng ý / Từ chối yêu cầu thay đổi** (trong 24 giờ) · **"Sinh viên không đến nhận phòng"** (từ T + 3 giờ)|
|**Cọc trực tiếp**|Phòng đã có người cọc trực tiếp, chờ nhận phòng. Nút: **"Đã cho thuê"** · **"Người cọc không thuê nữa"** · sửa ngày nhận phòng dự kiến (app chỉ ghi nhận, không xử lý tiền, mục 2.5d)|
|**Tin nhắn · Đánh giá · Hồ sơ**||

**"Đã cho thuê ngoài app":** dùng khi chủ trọ cho người ngoài app thuê luôn (không qua giai đoạn cọc). Phòng `available` → `rented`. Không dùng được khi phòng `reserved` hoặc đang khóa thanh toán. Không mở đánh giá.

**Sửa tin:**
- Sửa **giá, phí, mô tả, tiện ích, nội quy, số người, ngày vào ở** → hiện ngay, áp cho người cọc sau. Khoản cọc đã có **không bị ảnh hưởng** (đã có bản chụp thông tin và nội quy lúc cọc, mục 2.5k).
- Sửa **ảnh, video, địa chỉ, vị trí ghim** → tạo **bản chỉnh sửa chờ duyệt**. Bản đang hiện vẫn giữ nguyên; duyệt xong mới thay. Bị từ chối thì giữ bản cũ, chủ trọ thấy lý do.
- **Ẩn, Xóa, Đăng lại** bị chặn khi phòng `reserved` (mục 2.14).
- **Xóa phòng là xóa mềm:** phòng không còn hiện ở đâu và không nhận cọc nữa, nhưng dữ liệu vẫn giữ; khoản cọc đã kết thúc, đánh giá và lịch sử liên quan **vẫn giữ** như bình thường (đánh giá gắn với nhà trọ).

**Giữ tin luôn mới:**
- Nhà trọ **tự hết hạn** nếu chủ trọ không bấm "Vẫn còn cho thuê" (thời hạn ở 2.16). App nhắc trước. Gia hạn **không cần duyệt lại**.
- **Đăng lại phòng** đã cho thuê: video còn mới thì đăng lại ngay; video quá cũ thì **phải quay video mới** và duyệt lại.

**Chỉ số uy tín hiện công khai:** tỷ lệ phản hồi tin nhắn · **tỷ lệ giữ đúng cam kết** (phần trăm khoản cọc qua app mà chủ trọ không hủy, không bị khiếu nại được chấp nhận, trả lời yêu cầu thay đổi đúng hạn; tính 90 ngày) · điểm đánh giá.

## 2.4 Phía sinh viên — từ đầu đến cuối

### Bước 1. Tìm trọ

**Màn hình danh sách:**
```
[ 🔍 Tìm tên trọ, tên đường, phường...      ⚙ Lọc   🗺 ]
[ Gần tôi ] [ Dưới 2tr ] [ Có gác ] [ Máy lạnh ] [ Còn phòng ]
12 nhà trọ · 27 phòng phù hợp            Sắp xếp: Gần nhất ▾
[ Thẻ nhà trọ ]
[ Thẻ nhà trọ ]
```

**Mỗi thẻ nhà trọ có:** ảnh bìa (khung hình từ video khu trọ) · tên · huy hiệu xác thực · ★ điểm · loại hình · địa chỉ ngắn · "Cách bạn 650 m" · khoảng giá · 🟢 Còn 3 phòng / 🔴 Hết phòng · "2 phòng phù hợp" (khi đang lọc) · icon nội quy (🕐 Tự do 24/24 hoặc 🕐 Đóng cửa 22:00 · 🐶 Cho nuôi thú cưng) · nút ❤️.

**Thanh tìm kiếm:** gõ tên nhà trọ, tên đường, phường. **Gõ không dấu vẫn tìm được** ("nguyen hue" ra "Nguyễn Huệ").

**Bộ lọc:**

|Lọc theo|Lựa chọn|
|---|---|
|Loại hình|Cho thuê phòng · Nguyên căn|
|Loại phòng|Có gác · Không gác *(chỉ hiện khi chọn cho thuê phòng)*|
|Khoảng cách|Chọn điểm gốc + bán kính (mục 2.7)|
|Giá|Kéo thanh từ – đến, hoặc mốc nhanh (bảng 2.16)|
|Tiện ích|Máy lạnh · WC riêng · Wifi · Chỗ để xe · Camera an ninh · Máy giặt|
|🕐 **Giờ giấc ra vào**|**Tự do 24/24** · **Về muộn được tới ít nhất __ giờ** (chọn 23:00 → hiện trọ tự do và trọ đóng cửa từ 23:00 trở đi)|
|🐶 **Nuôi thú cưng**|**Cho phép nuôi thú cưng**|
|🛏️ **Ở qua đêm**|**Cho bạn bè / người thân ở qua đêm**|
|📅 **Báo trước khi trả phòng**|**Tối đa** 1 tuần · 2 tuần · 3 tuần (chọn "tối đa 2 tuần" → hiện trọ 1 tuần và 2 tuần)|
|Chỉ hiện nơi còn phòng|*Bật sẵn*|

- Nút cuối bảng lọc: **[Xóa bộ lọc]** và **[Xem 12 kết quả]** — con số đổi ngay khi chọn.
- **Sắp xếp:** Gần nhất · Giá thấp nhất · Mới nhất · Đánh giá cao nhất.
- App **nhớ bộ lọc** lần trước.

**Cách lọc hoạt động:** nội quy là của **nhà trọ** (áp cho mọi phòng). Giá, gác, **tiện ích trong phòng** (máy lạnh, WC riêng…) là của **phòng**; **tiện ích chung** (wifi, chỗ để xe, camera, máy giặt chung…) là của **nhà trọ** và áp cho mọi phòng. Danh sách hiện **nhà trọ**. Nhà trọ được hiện khi có **ít nhất 1 phòng "Còn trống" thỏa điều kiện**. Bấm vào nhà trọ thì các phòng phù hợp nằm trên cùng. Tắt "Chỉ hiện nơi còn phòng" thì nhà trọ hết phòng hiện ở cuối, có nút ❤️ để theo dõi.

**Ví dụ:** sinh viên nuôi mèo bật "Cho phép nuôi thú cưng" → chỉ còn trọ cho nuôi. Sinh viên đi làm ca tối bật "Tự do 24/24" → chỉ còn trọ không có giờ đóng cửa.

**Không có kết quả:** "Không tìm thấy nhà trọ phù hợp — thử nới khoảng giá hoặc tăng bán kính" + nút Xóa bộ lọc.

**Chế độ bản đồ:** ghim hiện giá thấp nhất ("từ 1,5tr"); xanh = còn phòng, xám = hết phòng.

### Bước 2. Xem chi tiết và liên hệ chủ trọ

**Trang nhà trọ** — trên là thông tin chung, dưới là danh sách phòng:
- **Phần trên:** video, ảnh khu trọ · tên, huy hiệu, ★ · tổng số phòng, số tầng, khoảng giá theo loại phòng · tiện ích chung · **nội quy** (giờ giấc ra vào, nuôi thú cưng, ở qua đêm, báo trước khi trả phòng) · mô tả · địa chỉ + bản đồ + nút **Chỉ đường** · **chủ trọ** (tên, huy hiệu, tỷ lệ phản hồi, tỷ lệ giữ đúng cam kết, số điện thoại, nút **Gọi**, nút **Nhắn tin**) · ❤️ · Báo cáo.
- **Phần dưới:** danh sách phòng **còn trống** (nguyên căn thì hiện thông tin căn nhà). Phòng đã cọc / đã cho thuê hiện mờ ở cuối, có nhãn.
- **Cuối trang:** đánh giá.

**Trang phòng:** video, ảnh · tên phòng, khu, tầng, có gác không · "18 m² + gác 10 m² · Tối đa 2 người" · tiện ích · **bảng chi phí** (thuê, cọc, điện, nước, phí khác, hợp đồng tối thiểu) · ngày có thể vào ở · mô tả · dòng nhắc: *"Đi xem phòng không giữ phòng. Muốn chắc chắn giữ phòng, hãy đặt cọc trên app."*

**Nút ở cuối trang phòng** (mỗi trang chỉ 1 nút chính màu xanh đặc, còn lại là nút phụ viền):

|Phòng đang|Nút chính|Nút phụ|
|---|---|---|
|Còn trống|💳 Đặt cọc giữ phòng|💬 Nhắn tin · 📞 Gọi · 🧭 Chỉ đường|
|Còn trống, đang có người thanh toán|💳 Đặt cọc giữ phòng (mờ, "Đang có người thanh toán, thử lại sau ít phút")|💬 Nhắn tin · 📞 Gọi|
|Đã cọc / Đã cho thuê|(không có) — hiện "Đã có người cọc" / "Đã cho thuê"|❤️ theo dõi nhà trọ|

**Muốn xem tận mắt trước khi cọc:** nhắn tin hoặc gọi chủ trọ để hẹn, dùng địa chỉ và Chỉ đường để tới. App **không tạo lịch xem, không giữ phòng** cho việc đi xem: trong lúc đi xem, người khác vẫn có thể cọc trước.

### Bước 3. Đặt cọc giữ phòng

1. Bấm **"Đặt cọc giữ phòng"**. Cần đã OTP, không bị khóa cọc trên app (mục 2.5e).
2. Chọn **thời điểm nhận phòng** (ngày + giờ): cách lúc cọc **ít nhất 2 giờ**, không trước "ngày có thể vào ở" của phòng, **không quá 14 ngày** kể từ lúc cọc.
3. Đọc **chính sách cọc** (mục 2.5a) và **điều khoản nhận phòng**, tick đồng ý mới thanh toán được:
   > *"Sau thời điểm nhận phòng, nếu đã nhận phòng thành công, bạn cần xác nhận 'Đã nhận phòng'. Nếu chủ trọ không thực hiện đúng cam kết, bạn cần báo vấn đề trên hệ thống. Nếu sau 48 giờ kể từ thời điểm nhận phòng không bên nào báo có vấn đề hoặc tranh chấp, hệ thống sẽ tự động xác nhận giao dịch hoàn tất và giải ngân tiền cọc cho chủ trọ."*

   Màn hình cũng hiện **số lần hủy miễn phí còn lại**.
4. Hệ thống **khóa phòng** cho riêng mình trong thời hạn chờ thanh toán. Ai bấm cọc sau sẽ được báo "Đang có người thanh toán, thử lại sau ít phút" và **không bị tạo giao dịch**.
5. **Thanh toán** PayPal / MoMo (bản thử nghiệm) → **app giữ tiền** (`held`) → phòng chuyển **"Đã cọc"**. App lưu **bản chụp thông tin phòng lúc cọc** (giá, chi phí, tiện ích, **4 tiêu chí nội quy**, mô tả, ảnh, video) để đối chiếu nếu có khiếu nại.
6. Trong **30 phút đầu** được hủy và hoàn 100% (chỉ để sửa khi bấm nhầm), tối đa **2 lần / 30 ngày** mỗi số điện thoại. Hết quyền này thì khoản cọc không có nút hủy miễn phí.
7. **Trước thời điểm nhận phòng**, sinh viên có thể:
   - **"Yêu cầu thay đổi thời điểm nhận phòng"** — 1 lần duy nhất, phải trước thời điểm nhận phòng hơn 24 giờ (mục 2.5b).
   - **"Không thuê nữa"** — hộp xác nhận nhắc **mất cọc** → tiền chuyển cho chủ trọ, phòng mở lại.
   - App nhắc trước thời điểm nhận phòng 1 ngày.

### Bước 4. Nhận phòng (từ thời điểm nhận phòng)

Tới **thời điểm nhận phòng**, tiền cọc **vẫn đang giữ**, chưa tự chuyển. Hai bên **không cần cùng xác nhận**: sinh viên xác nhận khi thành công, mỗi bên chỉ báo khi bên kia không làm đúng cam kết.

|Ai|Nút|Kết quả|
|---|---|---|
|**Sinh viên**|✅ **"Đã nhận phòng"**|Giao dịch hoàn tất · tiền **chuyển cho chủ trọ** · phòng **Đã cho thuê** · mở đánh giá. Chủ trọ không cần xác nhận lại|
|**Sinh viên**|⚠️ **"Chủ trọ không thực hiện đúng cam kết"**|Chọn lý do + mô tả + bằng chứng → khoản cọc **Đang khiếu nại**, tiền tiếp tục giữ, admin xử lý (mục 2.5c)|
|**Chủ trọ**|⚠️ **"Sinh viên không đến nhận phòng"** (chỉ bấm được **từ T + 3 giờ tới hết T + 48 giờ**; 3 giờ đầu là **ân hạn** cho sinh viên đến trễ)|Báo ngay cho sinh viên; sinh viên có **12 giờ để phản đối**. Không phản đối → **bỏ cọc**: tiền chuyển cho chủ trọ, phòng **Còn trống**. Phản đối → **Đang khiếu nại**, admin xử lý|

Chủ trọ **không có** nút "Sinh viên đã nhận phòng". Khi chủ trọ đã báo "không đến", sinh viên **chỉ còn nút Phản đối** (không bấm "Đã nhận phòng" được nữa) — đã nhận phòng thật thì phản đối để admin xác nhận.

**Nếu không ai làm gì:**
- Sau **24 giờ** kể từ thời điểm nhận phòng (chưa ai bấm, không có khiếu nại): app gửi **nhắc cuối cùng** cho cả hai bên. Tiền vẫn giữ.
- Hết **48 giờ** kể từ thời điểm nhận phòng (vẫn không ai báo vấn đề, không có tranh chấp đang xử lý): hệ thống **tự động xác nhận giao dịch hoàn tất** theo điều khoản hai bên đã đồng ý — tiền **chuyển cho chủ trọ**, phòng **Đã cho thuê**. Đây là **tự hoàn tất do hết thời hạn phản hồi**, không có nghĩa app biết chắc sinh viên đã nhận phòng.
- Đang có khiếu nại hoặc chủ trọ đã báo "không đến" mà còn trong 12 giờ phản đối → **không tự hoàn tất**, dù đã quá 48 giờ.

### Bước 5. Đánh giá

**Nguyên tắc: một bên không thể tự tạo bằng chứng uy tín cho chính mình.** Nhãn xác minh chỉ có khi **chính sinh viên** xác nhận (hoặc admin xác minh).

|Trường hợp|Được viết đánh giá|Nhãn|Tính vào điểm nhà trọ|
|---|---|---|---|
|Cọc qua app, **sinh viên bấm "Đã nhận phòng"** (`student_confirmed`)|✅|**✔ Đã thuê**|✅ (người viết đã OTP)|
|Cọc qua app, khiếu nại / phản đối, **admin xác định sinh viên đã nhận phòng** (`admin_released`)|✅|**✔ Đã thuê**|✅|
|Cọc qua app, **tự hoàn tất sau 48 giờ** do hai bên không thao tác (`auto_complete`)|✅|**Không có nhãn** ("Chưa xác minh")|❌ — hiện riêng, màu nhạt, xếp sau|
|Cọc trực tiếp: chủ trọ nhập **số điện thoại người cọc**, **người đó bấm "Tôi đã thuê phòng này"** trong **7 ngày** sau khi chủ bấm "Đã cho thuê"|✅|**✔ Đã thuê**|✅|
|**Khiếu nại được chấp nhận** (hoàn tiền)|✅ trong **30 ngày** kể từ kết quả|**⚠ Có khiếu nại được chấp nhận**|✅|
|Bỏ cọc, "Không thuê nữa", hủy trong 30 phút, chủ hủy cọc|❌|—|—|
- **Khi nào:** từ thời điểm nhận phòng, trong vòng **12 tháng**. Được **cập nhật** trong thời hạn này (hiện "Cập nhật sau 3 tháng ở"). App chưa quản lý ngày trả phòng nên dùng mốc 12 tháng; khi có chức năng trả phòng (mục 2.24) thì đổi thành "đến khi trả phòng + 30 ngày". Vì vậy app lưu sẵn thời điểm nhận phòng và để chỗ cho ngày trả phòng.
- Đánh giá gắn với **nhà trọ**, kèm dòng "Đã ở phòng 203" và nhãn theo bảng trên.
- **5 tiêu chí:** Đúng mô tả · An ninh · Vệ sinh · Chủ trọ · Giá hợp lý.
- **Thẻ nhanh:** Yên tĩnh · Chủ dễ tính · Điện nước ổn định · Gần chợ · An ninh tốt · Hay cúp nước · Ồn ào · Ẩm thấp.
- **Điểm nhà trọ** = trung bình các đánh giá **có nhãn** (✔ Đã thuê / ⚠ Có khiếu nại được chấp nhận) của người đã OTP. Đánh giá không nhãn (khoản cọc tự hoàn tất) vẫn hiện, ghi "Chưa xác minh", không tính vào điểm.

**Những việc khác của sinh viên:**
- **❤️ Lưu nhà trọ:** được báo khi nhà trọ có phòng trống mới hoặc giảm giá.
- **Chat:** câu hỏi nhanh "Phòng còn trống không ạ?", "Em qua xem phòng lúc … được không ạ?", "Giá đã gồm điện nước chưa ạ?", "Có chỗ để xe không ạ?"; có nút Đặt cọc ngay trong chat.
- **Trang "Của tôi":** khoản cọc (đếm ngược tới thời điểm nhận phòng, các nút ở Bước 3 – 4) · nhà trọ đã lưu · phòng đã thuê (viết đánh giá, xác nhận "Tôi đã thuê phòng này" với cọc trực tiếp) · vi phạm và kháng nghị (mục 2.15).

## 2.5 Luật và tình huống đặc biệt

### a) Chính sách cọc trên app (một chính sách cho mọi phòng)

|Trường hợp|Tiền cọc|Phòng|
|---|---|---|
|Sinh viên hủy **trong 30 phút** sau khi cọc (còn quyền hủy miễn phí: tối đa 2 lần / 30 ngày)|**Hoàn 100%**|Còn trống|
|Sinh viên bấm **"Không thuê nữa"** trước thời điểm nhận phòng|**Không hoàn** — chuyển cho chủ trọ, bù cho việc giữ phòng|Còn trống|
|Sinh viên yêu cầu thay đổi thời điểm nhận phòng, **chủ trọ không trả lời trong 24 giờ**|**Hoàn 100%**, hủy giao dịch; chủ trọ bị ghi vi phạm|Còn trống|
|Sinh viên bấm **"Đã nhận phòng"**|Chuyển cho chủ trọ|Đã cho thuê|
|Chủ trọ báo **"Sinh viên không đến nhận phòng"**, sinh viên không phản đối trong 12 giờ (hoặc admin xác nhận) → **bỏ cọc**|Chuyển cho chủ trọ|Còn trống|
|**Không ai làm gì** tới 48 giờ sau thời điểm nhận phòng → **tự hoàn tất**|Chuyển cho chủ trọ|Đã cho thuê|
|**Chủ trọ không thực hiện đúng cam kết** (khiếu nại được chấp nhận)|**Hoàn 100%**; chủ trọ bị ghi vi phạm|Theo thực tế (Còn trống / Đã cho thuê / Tạm ẩn)|
|**Chủ trọ bấm "Hủy cọc"** (trước thời điểm nhận phòng)|**Hoàn 100%**; chủ trọ bị ghi vi phạm|Còn trống hoặc Tạm ẩn (chủ chọn)|
|Tiền đến muộn sau khi hết hạn thanh toán|**Tự hoàn 100%** (mục 2.6)|Không đổi|
|Admin kết luận chủ trọ lừa đảo|**Tự hoàn 100%** (mục 2.14)|Tạm ẩn|

Nguyên tắc: **ai sai người đó chịu.** Tiền cọc qua app **chưa chuyển cho chủ trọ** cho tới khi giao dịch hoàn tất, nên khi chủ trọ sai thì hoàn thẳng từ khoản đang giữ, app không phải tự bỏ tiền. **Không khoản cọc nào giữ phòng vô thời hạn:** mọi khoản cọc đều kết thúc chậm nhất 48 giờ sau thời điểm nhận phòng, trừ khi đang khiếu nại hoặc đang trong 12 giờ phản đối "không đến" (khi đó chậm nhất T + 60 giờ, hoặc tới khi admin quyết).

### b) Yêu cầu thay đổi thời điểm nhận phòng

- **Chỉ sinh viên** được gửi, **tối đa 1 lần cho mỗi khoản cọc**. Đây là **1 lần gửi**, không phải 1 lần thay đổi thành công.
- **Chỉ gửi được khi còn hơn 24 giờ** tới thời điểm nhận phòng hiện tại. Trong 24 giờ cuối, nút bị khóa.
  > Ví dụ: nhận phòng 10/10 lúc 14:00 → phải gửi yêu cầu **trước** 09/10 lúc 14:00.
- Thời điểm mới có thể **sớm hơn hoặc muộn hơn** T cũ, miễn là: cách lúc gửi ít nhất 24 giờ · không trước "ngày có thể vào ở" của phòng · **không quá 14 ngày** sau thời điểm nhận phòng ban đầu.
  > Ví dụ: T cũ = 10/10 lúc 14:00, gửi yêu cầu lúc 08/10 10:00 → đề xuất 09/10 lúc 14:00 (nhận sớm) hoặc 12/10 lúc 14:00 (nhận muộn) đều được; chỉ có hiệu lực khi chủ trọ đồng ý.
- **Chủ trọ có 24 giờ** kể từ lúc nhận yêu cầu để **Đồng ý** hoặc **Từ chối**. Trong lúc chờ, tiền vẫn giữ, sinh viên không gửi được yêu cầu khác.

|Chủ trọ|Kết quả|
|---|---|
|**Đồng ý**|Thời điểm mới thành cam kết chính thức; phòng tiếp tục giữ, tiền tiếp tục giữ; sinh viên hết quyền yêu cầu thay đổi|
|**Từ chối**|Thời điểm cũ vẫn hiệu lực; sinh viên hết quyền yêu cầu thay đổi; không tới nhận thì xử lý như bỏ cọc|
|**Không trả lời trong 24 giờ**|Coi là lỗi của chủ trọ: **hủy giao dịch, hoàn 100% cho sinh viên**, không chuyển tiền cho chủ; phòng về **Còn trống**; ghi vi phạm "không trả lời yêu cầu thay đổi"|

Vì yêu cầu phải gửi trước hơn 24 giờ và chủ trọ có đúng 24 giờ, hạn trả lời luôn **trước** thời điểm nhận phòng cũ; và vì thời điểm mới cách lúc gửi ít nhất 24 giờ, hạn trả lời cũng **không muộn hơn** thời điểm mới (kể cả khi đề xuất nhận sớm).

### c) Khiếu nại "Chủ trọ không thực hiện đúng cam kết"

1. **Lý do:** phòng đã cho người khác thuê / cọc (kể cả chủ nhận cọc trực tiếp mà không cập nhật) · chủ trọ không giao phòng · phòng thực tế **sai nghiêm trọng so với bản chụp thông tin lúc cọc** · **nội quy không đúng với thông tin đã khai tại thời điểm giao dịch** (nội quy đã sai ngay lúc cọc / nhận phòng, mục 2.5k) · vi phạm khác thuộc trách nhiệm chủ trọ.
2. **Gửi khi:** từ thời điểm nhận phòng tới hết 48 giờ sau đó, khi khoản cọc chưa hoàn tất. Hoặc sinh viên **phản đối** "Sinh viên không đến nhận phòng" trong 12 giờ.
3. Bắt buộc **mô tả + ảnh / video quay trong app, có GPS tại nhà trọ**.
4. Khoản cọc → **Đang khiếu nại**, tiền tiếp tục giữ. **Không bao giờ chuyển tiền khi đang khiếu nại.**
5. Chủ trọ trả lời kèm bằng chứng trong **24 giờ**. Không trả lời → admin quyết dựa trên bằng chứng của sinh viên.
6. **Admin quyết:**
   - Chủ trọ vi phạm → **hoàn 100%** cho sinh viên, ghi vi phạm chủ trọ, phòng về trạng thái thực tế.
   - Sinh viên thực ra đã nhận phòng → chuyển tiền cho chủ trọ, phòng **Đã cho thuê**.
   - Sinh viên thực ra không đến → **bỏ cọc**: chuyển tiền cho chủ trọ, phòng **Còn trống**.
7. Khiếu nại treo quá **72 giờ** → cờ khẩn.
8. Khiếu nại sai sự thật (bị admin bác) **3 lần / 30 ngày** → khóa cọc trên app 30 ngày (kháng nghị được, mục 2.15).

### d) Cọc trực tiếp ngoài app

- Khi có người cọc tiền mặt trực tiếp (kể cả người không dùng app), **chủ trọ phải vào app** bấm **"Xác nhận phòng đã có người cọc trực tiếp / ngoài ứng dụng"** trên phòng đang **Còn trống** → phòng **Đã cọc**, không ai cọc qua app được nữa.
- Chủ trọ nhập **ngày nhận phòng dự kiến**, và **số điện thoại người cọc** nếu người đó có tài khoản (tùy chọn, để họ được đánh giá).
- Sau đó chủ trọ bấm **"Đã cho thuê"** (phòng → Đã cho thuê) hoặc **"Người cọc không thuê nữa"** (phòng → Còn trống). Quá ngày nhận phòng dự kiến **3 ngày** mà chưa cập nhật → app nhắc chủ trọ. App **không tự đổi** trạng thái vì không biết thực tế.
- App **không giữ, không hoàn, không giải quyết khiếu nại tiền** cho khoản cọc trực tiếp.
- **Chủ trọ nhận cọc trực tiếp mà không cập nhật, để sinh viên khác cọc qua app:** sinh viên đó khiếu nại (mục 2.5c, lý do "phòng đã cho người khác"). Admin xác định chủ vi phạm → **hoàn 100%** khoản cọc qua app đang giữ, ghi vi phạm chủ trọ.

### e) Chống lạm dụng và vi phạm

|Phía|Luật|
|---|---|
|**Sinh viên**|Hủy cọc miễn phí tối đa **2 lần / 30 ngày** (không phải vi phạm, không kháng nghị) · khiếu nại sai sự thật 3 lần / 30 ngày → khóa cọc trên app 30 ngày · báo cáo sai (mục 2.10). Bỏ cọc **không** tính vi phạm vì đã mất tiền cọc. Mọi khóa gắn với số điện thoại, kháng nghị được (mục 2.15)|
|**Chủ trọ**|**Vi phạm** gồm: bấm "Hủy cọc" · không trả lời yêu cầu thay đổi trong 24 giờ · khiếu nại của sinh viên được chấp nhận · **admin xác nhận nội quy đã sai tại thời điểm giao dịch** (mục 2.5k; chủ đổi nội quy sau đó không tính). Mỗi lần: cảnh cáo, giảm **tỷ lệ giữ đúng cam kết**. **3 vi phạm / 90 ngày → khóa đăng tin / nhận cọc trong Tìm trọ 30 ngày** (kháng nghị được). Lừa đảo, giấy tờ giả → đề nghị khóa cả tài khoản (mục 4.4)|

### f) Lý do báo cáo riêng của Tìm trọ
Phòng không tồn tại / ảnh không đúng · Sai giá, sai mô tả · **Nội quy không đúng với thông tin đã khai tại thời điểm giao dịch** (khi giao dịch cọc đã hoàn tất; mục 2.5k, **không giới hạn thời gian gửi**) · Đã cho thuê / đã có người cọc vẫn đăng · **Yêu cầu chuyển cọc ngoài app** *(ưu tiên cao)*.

### g) Trạng thái khoản cọc trên app

|Tên|Mã|Nghĩa|
|---|---|---|
|Chờ thanh toán|`pending_payment`|Đã tạo, phòng đang bị khóa thanh toán|
|Hết hạn thanh toán|`expired`|Quá hạn chờ thanh toán hoặc thanh toán thất bại|
|Đang giữ tiền|`held`|Đã trả, app đang giữ, phòng `reserved`. Có thể kèm **yêu cầu thay đổi đang chờ** hoặc **báo "không đến" đang chờ phản đối** (không phải trạng thái riêng)|
|Hủy trong 30 phút|`cancelled_grace`|Sinh viên hủy trong 30 phút (còn quyền hủy miễn phí), đã hoàn 100%|
|Đang khiếu nại|`disputed`|Tiền tạm giữ, chờ admin|
|Đã chuyển cho chủ trọ|`released`|Hoàn tất thuê (sinh viên bấm "Đã nhận phòng", tự hoàn tất sau 48 giờ, hoặc admin xác nhận sinh viên đã nhận phòng)|
|Đã hoàn|`refunded`|Hoàn cho sinh viên|
|Mất cọc|`forfeited`|Sinh viên bấm "Không thuê nữa", hoặc **bỏ cọc** (không đến nhận phòng); tiền chuyển cho chủ trọ|

Mỗi khoản cọc kết thúc có **lý do kết thúc**: `grace_cancel` · `student_confirmed` (Đã nhận phòng) · `auto_complete` (hết 48 giờ) · `student_changed_mind` · `student_no_show` (bỏ cọc) · `owner_cancelled` · `owner_no_reply_reschedule` · `owner_violation` · `admin_released` · `system_late_payment` · `admin_fraud`.

### h) Bảng chuyển trạng thái khoản cọc

Gọi **T** = thời điểm nhận phòng hiện hành.

|Từ|Sự kiện / ai bấm|Điều kiện, hạn|Sang|Tiền|Phòng|Báo ai|
|---|---|---|---|---|---|---|
|(mới)|SV bấm cọc|Đã OTP; không bị khóa cọc; phòng `available`, không khóa thanh toán; số tiền ≤ 1 tháng thuê; T hợp lệ; đã đồng ý chính sách và điều khoản nhận phòng. Ghi khoản cọc **có quyền hủy miễn phí hay không** (số điện thoại này đã dùng < 2 lần trong 30 ngày gần nhất)|`pending_payment`|Chưa thu|Đặt khóa thanh toán|—|
|`pending_payment`|Cổng thanh toán báo đã trả|Trước hạn chờ thanh toán|`held`|Giữ|`reserved`, gỡ khóa; lưu bản chụp thông tin phòng|SV, chủ trọ|
|`pending_payment`|Hết hạn chờ / thanh toán thất bại|—|`expired`|Không thu|Gỡ khóa, giữ `available`|SV|
|`expired`|Tiền đến muộn|—|`refunded` (`system_late_payment`)|Hoàn 100%|Không đổi|SV|
|`held`|SV bấm Hủy|Trong 30 phút kể từ `held`, có quyền hủy miễn phí|`cancelled_grace` (`grace_cancel`)|Hoàn 100%|`available`|SV, chủ trọ|
|`held`|SV bấm "Không thuê nữa"|Hết quyền hủy miễn phí, trước T|`forfeited` (`student_changed_mind`)|Chuyển chủ trọ|`available`|SV, chủ trọ|
|`held`|Chủ trọ bấm "Hủy cọc"|Trước T|`refunded` (`owner_cancelled`)|Hoàn 100%|`available` hoặc `hidden` (chủ chọn)|SV, chủ trọ|
|`held`|SV gửi yêu cầu thay đổi|Chưa dùng quyền thay đổi; còn > 24 giờ tới T|`held` (ghi yêu cầu, hạn trả lời + 24 giờ)|Giữ|Giữ `reserved`|Chủ trọ|
|`held` (có yêu cầu thay đổi)|Chủ trọ Đồng ý|Trong 24 giờ|`held` (T = thời điểm mới)|Giữ|Giữ `reserved`|SV|
|`held` (có yêu cầu thay đổi)|Chủ trọ Từ chối|Trong 24 giờ|`held` (giữ T cũ)|Giữ|Giữ `reserved`|SV|
|`held` (có yêu cầu thay đổi)|Hết 24 giờ chủ không trả lời|—|`refunded` (`owner_no_reply_reschedule`)|Hoàn 100%|`available`|SV, chủ trọ|
|`held`|SV bấm "Đã nhận phòng"|Từ T, không đang có báo "không đến"|`released` (`student_confirmed`)|Chuyển chủ trọ|`rented`|SV, chủ trọ|
|`held`|SV bấm "Chủ trọ không thực hiện đúng cam kết"|Từ T tới T + 48 giờ, có bằng chứng|`disputed`|Tạm giữ|Giữ `reserved`|Chủ trọ, admin|
|`held`|Chủ trọ bấm "Sinh viên không đến nhận phòng"|Từ **T + 3 giờ** tới T + 48 giờ (ân hạn 3 giờ)|`held` (ghi báo "không đến", hạn phản đối + 12 giờ)|Giữ|Giữ `reserved`|SV|
|`held` (có báo "không đến")|SV phản đối|Trong 12 giờ, có lý do / bằng chứng|`disputed`|Tạm giữ|Giữ `reserved`|Chủ trọ, admin|
|`held` (có báo "không đến")|Hết 12 giờ không phản đối|—|`forfeited` (`student_no_show`)|Chuyển chủ trọ|`available`|SV, chủ trọ|
|`held` (không có báo, không có yêu cầu thay đổi)|**Hệ thống:** T + 24 giờ|—|(giữ nguyên)|Giữ|—|SV, chủ trọ (nhắc cuối)|
|`held` (không có báo "không đến")|**Hệ thống:** T + 48 giờ|—|`released` (`auto_complete`)|Chuyển chủ trọ|`rented`|SV, chủ trọ|
|`held` / `disputed`|Admin kết luận chủ trọ lừa đảo|Chưa có xác nhận / bằng chứng SV nhận phòng (ngoại lệ có chủ đích, mục 2.14). Khoản đã `released` không bị đảo ngược|`refunded` (`admin_fraud`)|Hoàn 100%|`hidden`|SV, chủ trọ|
|`disputed`|Admin: chủ trọ vi phạm|—|`refunded` (`owner_violation`)|Hoàn 100%|Theo thực tế|SV, chủ trọ|
|`disputed`|Admin: SV đã nhận phòng|—|`released` (`admin_released`)|Chuyển chủ trọ|`rented`|SV, chủ trọ|
|`disputed`|Admin: SV không đến|—|`forfeited` (`student_no_show`)|Chuyển chủ trọ|`available`|SV, chủ trọ|
|`disputed`|Quá 72 giờ chưa quyết|—|(không đổi, gắn cờ khẩn)|Tạm giữ|—|Admin|

### i) Hai người thao tác cùng lúc

Chỉ chuyển trạng thái khi trạng thái hiện tại còn đúng như lúc bấm; thao tác đến trước thắng, thao tác sau được báo "Thông tin đã thay đổi, vui lòng tải lại" (quy tắc chung ở mục 2.18).

|Tình huống|Kết quả|
|---|---|
|Hai sinh viên bấm cọc cùng một phòng|Người bấm trước được vào thanh toán; người sau được báo "Đang có người thanh toán", **không có giao dịch nào được tạo**, không bị trừ tiền|
|Cổng thanh toán ghi nhận thành công **sau** hạn, hoặc khi phòng đã thuộc người khác|Không nhận, **tự hoàn 100%**. Một phòng không bao giờ có 2 khoản cọc cùng lúc|
|Chủ trọ bấm "đã có người cọc trực tiếp" đúng lúc sinh viên đang thanh toán|Chủ trọ bị chặn tới khi khóa thanh toán gỡ. Nếu sinh viên trả thành công, chủ trọ phải "Hủy cọc" (hoàn 100%, tính vi phạm) nếu thật sự đã nhận cọc trực tiếp trước đó|
|Sinh viên bấm "Đã nhận phòng" đúng lúc chủ trọ bấm "Sinh viên không đến nhận phòng"|Thao tác đến trước thắng. Nếu chủ báo trước, sinh viên chỉ còn nút **Phản đối**|
|Hết 48 giờ tự hoàn tất đúng lúc sinh viên gửi khiếu nại|Chỉ một bên thắng: khiếu nại được ghi trước thì không tự hoàn tất|
|Chủ trọ "Hủy cọc" đúng lúc sinh viên "Không thuê nữa"|Thao tác đến trước thắng, thao tác sau được báo đã thay đổi|
|Đang có yêu cầu thay đổi chờ trả lời thì sinh viên "Không thuê nữa" hoặc chủ trọ "Hủy cọc"|Được phép; khoản cọc kết thúc theo thao tác đó, yêu cầu thay đổi **tự đóng**, không tính vi phạm "không trả lời yêu cầu thay đổi"|
|Chủ trọ bấm Đồng ý / Từ chối đúng lúc hết 24 giờ|Thao tác đến trước thắng: chủ trả lời được ghi trước thì theo trả lời; hết hạn được ghi trước thì hoàn 100%|

### j) Kiểm tra giấy tờ nhà (riêng Tìm trọ)
Admin đối chiếu: tên trên giấy tờ nhà khớp **họ tên đã xác thực** (mục 4.2) (hoặc có hợp đồng thuê nếu cho thuê lại) · địa chỉ khớp vị trí ghim và GPS · video quay tại nhà trọ khớp ảnh. Mức chắc chắn trung bình, nghi ngờ thì admin gọi điện hoặc tới tận nơi. Không khớp → từ chối. Phát hiện giả → ẩn nhà trọ, **đề nghị admin danh tính** khóa cả tài khoản + chặn CCCD và số điện thoại (mục 4.4).

### k) Nội quy không đúng với thông tin đã khai tại thời điểm giao dịch

**Bản chụp nội quy lúc cọc:** khi cọc thành công, bản chụp thông tin phòng lưu kèm **4 tiêu chí nội quy** lúc đó (giờ giấc ra vào, nuôi thú cưng, ở qua đêm, thời gian báo trước khi trả phòng). Bản chụp chỉ ghi nhận **nội quy chủ trọ đã công bố lúc sinh viên quyết định cọc**. Chủ trọ sửa nội quy trên tin sau đó không làm thay đổi bản chụp này.

Bản chụp **không phải cam kết nội quy giữ nguyên suốt thời gian thuê**. Admin phân biệt hai trường hợp:

|Trường hợp|Ví dụ|Xử lý|
|---|---|---|
|**1. Nội quy đã sai ngay lúc giao dịch / nhận phòng** → chủ trọ **khai sai**|Lúc cọc tin ghi "Cho phép nuôi thú cưng", tới nhận phòng chủ đã áp "Không cho nuôi". Hoặc sinh viên phát hiện sau vài ngày nhưng có bằng chứng quy định "không cho nuôi" **đã có từ trước hoặc ngay lúc nhận phòng**|Sinh viên khiếu nại / báo cáo **"Nội quy không đúng với thông tin đã khai tại thời điểm giao dịch"**. Admin đối chiếu bản chụp lúc cọc · thời điểm nội quy thực tế bắt đầu áp dụng · bằng chứng các bên. Xác định khai sai → **1 vi phạm** cho chủ trọ (luật vi phạm hiện có, mục 2.5e); tiền xử lý theo bảng bên dưới|
|**2. Nội quy lúc đầu đúng, chủ đổi sau một thời gian** → **không phải khai sai**|Lúc cọc và nhận phòng "Cho phép nuôi thú cưng", sinh viên được nuôi thật. 8 tháng sau thú cưng ảnh hưởng phòng khác, chủ đổi thành "Không cho phép"|**Không** mặc định là khai sai · **không** tự ghi vi phạm chỉ vì nội quy hiện tại khác bản chụp · **không** dùng bản chụp cũ để kết luận chủ gian dối · **không** hoàn tiền cọc|

**Tiền cọc trong trường hợp 1:**

|Lúc phát hiện|Sinh viên dùng|Tiền|
|---|---|---|
|**Tiền cọc còn đang giữ** (chưa bấm "Đã nhận phòng", chưa tự hoàn tất)|**Khiếu nại** "Chủ trọ không thực hiện đúng cam kết" → lý do "Nội quy không đúng với thông tin đã khai tại thời điểm giao dịch" + mô tả + bằng chứng (mục 2.5c)|Theo cơ chế khiếu nại hiện có: chủ sai đủ nghiêm trọng → **hoàn 100%**|
|**Giao dịch đã hoàn tất, tiền đã chuyển cho chủ trọ**|**Báo cáo** với cùng lý do: chọn tiêu chí bị sai · mô tả · bằng chứng (nếu có) · thời điểm phát hiện / xảy ra|**Không** mở lại khoản cọc, **không** thu hồi, **không** hoàn tiền. Admin chỉ xử lý vi phạm và yêu cầu chủ sửa nội quy trên tin nếu đang hiển thị sai|

**Không có hạn cứng để báo cáo** (không giới hạn 30 ngày hay 12 tháng). Nhưng báo cáo chỉ được chấp nhận khi chứng minh được nội quy **đã sai từ lúc giao dịch / nhận phòng**; báo cáo càng xa thời điểm cọc thì càng cần bằng chứng rõ.

**Phạm vi:** app chỉ dùng bản chụp để bảo vệ sinh viên trước trường hợp *nội quy công bố khi cọc không đúng với thực tế lúc giao dịch / nhận phòng*. App **không** quản lý việc thay đổi nội quy, hợp đồng thuê hay tranh chấp trong suốt thời gian ở.

## 2.6 Thanh toán và giữ tiền

> Phần thanh toán **riêng của module Tìm trọ**: cổng thanh toán, khoản tiền, ví người bán đều tách khỏi module khác.

**Cách hoạt động:**
```
Sinh viên trả tiền  →  App GIỮ tiền  →  Giao dịch hoàn tất  →  Chuyển cho chủ trọ
                                     →  Chủ trọ sai       →  Hoàn cho sinh viên
```

Dùng cho **đặt cọc phòng trên app**. Khi nào chuyển, khi nào hoàn: **mục 2.5a, 2.5h**.

- **Cổng thanh toán:** PayPal hoặc MoMo, **bản thử nghiệm** — chạy đủ luồng nhưng không có tiền thật.
- Chưa trả tiền trong **thời hạn chờ thanh toán** (bảng 2.16) → giao dịch hết hạn.
- App **chỉ ghi nhận "đã thanh toán" khi cổng thanh toán báo về** và chữ ký hợp lệ; không tin thông tin từ điện thoại.
- Bấm thanh toán 2 lần **không bị trừ tiền 2 lần**; cổng báo "đã trả" 2 lần chỉ ghi nhận lần đầu.
- **Đúng hạn hay trễ hạn xét theo thời điểm cổng thanh toán ghi nhận giao dịch thành công**, không theo lúc cổng báo về hệ thống. Ví dụ: hạn 14:00, cổng ghi nhận thành công 13:59:58, báo về hệ thống 14:00:05 → **đúng hạn**, không coi là trễ. Vì vậy khi tới hạn, hệ thống **hỏi lại cổng thanh toán** trước khi cho giao dịch hết hạn / gỡ khóa. Khoảng chênh kỹ thuật (nếu sandbox cần) để trong file cấu hình, không ghi cứng vào luật.
- **Tiền đến muộn:** cổng thanh toán ghi nhận giao dịch thành công **sau** hạn, hoặc sau khi giao dịch đã bị hủy → **không nhận**, **tự hoàn 100%**, ghi lý do, báo sinh viên.
- **PayPal:** giá hiển thị bằng VND, lúc thanh toán quy đổi sang USD (theo hiểu biết, PayPal không hỗ trợ VND — cần kiểm tra lại). Lưu **tỷ giá** và **số USD đã thu**; hoàn tiền (luôn 100% trong module này) trả đúng số USD đã thu.
- **Khoản đang giữ không bao giờ tự chuyển đi khi đang có khiếu nại.**
- **Trạng thái của giao dịch và trạng thái của tiền là hai chuyện riêng:** ví dụ khoản cọc đang khiếu nại thì tiền vẫn đang giữ; khoản cọc đã chuyển cho chủ trọ thì tiền mới `released`. **Cọc trực tiếp không có khoản tiền nào qua app** nên không bao giờ có giữ tiền, chuyển tiền hay hoàn tiền.
- Chủ trọ xem được số tiền **đang giữ** và **đã nhận** của mình trong module này.

## 2.7 Tìm theo khoảng cách và bản đồ

**Chọn điểm để tính khoảng cách** ("điểm gốc"), một trong hai:
- 📍 **Vị trí hiện tại** của điện thoại.
- 🗺️ **Chọn điểm trên bản đồ** — gõ địa chỉ hoặc kéo ghim. Dùng khi muốn tìm quanh một nơi khác chỗ đang đứng, ví dụ sinh viên đang ở quê muốn tìm trước quanh khu mình sẽ ở.

**Quy định:**
- Không cho phép định vị → app gợi ý chọn trên bản đồ, các bộ lọc khác vẫn dùng bình thường.
- App nhớ điểm gốc lần trước (riêng trong module này).
- Bán kính chọn và cách tính: bảng 2.16. Khoảng cách tính theo **đường thẳng**.

**Chế độ bản đồ:** chuyển qua lại giữa danh sách và bản đồ, dùng chung bộ lọc. Ghim hiện giá; nhiều ghim gần nhau gom thành 1 cụm có số; bấm ghim hiện thẻ nhỏ; kéo bản đồ sang chỗ khác thì hiện nút "Tìm ở khu vực này".

## 2.8 Chat

> Chat **riêng của module Tìm trọ**, không lẫn với tin nhắn của module khác.

- Nhắn tin 1–1 giữa sinh viên và chủ trọ. **Mỗi cặp chỉ có 1 cuộc trò chuyện** trong module này.
- Mở chat từ một phòng hay một khoản cọc thì app **tự gắn thẻ thông tin** phòng (ảnh, tên, giá) vào cuộc chat.
- Gửi chữ, gửi ảnh, có trạng thái **Đã gửi / Đã xem**, có thông báo khi có tin mới.
- **Câu hỏi nhanh** cho sinh viên (mục 2.4), **mẫu trả lời nhanh** cho chủ trọ.
- **Cảnh báo lừa đảo:**
  - Trước khi quét, tin nhắn được **chuẩn hóa**: chữ thường, **bỏ dấu**, bỏ ký tự đặc biệt và khoảng trắng thừa (để "Chuyển khoản", "chuyen khoan", "c.h.u.y.e.n k.h.o.a.n" đều bị bắt).
  - Từ khóa: chuyển khoản · CK · cọc trước · số tài khoản · STK · zalo · QR · momo · ví điện tử · ngân hàng. **Danh sách từ khóa đặt ở file cấu hình**, không viết cứng.
  - **Cách khớp:** "CK", "STK", "QR" phải **khớp nguyên từ** (không bắt "check", "tick"…). "momo" **chỉ cảnh báo khi đi cùng ngữ cảnh chuyển tiền** (ví dụ "chuyển momo", "momo trước", "qua momo cho anh") — vì MoMo cũng là cổng thanh toán hợp lệ trên app.
  - Khớp từ khóa → app hiện: *"⚠️ Hãy đặt cọc qua app để được bảo vệ. Không chuyển tiền cọc ngoài app."*
- Có nút **Chặn** (người bị chặn không nhắn được nữa) và **Báo cáo**.
- **Tỷ lệ phản hồi** của chủ trọ = phần trăm cuộc trò chuyện mới được trả lời trong 24 giờ (tính 30 ngày gần nhất), hiện công khai.

## 2.9 Đánh giá

> Đánh giá **riêng của module Tìm trọ**: điểm, nhãn và danh sách đánh giá không dính gì tới module khác. Ai được viết và điểm tính thế nào: **mục 2.4 Bước 5**.

- Chấm 1–5 sao theo **5 tiêu chí**, điểm của một đánh giá là trung bình các tiêu chí đã chấm.
- Chọn thêm **thẻ nhanh** (ví dụ "Yên tĩnh", "Chủ dễ tính").
- Nhận xét **ít nhất 20 ký tự**, tối đa **5 ảnh**.
- Chủ trọ **trả lời công khai 1 lần**, **không xóa được** đánh giá, chỉ báo cáo nếu vi phạm.
- Chủ trọ **không được đánh giá** nhà trọ của mình.
- **Nhãn xác minh** chỉ được tính vào điểm và xếp hạng khi người viết **đã xác thực số điện thoại**.

## 2.10 Báo cáo vi phạm

- Báo cáo được: nhà trọ, phòng, người dùng, đánh giá, tin nhắn. Lý do riêng của module: **mục 2.5f**.
- **Báo cáo được tính** khi người báo cáo đã xác thực số điện thoại và tài khoản đã tạo **ít nhất 7 ngày**.
- **Không tự ẩn chỉ vì số lượng báo cáo** (tránh bị báo cáo hàng loạt / đối thủ cố tình báo cáo). Số báo cáo chỉ là **tín hiệu để ưu tiên kiểm tra**: **3 người khác nhau, khác số điện thoại** cùng báo cáo một **nhà trọ hoặc phòng** → **gắn cờ**, đưa lên đầu hàng chờ admin. Tin vẫn hiện bình thường tới khi admin quyết; admin mới là người ẩn tin (nếu có căn cứ), giao dịch đang chạy đi tiếp theo mục 2.14.
- **Không tự ghi vi phạm** cho chủ chỉ vì đạt số lượng báo cáo; chỉ ghi khi admin xác định có vi phạm.
- **Đánh giá và tin nhắn không tự ẩn** khi đủ 3 báo cáo: chỉ gắn cờ gửi admin, đánh giá **vẫn hiển thị**. **Ngoại lệ:** 3 báo cáo cùng lý do **"xúc phạm / lộ thông tin cá nhân"** → **ẩn tạm** đánh giá / tin nhắn đó chờ admin (để che nhanh thông tin cá nhân). Ẩn tạm **không** phải xác nhận vi phạm, **không** tự ghi vi phạm hay khóa tài khoản; admin **khôi phục** nếu báo cáo không hợp lệ.
- Báo cáo **nghiêm trọng** (lừa đảo, yêu cầu chuyển tiền ngoài app, hành vi có nguy cơ gây thiệt hại trực tiếp cho người dùng) → **ưu tiên cao**, admin kiểm tra sớm. Biện pháp tạm thời (ẩn tin) chỉ do admin quyết dựa trên bằng chứng, không dựa vào số báo cáo.
- Người báo cáo được báo kết quả.
- Mỗi người báo cáo **tối đa 10 lần / ngày** trong module này. **Báo cáo sai 3 lần** (admin bác bỏ) → khóa chức năng báo cáo của module này 30 ngày.

## 2.11 Thông báo

- Thông báo đẩy trên điện thoại + danh sách thông báo **riêng của module** (biểu tượng chuông trong module), đánh dấu đã đọc.
- **Cài đặt thông báo của module:** tắt được từng nhóm (nhà trọ đã lưu có phòng trống / giảm giá, tin nhắn, nhắc đánh giá…), **trừ** thông báo về tiền cọc, nhận phòng, yêu cầu thay đổi, khiếu nại, kháng nghị.
- Máy tính: mục 2.19 (giới hạn theo nền tảng).

|Gửi cho|Khi nào|
|---|---|
|**Sinh viên**|Cọc thành công (kèm thời điểm nhận phòng, hạn hủy miễn phí) · thanh toán hết hạn · tiền đến muộn đã được hoàn · nhắc thời điểm nhận phòng (trước 1 ngày) · hạn cuối gửi yêu cầu thay đổi sắp tới · chủ trọ **đồng ý / từ chối** yêu cầu thay đổi · yêu cầu thay đổi **quá hạn không được trả lời** → đã hoàn 100% · **chủ trọ hủy cọc** (đã hoàn 100%) · tới thời điểm nhận phòng (nhắc bấm "Đã nhận phòng" hoặc báo vấn đề) · **chủ trọ báo "Sinh viên không đến nhận phòng"** (còn 12 giờ phản đối, nhắc lại khi còn 2 giờ) · **nhắc cuối cùng** sau T + 24 giờ · đã tự hoàn tất sau 48 giờ · tiền đã chuyển / đã hoàn / mất cọc · chủ trọ trả lời khiếu nại · kết quả khiếu nại · được viết đánh giá · **chủ trọ ghi bạn là người cọc trực tiếp** (kèm cảnh báo không được app bảo vệ, nhắc bấm "Tôi đã thuê phòng này") · nhà trọ đã lưu có phòng trống, giảm giá · sắp bị khóa cọc trên app · kết quả kháng nghị|
|**Chủ trọ**|Có người cọc (kèm thời điểm nhận phòng) · sinh viên hủy trong 30 phút · sinh viên "Không thuê nữa" (đã nhận tiền cọc) · **có yêu cầu thay đổi** (trả lời trong 24 giờ, nhắc lại khi còn 6 giờ và 1 giờ, kèm cảnh báo không trả lời sẽ hoàn 100% và bị ghi vi phạm) · nhắc thời điểm nhận phòng (trước 1 ngày) · sinh viên bấm "Đã nhận phòng" (đã nhận tiền) · **nhắc cuối cùng** sau T + 24 giờ · đã tự hoàn tất sau 48 giờ (đã nhận tiền) · có khiếu nại (trả lời trong 24 giờ) · sinh viên phản đối "không đến" · sinh viên không phản đối → bỏ cọc (đã nhận tiền) · kết quả khiếu nại · bị ghi vi phạm · **cọc trực tiếp quá ngày nhận dự kiến 3 ngày chưa cập nhật** · kết quả duyệt (nhà trọ, phòng, bản chỉnh sửa) · tin sắp hết hạn · đánh giá mới · tin bị báo cáo · sắp bị khóa đăng tin / nhận cọc · kết quả kháng nghị|
|**Admin Tìm trọ**|Hồ sơ / bản chỉnh sửa chờ duyệt · tin bị gắn cờ do nhiều báo cáo · báo cáo ưu tiên cao · khiếu nại cọc mới · khiếu nại có cờ khẩn · kháng nghị mới|

## 2.12 Admin

> Admin **riêng của module Tìm trọ**: hàng chờ, quyền xử lý và nhật ký tách khỏi module khác. Duyệt **danh tính người thật** là phần chung (mục 4.2).

- Admin dùng ngay trong app, chỉ tài khoản admin của module mới thấy.
- **Hàng chờ của module**, lọc theo loại: Nhà trọ · Phòng · **Chỉnh sửa chờ duyệt** · Báo cáo · Khiếu nại cọc · **Kháng nghị**.
- **Thứ tự xử lý:** khiếu nại có **cờ khẩn** (treo quá 72 giờ) → khiếu nại tiền và báo cáo ưu tiên cao → hồ sơ bị gắn cờ → còn lại theo thời gian.
- **Không bao giờ tự chuyển tiền khi đang khiếu nại.**
- Mọi quyết định đều được ghi nhật ký (ai, lúc nào, lý do).
- Admin có thể: ẩn nhà trọ / phòng · khóa chức năng của người dùng trong Tìm trọ (cọc trên app, báo cáo; khóa đăng tin / nhận cọc của chủ trọ) · quyết định khiếu nại, kháng nghị · đề nghị khóa cả tài khoản khi lừa đảo (mục 4.4).

|Việc|Admin kiểm tra|
|---|---|
|**Duyệt nhà trọ**|Giấy tờ rõ · tên khớp CCCD (hoặc có hợp đồng thuê) · địa chỉ khớp địa chỉ khai và vị trí ghim · video khu trọ khớp ảnh · GPS không bị gắn cờ, không giả lập · mô tả không có quảng cáo, số điện thoại lạ|
|**Duyệt phòng**|Ảnh, video đúng 1 phòng · khớp nhà trọ · giá hợp lý · tiền cọc ≤ 1 tháng thuê · GPS ổn|
|**Duyệt bản chỉnh sửa**|Như duyệt nhà trọ / phòng, chỉ với phần thay đổi|
|**Báo cáo nội quy không đúng tại thời điểm giao dịch**|So với **bản chụp nội quy lúc cọc** (không so với tin hiện tại) · **thời điểm nội quy thực tế bắt đầu áp dụng** · bằng chứng · chat. Nội quy đã sai từ lúc cọc / nhận phòng → ghi 1 vi phạm, yêu cầu chủ sửa tin nếu đang sai. Chủ **đổi nội quy sau khi sinh viên đã nhận phòng** → bác báo cáo, không ghi vi phạm. **Không** đụng tới tiền cọc đã chuyển (mục 2.5k)|
|**Khiếu nại cọc** (gồm cả sinh viên phản đối "không đến")|So **bản chụp thông tin phòng lúc cọc** với bằng chứng hai bên (ảnh / video có GPS), chat, lịch sử khoản cọc (yêu cầu thay đổi, lúc chủ báo "không đến", cọc trực tiếp chủ đã ghi) → chọn 1 trong 3: **chủ trọ vi phạm** (hoàn 100%, ghi vi phạm chủ, `owner_violation`) · **sinh viên đã nhận phòng** (chuyển tiền, `admin_released`) · **sinh viên không đến** (bỏ cọc, `student_no_show`). Ghi lý do. **Tính "khiếu nại sai" cho sinh viên** khi admin kết luận ngược với điều sinh viên báo: sinh viên khiếu nại chủ trọ mà admin chọn "đã nhận phòng" hoặc "không đến"; sinh viên phản đối "không đến" mà admin chọn "không đến". Sinh viên phản đối và admin chọn "đã nhận phòng" thì **không** tính|

**Lý do từ chối có sẵn:** Ảnh mờ · Giấy tờ không khớp · Video không đúng địa điểm · Ảnh không đúng thực tế · Thông tin sai lệch · Nội dung quảng cáo · Khác.

## 2.13 Khách chưa đăng nhập

- **Được xem:** danh sách, bộ lọc, bản đồ, chi tiết nhà trọ / phòng, đánh giá.
- **Bị ẩn:** số điện thoại chủ trọ.
- **Phải đăng nhập mới làm được:** chat, gọi, đặt cọc, lưu ❤️, đánh giá, báo cáo, đăng tin.
- Đăng nhập xong app **quay lại đúng trang** đang xem.

## 2.14 Ẩn, khóa khi còn giao dịch đang chạy

> **Nguyên tắc:** ẩn / khóa / hết hạn / đình chỉ **chỉ chặn giao dịch MỚI**. Giao dịch **ĐANG chạy đi tiếp** theo luật bình thường, **trừ trường hợp lừa đảo**.

"Giao dịch đang chạy" của module này gồm: khoản cọc đang chờ thanh toán / đang giữ (kể cả đang có yêu cầu thay đổi hoặc báo "không đến") / đang khiếu nại · cọc trực tiếp chưa cập nhật kết quả · khiếu nại, kháng nghị chưa xong.

|Tình huống|Xử lý|
|---|---|
|Nhà trọ bị ẩn / hết hạn khi có phòng "Đã cọc"|Khoản cọc đang chạy đi tiếp tới hết; không nhận cọc mới. Nhà trọ còn phòng đang có **khoản cọc qua app** chưa kết thúc **không bị hết hạn** (nhắc chủ trọ, xử lý sau khi xong). Cọc trực tiếp **không** được miễn hết hạn, vì app không quản lý và không xác minh được khoản cọc đó|
|Chủ trọ tự Ẩn / Xóa / Đăng lại phòng "Đã cọc" hoặc đang khóa thanh toán|**Bị chặn**, kèm giải thích (muốn bỏ cọc qua app thì dùng "Hủy cọc")|
|Admin kết luận chủ trọ **lừa đảo hoặc giấy tờ giả**|**Ngoại lệ có chủ đích của Tìm trọ:** mọi khoản cọc qua app **app còn đang giữ** (`held`, `disputed`) và **chưa có xác nhận / bằng chứng sinh viên đã nhận phòng** → **hoàn 100%** cho sinh viên (`admin_fraud`), vì nghĩa vụ giao phòng của chủ trọ chưa được xác nhận hoàn thành. Khoản cọc **đã hoàn tất** hoặc **đã xác minh sinh viên nhận phòng** trước đó (`released`) **không bị đảo ngược** chỉ vì chủ trọ bị kết luận lừa đảo; nếu chính giao dịch đó có gian lận thì xử lý riêng qua khiếu nại / admin. **Đề nghị admin danh tính** khóa cả tài khoản (mục 4.4)|
|Chủ trọ bị **khóa đăng tin / nhận cọc** trong Tìm trọ (không phải khóa cả tài khoản)|Khoản cọc đang giữ **đi tiếp bình thường** tới khi kết thúc; chỉ chặn đăng tin mới và nhận cọc mới|
|Sinh viên bị khóa cọc trên app|Chỉ chặn cọc mới; khoản cọc đang chạy đi tiếp|
|Người dùng muốn xóa tài khoản|Bị chặn nếu còn giao dịch đang chạy, tiền đang giữ, khiếu nại, kháng nghị trong module này (mục 4.1)|

## 2.15 Kháng nghị

> Kháng nghị **riêng của module Tìm trọ**. Kháng nghị khóa cả tài khoản / chặn CCCD thuộc phần chung (mục 4.4).

- **Áp dụng cho:** ẩn nhà trọ / phòng · khóa cọc trên app (sinh viên) · lần khiếu nại bị tính là sai · khóa báo cáo · **lần vi phạm của chủ trọ** · khóa đăng tin / nhận cọc (chủ trọ).
- **Không áp dụng cho:** quyết định của admin về **tiền** trong khiếu nại (hoàn / chuyển / bỏ cọc là kết quả cuối cùng của khoản cọc đó).
- **Luồng:** nút **"Kháng nghị"** ngay tại thông báo phạt hoặc trong "Của tôi" của module → ghi lý do + bằng chứng (ảnh / video chụp trong app, tối đa 3) → gửi.
- **Hạn gửi:** trong 7 ngày kể từ quyết định. **Admin của module trả lời trong 48 giờ.**
- **Mỗi quyết định chỉ kháng nghị 1 lần.**
- **Kết quả:** gỡ khóa · giữ nguyên · xóa lần vi phạm khỏi bộ đếm (lần vi phạm chuyển sang "đã gỡ").
- Đang kháng nghị thì hình phạt **vẫn còn hiệu lực** cho tới khi admin quyết.

## 2.16 Các con số quy định

> Mọi con số của module, kể cả thanh toán, báo cáo, kháng nghị. Con số của tài khoản và xác nhận người thật ở mục 4.5. **T** = thời điểm nhận phòng hiện hành.

|Quy định|Con số|
|---|---|
|Ảnh mỗi nhà trọ / phòng|3 – 10|
|Video mỗi nhà trọ / phòng|1 – 2, mỗi video 15 – 60 giây|
|Nhà trọ hết hạn sau · nhắc trước|30 ngày · 3 ngày|
|Đăng lại phòng phải quay video mới nếu video cũ quá|90 ngày|
|Mốc giá nhanh|Dưới 1tr · 1–1,5tr · 1,5–2tr · 2–3tr · trên 3tr|
|Chờ thanh toán (= khóa thanh toán phòng)|15 phút|
|Tiền cọc trên app tối đa|1 tháng tiền thuê|
|Thời điểm nhận phòng T (ngày + giờ)|≥ lúc cọc + 2 giờ · ≥ ngày có thể vào ở · ≤ lúc cọc + 14 ngày|
|Hủy cọc được hoàn 100%|Trong 30 phút kể từ khi giữ tiền · tối đa 2 lần / số điện thoại / 30 ngày|
|Nhắc thời điểm nhận phòng|Trước 1 ngày|
|Yêu cầu thay đổi thời điểm nhận phòng|1 lần gửi / khoản cọc · chỉ gửi khi còn > 24 giờ tới T · thời điểm mới **sớm hơn hoặc muộn hơn** T cũ: ≥ lúc gửi + 24 giờ, ≥ ngày có thể vào ở, ≤ T ban đầu + 14 ngày|
|Nhắc sinh viên hạn cuối gửi yêu cầu thay đổi|12 giờ trước hạn (tức T − 36 giờ), chỉ khi chưa dùng quyền thay đổi|
|Chủ trọ trả lời yêu cầu thay đổi|24 giờ · nhắc khi còn 6 giờ và 1 giờ · quá hạn → hoàn 100%|
|Ân hạn trước khi chủ trọ được báo "không đến"|3 giờ|
|Chủ trọ báo "Sinh viên không đến nhận phòng"|Từ **T + 3 giờ** tới T + 48 giờ|
|Sinh viên phản đối "không đến"|12 giờ · nhắc khi còn 2 giờ|
|Sinh viên gửi khiếu nại "Chủ trọ không thực hiện đúng cam kết"|Từ T tới T + 48 giờ|
|Nhắc cuối cùng cho hai bên|T + 24 giờ|
|Tự hoàn tất|T + 48 giờ (không tự hoàn tất khi đang khiếu nại / đang trong 12 giờ phản đối)|
|Chủ trọ trả lời khiếu nại|24 giờ|
|Khiếu nại treo → cờ khẩn|72 giờ|
|Khiếu nại sai sự thật|3 lần bị bác / 30 ngày → khóa cọc trên app 30 ngày|
|Vi phạm của chủ trọ|3 lần / 90 ngày → khóa đăng tin / nhận cọc trong Tìm trọ 30 ngày|
|Tỷ lệ giữ đúng cam kết của chủ trọ|Tính 90 ngày|
|Cọc trực tiếp chưa cập nhật → nhắc chủ trọ|Ngày nhận phòng dự kiến + 3 ngày|
|Xác nhận "Tôi đã thuê phòng này" (cọc trực tiếp)|Trong 7 ngày sau khi chủ trọ bấm "Đã cho thuê"|
|Thời hạn viết đánh giá|12 tháng từ thời điểm nhận phòng · 30 ngày nếu khiếu nại được chấp nhận|
|GPS lệch bao nhiêu thì gắn cờ|200 m|
|Bán kính lọc|300 m · 500 m · 1 km · 2 km · 3 km · 5 km|
|Báo cáo được tính|Đã OTP, tài khoản ≥ 7 ngày tuổi|
|Gắn cờ ưu tiên do báo cáo (không tự ẩn)|3 người khác số điện thoại|
|Ẩn tạm đánh giá / tin nhắn|3 báo cáo cùng lý do "xúc phạm / lộ thông tin cá nhân" (không tính vi phạm, admin khôi phục được)|
|Báo cáo tối đa · báo cáo sai|10 / người / ngày · 3 lần sai → khóa báo cáo 30 ngày|
|Nhận xét đánh giá|≥ 20 ký tự, ≤ 5 ảnh|
|Tỷ lệ phản hồi|Trả lời trong 24 giờ, tính 30 ngày gần nhất|
|Mục tiêu admin xử lý|24 giờ · khiếu nại tiền 12 giờ · báo cáo "xúc phạm / lộ thông tin" 24 giờ|
|Kháng nghị|Gửi trong 7 ngày · admin trả lời trong 48 giờ · 1 lần / quyết định · tối đa 3 bằng chứng|
|Bộ đếm vi phạm|Cửa sổ trượt (30 ngày với sinh viên, 90 ngày với chủ trọ), theo số điện thoại|

## 2.17 Dữ liệu cần lưu

> Danh sách **thông tin module cần lưu**, viết bằng lời. Tên bảng, tên trường, kiểu dữ liệu do người code đặt, nhưng **phải lưu đủ những thông tin dưới đây**. Mọi mốc hạn đều lưu thành **thời điểm cụ thể** để app tự xử lý khi tới hạn. Dữ liệu của module này **tách riêng** khỏi module khác; chỉ dùng chung tài khoản và xác nhận người thật (mục 4.6). Mã trạng thái dùng đúng như mục 2.2 và 2.5.

|Nhóm dữ liệu|Cần lưu những gì|
|---|---|
|**Nhà trọ**|Chủ trọ · tên · loại hình (cho thuê phòng / nguyên căn) · tổng số phòng, số tầng · tiện ích chung · **nội quy** (giờ giấc ra vào: tự do / giờ đóng cửa · nuôi thú cưng · ở qua đêm · số tuần báo trước khi trả phòng) · mô tả · địa chỉ đầy đủ + **vị trí ghim** · chữ tìm kiếm không dấu (tên + đường + phường) · ảnh thư viện · video khu trọ (kèm GPS lúc quay, khoảng cách tới ghim, có giả lập vị trí không, bị gắn cờ không) · ảnh bìa (khung hình cắt từ video) · trạng thái · lý do từ chối · đã xác thực nhà chưa · **bản chỉnh sửa chờ duyệt** · ngày hết hạn · số liệu tự tính (số phòng trống, giá thấp nhất – cao nhất, điểm đánh giá)|
|**Phòng**|Nhà trọ nào · tên / số phòng, khu, tầng · có gác không, diện tích sàn, diện tích gác · số người tối đa · (nguyên căn) số phòng ngủ, số WC, có bếp · tiện ích trong phòng · giá thuê · tiền cọc (**số tiền**, ≤ 1 tháng thuê) · tiền điện, tiền nước (cách tính + giá) · phí khác · hợp đồng tối thiểu · ngày có thể vào ở · mô tả · ảnh, video phòng, lần quay video gần nhất · ảnh bìa · trạng thái · bản chỉnh sửa chờ duyệt · **khóa thanh toán** (ai đang thanh toán, tới lúc nào — tối đa 1) · **đang giữ cho ai**: khoản cọc qua app hoặc cọc trực tiếp (tối đa 1) · chỗ để trống cho ngày trả phòng (làm sau) · một số thông tin chép từ nhà trọ để lọc nhanh (trạng thái nhà trọ, loại hình, tiện ích chung, nội quy, vị trí, chữ tìm kiếm)|
|**Khoản cọc trên app**|Phòng, nhà trọ · sinh viên (kèm **số điện thoại** để đếm quyền hủy miễn phí), chủ trọ · số tiền · khoản tiền liên quan (nhóm "Khoản tiền" bên dưới) · trạng thái · **lý do kết thúc** (mục 2.5g) · **bản chụp thông tin phòng lúc cọc** (giá, chi phí, tiện ích, **4 tiêu chí nội quy**, mô tả, ảnh, video; không đổi khi chủ sửa tin) · lúc đồng ý chính sách cọc và **điều khoản nhận phòng** · hạn thanh toán · lúc bắt đầu giữ tiền · **hạn hủy miễn phí** (+ 30 phút) · **có quyền hủy miễn phí không** (ghi lúc tạo) · **thời điểm nhận phòng ban đầu** và **thời điểm nhận phòng hiện hành (T)** · **yêu cầu thay đổi** (đã dùng quyền chưa, lúc gửi, thời điểm yêu cầu thay đổi, hạn trả lời + 24 giờ, kết quả: đồng ý / từ chối / quá hạn) · **báo "không đến"** (lúc chủ báo, hạn phản đối + 12 giờ, sinh viên có phản đối không) · **mốc nhắc cuối** (T + 24 giờ, đã gửi chưa) · **hạn tự hoàn tất** (T + 48 giờ) · khiếu nại (ai mở: sinh viên khiếu nại / sinh viên phản đối, lý do, mô tả, bằng chứng kèm GPS, lúc mở, trả lời của chủ trọ, mốc cờ khẩn + 72 giờ, quyết định của admin)|
|**Cọc trực tiếp**|Phòng, nhà trọ · chủ trọ · lúc chủ xác nhận · **ngày nhận phòng dự kiến** (và các lần sửa) · số điện thoại người cọc (tùy chọn) và tài khoản tương ứng nếu có · kết quả (đang chờ / đã cho thuê / người cọc không thuê nữa) và lúc cập nhật · đã nhắc chủ trọ chưa (ngày dự kiến + 3 ngày) · lúc người cọc bấm "Tôi đã thuê phòng này" · hạn xác nhận (+ 7 ngày)|
|**Hồ sơ trong module**|Mỗi tài khoản có hồ sơ riêng trong Tìm trọ: chỉ số chủ trọ (tỷ lệ phản hồi, **tỷ lệ giữ đúng cam kết**, số vi phạm trong 90 ngày) · các khóa đang áp trong module kèm thời hạn (cọc trên app, báo cáo; đăng tin / nhận cọc của chủ trọ) · điểm gốc tìm kiếm · cài đặt thông báo|
|**Khoản tiền**|Người trả · người nhận (chủ trọ) · cho khoản cọc nào · cổng (PayPal / MoMo) · mã giao dịch của cổng · mã chống trả 2 lần · số tiền VND · PayPal: số USD đã thu và tỷ giá · **trạng thái tiền** (chờ trả · đang giữ · đã chuyển · đã hoàn · hết hạn · thất bại) · số đã hoàn · hết hạn lúc · lịch sử từng lần đổi trạng thái|
|**Ví chủ trọ**|Số tiền đang giữ · đã nhận (chỉ để hiển thị)|
|**Chat**|Hai người trong cuộc trò chuyện (**mỗi cặp 1 cuộc** trong module) · ai đã chặn ai · tin cuối · số tin chưa đọc|
|**Tin nhắn**|Người gửi · loại: chữ / ảnh / thẻ tin · nội dung · nội dung đã bỏ dấu (để lọc từ khóa) · từ khóa bị cảnh báo · thẻ tin trỏ tới đâu · đã xem lúc · trạng thái hiển thị (hiện / tạm ẩn do báo cáo / ẩn)|
|**Đánh giá**|Nhà trọ được đánh giá · người viết · điểm từng tiêu chí và điểm trung bình · thẻ nhanh · nhận xét · ảnh · **nhãn xác minh** · có được tính vào điểm không · bằng chứng (khoản cọc hoặc cọc trực tiếp) · trả lời của chủ · đã cập nhật chưa · trạng thái hiển thị (hiện / tạm ẩn / ẩn)|
|**Lưu ❤️**|Ai lưu · nhà trọ nào · có nhận thông báo không|
|**Báo cáo**|Người báo · báo cái gì · lý do, ghi chú · (nội quy không đúng tại thời điểm giao dịch) tiêu chí bị sai, thời điểm phát hiện / xảy ra, bằng chứng, khoản cọc liên quan để đối chiếu bản chụp · ưu tiên cao hay thường · có được tính vào ngưỡng gắn cờ không · trạng thái xử lý, ai xử lý|
|**Lần vi phạm**|Tài khoản và **số điện thoại** · loại (sinh viên: báo cáo sai / khiếu nại sai · chủ trọ: hủy cọc / không trả lời yêu cầu thay đổi / khiếu nại được chấp nhận / nội quy sai tại thời điểm giao dịch) · từ giao dịch nào · lúc nào · còn hiệu lực hay đã gỡ. Mỗi giao dịch chỉ sinh **tối đa 1** lần vi phạm cùng loại|
|**Kháng nghị**|Người gửi · kháng nghị quyết định nào · lý do, bằng chứng · trạng thái · kết quả · ai xử lý|
|**Thông báo**|Gửi cho ai · loại · tiêu đề, nội dung · bấm vào thì mở đâu · đã đọc lúc · cài đặt thông báo của module|
|**Nhật ký admin**|Admin nào · làm gì · với cái gì · ghi chú · lúc nào|

## 2.18 Quy tắc khi làm

1. **Con số không viết cứng:** mọi thời hạn, giới hạn lấy từ bảng 2.16 (để trong file cấu hình của module).
2. **Mọi danh sách** có đủ 3 trạng thái: đang tải · trống · lỗi (mục 2.19).
3. **Giá tiền** lưu dạng số, chỉ định dạng "35.000đ" khi hiển thị.
4. **Hệ thống quyết định, không tin app:** giá, tổng tiền, trạng thái thanh toán, khoảng cách GPS, giờ, quyền của người bấm, trạng thái hiện tại và hạn đều do hệ thống kiểm tra. Nút bị ẩn trên app nhưng cũng phải bị chặn ở hệ thống.
5. **Không tự giao dịch với nhà trọ của mình:** chủ trọ không được dùng các chức năng của sinh viên (cọc, đánh giá, lưu ❤️, nhắn tin) với nhà trọ của chính mình.
6. **Hạn tự động:** mỗi hạn lưu thành một thời điểm cụ thể. Tới hạn thì hệ thống tự chuyển trạng thái; mở lại một giao dịch đã quá hạn thì thấy ngay trạng thái sau hạn. Việc tự xử lý chạy lại nhiều lần **không được** hoàn tiền 2 lần, chuyển tiền 2 lần, tính vi phạm 2 lần hay gửi thông báo 2 lần.
7. **Hai người thao tác cùng lúc:** chỉ chuyển trạng thái khi trạng thái hiện tại còn đúng như lúc bấm; thao tác đến trước thắng (tình huống cụ thể: mục 2.5i).
8. **Không dùng code, dữ liệu, màn hình của module khác.** Chỉ dùng chung tài khoản và xác nhận người thật (Phần 4), model `User` trong `shared/`, và các tiện ích chung trong `core/utils`, `core/services` (cây thư mục: mục 2.21).
9. **Không để mật khẩu, khóa bí mật** (chuỗi kết nối, khóa thanh toán…) trong code hay gửi qua chat — repo đang public.
10. Làm đúng **1 task mỗi lần**, xong thì kiểm tra theo mục 2.23 rồi mới sang task tiếp.

## 2.19 Giao diện riêng của module (xanh biển – trắng)

> Bộ giao diện **riêng của module Tìm trọ**. Mọi màu, chữ, khoảng cách khai báo **một lần** trong file `widgets/tro_theme.dart` của module (mục 2.21), các màn hình của module chỉ dùng lại. Module khác có bộ giao diện riêng; hiện cả hai cùng tông xanh biển – trắng nhưng **được đổi độc lập**.

### Bảng màu

**Màu chính (xanh biển)**

|Tên token|Mã màu|Dùng cho|
|---|---|---|
|`primary`|`#1565C0`|Nút chính, liên kết, tab đang chọn, icon đang chọn, ghim bản đồ|
|`primaryDark`|`#0D47A1`|Nút chính khi nhấn giữ, tiêu đề lớn có màu|
|`primaryLight`|`#E3F0FF`|Nền chip đang chọn, nền thẻ được chọn, nền huy hiệu xác thực|
|`primarySoft`|`#BBD8FA`|Viền ô đang nhập, thanh tiến trình nền|
|`accent`|`#29B6F6`|**Chỉ trang trí** (minh họa, gradient banner). Không đặt chữ trắng lên màu này vì không đủ tương phản|

**Màu nền và chữ**

|Tên token|Mã màu|Dùng cho|
|---|---|---|
|`white`|`#FFFFFF`|Nền thẻ, nền thanh trên, nền bảng bộ lọc|
|`background`|`#F4F8FD`|Nền màn hình (trắng ánh xanh nhẹ để thẻ trắng nổi lên)|
|`border`|`#D6E4F5`|Viền thẻ, đường kẻ phân cách|
|`textPrimary`|`#0F1C2E`|Chữ chính|
|`textSecondary`|`#5B6B80`|Chữ phụ, mô tả, thời gian|
|`textDisabled`|`#A9B6C6`|Chữ khi bị vô hiệu|

**Màu trạng thái**

|Tên token|Mã màu|Nền nhạt|Dùng cho|
|---|---|---|---|
|`success`|`#137333`|`#E8F6EE`|Còn phòng, đã xác thực, thanh toán thành công|
|`warning`|`#B45309`|`#FFF4E0`|Đã cọc, đang có người thanh toán, sắp hết hạn, đang khiếu nại|
|`danger`|`#C62828`|`#FDECEC`|Hết phòng, lỗi, hủy, cảnh báo lừa đảo|
|`info`|`#1565C0`|`#E3F0FF`|Thông tin chung (dùng lại màu chính)|

**Quy tắc màu**
- Mỗi màn hình **tối đa 1 nút chính** (nền xanh đặc) cho hành động chính của ngữ cảnh. Mọi hành động khác dùng nút phụ (viền). Ví dụ trang phòng: "Đặt cọc giữ phòng" là nút chính, "Nhắn tin", "Gọi", "Chỉ đường" là nút phụ.
- Chữ trên nền xanh `primary` luôn là **trắng**. Chữ trên nền trắng tối thiểu là `textSecondary`.
- Tương phản chữ tối thiểu **4,5 : 1** (chuẩn WCAG). Đã tính cho các cặp đang dùng:

|Cặp màu (chữ / nền)|Tỷ lệ|Kết quả|
|---|---|---|
|Trắng / `primary` `#1565C0`|5,75|Đạt|
|Trắng / `primaryDark` `#0D47A1`|8,63|Đạt|
|`textPrimary` `#0F1C2E` / trắng · / `background`|17,13 · 16,06|Đạt|
|`textSecondary` `#5B6B80` / trắng · / `background`|5,44 · 5,10|Đạt|
|`primary` / trắng · / `primaryLight` · / `background`|5,75 · 4,97 · 5,39|Đạt|
|`success` `#137333` / nền nhạt `#E8F6EE`|5,34|Đạt|
|`warning` `#B45309` / nền nhạt `#FFF4E0`|4,61|Đạt|
|`danger` `#C62828` / nền nhạt `#FDECEC` · trắng / `danger`|4,92 · 5,62|Đạt|
|Trắng / ghim xám `#64748B`|4,76|Đạt|
|Trắng / nút vô hiệu `#C9D6E6` · `textDisabled` `#A9B6C6` / trắng|1,47 · 2,06|**Ngoại lệ hợp lệ**: thành phần đang vô hiệu được miễn theo WCAG|
|Trắng / `accent` `#29B6F6`|2,30|**Không dùng** cho chữ (accent chỉ để trang trí)|
- **Không dùng màu làm tín hiệu duy nhất:** trạng thái luôn có **chữ hoặc icon** đi kèm (ví dụ 🟢 + "Còn 3 phòng").

### Chữ

- **Font:** **Be Vietnam Pro** (hiển thị tiếng Việt có dấu đẹp, miễn phí trên Google Fonts). Dự phòng: font mặc định hệ thống.

|Kiểu|Cỡ / Độ đậm|Dùng cho|
|---|---|---|
|`display`|28 / Bold|Tiêu đề màn hình chào, số tiền lớn|
|`h1`|22 / Bold|Tiêu đề trang (tên nhà trọ, tên phòng)|
|`h2`|18 / SemiBold|Tiêu đề khối (Tiện ích, Danh sách phòng, Đánh giá)|
|`h3`|16 / SemiBold|Tiêu đề thẻ, tên phòng|
|`body`|15 / Regular|Nội dung chính|
|`bodySmall`|13 / Regular|Mô tả phụ, địa chỉ, thời gian|
|`label`|14 / SemiBold|Chữ trên nút, chip, tab|
|`price`|16 / Bold, màu `primary`|Giá tiền|

### Khoảng cách, bo góc, đổ bóng

- **Lưới 4 điểm:** khoảng cách chỉ dùng 4 · 8 · 12 · 16 · 20 · 24 · 32.
- **Lề màn hình:** 16. Khoảng cách giữa các thẻ: 12.
- **Bo góc:** nút 12 · thẻ 16 · ô nhập 12 · chip **bo tròn hẳn** · bảng kéo từ dưới lên 24 (góc trên).
- **Đổ bóng:** nhẹ, màu xanh rất nhạt (`#1565C0` độ mờ 8%), chỉ dùng cho thẻ và thanh dưới cùng.

### Nút

|Loại|Hình dáng|Khi nào dùng|
|---|---|---|
|**Chính**|Nền `primary`, chữ trắng, cao 48, bo 12, rộng hết hàng trên điện thoại|Tối đa 1 / màn hình: "Đặt cọc giữ phòng", "Đã nhận phòng", "Gửi duyệt"|
|**Phụ**|Nền trắng, viền `primary` 1.5, chữ `primary`|"Nhắn tin", "Gọi", "Yêu cầu thay đổi thời điểm nhận phòng", "Lưu nháp", "Xem trên bản đồ"|
|**Chữ**|Không nền, chữ `primary`|"Xem tất cả", "Bỏ qua"|
|**Nguy hiểm**|Nền `danger`, chữ trắng (hoặc viền đỏ nếu là hành động phụ)|"Hủy cọc", "Không thuê nữa", "Chủ trọ không thực hiện đúng cam kết", "Sinh viên không đến nhận phòng", "Xóa phòng"|
|**Icon tròn**|40×40, nền trắng, icon `primary`|❤️ lưu, chia sẻ, quay lại trên ảnh bìa|

**Trạng thái nút:** bình thường · **nhấn** (đậm hơn: `primaryDark`) · **vô hiệu** (nền `#C9D6E6`, chữ trắng) · **đang xử lý** (vòng xoay trắng thay chữ, không bấm lại được — chống bấm 2 lần khi thanh toán).

**Thanh hành động dưới cùng** (trang chi tiết phòng): nền trắng, đổ bóng phía trên, chứa giá bên trái + nút chính bên phải.

### Ô nhập, chip, công tắc

- **Ô nhập:** nền trắng, viền `border`, cao 48. Đang nhập: viền `primary` 1.5. Lỗi: viền `danger` + dòng lỗi màu đỏ bên dưới. Nhãn luôn nằm **trên** ô (không chỉ dùng chữ mờ gợi ý).
- **Ô tìm kiếm:** bo tròn hẳn, nền `primaryLight`, icon kính lúp `primary`.
- **Chip lọc:** chưa chọn = nền trắng viền `border` chữ `textPrimary`; đã chọn = nền `primaryLight` viền `primary` chữ `primary` + dấu ✓.
- **Công tắc, ô tick:** bật = `primary`.
- **Thanh tiến trình form nhiều bước:** nền `primarySoft`, phần đã xong `primary`, kèm chữ "Bước 2/5".

### Thẻ (card)

**Thẻ ở danh sách** (nội dung thẻ: mục 2.4 Bước 1). **Ảnh bìa luôn là hình chụp tại chỗ** (khung hình từ video khu trọ / video phòng) — mục 1.3.
- Ảnh bìa 16:9 ở trên, bo góc trên; nút ❤️ tròn trắng ở góc phải ảnh; icon nội quy nổi bật (🕐 🐶) ở góc dưới ảnh.
- Phần chữ bên dưới: tên (`h3`) + huy hiệu xanh · dòng phụ ★, khoảng cách, phường (`bodySmall`, `textSecondary`) · giá (`price`) · nhãn trạng thái.
- Nền trắng, bo 16, viền `border`, đổ bóng nhẹ. Bấm vào thu nhỏ nhẹ (98%).

**Huy hiệu (badge)**
|Huy hiệu|Kiểu|
|---|---|
|✔ Đã xác thực danh tính / Đã xác thực nhà|Nền `primaryLight`, chữ + icon `primary`|
|🟢 Còn phòng|Nền `success` nhạt, chữ `success`|
|🟠 Đã cọc · Đang có người thanh toán · Sắp hết hạn|Nền `warning` nhạt, chữ `warning`|
|🔴 Hết phòng|Nền `danger` nhạt, chữ `danger`|
|✔ Đã thuê · ⚠ Có khiếu nại được chấp nhận (trên đánh giá)|Nền xám xanh nhạt, chữ `primary`|

### Điều hướng

**Thanh điều hướng dưới của module — 4 mục**
`🔍 Khám phá` · `💬 Tin nhắn` · `🔔 Thông báo` · `👤 Của tôi` (tin nhắn, thông báo chỉ của module Tìm trọ)
- Mục đang chọn: icon đặc + chữ `primary`; mục khác: icon viền + `textSecondary`.
- Nền trắng, đổ bóng nhẹ phía trên. Số tin chưa đọc: chấm đỏ `danger`.
- Góc trên có nút **về trang chủ của app** (trang chủ chỉ là lưới icon các module, do nhóm làm, không thuộc tài liệu này).

**Thanh trên (app bar):** nền trắng, tiêu đề `h2` màu `textPrimary`, nút quay lại `primary`. Trang chi tiết có ảnh bìa: thanh trong suốt, nút tròn trắng nổi trên ảnh.

**Máy tính (màn hình rộng):** thanh điều hướng chuyển sang **cột bên trái**; sảnh hiện **danh sách bên trái + bản đồ bên phải** cùng lúc; trang quản lý và admin dùng bảng nhiều cột. Các chức năng chỉ có trên điện thoại (quay video, chụp giấy tờ nhà, chụp bằng chứng khiếu nại có GPS) hiện thông báo "Vui lòng dùng app trên điện thoại" — bảng "Điện thoại và máy tính" bên dưới.

### Bản đồ

- Ghim nhà trọ: **viên thuốc** (pill) nền `primary`, chữ trắng, hiện giá ("từ 1,5tr").
- Hết phòng: ghim **xám** `#64748B`.
- Đang chọn: ghim **to hơn** + viền trắng dày.
- Cụm: vòng tròn `primary` với số ở giữa.
- Điểm gốc: chấm xanh `#29B6F6` có quầng sáng + vòng tròn bán kính viền `primary` nét đứt, nền mờ 8%.

### Trạng thái màn hình

|Trạng thái|Hiển thị|
|---|---|
|**Đang tải**|**Khung xương (skeleton)** màu `#E6EEF8` nhấp nháy, đúng hình dạng thẻ thật. Không dùng màn hình trắng có vòng xoay|
|**Rỗng**|Hình minh họa nét xanh + 1 dòng giải thích + 1 nút gợi ý (vd "Không tìm thấy nhà trọ phù hợp" + [Xóa bộ lọc])|
|**Lỗi**|Icon cảnh báo + "Không tải được dữ liệu" + [Thử lại]|
|**Thành công**|Thông báo nổi (snackbar) nền `textPrimary`, chữ trắng, kèm ✓ xanh lá; thao tác về tiền dùng **màn hình kết quả riêng**|
|**Cảnh báo lừa đảo**|Khung nền `danger` nhạt, viền trái đỏ, icon ⚠️|

### Icon, ảnh, chuyển động

- **Icon:** bộ **Material Symbols Rounded**, nét bo tròn, cỡ 24 (trong nút 20).
- **Ảnh:** tỷ lệ 16:9 cho ảnh bìa, 1:1 cho ảnh phòng; luôn có ảnh giữ chỗ màu `primaryLight` khi đang tải.
- **Chuyển động:** ngắn (150–250 ms), nhẹ nhàng: chuyển trang trượt ngang, bảng lọc trượt từ dưới lên, ❤️ nảy nhẹ khi bấm. Không dùng hiệu ứng rườm rà.

### Khả năng tiếp cận

- Vùng bấm tối thiểu **48×48**.
- Hỗ trợ **phóng to chữ** của hệ điều hành (giao diện không vỡ khi chữ lớn 130%).
- Ảnh có mô tả thay thế cho trình đọc màn hình.
- Mọi biểu mẫu báo lỗi **bằng chữ**, không chỉ đổi màu viền.

### Điện thoại và máy tính

App Flutter chạy trên **điện thoại** (đủ chức năng) và **máy tính Windows** (xem và quản lý). Theo hiểu biết hiện tại, một số thư viện chưa chạy trên Windows (cần kiểm tra lại trên pub.dev):

|Chức năng|Điện thoại|Máy tính|
|---|---|---|
|Xem, tìm, lọc, chi tiết, chat, đánh giá|✅|✅|
|Quản lý nhà trọ, phòng, tiền cọc, cọc trực tiếp, trả lời yêu cầu thay đổi|✅|✅|
|Admin duyệt, xử lý khiếu nại, kháng nghị|✅|✅ (nên dùng)|
|Thanh toán|✅|✅ (mở trang của cổng thanh toán)|
|Bản đồ|Google Maps|Nếu không hỗ trợ: dùng bản đồ thay thế (ví dụ bản đồ mở OpenStreetMap) hoặc chỉ hiện danh sách + nút mở bản đồ|
|Quay video, chụp giấy tờ, chụp bằng chứng khiếu nại / phản đối|✅|❌ — hiện "Vui lòng dùng app trên điện thoại"|
|Thông báo đẩy|✅|Nếu không hỗ trợ: cập nhật khi app đang mở|

## 2.20 Danh sách màn hình

|Mã|Màn hình|Ai dùng|
|---|---|---|
|TRO-SV-01|Sảnh — danh sách|Khách, SV|
|TRO-SV-02|Bảng bộ lọc|Khách, SV|
|TRO-SV-03|Chọn điểm gốc|Khách, SV|
|TRO-SV-04|Sảnh — bản đồ|Khách, SV|
|TRO-SV-05|Chi tiết nhà trọ|Khách, SV|
|TRO-SV-06|Chi tiết phòng (nút theo trạng thái, dòng nhắc "Đi xem phòng không giữ phòng")|Khách, SV|
|TRO-SV-07|Đặt cọc: chọn thời điểm nhận phòng (ngày + giờ), chính sách cọc, điều khoản nhận phòng 48 giờ, số lần hủy miễn phí còn lại|SV|
|TRO-SV-08|Chi tiết khoản cọc: đếm ngược tới thời điểm nhận phòng · hủy trong 30 phút · "Yêu cầu thay đổi thời điểm nhận phòng" · "Không thuê nữa" · từ thời điểm nhận phòng: **"Đã nhận phòng"** / **"Chủ trọ không thực hiện đúng cam kết"** · phản đối "không đến" (đếm ngược 12 giờ) · đếm ngược tới tự hoàn tất 48 giờ|SV|
|TRO-SV-09|Gửi khiếu nại / phản đối: lý do, mô tả, ảnh / video quay trong app có GPS|SV|
|TRO-SV-10|Của tôi — Trọ (khoản cọc, nhà trọ đã lưu, phòng đã thuê, vi phạm và kháng nghị)|SV|
|TRO-SV-11|Viết / cập nhật đánh giá|SV|
|TRO-SV-12|Cọc trực tiếp: "Tôi đã thuê phòng này"|SV|
|TRO-SV-13|Chat của module (danh sách, cuộc trò chuyện, thẻ tin, câu hỏi nhanh)|SV, chủ trọ|
|TRO-SV-14|Thông báo của module + cài đặt thông báo|SV, chủ trọ|
|TRO-SV-15|Báo cáo · kháng nghị (gửi, xem kết quả)|SV, chủ trọ|
|TRO-SV-16|Thanh toán (chuyển sang cổng, màn hình kết quả)|SV|
|TRO-CT-01|Tạo nhà trọ (5 phần)|Chủ trọ|
|TRO-CT-02|Thêm phòng (4 phần) + Nhân bản|Chủ trọ|
|TRO-CT-03|Quay video (gợi ý, GPS, chọn khung hình bìa, nén, tải lên)|Chủ trọ|
|TRO-CT-04|Quản lý — Tổng quan|Chủ trọ|
|TRO-CT-05|Quản lý — Nhà trọ / phòng (bản chỉnh sửa chờ duyệt, "Đã cho thuê ngoài app", **"Xác nhận phòng đã có người cọc trực tiếp / ngoài ứng dụng"**)|Chủ trọ|
|TRO-CT-06|Quản lý — Tiền cọc: "Hủy cọc" · Đồng ý / Từ chối yêu cầu thay đổi (đếm ngược 24 giờ) · "Sinh viên không đến nhận phòng" (từ T + 3 giờ) · trả lời khiếu nại|Chủ trọ|
|TRO-CT-07|Quản lý — Cọc trực tiếp: "Đã cho thuê" · "Người cọc không thuê nữa" · sửa ngày nhận phòng dự kiến|Chủ trọ|
|TRO-CT-08|Ví chủ trọ: tiền cọc đang giữ, đã nhận|Chủ trọ|
|TRO-AD-01|Duyệt nhà trọ / phòng / bản chỉnh sửa|Admin Tìm trọ|
|TRO-AD-02|Khiếu nại cọc (so bản chụp lúc cọc, bằng chứng, chat, lịch sử khoản cọc)|Admin Tìm trọ|
|TRO-AD-03|Hàng chờ admin Tìm trọ (lọc theo loại, cờ khẩn)|Admin Tìm trọ|
|TRO-AD-04|Xử lý báo cáo · kháng nghị · khóa chức năng người dùng|Admin Tìm trọ|

## 2.21 Cây thư mục

> Khớp **sườn chung của nhóm**: module nằm ở `lib/features/tro/` và **chỉ có đúng 4 thư mục con** `models/ · services/ · screens/ · widgets/` (file cấu hình nằm trong `models/`, điều hướng trong `screens/`, giao diện riêng trong `widgets/`). Thư mục **riêng** của module gồm cả giao diện, thanh toán, **chat, đánh giá** (mỗi module tự có, không dùng chung vì đánh giá phòng trọ và đánh giá quán khác tiêu chí, khác nhãn; chat gắn với phòng / đơn của từng module), báo cáo, kháng nghị, thông báo. Từ phần chung của app chỉ dùng: `shared/` → **chỉ model `User`** · `core/utils` (định dạng giá, ngày…) · `core/services` (kết nối chung) · `features/auth/` (tài khoản, xác nhận người thật — Phần 4). Giao diện **không** dùng `core/theme` mà dùng theme riêng của module. Trong `screens/` chia theo **vai trò**. Mã màn hình ở cuối dòng khớp với mục 2.20. Con số quy định (bảng 2.16) để trong file cấu hình, **không viết cứng**. **Không dùng code của module khác**; chỉ gọi phần tài khoản và xác nhận người thật (Phần 4).

```
lib/features/tro/                    # Module Tìm trọ
├── models/
│   ├── tro_config.dart              # Bảng 2.16 (không viết cứng số trong code)
│   ├── nha_tro.dart                 # Nhà trọ, bản chỉnh sửa chờ duyệt, số liệu (2.17)
│   ├── phong_tro.dart               # Phòng, chi phí, khóa thanh toán, đang giữ cho ai (2.17)
│   ├── dat_coc.dart                 # Khoản cọc, T, yêu cầu thay đổi, báo không đến, lý do kết thúc (2.5g)
│   ├── coc_truc_tiep.dart           # Cọc trực tiếp ngoài app (2.5d)
│   ├── khieu_nai.dart               # Khiếu nại / phản đối, bằng chứng GPS (2.5c)
│   ├── tro_filter.dart
│   ├── video_info.dart              # Video kèm GPS, cờ lệch / giả lập
│   ├── thanh_toan.dart
│   ├── tin_nhan.dart
│   ├── danh_gia.dart
│   ├── bao_cao.dart
│   ├── khang_nghi.dart
│   └── thong_bao.dart
├── services/
│   ├── nha_tro_service.dart         # Sảnh, chi tiết, tạo/sửa nhà trọ, gửi duyệt
│   ├── phong_tro_service.dart       # Phòng, nhân bản, đăng lại, đã cho thuê ngoài app
│   ├── dat_coc_service.dart         # Cọc, hủy, không thuê, yêu cầu thay đổi, nhận phòng, không đến (từ T + 3), 24/48 giờ
│   ├── coc_truc_tiep_service.dart   # Xác nhận cọc trực tiếp, đã cho thuê, người cọc không thuê
│   ├── khieu_nai_service.dart
│   ├── thanh_toan_service.dart
│   ├── chat_service.dart
│   ├── danh_gia_service.dart
│   ├── bao_cao_service.dart
│   ├── khang_nghi_service.dart
│   └── thong_bao_service.dart
├── screens/
│   ├── tro_routes.dart              # Điều hướng giữa các màn hình của module
│   ├── sinh_vien/
│   │   ├── tro_sanh_screen.dart     # TRO-SV-01
│   │   ├── tro_bo_loc_sheet.dart    # TRO-SV-02
│   │   ├── chon_diem_goc_screen.dart # TRO-SV-03
│   │   ├── tro_ban_do_screen.dart   # TRO-SV-04
│   │   ├── nha_tro_detail_screen.dart # TRO-SV-05
│   │   ├── phong_tro_detail_screen.dart # TRO-SV-06
│   │   ├── dat_coc_screen.dart      # TRO-SV-07
│   │   ├── dat_coc_detail_screen.dart # TRO-SV-08
│   │   ├── khieu_nai_screen.dart    # TRO-SV-09
│   │   ├── cua_toi_tro_screen.dart  # TRO-SV-10
│   │   ├── danh_gia_tro_screen.dart # TRO-SV-11
│   │   └── xac_nhan_da_thue_screen.dart # TRO-SV-12
│   ├── tuong_tac/
│   │   ├── chat_screen.dart         # TRO-SV-13
│   │   ├── thong_bao_screen.dart    # TRO-SV-14
│   │   ├── bao_cao_khang_nghi_screen.dart # TRO-SV-15
│   │   └── thanh_toan_screen.dart   # TRO-SV-16
│   ├── chu_tro/
│   │   ├── tao_nha_tro_screen.dart  # TRO-CT-01
│   │   ├── them_phong_screen.dart   # TRO-CT-02
│   │   ├── quay_video_screen.dart   # TRO-CT-03
│   │   ├── quan_ly_tong_quan_screen.dart # TRO-CT-04
│   │   ├── quan_ly_nha_tro_screen.dart # TRO-CT-05
│   │   ├── quan_ly_dat_coc_screen.dart # TRO-CT-06
│   │   ├── quan_ly_coc_truc_tiep_screen.dart # TRO-CT-07
│   │   └── vi_screen.dart           # TRO-CT-08
│   └── admin/
│       ├── duyet_tro_screen.dart    # TRO-AD-01
│       ├── khieu_nai_coc_screen.dart # TRO-AD-02
│       ├── hang_cho_admin_screen.dart # TRO-AD-03
│       └── bao_cao_khang_nghi_admin_screen.dart # TRO-AD-04
└── widgets/
    ├── tro_theme.dart               # Giao diện riêng của module (mục 2.19)
    ├── nha_tro_card.dart
    ├── phong_tro_tile.dart
    ├── tro_status_badge.dart        # Còn phòng / Đang có người thanh toán / Đã cọc / Đã cho thuê
    ├── gia_dien_nuoc_table.dart
    ├── noi_quy_block.dart           # Nội quy ở trang chi tiết + icon trên thẻ
    ├── phong_action_bar.dart        # Nút theo trạng thái (2.4 Bước 2)
    ├── tro_map_marker.dart
    ├── chinh_sach_coc_box.dart      # Chính sách cọc + điều khoản nhận phòng 48 giờ
    ├── chon_thoi_diem_nhan_phong.dart # Chọn ngày + giờ, kiểm tra 2 giờ / 14 ngày
    └── dem_nguoc_coc_banner.dart    # Đếm ngược tới T, ân hạn 3 giờ, hạn trả lời yêu cầu thay đổi, 12 giờ phản đối, 48 giờ
test/features/tro/
├── models/
├── services/
└── logic/                           # Bảng 2.5a, 2.5h, luật 2.5b – 2.5d, mốc 3 / 12 / 24 / 48 giờ
```


## 2.22 Thứ tự làm

> Mỗi task ≈ 1 buổi code; làm xong, kiểm tra theo mục 2.23 rồi mới sang task tiếp. Cần phần tài khoản và xác nhận người thật (mục 4.8) có trước, hoặc tạm dùng tài khoản giả.

**Giai đoạn 1 — Nền của module**
- [ ] TR-1.1 Giao diện của module (mục 2.19): màu, chữ, nút, thẻ, ô nhập, trạng thái tải / rỗng / lỗi
- [ ] TR-1.2 Tải ảnh / video lên (công khai + riêng tư)
- [ ] TR-1.3 Điểm gốc + bản đồ (mục 2.7)
- [ ] TR-1.4 Tự xử lý hạn + chặn hai người thao tác cùng lúc (mục 2.18)
- [ ] TR-1.5 Thông báo đẩy + danh sách thông báo của module (mục 2.11)
- [ ] TR-1.6 Bộ đếm lần vi phạm theo số điện thoại (30 ngày với sinh viên, 90 ngày với chủ trọ)
- [ ] TR-1.7 Thanh toán sandbox PayPal / MoMo + giữ tiền + chỉ tin kết quả từ cổng + chống trừ tiền 2 lần + tiền đến muộn (mục 2.6)

**Giai đoạn 2 — Xem và đăng**
- [ ] TR-2.1 Dữ liệu nhà trọ, phòng (mục 2.17) + dữ liệu mẫu
- [ ] TR-2.2 Sảnh: thẻ, tìm không dấu kèm bán kính, bộ lọc, số kết quả, sắp xếp
- [ ] TR-2.3 Bản đồ nhà trọ
- [ ] TR-2.4 Chi tiết nhà trọ, chi tiết phòng, bảng nút theo trạng thái, nút Nhắn tin / Gọi / Chỉ đường
- [ ] TR-2.5 Quay video trong app (GPS, cờ giả lập, nén, tải lên, cắt ảnh bìa)
- [ ] TR-2.6 Tạo nhà trọ 5 phần + giấy tờ + admin duyệt
- [ ] TR-2.7 Thêm phòng 4 phần + nhân bản + trần cọc + admin duyệt
- [ ] TR-2.8 Quản lý nhà trọ: sửa, bản chỉnh sửa chờ duyệt, ẩn, đăng lại, gia hạn, "Đã cho thuê ngoài app"
- [ ] TR-2.9 Nội quy nhà trọ (4 tiêu chí) + bộ lọc theo nội quy + icon trên thẻ

**Giai đoạn 3 — Cọc và nhận phòng**
- [ ] TR-3.1 Đặt cọc: chọn thời điểm nhận phòng (2 giờ – 14 ngày), chính sách + điều khoản 48 giờ, khóa thanh toán 15 phút, gắn thanh toán (TR-1.7), bản chụp thông tin phòng
- [ ] TR-3.2 Trước thời điểm nhận phòng: hủy trong 30 phút (tối đa 2 lần / 30 ngày), "Không thuê nữa", chủ trọ "Hủy cọc" + ghi vi phạm, nhắc trước 1 ngày
- [ ] TR-3.3 Yêu cầu thay đổi thời điểm nhận phòng (sớm hơn hoặc muộn hơn): 1 lần gửi, > 24 giờ trước T, chủ trả lời trong 24 giờ, quá hạn hoàn 100% (mục 2.5b)
- [ ] TR-3.4 Từ thời điểm nhận phòng: "Đã nhận phòng", "Sinh viên không đến nhận phòng" (từ T + 3 giờ, ân hạn 3 giờ) + phản đối 12 giờ, nhắc cuối T + 24 giờ, tự hoàn tất T + 48 giờ
- [ ] TR-3.5 Khiếu nại "Chủ trọ không thực hiện đúng cam kết" (lý do, bằng chứng GPS, chủ trả lời 24 giờ, cờ khẩn 72 giờ) + admin quyết 3 hướng
- [ ] TR-3.6 Cọc trực tiếp ngoài app: xác nhận, "Đã cho thuê", "Người cọc không thuê nữa", nhắc + 3 ngày, "Tôi đã thuê phòng này"
- [ ] TR-3.7 Vi phạm chủ trọ (3 lần / 90 ngày → khóa 30 ngày), tỷ lệ giữ đúng cam kết + trang "Của tôi" + trang quản lý tiền cọc / cọc trực tiếp

**Giai đoạn 4 — Tương tác và hoàn thiện**
- [ ] TR-4.1 Chat của module + thẻ tin + câu hỏi nhanh + cảnh báo từ khóa + chặn (mục 2.8)
- [ ] TR-4.2 Đánh giá của module (nhãn xác minh, điểm chỉ tính đánh giá xác minh) (mục 2.9)
- [ ] TR-4.3 Lưu ❤️ + cài đặt thông báo
- [ ] TR-4.4 Báo cáo + gắn cờ ưu tiên + ẩn tạm đánh giá / tin nhắn (xúc phạm / lộ thông tin) và admin khôi phục + admin của module (mục 2.10, 2.12)
- [ ] TR-4.5 Kháng nghị + admin xử lý (mục 2.15)
- [ ] TR-4.6 Ẩn / khóa khi còn giao dịch đang chạy (mục 2.14)
- [ ] TR-4.7 Giao diện máy tính: chỉ xem và quản lý
- [ ] TR-4.8 Kiểm thử theo mục 2.23

**Nếu thiếu thời gian (Mức 2):** lùi **giao diện máy tính** (TR-4.7) và **lưu ❤️ + thông báo nhà trọ đã lưu** (TR-4.3) sang mục 2.24. **Không cắt** luồng cọc, yêu cầu thay đổi, nhận phòng, khiếu nại, cọc trực tiếp vì đó là luật cốt lõi của module.


## 2.23 Tiêu chí nghiệm thu

> Một chức năng được coi là **xong** khi đạt hết các tiêu chí dưới đây và tuân thủ quy tắc chung ở mục 2.18. Con số lấy từ bảng 2.16 và 4.5; khi test được phép **rút ngắn thời hạn qua file cấu hình**.

**Đăng tin**
- [ ] Nhà trọ chưa duyệt: không thêm phòng được, không hiện ở sảnh.
- [ ] Màn hình video **không có** lựa chọn lấy từ thư viện; video < 15 giây hoặc > 60 giây bị từ chối.
- [ ] Video quay cách ghim > 200 m hoặc thư viện định vị báo vị trí giả lập: chủ thấy cảnh báo, hồ sơ bị gắn cờ ở admin.
- [ ] Ảnh bìa chỉ chọn được từ khung hình cắt ra từ video đã quay.
- [ ] Thoát giữa chừng vào lại: dữ liệu các bước còn nguyên.
- [ ] Nhân bản: thông tin được copy, ảnh / video trống, bắt buộc làm lại.
- [ ] Tiền cọc lớn hơn 1 tháng tiền thuê thì không lưu được; đổi tiền cọc khi phòng `reserved` bị chặn.
- [ ] Sửa giá, mô tả cập nhật ngay, **khoản cọc đang giữ vẫn theo bản chụp lúc cọc**; sửa ảnh, video, địa chỉ, vị trí ghim tạo **bản chỉnh sửa chờ duyệt**, bản cũ vẫn hiện tới khi duyệt.
- [ ] Ẩn / Xóa / Đăng lại phòng `reserved` hoặc đang khóa thanh toán bị chặn, có giải thích.
- [ ] "Đã cho thuê ngoài app": phòng `available` → `rented`; bị chặn khi phòng `reserved` hoặc đang khóa thanh toán.
- [ ] Nhà trọ có phòng đang có khoản cọc qua app chưa kết thúc: không bị hết hạn; khoản cọc vẫn đi tiếp khi nhà trọ bị ẩn (mục 2.14).
- [ ] Nhà trọ chỉ có phòng cọc trực tiếp (không có cọc qua app): vẫn hết hạn đúng 30 ngày nếu chủ không bấm "Vẫn còn cho thuê".

**Sảnh và chi tiết**
- [ ] Gõ "nguyen hue" kèm điểm gốc và bán kính 1 km: trả về đúng các nhà trọ có tên / đường "Nguyễn Huệ", trong bán kính 1 km tính từ điểm gốc.
- [ ] Ký tự đặc biệt trong ô tìm (`(`, `*`, `.`) không làm lỗi tìm kiếm.
- [ ] Nút "Xem X kết quả" đổi số ngay khi chọn tiêu chí.
- [ ] Nhà trọ chỉ hiện khi có ≥ 1 phòng `available` thỏa lọc; phòng phù hợp lên đầu ở chi tiết.
- [ ] Từ chối quyền vị trí: gợi ý chọn trên bản đồ, bộ lọc khác vẫn chạy.
- [ ] Tạo nhà trọ chưa chọn đủ 4 tiêu chí nội quy: không gửi duyệt được; chọn "Có giới hạn" mà chưa nhập giờ: không lưu được.
- [ ] Lọc "Tự do 24/24": chỉ ra trọ tự do. Lọc "Về muộn được tới ít nhất 23:00": ra trọ tự do và trọ đóng cửa 23:00, không ra trọ đóng cửa 22:00.
- [ ] Lọc "Cho phép nuôi thú cưng" / "Cho ở qua đêm": chỉ ra trọ khai "Cho phép".
- [ ] Lọc "Báo trước tối đa 2 tuần": ra trọ 1 tuần và 2 tuần, không ra trọ 3 tuần.
- [ ] Lọc nội quy kết hợp được với giá, bán kính, tiện ích.
- [ ] 0 kết quả: hiện thông báo + Xóa bộ lọc. Danh sách đủ trạng thái tải / rỗng / lỗi.
- [ ] Trang phòng `available` có nút chính "Đặt cọc giữ phòng" và dòng nhắc "Đi xem phòng không giữ phòng"; **không có** nút đặt lịch xem nào trong module.
- [ ] Phòng `reserved` / `rented`: không có nút cọc, hiện nhãn "Đã có người cọc" / "Đã cho thuê".

**Đặt cọc**
- [ ] Mọi phòng `available` đều có nút cọc (không có công tắc bật / tắt cọc).
- [ ] Thời điểm nhận phòng cách lúc cọc dưới 2 giờ, trước "ngày có thể vào ở" hoặc quá 14 ngày: bị chặn.
- [ ] Chưa tick chính sách cọc và **điều khoản nhận phòng 48 giờ** (đúng câu ở mục 2.4 Bước 3) thì không thanh toán được; thời điểm đồng ý được lưu.
- [ ] Hai người cùng bấm cọc 1 phòng: chỉ 1 người vào `pending_payment`; người kia nhận "Đang có người thanh toán", **không có giao dịch nào được tạo**, không bị trừ tiền.
- [ ] Khóa thanh toán tự gỡ khi hết 15 phút; phòng trở lại `available`.
- [ ] Cổng **ghi nhận** thanh toán thành công sau hạn 15 phút: khoản cọc `refunded` (`system_late_payment`), phòng không đổi.
- [ ] Cổng ghi nhận thành công trước hạn nhưng báo về hệ thống sau hạn: vẫn tính **đúng hạn**, khoản cọc `held`, không bị hoàn.
- [ ] Thanh toán sandbox thành công → phòng `reserved`, khoản cọc `held`, **bản chụp thông tin phòng** được lưu.
- [ ] Đi xem phòng (đã nhắn tin hẹn với chủ) không đổi trạng thái phòng; người khác cọc trước thì người đi xem không còn nút cọc.

**Trước thời điểm nhận phòng**
- [ ] Hủy trong 30 phút: `cancelled_grace`, hoàn 100%, phòng `available`. Sau 30 phút chỉ còn "Không thuê nữa" → `forfeited` (`student_changed_mind`), tiền chuyển chủ trọ, phòng `available`.
- [ ] Đã dùng 2 lần hủy miễn phí trong 30 ngày: màn hình cọc báo trước, khoản cọc mới không có nút hủy miễn phí. Lần hủy cũ hơn 30 ngày không còn được tính.
- [ ] Chủ trọ "Hủy cọc": `refunded` (`owner_cancelled`), hoàn 100%, ghi 1 vi phạm cho chủ, phòng `available` hoặc `hidden` theo chủ chọn.
- [ ] Nhắc thời điểm nhận phòng gửi cho cả hai bên trước 1 ngày.
- [ ] Trước T, sinh viên **không** thấy nút "Đã nhận phòng", "Chủ trọ không thực hiện đúng cam kết"; chủ trọ **không** thấy nút "Sinh viên không đến nhận phòng" (hệ thống cũng chặn).

**Yêu cầu thay đổi thời điểm nhận phòng**
- [ ] Chỉ sinh viên có nút; chủ trọ **không có** chức năng chủ động yêu cầu thay đổi.
- [ ] Còn ≤ 24 giờ tới T: nút bị khóa. Ví dụ T = 10/10 14:00 → gửi lúc 09/10 13:59 được, 09/10 14:01 bị chặn.
- [ ] Thời điểm mới cách lúc gửi dưới 24 giờ, trước "ngày có thể vào ở" hoặc quá T ban đầu + 14 ngày: bị chặn.
- [ ] Đề xuất nhận **sớm hơn** T cũ (ví dụ T = 10/10 14:00, gửi lúc 08/10 10:00, đề xuất 09/10 14:00) được chấp nhận gửi; chủ đồng ý → T mới = 09/10 14:00, các mốc 3 / 24 / 48 giờ tính theo T mới.
- [ ] Chủ **Đồng ý** → T đổi sang thời điểm mới, các mốc 3 / 24 / 48 giờ tính lại theo T mới. Chủ **Từ chối** → giữ T cũ.
- [ ] Sau 1 lần gửi (dù được đồng ý, bị từ chối hay quá hạn), không gửi được lần 2. Đang chờ trả lời thì không gửi được yêu cầu khác.
- [ ] Chủ không trả lời trong 24 giờ → `refunded` (`owner_no_reply_reschedule`), hoàn 100%, phòng `available`, ghi 1 vi phạm cho chủ. Chủ được nhắc khi còn 6 giờ và 1 giờ.
- [ ] Sinh viên chưa dùng quyền thay đổi được nhắc hạn cuối lúc T − 36 giờ.
- [ ] Đang chờ trả lời mà sinh viên "Không thuê nữa" hoặc chủ "Hủy cọc": yêu cầu thay đổi tự đóng, không ghi vi phạm "không trả lời".

**Nhận phòng (từ T)**
- [ ] Sinh viên bấm "Đã nhận phòng" → `released` (`student_confirmed`), phòng `rented`, mở đánh giá; chủ trọ không phải xác nhận gì.
- [ ] Chủ trọ **không có** nút "Sinh viên đã nhận phòng".
- [ ] Chủ trọ bấm "Sinh viên không đến nhận phòng" trước **T + 3 giờ** bị chặn (ví dụ T = 10/10 14:00 → từ 17:00 ngày 10/10 mới bấm được); trong 3 giờ ân hạn sinh viên vẫn bấm "Đã nhận phòng" / khiếu nại bình thường. Từ T + 3 giờ chủ bấm được, sinh viên được báo ngay, có 12 giờ.
- [ ] Sinh viên phản đối trong 12 giờ → `disputed`; không phản đối → `forfeited` (`student_no_show`), tiền chuyển chủ, phòng `available`. Sinh viên được nhắc khi còn 2 giờ.
- [ ] Chủ bấm "Sinh viên không đến nhận phòng" sau T + 48 giờ (khoản cọc đã tự hoàn tất) bị chặn.
- [ ] Đã có báo "không đến": sinh viên chỉ còn nút **Phản đối**, không bấm được "Đã nhận phòng".
- [ ] T + 24 giờ, chưa ai làm gì: cả hai nhận **nhắc cuối cùng**, tiền vẫn `held`. Đang khiếu nại hoặc đang có báo "không đến" thì **không** gửi nhắc cuối.
- [ ] T + 48 giờ, chưa ai làm gì: `released` (`auto_complete`), phòng `rented`, mở đánh giá (**không** nhãn "✔ Đã thuê", không tính điểm) — **kết quả duy nhất**.
- [ ] Đang `disputed` hoặc đang trong 12 giờ phản đối: quá T + 48 giờ vẫn **không** tự hoàn tất.
- [ ] Chủ báo "không đến" lúc T + 47 giờ: hết 12 giờ phản đối (T + 59 giờ) mới xử lý, không tự hoàn tất lúc T + 48 giờ.
- [ ] Tự hoàn tất T + 48 giờ trùng lúc sinh viên gửi khiếu nại: chỉ một kết quả thắng (khiếu nại ghi trước thì không tự hoàn tất), không chuyển tiền rồi lại mở khiếu nại.

**Khiếu nại**
- [ ] Không có mô tả hoặc ảnh / video quay trong app có GPS thì không gửi được; gửi sau T + 48 giờ (khoản cọc đã kết thúc) bị chặn.
- [ ] Đang khiếu nại thì tiền không bao giờ được chuyển.
- [ ] Chủ trọ không trả lời trong 24 giờ → admin quyết dựa trên bằng chứng của sinh viên. Treo quá 72 giờ → cờ khẩn.
- [ ] Admin chọn "chủ trọ vi phạm" → `refunded` (`owner_violation`), hoàn 100%, ghi vi phạm chủ; "sinh viên đã nhận phòng" → `released` (`admin_released`), phòng `rented`; "sinh viên không đến" → `forfeited` (`student_no_show`), phòng `available`.
- [ ] Khiếu nại sai sự thật bị bác 3 lần / 30 ngày → khóa cọc trên app 30 ngày. Sinh viên phản đối "không đến" và admin kết luận "đã nhận phòng" thì **không** tính khiếu nại sai.
- [ ] Khiếu nại lý do "Nội quy không đúng với thông tin đã khai tại thời điểm giao dịch" khi tiền còn giữ: admin so với bản chụp nội quy lúc cọc; chủ sai → hoàn 100% + 1 vi phạm.
- [ ] Giao dịch đã `released`: không gửi khiếu nại được, chỉ còn **Báo cáo** "Nội quy không đúng với thông tin đã khai tại thời điểm giao dịch"; admin xác nhận → 1 vi phạm cho chủ, **không** hoàn tiền, khoản cọc không mở lại.
- [ ] Báo cáo "Nội quy không đúng với thông tin đã khai tại thời điểm giao dịch" gửi được **bất kỳ lúc nào** sau khi thuê (không có hạn 30 ngày / 12 tháng); form bắt chọn tiêu chí bị sai và thời điểm xảy ra.
- [ ] Chủ sửa nội quy trên tin: bản chụp của khoản cọc cũ **không đổi**; người cọc sau thấy và được lưu nội quy mới.
- [ ] Nội quy lúc cọc và nhận phòng đúng, 8 tháng sau chủ đổi: báo cáo bị admin bác, **không** ghi vi phạm, **không** hoàn tiền.
- [ ] Chủ trọ đủ 3 vi phạm / 90 ngày (hủy cọc, không trả lời yêu cầu thay đổi, khiếu nại được chấp nhận, nội quy sai tại thời điểm giao dịch — cộng chung) → khóa đăng tin / nhận cọc trong Tìm trọ 30 ngày; khoản cọc đang giữ vẫn đi tiếp.
- [ ] Mỗi chuyển trạng thái trong bảng 2.5h có ít nhất 1 test tự động.

**Cọc trực tiếp**
- [ ] Chủ trọ bấm "Xác nhận phòng đã có người cọc trực tiếp / ngoài ứng dụng" trên phòng `available` → phòng `reserved`, **không có** khoản tiền nào qua app, không ai cọc qua app được nữa.
- [ ] Bị chặn khi phòng đang khóa thanh toán hoặc đã `reserved`.
- [ ] "Đã cho thuê" → phòng `rented`; "Người cọc không thuê nữa" → phòng `available`. Không có hoàn tiền, không ghi vi phạm.
- [ ] Quá ngày nhận phòng dự kiến 3 ngày chưa cập nhật: chủ trọ được nhắc; trạng thái phòng **không tự đổi**.
- [ ] Chủ nhận cọc trực tiếp mà không cập nhật, sinh viên khác cọc qua app rồi khiếu nại "phòng đã cho người khác" được chấp nhận → hoàn 100%, ghi vi phạm chủ.

**Đánh giá, khách**
- [ ] Cọc qua app chưa `released`: không có nút đánh giá. `forfeited` thì không bao giờ có.
- [ ] SV bấm "Đã nhận phòng" → đánh giá có nhãn "✔ Đã thuê", tính vào điểm. Khoản cọc tự hoàn tất sau 48 giờ → vẫn viết được nhưng **không có nhãn**, ghi "Chưa xác minh", **không** tính vào điểm nhà trọ.
- [ ] Cọc trực tiếp: chỉ đánh giá được khi người cọc (số điện thoại chủ đã nhập) bấm "Tôi đã thuê phòng này" trong 7 ngày sau khi chủ bấm "Đã cho thuê"; quá 7 ngày nút biến mất, hệ thống chặn.
- [ ] Đánh giá trọ sửa được trong 12 tháng kể từ thời điểm nhận phòng.
- [ ] Khiếu nại được chấp nhận: đánh giá được trong 30 ngày, có nhãn "⚠ Có khiếu nại được chấp nhận".
- [ ] Khách không thấy số điện thoại; bấm hành động thì bắt đăng nhập rồi quay lại đúng trang.

**Thanh toán**
- [ ] Bấm thanh toán 2 lần chỉ tạo 1 giao dịch, không bị trừ 2 lần.
- [ ] Cổng thanh toán báo về với chữ ký sai: bị từ chối, không đổi trạng thái gì.
- [ ] Quá 15 phút chưa trả: giao dịch hết hạn, chỗ khóa được gỡ.
- [ ] Cổng thanh toán **ghi nhận** thành công **sau** hạn: tiền tự hoàn 100%, người dùng nhận thông báo. Ghi nhận trước hạn mà báo về sau hạn: vẫn đúng hạn.
- [ ] PayPal hoàn tiền: hoàn đúng số USD đã thu (module này chỉ hoàn 100% hoặc không hoàn); lịch sử khoản tiền ghi lại lần hoàn.

**Hạn tự động**
- [ ] Mở lại một giao dịch đã quá hạn mà chưa được tự xử lý: app vẫn hiện đúng trạng thái sau hạn.
- [ ] Việc tự xử lý hạn chạy 2 lần hoặc chạy trễ: không hoàn tiền 2 lần, không chuyển tiền 2 lần, không ghi vi phạm 2 lần, không gửi thông báo 2 lần.

**Chat**
- [ ] Mỗi cặp người dùng chỉ có 1 cuộc trò chuyện.
- [ ] Mở chat từ phòng: thẻ tin hiện đầu cuộc trò chuyện.
- [ ] Gõ "chuyển khoản", "chuyen khoan", "CK trước", "c.k" đều hiện cảnh báo (văn bản đã chuẩn hóa).
- [ ] Gõ "check", "tick" **không** bị cảnh báo ("CK" khớp nguyên từ). Gõ "trả bằng momo trên app" **không** cảnh báo; "chuyển momo trước cho anh" **có** cảnh báo.
- [ ] Chặn người dùng: người bị chặn không gửi tin được nữa.
- [ ] Tỷ lệ phản hồi của chủ trọ = phần trăm cuộc trò chuyện mới được trả lời trong 24 giờ, tính 30 ngày gần nhất.
- [ ] Tin nhắn của module này không hiện trong module khác và ngược lại.

**Đánh giá**
- [ ] Nhận xét dưới 20 ký tự hoặc quá 5 ảnh không gửi được.
- [ ] Chủ trọ chỉ trả lời 1 lần mỗi đánh giá; không đánh giá được nhà trọ của mình.
- [ ] Nhãn xác minh chỉ có khi người viết đã OTP và thỏa điều kiện của module.
- [ ] Điểm, nhãn, danh sách đánh giá chỉ tính trong module này.

**Báo cáo**
- [ ] Báo cáo từ tài khoản chưa OTP hoặc dưới 7 ngày tuổi không được tính vào ngưỡng gắn cờ.
- [ ] 3 báo cáo từ 3 số điện thoại khác nhau: tin **được gắn cờ** lên đầu hàng chờ admin nhưng **vẫn hiển thị**, không tự ghi vi phạm; chỉ ẩn khi admin quyết.
- [ ] Đánh giá và tin nhắn **không** tự ẩn, trừ 3 báo cáo cùng lý do "xúc phạm / lộ thông tin" → ẩn tạm, không ghi vi phạm; admin bác báo cáo → khôi phục.
- [ ] Quá 10 báo cáo / ngày bị chặn; 3 lần báo cáo sai → khóa báo cáo 30 ngày.

**Thông báo**
- [ ] Tắt một nhóm thông báo thì không nhận nhóm đó; thông báo về **tiền cọc, nhận phòng, yêu cầu thay đổi, khiếu nại, kháng nghị** không tắt được.

**Kháng nghị**
- [ ] Nút "Kháng nghị" có ở thông báo phạt và trong "Của tôi"; quá 7 ngày thì nút biến mất.
- [ ] Mỗi quyết định chỉ kháng nghị 1 lần; tối đa 3 bằng chứng chụp trong app.
- [ ] Đang kháng nghị thì hình phạt vẫn còn hiệu lực.
- [ ] Admin chấp nhận "xóa lần vi phạm": lần vi phạm chuyển sang "đã gỡ", bộ đếm giảm, khóa được gỡ nếu dưới ngưỡng.
- [ ] Lần vi phạm cũ hơn cửa sổ đếm (30 ngày với sinh viên, 90 ngày với chủ trọ) không còn được tính.

**Admin**
- [ ] Hàng chờ admin sắp theo: cờ khẩn → khiếu nại tiền và báo cáo ưu tiên cao → hồ sơ bị gắn cờ → còn lại theo thời gian; lọc được loại "Chỉnh sửa chờ duyệt", "Kháng nghị".
- [ ] Khiếu nại treo quá 72 giờ tự có cờ khẩn.
- [ ] Mọi quyết định của admin được ghi vào nhật ký admin (ai, lúc nào, lý do).
- [ ] Admin kết luận chủ trọ lừa đảo: mọi khoản cọc đang giữ (`held`, `disputed`, chưa có xác nhận sinh viên nhận phòng) **hoàn 100%** (`admin_fraud`); khoản đã `released` trước đó **không** bị đảo ngược; đề nghị khóa cả tài khoản được gửi tới admin danh tính (mục 2.14, 4.4).
- [ ] Admin của module này không thấy, không xử lý được hồ sơ, báo cáo, khiếu nại của module khác.

**Không tự giao dịch**
- [ ] Chủ trọ không dùng được các chức năng của sinh viên với nhà trọ của chính mình (hệ thống chặn, không chỉ ẩn nút); mở chat với nhà trọ của mình bị chặn.

**Bảo mật**
- [ ] Không mật khẩu, khóa bí mật nào nằm trong code hay repo.

## 2.24 Hướng phát triển

|Tính năng|Mô tả|
|---|---|
|Ở ghép|Sinh viên đăng tin tìm người ở ghép, lọc người ở ghép theo thói quen (giờ ngủ, hút thuốc, ăn chay…)|
|Hợp đồng điện tử|Ký hợp đồng thuê ngay trong app|
|Trả phòng|Ghi nhận ngày trả phòng; thời hạn đánh giá đổi thành "đến khi trả phòng + 30 ngày"|
|Hoàn một phần khi "Không thuê nữa" sớm|Ví dụ hoàn 50% khi báo không thuê từ rất sớm trước thời điểm nhận phòng (bản hiện tại đã chốt không hoàn, mục 5.2 câu 1)|
|Video 360°|Tham quan phòng từ xa|
|Giao diện máy tính · lưu ❤️|Chỉ khi bị cắt ở Mức 2 (mục 2.22)|
|Thanh toán tiền thật|Chuyển từ bản thử nghiệm sang giao dịch thật, hợp tác đơn vị trung gian thanh toán được cấp phép để giữ tiền cọc hộ đúng quy định|
|Rút tiền cho chủ trọ|Chủ trọ rút tiền cọc đã nhận về tài khoản ngân hàng|
|Tìm kiếm thông minh hơn|Gõ sai chính tả vẫn ra kết quả, xếp theo độ liên quan|
|Khoảng cách theo đường đi|Tính theo đường đi thực tế thay cho đường thẳng|
|Gợi ý cá nhân hóa|Gợi ý nhà trọ theo lịch sử tìm kiếm, lưu|
|Chống gian lận nâng cao|Phát hiện cụm tài khoản liên quan để chặn đánh giá ảo, báo cáo ảo|
|Đầy đủ chức năng trên máy tính|Quay video, chụp giấy tờ, chụp bằng chứng khiếu nại trên máy tính khi thư viện hỗ trợ|
|Bản web|Phiên bản chạy trên trình duyệt|
|Chế độ tối|Bộ màu tối cho module|

## 2.25 Đánh giá module Tìm trọ

|Tiêu chí|Điểm|Nhận xét|
|---|---|---|
|Chống lừa đảo|⭐⭐⭐⭐|2 lớp xác thực, video tại chỗ, cọc được app giữ tiền tới khi nhận phòng, bản chụp thông tin lúc cọc, khóa thanh toán, cảnh báo chuyển khoản|
|Giải quyết vấn đề thực tế|⭐⭐⭐⭐⭐|Tin ảo, đánh giá ảo, chủ trọ cho người khác thuê, chủ không giao phòng đều có cách xử lý; luật giữ phòng rõ ràng: ai cọc trước người đó giữ|
|Công bằng hai phía|⭐⭐⭐⭐|Ai sai người đó chịu; sinh viên bỏ cọc thì chủ trọ được bù; mọi quyết định một phía đều có đường phản đối (12 giờ, khiếu nại, kháng nghị)|
|Dễ dùng cho sinh viên|⭐⭐⭐⭐|Tìm, lọc, liên hệ, cọc nhanh; sau khi nhận phòng chỉ cần 1 nút "Đã nhận phòng"|
|Dễ dùng cho chủ trọ|⭐⭐⭐|Đăng tin nhiều bước (xác thực, video từng phòng), bù lại có Nhân bản; không phải xác nhận lịch xem; phải nhớ cập nhật cọc trực tiếp|
|Độ khó khi làm|Khó|Bỏ lịch xem và hàng chờ nên bớt nhiều trạng thái; còn lại khóa thanh toán, các mốc 3 / 12 / 24 / 48 giờ, yêu cầu thay đổi, khiếu nại|
|Khả năng làm xong|⭐⭐⭐|Khoảng 31 task, nhiều mốc giờ và trạng thái tiền; vừa sức nếu làm đúng thứ tự mục 2.22 và sẵn phương án cắt giảm|

**Rủi ro còn lại**

|Rủi ro|Ghi chú|
|---|---|
|Sinh viên đi xem phòng rồi mất phòng vì người khác cọc trước|**Chấp nhận theo nguyên tắc** "chưa cọc thì chưa giữ phòng"; trang phòng ghi rõ "Đi xem phòng không giữ phòng"|
|Sinh viên cọc khi chưa xem tận mắt, tới nơi thấy không như mong đợi|Có **bản chụp thông tin lúc cọc**: sai nghiêm trọng thì khiếu nại được hoàn 100%; đúng mô tả mà không thích thì là đổi ý → mất cọc. Giảm bằng trần cọc 1 tháng, cảnh báo rõ trước khi trả, video quay tại chỗ|
|Tự hoàn tất sau 48 giờ khi sinh viên quên báo vấn đề|Điều khoản phải đồng ý trước khi cọc, nhắc lúc T và nhắc cuối lúc T + 24 giờ; là **tự hoàn tất do hết thời hạn phản hồi**, không phải app biết chắc đã nhận phòng|
|Chủ trọ nhận cọc trực tiếp mà không cập nhật app|Sinh viên cọc qua app sau đó vẫn được bảo vệ: khiếu nại → hoàn 100%, ghi vi phạm chủ|
|Số điện thoại chủ trọ hiện cho người đã đăng nhập → có thể bị rủ chuyển tiền ngoài app|Cảnh báo trong chat, nút báo cáo ưu tiên cao, nhắc "chỉ được bảo vệ khi cọc qua app"|
|Né bộ lọc chat bằng cách viết lách|Chuẩn hóa trước khi quét, danh sách từ khóa ở file cấu hình để bổ sung dần|
|Chủ trọ dùng tài khoản phụ (khác số điện thoại) giả làm người thuê để tự đánh giá|Giảm bằng chặn tự giao dịch, 1 số / 1 tài khoản, xác nhận "Tôi đã thuê phòng này"; không chặn được hoàn toàn|
|GPS giả lập khi quay video hoặc chụp bằng chứng khiếu nại|Gắn cờ khi thư viện định vị báo giả lập (cần kiểm tra lại); admin vẫn xem video / ảnh|

---

# PHẦN 3. MODULE QUÁN ĂN

> Module **độc lập**: có luồng, thanh toán, chat, đánh giá, báo cáo, thông báo, kháng nghị, admin, dữ liệu, giao diện, thư mục code **riêng**. Chỉ dùng chung **tài khoản và xác nhận người thật** (Phần 4).

> **🌟 Điểm nổi bật**
> - **Hai loại quán – một nền tảng uy tín** — thấy mọi quán kể cả vỉa hè, nhưng **chỉ hộ kinh doanh đã xác thực mới nhận đơn**; tiền chỉ tới quán khi **có bằng chứng giao / nhận**.
> - **Khác biệt (ngách):** tham khảo Yelp, nhóm thấy hai điều app tìm quán Việt Nam thường chưa làm kỹ và **tự triển khai gọn cho sinh viên**: **lọc theo nhu cầu** (ăn tại quán · mang đi · giao hàng · ★ đánh giá) và **đánh giá 4 tiêu chí** (món ăn · giá · vệ sinh · phục vụ), chỉ tính điểm đánh giá có bằng chứng.

## 3.1 Module làm gì

Giúp sinh viên **tìm quán ăn quanh mình** theo món, giá, khoảng cách, giờ mở cửa; xem menu, khuyến mãi, đánh giá; **đặt bàn**; **đặt món và thanh toán trên app**.

Module phục vụ **hai nhu cầu khác nhau**:
- **Tìm chỗ ăn rồi tự đi** → mọi quán đều hiện, kể cả xe đẩy, quán vỉa hè.
- **Đặt món, giao tận nơi** → chỉ **hộ kinh doanh đã xác thực** mới nhận đơn → giữ uy tín cho nền tảng.

**Chỉ chủ quán mới đăng được quán.** Không cho người khác đăng hộ, vì quán phải là nơi chủ muốn bán và chịu trách nhiệm thông tin.

## 3.2 Khái niệm cần hiểu trước

### Hai loại quán

||**Hộ kinh doanh**|**Bán lẻ / vỉa hè**|
|---|---|---|
|Ví dụ|Quán cơm, quán phở có mặt bằng, có đăng ký|Xe đẩy, gánh hàng, quán vỉa hè, bán tại nhà|
|Xác thực chủ quán|Như mục 4.2|Như mục 4.2|
|Ảnh mặt tiền|Chụp trong app, có GPS|Chụp trong app, có GPS|
|Giấy tờ|**Bắt buộc mã số thuế** + ảnh giấy chứng nhận|Không cần|
|Huy hiệu|**"Đã xác thực kinh doanh"**|**"Đã xác thực chủ quán"**|

### Mỗi loại quán được làm gì

|Quyền|Hộ kinh doanh|Bán lẻ / vỉa hè|
|---|---|---|
|Hiện ở danh sách, bản đồ, có menu, được đánh giá, check-in|✅|✅|
|Ưu tiên khi sắp xếp|Chỉ dùng để **phá hòa**: cùng điểm xếp thì hộ kinh doanh đứng trước. **Không** đẩy quán lên khi chọn "Gần nhất"|—|
|Khuyến mãi|Tối đa 5, **tự trừ vào đơn**|Tối đa 1, **chỉ hiển thị**|
|Nhận đặt bàn|✅ (nếu bật)|❌|
|**Nhận đặt món, thanh toán qua app**|✅ (nếu bật)|❌|

Quán bán lẻ có giấy tờ thì bấm **"Nâng cấp lên hộ kinh doanh"**, gửi mã số thuế + ảnh giấy chứng nhận để duyệt.

*Lưu ý pháp lý:* theo hiểu biết hiện tại, một số trường hợp như bán hàng rong, kinh doanh lưu động, thu nhập thấp không bắt buộc đăng ký hộ kinh doanh, nên lựa chọn "bán lẻ / vỉa hè" là hợp lệ. Khi đưa vào báo cáo cần dẫn đúng văn bản pháp luật hiện hành (cần kiểm tra lại).

### Menu

```
QUÁN
 └── NHÓM MÓN (Món chính, Đồ uống, Món thêm…)
      └── MÓN (tên, giá, ảnh)
           └── TÙY CHỌN (Cỡ: Nhỏ/Lớn · Topping: thêm trứng +5k…)
```

Mỗi nhóm món được đánh dấu **"món chính"** hoặc **"đồ uống / món thêm"** — dùng để tính mức giá của quán.

### Giờ mở cửa

- Khai theo **từng ngày trong tuần**, mỗi ngày **tối đa 2 ca** (ví dụ 6:00–10:00 và 16:00–21:00) hoặc nghỉ.
- **Ca qua nửa đêm** (ví dụ 18:00–02:00) thuộc **ngày bắt đầu ca**.
- App tự hiện trạng thái:

|Trạng thái|Khi nào|Hiện như|
|---|---|---|
|🟢 Đang mở cửa|Trong ca|"Đang mở · Đóng lúc 21:00"|
|🟠 Sắp đóng cửa|Gần hết ca (bảng 3.16)|"Sắp đóng · 20:40"|
|🔴 Đã đóng cửa|Ngoài ca|"Mở lúc 6:00 sáng mai"|
|⏸ Tạm nghỉ hôm nay|Chủ quán bấm|Hết hiệu lực khi tới **ca mở kế tiếp theo lịch tuần, tính từ ngày mai**|
|⏸ Nghỉ đến ngày…|Chủ quán đặt lịch nghỉ|Tự mở lại đúng ngày|

### Trạng thái quán

|Tên|Mã|Nghĩa|Hiện ở danh sách|
|---|---|---|---|
|Nháp|`draft`|Chủ quán đang soạn|Không|
|Chờ duyệt|`pending_review`|Đã gửi, chờ admin|Không|
|Bị từ chối|`rejected`|Admin không duyệt; sửa rồi gửi lại|Không|
|Đang hoạt động|`active`|Đã duyệt|**Có**, khi có ít nhất 3 món|
|Tạm ẩn|`hidden`|Chủ tự ẩn, admin ẩn sau khi xử lý báo cáo, hoặc không xác nhận còn hoạt động|Không|
|Bị đình chỉ|`suspended`|Admin đình chỉ do vi phạm|Không|
|Ngừng kinh doanh|`closed`|Chủ quán đóng quán vĩnh viễn|Không|

"Đang mở / Đã đóng cửa" **không phải trạng thái quán**, mà được tính từ giờ mở cửa. Ẩn / đình chỉ khi đang có đơn hoặc bàn: mục 3.14.

## 3.3 Phía chủ quán — từ đầu đến cuối

### Bước 1. Xác thực người thật
Làm theo **mục 4.2** (xác thực người thật). Tài khoản đã xác thực người thật (mục 4.2) thì không phải làm lại bước này, nhưng **quán vẫn phải đăng ký và duyệt riêng** (Bước 2).

### Bước 2. Đăng quán (form 5 phần)

Có thanh tiến trình, quay lại không mất dữ liệu, tự lưu nháp.

|Phần|Điền gì|Quy định|
|---|---|---|
|**(1) Thông tin chung**|Tên quán · **Loại quán** (hộ kinh doanh / bán lẻ) · Loại món chính · Mô tả · Số điện thoại quán|Tên 3–80 ký tự. Loại món chọn 1–3 trong: Cơm · Bún/Phở/Mì · Bánh mì · Ăn vặt · Lẩu/Nướng · Chay · Đồ uống · Trà sữa · Cà phê · Tráng miệng · Khác|
|**(2) Vị trí và giờ mở cửa**|Địa chỉ + **ghim bản đồ** · Giờ mở cửa từng ngày|*Xe đẩy không đứng cố định:* tick "Bán lưu động", ghim **chỗ bán thường xuyên** + ghi chú ("Đầu hẻm 51"). Đổi chỗ bán thường xuyên thì **chụp lại ảnh và duyệt lại**|
|**(3) Tiện ích**|**Hình thức phục vụ:** Ăn tại quán · Mang đi · Chỗ ngồi trong nhà · Ngồi ngoài trời · Máy lạnh · Wifi · Ổ cắm sạc · Chỗ để xe · Phù hợp học nhóm|**Bắt buộc chọn ít nhất 1 hình thức phục vụ** (ăn tại quán / mang đi). *Chỉ hộ kinh doanh:* Nhận đặt bàn · Nhận đặt món qua app · Quán tự giao|
|**(4) Ảnh**|**Ảnh mặt tiền** (bắt buộc, chụp trong app — ảnh đầu tiên là **ảnh bìa**) · ảnh không gian, ảnh món|Mặt tiền 1–3 ảnh. Ảnh khác 0–10, được chọn từ thư viện, chỉ hiện ở trang chi tiết|
|**(5) Giấy tờ và gửi**|*Hộ kinh doanh:* **mã số thuế** + ảnh giấy chứng nhận (chụp trong app), giấy an toàn thực phẩm (tùy chọn). *Bán lẻ:* không cần. Tick cam kết → xem trước → gửi duyệt||

### Bước 3. Thêm menu (sau khi quán được duyệt)

|Thông tin món|Quy định|
|---|---|
|Tên món · Nhóm món · Giá|Tên 2–60 ký tự, giá > 0|
|Ảnh · Mô tả|Tùy chọn (nên có ảnh)|
|Món nổi bật ⭐|Tối đa 5 món, hiện đầu menu|
|Còn bán / Hết món|Bật tắt nhanh; hết món thì không đặt được|
|Tùy chọn|Tên nhóm (Cỡ, Topping) · bắt buộc hay không · chọn 1 hay nhiều · mỗi lựa chọn có giá cộng thêm|

- Quán có **ít nhất 3 món** mới hiện ở danh sách. Tối đa 20 nhóm, 200 món.
- Sửa menu, giá → hiện ngay, **không cần duyệt**. Đơn đã đặt vẫn giữ giá lúc đặt.

**Mức giá của quán** (app tự tính, cập nhật khi menu đổi):
- Lấy giá các món thuộc nhóm **món chính**. Quán **không có món chính** (chỉ bán đồ uống, trà sữa, cà phê, tráng miệng) thì lấy **toàn bộ món**.
- **Trên thẻ** hiện khoảng từ phân vị 25 tới phân vị 75, dạng "25–40k".
- **Khi lọc theo giá** dùng **giá trung vị**: quán khớp mốc nếu giá trung vị nằm trong mốc. Chip nhanh "Dưới 35k" = giá trung vị dưới 35.000đ.

### Bước 4. Khuyến mãi (tùy chọn)

|Loại|Ví dụ|
|---|---|
|Giảm %|Giảm 10%, tối đa 20k, cho đơn từ 50k|
|Giảm tiền|Giảm 15k cho đơn từ 80k|
|Combo|Cơm + nước 35k|
|Giờ vàng|14:00–16:00 các ngày T2–T6 giảm 20%|
|Ưu đãi sinh viên|Giảm 5k cho tài khoản có huy hiệu "Email trường"|

- Bắt buộc có **ngày bắt đầu, ngày kết thúc** (tối đa 90 ngày). **Hết hạn tự ẩn.**
- Khuyến mãi không cần duyệt, nhưng bị báo cáo "không đúng thực tế" thì admin xử lý.
- **Quán bán lẻ:** khuyến mãi chỉ hiển thị, không tự trừ.

**Cách tính tiền khuyến mãi (hộ kinh doanh, đơn đặt trên app):**
1. **Tiền món (tạm tính)** = tổng (giá món + giá tùy chọn) × số lượng. **Không gồm phí giao.**
2. **Combo:** khi giỏ có đủ các món của combo với số lượng ≥ yêu cầu, giá combo thay cho tổng giá thường của các món đó; phần dư tính giá thường. Mức giảm của combo = tổng giá thường của bộ món − giá combo.
3. **Đơn tối thiểu** của khuyến mãi tính trên tiền món **trước giảm**, không gồm phí giao.
4. **Giảm % / giảm tiền / giờ vàng / ưu đãi sinh viên** tính trên tiền món, **không áp lên phí giao**; mức giảm không vượt tiền món; giảm % có **mức giảm tối đa**.
5. **Giờ vàng** xét theo **thời điểm đặt đơn** (giờ của hệ thống, không lấy giờ điện thoại) và các ngày áp dụng.
6. Mỗi đơn áp **combo (nếu có) + thêm 1 khuyến mãi đơn có lợi nhất** = khuyến mãi giảm được nhiều tiền nhất; bằng nhau thì chọn khuyến mãi sắp hết hạn trước.
7. **Hệ thống luôn tự tính lại**, app chỉ gửi món, số lượng, tùy chọn.

### Bước 5. Cài đặt đặt món (chỉ hộ kinh doanh có bật)

- Hình thức: **Đến lấy** · **Quán tự giao** (một hoặc cả hai).
- Giao hàng: **bán kính giao tối đa** · **phí giao** (cố định hoặc theo km) · **đơn tối thiểu** (tính trên tiền món).
- **Thời gian chuẩn bị trung bình** (phút) — dùng để tính giờ dự kiến.
- Có nhận **tiền mặt khi nhận hàng** không (mục 3.5c).
- Sửa lại được bất cứ lúc nào trong trang quản lý (không cần duyệt).

### Bước 6. Quản lý hằng ngày

Đồ án dùng **1 tài khoản chủ quán**, đăng nhập được trên **nhiều thiết bị**, thiết bị nào cũng nhận chuông đơn mới.

|Mục|Làm gì|
|---|---|
|**Đơn hàng** *(mục đầu tiên, có chuông báo đơn mới)*|Đơn mới (đếm ngược) · Đang làm · Sẵn sàng / Đang giao · Đã xong · Khiếu nại. Nút: Nhận · Từ chối · Sẵn sàng · Đang giao · **Nhập mã nhận món** (đến lấy) · **Đã giao + chụp ảnh** (giao) · Khách không nhận · Hủy|
|**Đặt bàn**|Xác nhận · Từ chối · Khách đã đến · Khách không đến|
|**Menu**|Sửa món, bật tắt còn / hết|
|**Khuyến mãi**|Tạo, sửa, dừng|
|**Giờ mở cửa**|Lịch tuần · **Tạm nghỉ hôm nay** · Nghỉ dài ngày · **Tạm ngưng nhận đơn** (khi quá đông, quán vẫn hiện là đang mở). Bấm tạm nghỉ khi đang có đơn / bàn: xử lý theo mục 3.14|
|**Doanh thu**|Số đơn, tổng tiền theo ngày / tuần · tiền đang giữ / đã nhận|
|**Thông tin quán**|Sửa thông tin · cài đặt đặt món · **nâng cấp lên hộ kinh doanh** · **Ngừng kinh doanh** (quán chuyển `closed`; bị chặn khi còn giao dịch đang chạy, mục 3.14)|
|**Tin nhắn · Đánh giá**||

**Sửa thông tin quán:**
- Sửa **menu, giá, giờ mở cửa, khuyến mãi, tiện ích (kể cả hình thức phục vụ), mô tả, cài đặt đặt món** → hiện ngay.
- Sửa **tên quán, loại quán, địa chỉ, vị trí ghim, ảnh mặt tiền, giấy tờ** → tạo **bản chỉnh sửa chờ duyệt**; bản cũ vẫn hiện, duyệt xong mới thay, bị từ chối thì giữ bản cũ và thấy lý do.

**Quán còn hoạt động không?** 90 ngày không có cập nhật, check-in hay đơn nào → app nhắc chủ quán bấm "Quán vẫn hoạt động". 7 ngày không bấm → quán bị ẩn.

**Chỉ số công khai:** tỷ lệ phản hồi tin nhắn · **tỷ lệ nhận đơn** (phần trăm đơn được quán nhận và không hủy, tính 30 ngày; hiện khi quán nhận đặt món) · **tỷ lệ giữ bàn** (phần trăm bàn đã xác nhận mà quán không hủy, tính 30 ngày; hiện khi quán nhận đặt bàn) · điểm đánh giá.

## 3.4 Phía sinh viên — từ đầu đến cuối

### Bước 1. Tìm quán

**Màn hình danh sách:**
```
[ 🔍 Tìm quán, tên món, tên đường...        ⚙ Lọc   🗺 ]
[ Đang mở ] [ Gần tôi ] [ Dưới 35k ] [ Đặt món ] [ Khuyến mãi ] [ Học nhóm ]
18 quán phù hợp                           Sắp xếp: Gần nhất ▾
[ Thẻ quán ]
```

**Mỗi thẻ quán có:** ảnh bìa (ảnh mặt tiền chụp trong app) · tên · huy hiệu · **★ điểm xác minh** (hoặc "Chưa có đánh giá xác minh") · loại món · khoảng giá "25–40k" · "Cách bạn 400 m" · 🟢 Đang mở · Đóng 21:00 / 🔴 Đã đóng · nhãn 🏷 Khuyến mãi · 🛵 Đặt món · 🔥 Sinh viên hay ăn · 🆕 Mới mở · ❤️.

**Thanh tìm kiếm:** tìm được theo **tên quán, tên món**, tên đường, phường; gõ không dấu vẫn ra.

**Bộ lọc:**

|Lọc theo|Lựa chọn|
|---|---|
|Loại món|Cơm · Bún/Phở/Mì · Bánh mì · Ăn vặt · Lẩu/Nướng · Chay · Đồ uống · Trà sữa · Cà phê · Tráng miệng|
|Mức giá|Mốc theo giá trung vị (bảng 3.16)|
|Khoảng cách|Điểm gốc + bán kính (mục 3.7)|
|Đang mở cửa|*Bật sẵn*|
|**Hình thức phục vụ**|**Ăn tại quán** · **Mang đi** (quán tự khai)|
|**Giao hàng (đặt qua app)**|Chỉ hiện quán nhận đơn và **giao tới chỗ bạn được** (hoặc có đến lấy). Không do quán tự khai: chỉ hộ kinh doanh đã bật đặt món mới có (mục 3.2)|
|**Điểm đánh giá**|Từ ★4 trở lên · Từ ★3,5 trở lên (theo điểm tổng thể đã xác minh)|
|Tiện ích|Ngồi ngoài trời · Máy lạnh · Wifi · Ổ cắm · Chỗ để xe · Phù hợp học nhóm · Nhận đặt bàn|
|Loại quán|Hộ kinh doanh · Bán lẻ / vỉa hè|
|Có khuyến mãi|Bật / tắt|

- **Sắp xếp:** Gần nhất · Đánh giá cao nhất · Giá thấp nhất · Sinh viên hay ăn · Mới mở. Quán đang mở luôn xếp trước quán đã đóng; cùng điểm xếp thì hộ kinh doanh trước.
- **🔥 Sinh viên hay ăn:** đếm **số người khác nhau** có check-in hoặc đơn hoàn tất trong 30 ngày (mỗi người tính tối đa 1 lượt / quán / 7 ngày, không tính chủ quán). Quán có **ít nhất 10 người** và nằm trong **20% cao nhất so với các quán trong bán kính 3 km quanh nó** thì có nhãn. Tính mỗi đêm, không tính lúc tìm kiếm.
- **🆕 Mới mở:** quán được duyệt trong 30 ngày gần đây.
- **Bản đồ:** ghim hiện khoảng giá; xanh = đang mở, xám = đã đóng.

### Bước 2. Xem quán

**Trang quán, từ trên xuống:**
1. **Thông tin:** ảnh mặt tiền, ảnh không gian · tên, huy hiệu, ★ điểm xác minh · loại món, khoảng giá · trạng thái mở cửa + xem giờ cả tuần · hình thức phục vụ (ăn tại quán / mang đi / giao hàng qua app) · tiện ích · mô tả · địa chỉ + bản đồ + Chỉ đường · chủ quán (tỷ lệ phản hồi, tỷ lệ nhận đơn, tỷ lệ giữ bàn, số điện thoại, Gọi, Nhắn tin) · ❤️ · 📍 Check-in · Báo cáo.
2. **Khuyến mãi** đang có.
3. **Menu:** thanh nhóm món cuộn ngang · món nổi bật trên cùng · mỗi món có ảnh, tên, giá, nút **＋** · món hết hiện mờ.
4. **Đánh giá.**

**Nút ở cuối trang:**

|Quán|Nút chính|Nút phụ|
|---|---|---|
|Nhận đặt món, đang mở, chưa tạm ngưng|🛒 Xem giỏ (2 món · 70k)|📅 Đặt bàn (nếu có)|
|Nhận đặt món và đặt bàn, nhưng **đang đóng cửa** hoặc **tạm ngưng nhận đơn**|📅 Đặt bàn (đặt trước cho giờ mở cửa)|💬 Nhắn tin · dòng "Đang đóng cửa — mở lúc …" / "Tạm ngưng nhận đơn"|
|Chỉ nhận đặt bàn|📅 Đặt bàn|💬 Nhắn tin|
|**Tạm nghỉ** (nghỉ hôm nay / nghỉ đến ngày…)|🧭 Chỉ đường|💬 Nhắn tin · dòng "Tạm nghỉ đến …"; không đặt món, không đặt bàn trong thời gian nghỉ|
|Quán còn lại|🧭 Chỉ đường|💬 Nhắn tin|

### Bước 3. Check-in khi tới quán (tùy chọn)

- Bấm **📍 Check-in**. Điều kiện: đã đăng nhập, đứng **gần quán** (bảng 3.16), **trong giờ mở cửa**, **1 lần / quán / ngày**.
- Kèm ảnh (chụp trong app) và cảm nghĩ ngắn — đều tùy chọn.
- Tác dụng: đánh giá có nhãn **"📍 Check-in tại quán"** (GPS chỉ cho biết đã đứng gần quán, không chứng minh chắc đã ăn — nên đây là nhãn yếu nhất); được tính vào **"Sinh viên hay ăn"** (theo luật ở Bước 1); dùng làm bằng chứng đã tới khi đặt bàn (mục 3.5e).

### Bước 4. Đặt bàn (quán hộ kinh doanh có bật)

1. Chọn **ngày giờ** (cách hiện tại **ít nhất 1 giờ**, trong **7 ngày tới**, trong giờ mở cửa), **số người** (1–20), ghi chú → gửi. Cần đã OTP.
2. Quán **xác nhận trong 30 phút, nhưng không muộn hơn giờ hẹn − 30 phút**; không trả lời thì tự hết hạn.
3. App nhắc sinh viên **1 giờ trước** giờ hẹn.
4. Quán **giữ bàn 15 phút**. Tới nơi → sinh viên **check-in** (để có nhãn 🍽) và / hoặc quán bấm "Khách đã đến" (chỉ để quản lý bàn, không sinh nhãn). Quá 15 phút → quán bấm "Khách không đến" (trừ khi sinh viên đã check-in hợp lệ, mục 3.5e).

Đặt bàn **không thu tiền** trong đồ án.

### Bước 5. Đặt món và thanh toán (quán hộ kinh doanh có bật)

**5a. Thêm món vào giỏ**
- Giỏ chỉ chứa món của **1 quán**. Thêm món quán khác → app hỏi "Xóa giỏ hiện tại?".
- Mỗi món chọn số lượng, tùy chọn (phải chọn đủ phần bắt buộc), ghi chú.

**5b. Đặt món**
- Chọn **Đến lấy** hoặc **Giao tận nơi** (chọn địa chỉ đã lưu hoặc vị trí hiện tại — ngoài bán kính giao thì không chọn được).
- Chọn giờ:
  - **Càng sớm càng tốt** (`asap`): app hiện giờ dự kiến.
  - **Hẹn giờ** (`scheduled`): cách hiện tại **30 phút – 2 giờ**, và phải **trước giờ đóng cửa của ca đang mở** (quán đang tạm nghỉ hoặc tạm ngưng nhận đơn thì không hẹn được). Không có quản lý suất theo khung giờ.
  - Cả hai loại đều gửi quán **ngay** và quán nhận trong **5 phút**. Với đơn hẹn giờ, giờ dự kiến sẵn sàng = giờ hẹn.
- Số điện thoại người nhận (đã OTP) + ghi chú cho quán.
- Xem **tổng tiền**: tiền món · giảm giá (tự áp, ghi tên khuyến mãi) · phí giao · **tổng**. Chưa đủ đơn tối thiểu thì không đặt được.
- Chọn cách trả: **Trên app (PayPal / MoMo)** — mặc định · hoặc **Tiền mặt khi nhận** (nếu quán cho phép và đủ điều kiện, mục 3.5c).
- Bấm **"Đặt món · 85.000đ"** → hệ thống **tính lại toàn bộ giá** theo menu hiện tại (app chỉ gửi món, tùy chọn, số lượng, cách nhận, địa chỉ, không gửi số tiền) → thanh toán → **app giữ tiền** → đơn gửi tới quán.
- **Chốt giá khi tạo đơn:** đơn lưu lại giá từng món, tùy chọn, khuyến mãi đã áp, phí giao, tổng. Sau đó quán đổi giá, khuyến mãi hết hạn hay món chuyển "Hết" **không làm đổi đơn đã tạo**.
- **Thay đổi trong lúc đang đặt** (trước khi đơn được tạo): món vừa hết, quán vừa tạm ngưng / đóng, khuyến mãi vừa hết hạn, giá vừa đổi → hệ thống không tạo đơn và báo lý do hoặc tổng tiền mới, sinh viên xem lại rồi bấm đặt lần nữa. Không tạo giao dịch thanh toán nào.
- **Thay đổi sau khi đã trả tiền** (đơn đang chờ quán xác nhận): quán không làm được thì bấm "Từ chối" → hoàn 100%.

**5c. Theo dõi đơn**
```
Chờ quán xác nhận → Đang chuẩn bị → Sẵn sàng để lấy / Đang giao → Đã giao (có bằng chứng) → Hoàn tất
```
Đầy đủ trạng thái, kể cả hủy, khiếu nại và tiền mặt: **mục 3.5i**.

Khi đơn bị chậm:
- **Quán chậm:** quá giờ dự kiến sẵn sàng (đơn hẹn giờ: giờ hẹn) + 30 phút mà quán chưa báo "Sẵn sàng" / "Đang giao" → sinh viên có nút **"Hủy vì quán chậm"** → hoàn 100%.
- **Giao lâu:** đơn "Đang giao" quá 60 phút → sinh viên có nút **"Chưa nhận được món"** → mở khiếu nại ngay.
- **Đến lấy mà không nhận được món:** gọi **T_lấy** = **thời điểm nhận món dự kiến** của đơn (đơn hẹn giờ: giờ hẹn; đơn "càng sớm càng tốt": giờ dự kiến sẵn sàng quán ghi khi bấm "Nhận"; mọi đơn đến lấy đều có T_lấy). Nút **"Chưa nhận được món"** chỉ **bấm được từ T_lấy trở đi**, không cần chờ thêm. Quán báo "Sẵn sàng" sớm hơn T_lấy thì sinh viên vẫn thấy "Sẵn sàng" nhưng nút **mờ**, kèm dòng *"Bạn có thể báo chưa nhận được món từ thời điểm nhận món dự kiến."* (ví dụ T_lấy 18:00, quán xong 17:30 → 17:30–17:59 nút mờ, từ 18:00 bấm được). Bấm nút **không** phải hoàn tiền tự động: đơn trả trên app thì tiền tiếp tục giữ và chuyển sang khiếu nại (mục 3.5d); đơn tiền mặt thì ghi nhận tranh chấp giao nhận, admin xác minh. Mốc 6 giờ vẫn chỉ là dự phòng.

**5d. Nhận món — phải có bằng chứng giao / nhận**

Quán **không được** chỉ bấm "Đã giao" một phía. App chỉ ghi nhận đã giao / đã lấy khi có **bằng chứng hợp lệ**:

|Loại đơn|Bằng chứng|
|---|---|
|**Đến lấy**|Khi đơn "Sẵn sàng", app của sinh viên hiện **mã nhận món 4 số**. Sinh viên tới quán đọc mã, quán **nhập đúng mã** → ghi nhận "Khách đã lấy". Nhập sai thì không ghi nhận|
|**Giao tận nơi**|Quán / người giao bấm "Đã giao" và **chụp ảnh giao hàng trong app**, có GPS lúc chụp, trong ngưỡng GPS (bảng 3.16) so với điểm giao. Thiếu ảnh hoặc GPS không hợp lệ → không ghi nhận|

- **Đơn trả trên app:** có bằng chứng → đơn chuyển **"Chờ xác nhận nhận món"** (`delivered`), tiền **vẫn giữ**. Sinh viên có **24 giờ** để báo **"Chưa nhận được món"** hoặc khiếu nại (mục 3.5d).
- **Đơn tiền mặt:** dùng **cùng chuẩn** mã / ảnh như đơn trả trên app.
  - *Đến lấy:* quán nhập đúng mã (sinh viên đọc mã = bằng chứng từ phía sinh viên) → **hoàn tất**.
  - *Giao tận nơi:* có ảnh giao GPS hợp lệ → **chưa hoàn tất ngay**, đơn chuyển **"Chờ xác nhận nhận món"** (`delivered`) và bắt đầu **24 giờ** để sinh viên báo **"Chưa nhận được món"**. Không phản đối → hoàn tất. Phản đối → chuyển admin xác minh.
  - 24 giờ này với đơn tiền mặt **chỉ để xác minh giao nhận và điều kiện nhãn 🛵**, không liên quan giải ngân (tiền trả trực tiếp).
- Nhận đủ, đúng → sinh viên bấm **"Đã nhận món"** → hoàn tất; đơn trả trên app thì tiền chuyển cho quán. **Bấm "Đã nhận món" là chốt, không khiếu nại được nữa** (hộp xác nhận ghi rõ). Sinh viên bấm trước khi quán ghi nhận bằng chứng → hoàn tất luôn.
- Đơn trả trên app có bằng chứng mà sinh viên không làm gì → app nhắc sau 1 giờ và khi còn 1 giờ; hết **24 giờ** không phản đối → hoàn tất, tiền chuyển cho quán.
- **Không có bằng chứng thì không bao giờ tự coi là đã giao.** Mốc **6 giờ chỉ là phương án dự phòng**: đơn ở "Sẵn sàng" / "Đang giao" quá **6 giờ** mà chưa có bằng chứng giao / nhận **và** cả hai bên đều không xử lý (không "Đã nhận món", không "Chưa nhận được món", không "Khách không nhận") → **tự gắn cờ chuyển admin**. Tiền **tiếp tục giữ**: **không** tự hoàn cho sinh viên, **không** tự giải ngân cho quán. Admin xem chat, dòng thời gian, bằng chứng rồi quyết (đơn trả trên app: hoàn 100% / chuyển tiền cho quán; đơn tiền mặt: đóng đơn hoàn tất hoặc hủy). Admin kết luận **đơn thực tế đã giao / nhận** thì đơn được coi là **đã xác minh** (đủ điều kiện nhãn 🛵); không xác định được thì không cấp nhãn.
- Đơn xong có nút **"Đặt lại"** và nhắc đánh giá.

### Bước 6. Đánh giá

- **Ai được viết:** mọi người **đã đăng nhập, đã xác nhận email** (giống các nền tảng hiện nay). Check-in là tùy chọn.
- Mỗi người **1 đánh giá cho mỗi quán**, sửa được. Tối đa 10 đánh giá / ngày.
- **Nguyên tắc: một bên không thể tự tạo bằng chứng uy tín cho chính mình.** Quán chỉ bấm một phía thì không sinh ra nhãn. Xác minh chỉ đến từ: hành động hợp lệ của phía sinh viên · bằng chứng giao / nhận theo cơ chế hệ thống · hoặc kết luận của admin sau khi xem bằng chứng. Khóa bán, gắn cờ, hết hạn **không** thay thế bằng chứng.

|Nhãn|Điều kiện|Tính vào điểm chính|
|---|---|---|
|**🛵 Đã đặt món**|Đơn **hoàn tất** và **đã xác minh**: sinh viên bấm "Đã nhận món", **hoặc** quán nhập đúng mã nhận món 4 số (đến lấy), **hoặc** có ảnh giao hàng GPS hợp lệ và hết 24 giờ sinh viên không phản đối, **hoặc** admin kết luận đơn thực tế đã giao / nhận (sau cờ 6 giờ, khiếu nại, "Chưa nhận được món"). Áp dụng cả đơn trả trên app và đơn tiền mặt (đơn tiền mặt giao tận nơi **không** có nhãn ngay khi có ảnh, phải qua 24 giờ). Đơn hoàn tất do "Khách không nhận" (bom hàng) **không** có nhãn|✅ (người viết đã OTP)|
|**🍽 Đã đến theo đặt bàn**|**Chỉ khi sinh viên check-in hợp lệ** tại quán, gắn được với lượt đặt bàn đó (gần quán, trong giờ giữ bàn). Quán bấm "Khách đã đến" **không** sinh nhãn (chỉ để quản lý bàn); tự đóng sau 24 giờ cũng không có nhãn|✅|
|**📍 Check-in tại quán**|Check-in GPS hợp lệ|✅|
|Không nhãn ("Chưa xác minh")|Chỉ đăng nhập + xác nhận email|❌ — hiện điểm phụ, màu nhạt, xếp sau|

- **Nhãn xác minh** (từ mạnh tới yếu): **🛵 Đã đặt món** (điều kiện ở bảng trên) · **🍽 Đã đến theo đặt bàn** (sinh viên check-in hợp lệ gắn với lượt đặt bàn) · **📍 Check-in tại quán** (check-in GPS hợp lệ). Một đánh giá có nhiều bằng chứng thì hiện nhãn mạnh nhất. Cả ba đều tính vào điểm; đánh giá có nhãn mạnh hơn được xếp trước.
- **Điểm chính của quán** (hiện trên thẻ, dùng để sắp xếp) **chỉ tính từ đánh giá có nhãn của người đã OTP**. Quán chưa có đánh giá xác minh → hiện "Chưa có đánh giá xác minh".
- Đánh giá **không có nhãn** vẫn hiển thị, ghi **"Chưa xác minh"**, xếp sau; điểm trung bình của chúng chỉ hiện phụ, màu nhạt.
- **Đánh giá có cấu trúc — chấm 1–5 sao, bắt buộc đủ 4 tiêu chí:** 🍜 **Chất lượng món ăn** · 💰 **Giá cả / đáng tiền** · 🧹 **Vệ sinh** · 🙋 **Phục vụ**. Không có ô chấm "điểm chung" riêng.
- **Điểm tổng thể của một đánh giá** = (Món ăn + Giá cả + Vệ sinh + Phục vụ) / 4, app tự tính.
- **Điểm của quán:** điểm tổng thể = trung bình điểm tổng thể các đánh giá hợp lệ (đã xác minh, như trên); **đồng thời tính riêng điểm trung bình từng tiêu chí**. Hai quán cùng ★4,4 vẫn thấy được quán nào mạnh món ăn, quán nào giá tốt, quán nào sạch, quán nào phục vụ tốt.
- **Trang quán hiện:** ⭐ điểm tổng thể · số lượt đánh giá · điểm 4 tiêu chí · danh sách đánh giá (nhận xét, ảnh, nhãn xác minh). Ví dụ:
  ```
  ⭐ 4.4 Tổng thể · 128 đánh giá
  🍜 Món ăn 4.6   💰 Giá cả 4.7   🧹 Vệ sinh 4.1   🙋 Phục vụ 4.2
  ```
- **Thẻ quán ở danh sách** chỉ hiện điểm tổng thể (không hiện 4 tiêu chí).
- **Thẻ nhanh:** Món ngon · Phục vụ nhanh · Giá hợp lý · Phần ăn nhiều · Sạch sẽ · Hợp học nhóm · Chờ lâu · Giá cao · Ồn ào · Ít chỗ ngồi.

**Những việc khác của sinh viên:**
- **❤️ Lưu quán:** được báo khi quán có khuyến mãi mới, hoặc mở lại sau kỳ nghỉ.
- **Chat:** câu hỏi nhanh "Quán còn mở không ạ?", "Quán có giao tới … không ạ?", "Món này còn không ạ?", "Còn bàn cho … người không ạ?".
- **Trang "Của tôi":** đơn đang làm và đã xong · đặt bàn · check-in · quán đã lưu · địa chỉ đã lưu · lần bỏ hẹn, bom hàng (kháng nghị được, mục 3.15).

## 3.5 Luật và tình huống đặc biệt

### a) Hủy đơn và quá hạn (đơn trả trên app)

|Tình huống|Xử lý|
|---|---|
|Chưa thanh toán trong thời hạn chờ|Đơn hết hạn|
|Tiền đến muộn sau khi đơn hết hạn|Tự hoàn 100% (mục 3.6)|
|Sinh viên hủy khi quán **chưa nhận**|Hoàn 100%|
|Quán **đã nhận** đơn|Sinh viên không hủy được nữa (trừ "Hủy vì quán chậm")|
|Quán **từ chối**|Hoàn 100%|
|Quán **không xác nhận kịp**|Tự hủy, hoàn 100%|
|Quán quá hạn xác nhận **3 lần trong 1 ngày**|Quán tự bị "Tạm ngưng nhận đơn" tới hết ngày|
|Quán **hủy sau khi đã nhận**|Hoàn 100%, giảm tỷ lệ nhận đơn|
|**Quán chậm** (quá giờ dự kiến sẵn sàng / giờ hẹn + 30 phút) và sinh viên bấm "Hủy vì quán chậm"|Hoàn 100%, tính là quán hủy (giảm tỷ lệ nhận đơn)|

### b) Khách không nhận món (bom hàng)

1. Đơn giao gọi không nghe máy, hoặc đơn đến lấy **quá 30 phút** từ lúc "Sẵn sàng" mà khách không tới → quán bấm **"Khách không nhận"**, bắt buộc **ảnh chụp trong app có GPS** (đơn giao: tại điểm giao; đơn đến lấy: tại quán).
2. Nút này chỉ là **báo cáo của quán** ("giao thất bại"), **chưa phải kết luận** sinh viên bom hàng. Sinh viên được báo ngay và **trong 24 giờ** có nút **"Phản đối"** → chuyển admin xét.
3. Đơn trả trên app: tiền **giữ thêm 24 giờ**, chưa chuyển ngay.
4. Hết 24 giờ không phản đối, hoặc admin bác phản đối → đơn trả trên app thì tiền chuyển cho quán (đơn tiền mặt không có tiền để chuyển); **lúc đó mới tính 1 lần bom hàng**.
5. Admin chấp nhận phản đối → hoàn cho sinh viên, **không tính bom hàng**.
6. Bom hàng tính theo số điện thoại, cửa sổ 30 ngày:
   - **2 lần** → không được chọn tiền mặt khi nhận.
   - **3 lần** → khóa đặt món 7 ngày.
   - Kháng nghị được (mục 3.15).

### c) Tiền mặt khi nhận

- Quán tự bật. Chỉ cho đơn **dưới mức tối đa** (bảng 3.16). Sinh viên phải đã OTP và không bị khóa tiền mặt.
- **Không có giữ tiền, không có hoàn tiền.**
- Quán từ chối hoặc hủy → chỉ hủy đơn.
- **Không có giải ngân:** mọi chỗ **trong module này** ghi "chuyển tiền cho quán" / "hoàn tiền" **chỉ áp dụng cho đơn trả trên app**. Đơn tiền mặt không có khoản tiền nào qua app, nên không bao giờ có chuyển tiền hay hoàn tiền.
- **Hoàn tất khi:** sinh viên bấm "Đã nhận món" · đến lấy: quán nhập đúng mã nhận món · giao tận nơi: có ảnh giao GPS hợp lệ **và hết 24 giờ** sinh viên không báo "Chưa nhận được món" (mục 3.4 Bước 5d). Quá 6 giờ chưa có bằng chứng và hai bên không xử lý → gắn cờ chuyển admin.
- **Không mở khiếu nại tiền** (thiếu món, sai món… dùng nút **"Báo cáo"**, mục 3.10). Riêng **"Chưa nhận được món"** vẫn có để admin **xác minh giao nhận**: admin kết luận đã giao → `completed` (có nhãn 🛵); không giao → `cancelled_restaurant`.
- "Khách không nhận" vẫn áp dụng (có phản đối 24 giờ), bom hàng vẫn tính.

### d) Khiếu nại đơn (đơn trả trên app)

1. Gửi trong **24 giờ kể từ lúc app ghi nhận bằng chứng giao / nhận** (`delivered`), trước khi sinh viên bấm "Đã nhận món". Hoặc mở từ nút "Chưa nhận được món" (đến lấy: từ thời điểm nhận món dự kiến T_lấy, khi đơn đã "Sẵn sàng"; giao: quá 60 phút "Đang giao", hoặc trong 24 giờ sau khi quán ghi nhận đã giao).
2. Lý do: Không nhận được món · Thiếu món · Sai món · Món hư / mất vệ sinh · Khác.
3. Bắt buộc **ảnh chụp trong app** (trừ lý do "Không nhận được món").
4. Quán trả lời trong **2 giờ**, có thể tự đồng ý hoàn tiền (toàn phần hoặc một phần). Không trả lời → chuyển admin quyết dựa trên bằng chứng của sinh viên.
5. Hai bên không thống nhất → admin quyết: **hoàn toàn phần · hoàn một phần · chuyển tiền cho quán**. Admin kết luận đơn thực tế đã giao / nhận thành công → đơn **đã xác minh**, đánh giá được nhãn 🛵.
6. Khiếu nại treo quá **72 giờ** → cờ khẩn. **Không tự giải ngân khi đang khiếu nại.**
7. Sinh viên khiếu nại sai sự thật (bị admin bác) **3 lần / 30 ngày** → khóa đặt món trả trên app 30 ngày (kháng nghị được, mục 3.15).

### e) Đặt bàn

- Hủy khi quán **chưa xác nhận** (`pending`) → **không phạt**, dù sát giờ. Bàn **đã xác nhận**: hủy trước giờ hẹn **ít nhất 1 giờ** → không phạt; hủy **sát giờ** (dưới 1 giờ) hoặc không đến → **1 lần bỏ hẹn đặt bàn**.
- **3 lần bỏ hẹn đặt bàn trong 30 ngày → khóa đặt bàn 7 ngày** (chỉ trong module Quán ăn, gắn với số điện thoại, kháng nghị được).
- Sinh viên đã **check-in hợp lệ** tại quán (gần quán, trong khoảng giờ giữ bàn) → nút "Khách không đến" của quán **bị vô hiệu**, không tính bỏ hẹn.
- Quán hủy bàn đã xác nhận → giảm **tỷ lệ giữ bàn** (không ảnh hưởng tỷ lệ nhận đơn).

### f) Chống khai sai loại quán

1. **Đăng ký hộ kinh doanh gọn:** chỉ mã số thuế + ảnh giấy chứng nhận.
2. **Quyền lợi chênh lệch:** muốn nhận đơn qua app thì phải là hộ kinh doanh.
3. **Tự cảnh báo admin** khi quán khai bán lẻ nhưng: chọn máy lạnh / chỗ ngồi trong nhà · ảnh có biển hiệu cố định · menu trên 40 món · mở cửa trên 14 giờ/ngày. Admin xem lại, đúng thì yêu cầu **chuyển loại trong 7 ngày**, không chuyển thì ẩn quán.
4. Tick cam kết khi đăng ký + người dùng báo cáo "Khai sai loại hình".

### g) Kiểm tra giấy tờ giả (riêng quán ăn)
Admin tra **mã số thuế** trên trang tra cứu công khai: **còn hoạt động** · **tên chủ hộ khớp CCCD** · **địa chỉ khớp GPS** · (nếu áp dụng) **mã số thuế trùng số CCCD chủ quán** (theo hiểu biết hiện tại, từ 01/07/2025 mã số thuế của cá nhân, hộ kinh doanh dùng số định danh cá nhân — cần kiểm tra lại). Mức chắc chắn cao. Không khớp → từ chối. Phát hiện giả → ẩn quán, **khóa bán vĩnh viễn** trong Quán ăn, và **đề nghị admin danh tính** khóa cả tài khoản + chặn CCCD và số điện thoại (admin danh tính quyết, mục 4.4).

### h) Lý do báo cáo riêng của Quán ăn
Quán không tồn tại / đã đóng · Sai giờ mở cửa · Sai giá · Khuyến mãi không đúng thực tế · Khai sai loại hình · **Mất vệ sinh an toàn thực phẩm** *(ưu tiên cao)* · **Yêu cầu chuyển khoản ngoài app** *(ưu tiên cao)*.

### i) Trạng thái đơn món

|Tên|Mã|Từ|Ai / khi nào|Tiền (đơn trả trên app)|
|---|---|---|---|---|
|Chờ thanh toán|`pending_payment`|(mới)|SV đặt, trả trên app|Chưa thu|
|Hết hạn thanh toán|`expired`|`pending_payment`|Hết thời hạn chờ / thanh toán lỗi|Không thu (tiền đến muộn → `refunded`)|
|Chờ quán xác nhận|`placed`|(mới) / `pending_payment`|SV đặt tiền mặt / thanh toán thành công|Giữ|
|Sinh viên hủy|`cancelled_student`|`placed`|SV hủy|Hoàn 100%|
|Quán từ chối|`rejected`|`placed`|Quán bấm "Từ chối"|Hoàn 100%|
|Quán không xác nhận kịp|`expired_accept`|`placed`|Quá hạn xác nhận|Hoàn 100%|
|Đang chuẩn bị|`accepted`|`placed`|Quán bấm "Nhận" (ghi giờ dự kiến sẵn sàng)|Giữ|
|Quán hủy|`cancelled_restaurant`|`accepted`|Quán hủy, hoặc SV bấm "Hủy vì quán chậm" (lý do `restaurant_late`)|Hoàn 100%|
|Quán hủy (do quán ngừng nhận)|`cancelled_restaurant`|`placed`|Quán tạm nghỉ / bị ẩn / bị đình chỉ khi đơn còn chờ xác nhận (mục 3.14)|Hoàn 100%|
|(quán bị kết luận lừa đảo)|giữ nguyên trạng thái, gắn cờ "rà soát do quán lừa đảo"|`placed` / `accepted` / `ready` / `delivering` / `delivered` / `not_received`|Admin kết luận quán lừa đảo (mục 3.14). **Không** tự hoàn, **không** tự giải ngân; từng đơn xét theo bằng chứng của chính đơn đó: đã giao thật → `completed`; bằng chứng giả / không giao → `refunded` (hoàn 100%); chưa đủ căn cứ → giữ tiền, xử lý như tranh chấp (`disputed`)|Tiếp tục giữ tới khi admin quyết|
|Sẵn sàng để lấy|`ready`|`accepted`|Quán bấm "Sẵn sàng" (đơn đến lấy)|Giữ|
|Đang giao|`delivering`|`accepted`|Quán bấm "Đang giao" (đơn giao)|Giữ|
|Chờ xác nhận nhận món|`delivered`|`ready` / `delivering`|Có **bằng chứng hợp lệ**: đơn trả trên app — quán nhập đúng mã (đến lấy) hoặc chụp ảnh giao GPS (giao); **đơn tiền mặt giao tận nơi** — chụp ảnh giao GPS|Giữ, mở 24 giờ phản đối / khiếu nại (tiền mặt: chỉ để xác minh giao nhận)|
|Hoàn tất|`completed`|`ready` / `delivering` / `delivered` / `not_received`|SV bấm "Đã nhận món" · hết 24 giờ từ `delivered` không phản đối · tiền mặt đến lấy: quán nhập đúng mã · `not_received` hết 24 giờ không phản đối|Chuyển cho quán|
|Khách không nhận|`not_received`|`ready` / `delivering`|Quán bấm, có ảnh GPS|Giữ thêm 24 giờ|
|(gắn cờ quá hạn)|giữ nguyên `ready` / `delivering`|`ready` / `delivering`|**Hệ thống:** quá 6 giờ chưa có bằng chứng giao / nhận, hai bên không xử lý → gắn cờ, vào hàng chờ admin|Tiếp tục giữ|
|(admin quyết đơn quá hạn)|`refunded` / `completed`|`ready` / `delivering` có cờ|Admin: không giao được → hoàn 100% · đã giao thật → chuyển tiền cho quán, đơn **đã xác minh** (nhãn 🛵) (tiền mặt: `cancelled_restaurant` / `completed`)|Theo quyết định|
|Đang khiếu nại|`disputed`|`ready` / `delivered` / `delivering` / `not_received`|SV khiếu nại / "Chưa nhận được món" (đến lấy: từ T_lấy) / phản đối "Khách không nhận". Admin kết luận đã giao / nhận → `completed`, đơn đã xác minh (nhãn 🛵)|Tạm giữ|
|Đã hoàn toàn bộ|`refunded`|`disputed` / `expired`|Kết quả khiếu nại / tiền đến muộn|Hoàn 100%|
|Đã hoàn một phần|`partially_refunded`|`disputed`|Kết quả khiếu nại|Hoàn một phần, phần còn lại chuyển quán|
|(khiếu nại bị bác)|`completed`|`disputed`|Admin bác|Chuyển cho quán|

Đơn **tiền mặt** chỉ đi qua: `placed` → `accepted` → `ready` → `completed` (quán nhập đúng mã, hoặc SV bấm "Đã nhận món") / `delivering` → `delivered` (ảnh giao GPS) → `completed` (hết 24 giờ không phản đối, hoặc SV bấm "Đã nhận món"); SV bấm "Chưa nhận được món" → `disputed` để admin **xác minh giao nhận** (đã giao → `completed`, không giao → `cancelled_restaurant`); quá 6 giờ không bằng chứng → cờ admin, admin đóng thành `completed` hoặc `cancelled_restaurant`; hoặc `cancelled_student` / `rejected` / `expired_accept` / `cancelled_restaurant` / `not_received` (phản đối → `disputed` chỉ để admin quyết có tính bom hàng hay không: tính → `completed`; không tính → `cancelled_restaurant`; không có tiền chuyển hay hoàn).

### j) Trạng thái đặt bàn

|Tên|Mã|Từ|Ai / khi nào|
|---|---|---|---|
|Chờ quán xác nhận|`pending`|(mới)|SV gửi|
|Đã xác nhận|`confirmed`|`pending`|Quán xác nhận trong hạn|
|Bị từ chối|`rejected`|`pending`|Quán từ chối|
|Hết hạn|`expired`|`pending`|Quán không trả lời trong hạn|
|Sinh viên hủy|`cancelled_student`|`pending` / `confirmed`|SV hủy. Từ `pending`: không tính bỏ hẹn. Từ `confirmed`: ghi nhận **hủy sát giờ** nếu dưới 1 giờ trước giờ hẹn → tính bỏ hẹn|
|Quán hủy|`cancelled_restaurant`|`confirmed`|Quán hủy, hoặc quán tạm nghỉ (mục 3.14) → giảm tỷ lệ giữ bàn|
|Khách đã đến|`arrived`|`confirmed`|Quán bấm (chỉ quản lý bàn, **không** cấp nhãn 🍽), hoặc SV check-in hợp lệ trong giờ giữ bàn (**cấp nhãn 🍽**)|
|Khách không đến|`no_show`|`confirmed`|Quán bấm sau 15 phút giữ bàn, khi SV **không** có check-in hợp lệ|
|Khách đã đến (tự đóng)|`arrived`|`confirmed`|**Hệ thống:** hết giờ giữ bàn + 24 giờ mà quán không bấm gì. Không tính bỏ hẹn, **không cấp nhãn 🍽**|

### k) Hai người thao tác cùng lúc

Chỉ chuyển trạng thái khi trạng thái hiện tại còn đúng như lúc bấm; thao tác đến trước thắng, thao tác sau được báo "Thông tin đã thay đổi, vui lòng tải lại" (quy tắc chung ở mục 3.18).

|Tình huống|Kết quả|
|---|---|
|Đang đặt món thì quán tạm ngưng / món hết / giá hoặc khuyến mãi đổi|Không tạo đơn, không tạo giao dịch; báo lý do hoặc tổng tiền mới. Đơn đã tạo thì giá đã chốt|
|Quán ghi nhận đã giao (mã / ảnh) đúng lúc sinh viên bấm "Chưa nhận được món"|Khiếu nại được ghi trước thì đơn chuyển "Đang khiếu nại", tiền không chuyển cho quán|
|Hết 24 giờ tự hoàn tất đúng lúc sinh viên mở khiếu nại|Chỉ một bên thắng: còn trong hạn thì khiếu nại được nhận; đã quá hạn thì đơn hoàn tất|

## 3.6 Thanh toán và giữ tiền

> Phần thanh toán **riêng của module Quán ăn**: cổng thanh toán, khoản tiền, ví người bán đều tách khỏi module khác.

**Cách hoạt động:**
```
Sinh viên trả tiền  →  App GIỮ tiền  →  Giao dịch hoàn tất  →  Chuyển cho chủ quán
                                     →  Chủ quán sai       →  Hoàn cho sinh viên
```

Dùng cho **đặt món trả trên app**. Khi nào chuyển, khi nào hoàn: **mục 3.5a – 3.5d, 3.5i**.

- **Cổng thanh toán:** PayPal hoặc MoMo, **bản thử nghiệm** — chạy đủ luồng nhưng không có tiền thật.
- Chưa trả tiền trong **thời hạn chờ thanh toán** (bảng 3.16) → giao dịch hết hạn.
- App **chỉ ghi nhận "đã thanh toán" khi cổng thanh toán báo về** và chữ ký hợp lệ; không tin thông tin từ điện thoại.
- Bấm thanh toán 2 lần **không bị trừ tiền 2 lần**; cổng báo "đã trả" 2 lần chỉ ghi nhận lần đầu.
- **Đúng hạn hay trễ hạn xét theo thời điểm cổng thanh toán ghi nhận giao dịch thành công**, không theo lúc cổng báo về hệ thống. Ví dụ: hạn 14:00, cổng ghi nhận thành công 13:59:58, báo về hệ thống 14:00:05 → **đúng hạn**, không coi là trễ. Vì vậy khi tới hạn, hệ thống **hỏi lại cổng thanh toán** trước khi cho giao dịch hết hạn / gỡ khóa. Khoảng chênh kỹ thuật (nếu sandbox cần) để trong file cấu hình, không ghi cứng vào luật.
- **Tiền đến muộn:** cổng thanh toán ghi nhận giao dịch thành công **sau** hạn, hoặc sau khi giao dịch đã bị hủy → **không nhận**, **tự hoàn 100%**, ghi lý do, báo sinh viên.
- **PayPal:** giá hiển thị bằng VND, lúc thanh toán quy đổi sang USD (theo hiểu biết, PayPal không hỗ trợ VND — cần kiểm tra lại). Lưu **tỷ giá** và **số USD đã thu**. Hoàn một phần = (số VND hoàn ÷ số VND đã thu) × số USD đã thu, làm tròn 2 chữ số.
- **Khoản đang giữ không bao giờ tự chuyển đi khi đang có khiếu nại.**
- **Trạng thái của giao dịch và trạng thái của tiền là hai chuyện riêng:** ví dụ đơn đang khiếu nại thì tiền vẫn đang giữ; đơn hoàn tất thì tiền mới `released`. **Đơn tiền mặt không có khoản tiền nào qua app** nên không bao giờ có giữ tiền, chuyển tiền hay hoàn tiền.
- Chủ quán xem được số tiền **đang giữ** và **đã nhận** của mình trong module này.

## 3.7 Tìm theo khoảng cách và bản đồ

**Chọn điểm để tính khoảng cách** ("điểm gốc"), một trong hai:
- 📍 **Vị trí hiện tại** của điện thoại.
- 🗺️ **Chọn điểm trên bản đồ** — gõ địa chỉ hoặc kéo ghim. Dùng khi muốn tìm quanh một nơi khác chỗ đang đứng, ví dụ sinh viên đang ở quê muốn tìm trước quanh khu mình sẽ ở.

**Quy định:**
- Không cho phép định vị → app gợi ý chọn trên bản đồ, các bộ lọc khác vẫn dùng bình thường.
- App nhớ điểm gốc lần trước (riêng trong module này).
- Bán kính chọn và cách tính: bảng 3.16. Khoảng cách tính theo **đường thẳng**.

**Chế độ bản đồ:** chuyển qua lại giữa danh sách và bản đồ, dùng chung bộ lọc. Ghim hiện giá; nhiều ghim gần nhau gom thành 1 cụm có số; bấm ghim hiện thẻ nhỏ; kéo bản đồ sang chỗ khác thì hiện nút "Tìm ở khu vực này".

## 3.8 Chat

> Chat **riêng của module Quán ăn**, không lẫn với tin nhắn của module khác.

- Nhắn tin 1–1 giữa sinh viên và chủ quán. **Mỗi cặp chỉ có 1 cuộc trò chuyện** trong module này.
- Mở chat từ một quán hay một đơn thì app **tự gắn thẻ thông tin** quán hoặc đơn (ảnh, tên, giá) vào cuộc chat.
- Gửi chữ, gửi ảnh, có trạng thái **Đã gửi / Đã xem**, có thông báo khi có tin mới.
- **Câu hỏi nhanh** cho sinh viên (mục 3.4), **mẫu trả lời nhanh** cho chủ quán.
- **Cảnh báo lừa đảo:**
  - Trước khi quét, tin nhắn được **chuẩn hóa**: chữ thường, **bỏ dấu**, bỏ ký tự đặc biệt và khoảng trắng thừa (để "Chuyển khoản", "chuyen khoan", "c.h.u.y.e.n k.h.o.a.n" đều bị bắt).
  - Từ khóa: chuyển khoản · CK · trả trước · số tài khoản · STK · zalo · QR · momo · ví điện tử · ngân hàng. **Danh sách từ khóa đặt ở file cấu hình**, không viết cứng.
  - **Cách khớp:** "CK", "STK", "QR" phải **khớp nguyên từ** (không bắt "check", "tick"…). "momo" **chỉ cảnh báo khi đi cùng ngữ cảnh chuyển tiền** (ví dụ "chuyển momo", "momo trước", "qua momo cho anh") — vì MoMo cũng là cổng thanh toán hợp lệ trên app.
  - Khớp từ khóa → app hiện: *"⚠️ Hãy thanh toán qua app để được bảo vệ. Không chuyển tiền trước khi nhận món."*
- Có nút **Chặn** (người bị chặn không nhắn được nữa) và **Báo cáo**.
- **Tỷ lệ phản hồi** của chủ quán = phần trăm cuộc trò chuyện mới được trả lời trong 24 giờ (tính 30 ngày gần nhất), hiện công khai.

## 3.9 Đánh giá

> Đánh giá **riêng của module Quán ăn**: điểm, nhãn và danh sách đánh giá không dính gì tới module khác. Ai được viết và điểm tính thế nào: **mục 3.4 Bước 6**.

- Chấm 1–5 sao, **bắt buộc đủ 4 tiêu chí** (Món ăn · Giá cả · Vệ sinh · Phục vụ); điểm tổng thể của đánh giá = trung bình 4 tiêu chí, người viết không nhập điểm tổng riêng.
- Quán có điểm tổng thể và **điểm trung bình riêng từng tiêu chí** (mục 3.4 Bước 6).
- Chọn thêm **thẻ nhanh** (ví dụ "Món ngon", "Phục vụ nhanh").
- Nhận xét **ít nhất 20 ký tự**, tối đa **5 ảnh**.
- Chủ quán **trả lời công khai 1 lần**, **không xóa được** đánh giá, chỉ báo cáo nếu vi phạm.
- Chủ quán **không được đánh giá** quán của mình.
- **Nhãn xác minh** chỉ được tính vào điểm và xếp hạng khi người viết **đã xác thực số điện thoại**.

## 3.10 Báo cáo vi phạm

- Báo cáo được: quán, món, người dùng, đánh giá, tin nhắn. Lý do riêng của module: **mục 3.5h**.
- **Báo cáo được tính** khi người báo cáo đã xác thực số điện thoại và tài khoản đã tạo **ít nhất 7 ngày**.
- **Không tự ẩn chỉ vì số lượng báo cáo** (tránh bị báo cáo hàng loạt / đối thủ cố tình báo cáo). Số báo cáo chỉ là **tín hiệu để ưu tiên kiểm tra**: **3 người khác nhau, khác số điện thoại** cùng báo cáo một **quán hoặc món** → **gắn cờ**, đưa lên đầu hàng chờ admin. Tin vẫn hiện bình thường tới khi admin quyết; admin mới là người ẩn tin (nếu có căn cứ), giao dịch đang chạy đi tiếp theo mục 3.14.
- **Không tự ghi vi phạm** cho chủ chỉ vì đạt số lượng báo cáo; chỉ ghi khi admin xác định có vi phạm.
- **Đánh giá và tin nhắn không tự ẩn** khi đủ 3 báo cáo: chỉ gắn cờ gửi admin, đánh giá **vẫn hiển thị**. **Ngoại lệ:** 3 báo cáo cùng lý do **"xúc phạm / lộ thông tin cá nhân"** → **ẩn tạm** đánh giá / tin nhắn đó chờ admin (để che nhanh thông tin cá nhân). Ẩn tạm **không** phải xác nhận vi phạm, **không** tự ghi vi phạm hay khóa tài khoản; admin **khôi phục** nếu báo cáo không hợp lệ.
- Báo cáo **nghiêm trọng** (lừa đảo, yêu cầu chuyển tiền ngoài app, hành vi có nguy cơ gây thiệt hại trực tiếp cho người dùng) → **ưu tiên cao**, admin kiểm tra sớm. Biện pháp tạm thời (ẩn tin) chỉ do admin quyết dựa trên bằng chứng, không dựa vào số báo cáo.
- Người báo cáo được báo kết quả.
- Mỗi người báo cáo **tối đa 10 lần / ngày** trong module này. **Báo cáo sai 3 lần** (admin bác bỏ) → khóa chức năng báo cáo của module này 30 ngày.

## 3.11 Thông báo

- Thông báo đẩy trên điện thoại + danh sách thông báo **riêng của module** (biểu tượng chuông trong module), đánh dấu đã đọc.
- **Cài đặt thông báo của module:** tắt được từng nhóm (quán đã lưu có khuyến mãi / mở lại, tin nhắn, nhắc đánh giá…), **trừ** thông báo về tiền, đơn hàng, đặt bàn, khiếu nại, kháng nghị.
- Máy tính: mục 3.19 (giới hạn theo nền tảng).

|Gửi cho|Khi nào|
|---|---|
|**Sinh viên**|Thanh toán thành công / hết hạn · tiền đến muộn đã hoàn · quán đã nhận / từ chối / không xác nhận kịp (đã hoàn tiền) · đang chuẩn bị · sẵn sàng lấy · đang giao · **mã nhận món 4 số** (khi đơn sẵn sàng) · quán đã ghi nhận giao / lấy món (ảnh hoặc mã đúng; nhắc kiểm tra, còn 24 giờ khiếu nại) · đơn quá 6 giờ chưa có bằng chứng, đã chuyển admin · nhắc xác nhận nhận món (sau 1 giờ và khi còn 1 giờ) · đơn tự hoàn tất · có thể "Hủy vì quán chậm" · đã hoàn tiền · quán báo "Khách không nhận" (còn 24 giờ phản đối) · kết quả khiếu nại / phản đối · đặt bàn được xác nhận / từ chối / hết hạn / bị quán hủy · nhắc 1 giờ trước giờ đặt bàn · quán đã lưu có khuyến mãi / mở lại · nhắc đánh giá · cảnh báo bom hàng, bỏ hẹn · kết quả kháng nghị|
|**Chủ quán**|**Đơn mới (có chuông, nhắc lại sau 2 phút nếu chưa nhận)** · sinh viên hủy đơn · sinh viên hủy vì quán chậm · có khiếu nại (trả lời trong 2 giờ) · sinh viên phản đối "Khách không nhận" · đã nhận tiền · yêu cầu đặt bàn mới · sinh viên hủy bàn · kết quả duyệt (quán, bản chỉnh sửa, nâng cấp loại) · yêu cầu chuyển loại quán · nhắc xác nhận quán còn hoạt động · đánh giá mới · bị báo cáo · bị tự tạm ngưng nhận đơn · kết quả kháng nghị|
|**Admin Quán ăn**|Quán / bản chỉnh sửa chờ duyệt · đơn cần rà soát do quán bị kết luận lừa đảo · đơn quá 6 giờ chưa có bằng chứng giao / nhận · quán / món bị gắn cờ do nhiều báo cáo · quán bị cảnh báo khai sai loại · khiếu nại chưa thống nhất · phản đối "khách không nhận" · khiếu nại có cờ khẩn · báo cáo ưu tiên cao · kháng nghị mới|

## 3.12 Admin

> Admin **riêng của module Quán ăn**: hàng chờ, quyền xử lý và nhật ký tách khỏi module khác. Duyệt **danh tính người thật** là phần chung (mục 4.2).

- Admin dùng ngay trong app, chỉ tài khoản admin của module mới thấy.
- **Hàng chờ của module**, lọc theo loại: Quán · **Chỉnh sửa / nâng cấp loại chờ duyệt** · Quán nghi khai sai loại · Báo cáo · Khiếu nại đơn · Phản đối "khách không nhận" · **Đơn quá 6 giờ chưa có bằng chứng giao / nhận** · **Đơn cần rà soát do quán bị kết luận lừa đảo** · **Kháng nghị**.
- **Thứ tự xử lý:** khiếu nại có **cờ khẩn** (treo quá lâu) → khiếu nại tiền và báo cáo ưu tiên cao → hồ sơ bị gắn cờ → còn lại theo thời gian.
- **Khiếu nại treo quá hạn** → gắn **cờ khẩn**, nhắc admin. **Không bao giờ tự chuyển tiền khi đang khiếu nại.**
- Mọi quyết định đều được ghi nhật ký (ai, lúc nào, lý do).
- Admin có thể: ẩn / đình chỉ quán · **khóa bán vĩnh viễn** (khóa đăng quán và nhận đơn trong Quán ăn, không khóa cả tài khoản) · khóa chức năng của người dùng trong Quán ăn (đặt món, đặt bàn, tiền mặt, báo cáo) · quyết định kháng nghị · **đề nghị** khóa cả tài khoản khi lừa đảo (admin danh tính quyết, mục 4.4).

|Việc|Admin kiểm tra|
|---|---|
|**Duyệt quán**|Chủ quán đã xác thực · ảnh mặt tiền chụp trong app, GPS ổn, không giả lập · địa chỉ khớp vị trí ghim · *hộ kinh doanh:* mã số thuế còn hoạt động, tên khớp CCCD, địa chỉ khớp · *bán lẻ:* không có dấu hiệu khai sai · mô tả không quảng cáo|
|**Duyệt bản chỉnh sửa / nâng cấp loại**|Như duyệt quán, với phần thay đổi|
|**Quán bị cảnh báo khai sai loại**|Xem lại → yêu cầu chuyển loại trong 7 ngày|
|**Khiếu nại đơn, phản đối "khách không nhận"**|Xem bằng chứng hai bên + chat → hoàn toàn phần / một phần / chuyển tiền cho quán; có tính bom hàng hay không|
|**Đơn cần rà soát do quán bị kết luận lừa đảo**|Xét **từng đơn** theo bằng chứng của chính đơn (mã / ảnh GPS, chat, thời gian, vị trí, phản hồi sinh viên, dấu hiệu gian lận) → đã giao thật: hoàn tất · bằng chứng giả / không giao: hoàn 100% · chưa đủ căn cứ: giữ tiền, xử lý như tranh chấp. Kết luận "đã giao thật" thì đơn **đã xác minh** (nhãn 🛵)|
|**Đơn quá 6 giờ chưa có bằng chứng giao / nhận**|Xem chat, dòng thời gian, vị trí → đơn trả trên app: hoàn 100% hoặc chuyển tiền cho quán; đơn tiền mặt: `completed` hoặc `cancelled_restaurant`. Ghi lý do|
|**Đình chỉ quán**|Khi vi phạm vệ sinh, lừa đảo, tái phạm (xử lý đơn đang chạy theo mục 3.14)|

**Lý do từ chối có sẵn:** Ảnh mặt tiền không rõ / sai địa điểm · Mã số thuế không tồn tại / ngừng hoạt động · Tên chủ hộ không khớp · Địa chỉ không khớp · Khai sai loại hình · Thông tin sai lệch · Khác.

## 3.13 Khách chưa đăng nhập

- **Được xem:** danh sách, bộ lọc, bản đồ, chi tiết quán, menu, khuyến mãi, đánh giá.
- **Bị ẩn:** số điện thoại chủ quán.
- **Phải đăng nhập mới làm được:** chat, gọi, đặt món, đặt bàn, check-in, lưu ❤️, đánh giá, báo cáo, đăng quán.
- Đăng nhập xong app **quay lại đúng trang** đang xem.

## 3.14 Ẩn, khóa khi còn giao dịch đang chạy

> **Nguyên tắc:** ẩn / khóa / hết hạn / đình chỉ **chỉ chặn giao dịch MỚI**. Giao dịch **ĐANG chạy đi tiếp** theo luật bình thường. **Trạng thái của quán / tài khoản không tự quyết kết quả từng giao dịch**: kể cả khi quán bị kết luận lừa đảo, các đơn đang chạy được admin **rà soát từng đơn** theo bằng chứng của chính đơn đó.

"Giao dịch đang chạy" của module này gồm: đơn món từ "chờ quán xác nhận" tới trước "hoàn tất" · đặt bàn đã xác nhận chưa tới giờ · khiếu nại, kháng nghị chưa xong.

|Tình huống|Xử lý|
|---|---|
|Admin kết luận chủ quán **lừa đảo hoặc giấy tờ giả**|Kết luận này là về **quán / tài khoản**, không tự quyết kết quả từng đơn. Ngừng nhận đơn mới; **đề nghị admin danh tính** khóa cả tài khoản (mục 4.4); đặt bàn đã xác nhận bị hủy, không tính lỗi sinh viên. Đơn đang chạy: **(A)** đã hoàn tất hợp lệ trước đó, không có tranh chấp mở → **không** đảo ngược, **không** tự hoàn (có bằng chứng gian lận mới của chính đơn đó thì xử lý riêng qua khiếu nại / admin) · **(B)** đang "Chờ xác nhận nhận món" (đã có mã / ảnh GPS, còn trong 24 giờ) → **không** tự giải ngân, **không** tự hoàn, **giữ tiền**, gắn cờ cho admin xét **từng đơn** (bằng chứng, chat, thời gian, vị trí, phản hồi sinh viên, dấu hiệu gian lận): đã giao thật → hoàn tất theo luật; bằng chứng giả / không giao → hoàn 100%; chưa đủ căn cứ → giữ tiền, xử lý như tranh chấp · **(C)** chưa có bằng chứng giao / nhận → **không** coi là đã giao, xử lý hủy / hoàn / khiếu nại theo trạng thái thực tế, cần thì chuyển admin. Không mặc định coi mọi bằng chứng cũ là thật, cũng không mặc định là giả|
|Quán bị ẩn / đình chỉ (không phải lừa đảo)|Đơn "chờ quán xác nhận" → hủy và hoàn; đơn đã nhận trở đi đi tiếp; đặt bàn đã xác nhận → hủy, báo sinh viên, **không tính lỗi sinh viên**; quán vẫn phải trả lời khiếu nại|
|Quán bấm "Tạm nghỉ hôm nay" / nghỉ dài ngày khi đang có đơn hoặc bàn|Hộp cảnh báo liệt kê đơn và bàn. Xác nhận → đơn "chờ quán xác nhận" hủy và hoàn; bàn đã xác nhận → "quán hủy" (tính lỗi quán); đơn đã nhận vẫn phải làm xong. "Tạm ngưng nhận đơn" chỉ chặn đơn mới|
|Chủ quán bấm **Ngừng kinh doanh**|**Bị chặn** khi còn đơn chưa hoàn tất, bàn đã xác nhận, tiền đang giữ, khiếu nại, kháng nghị; kèm giải thích|
|Chủ quán bị **khóa bán vĩnh viễn** trong Quán ăn (= khóa quyền đăng quán và nhận đơn trong module Quán ăn; **không** khóa cả tài khoản, vẫn dùng module khác và vẫn mua như sinh viên)|**Khóa bán không tự quyết kết quả các đơn đã phát sinh.** Không nhận đơn mới, không bán mới; đơn cũ xử lý theo trạng thái và bằng chứng của từng đơn: đã có bằng chứng giao / nhận → tiếp tục 24 giờ phản đối, không phản đối thì hoàn tất và giải ngân theo luật thường · đang tranh chấp → tiền giữ, admin xử lý theo khiếu nại · chưa giao, chưa có bằng chứng → hủy / hoàn theo trạng thái thực tế và luật hiện có · đã hoàn tất trước khi khóa → không đổi. **Không hoàn tiền chỉ vì quán bị khóa**|
|Sinh viên bị khóa đặt món / đặt bàn / tiền mặt|Chỉ chặn hành động mới; giao dịch đang chạy đi tiếp|
|Người dùng muốn xóa tài khoản|Bị chặn nếu còn giao dịch đang chạy, tiền đang giữ, khiếu nại, kháng nghị trong module này (mục 4.1)|

## 3.15 Kháng nghị

> Kháng nghị **riêng của module Quán ăn**. Kháng nghị khóa cả tài khoản / chặn CCCD thuộc phần chung (mục 4.4).

- **Áp dụng cho:** khóa đặt món / đặt bàn · mất quyền tiền mặt · lần bom hàng · lần bỏ hẹn đặt bàn · **lần khiếu nại bị tính sai** · ẩn / đình chỉ quán · khóa bán vĩnh viễn · khóa báo cáo.
- **Luồng:** nút **"Kháng nghị"** ngay tại thông báo phạt hoặc trong "Của tôi" của module → ghi lý do + bằng chứng (ảnh / video chụp trong app, tối đa 3) → gửi.
- **Hạn gửi:** trong 7 ngày kể từ quyết định. **Admin của module trả lời trong 48 giờ.**
- **Mỗi quyết định chỉ kháng nghị 1 lần.**
- **Kết quả:** gỡ khóa · giữ nguyên · xóa lần vi phạm khỏi bộ đếm (lần vi phạm chuyển sang "đã gỡ").
- Đang kháng nghị thì hình phạt **vẫn còn hiệu lực** cho tới khi admin quyết.

## 3.16 Các con số quy định

> Mọi con số của module, kể cả thanh toán, báo cáo, kháng nghị. Con số của tài khoản và xác nhận người thật ở mục 4.5.

|Quy định|Con số|
|---|---|
|Ảnh mặt tiền · ảnh khác|1–3 · 0–10|
|Số món tối thiểu để hiện ở danh sách|3|
|Tối đa nhóm món · món|20 · 200|
|Món nổi bật tối đa|5|
|Ca mở cửa mỗi ngày|Tối đa 2|
|"Sắp đóng cửa" khi còn|30 phút|
|Khuyến mãi tối đa · thời hạn|Hộ kinh doanh 5, bán lẻ 1 · tối đa 90 ngày|
|Mốc giá (theo giá trung vị)|Dưới 20k · 20–35k · 35–50k · trên 50k|
|Chip nhanh "Dưới 35k"|Giá trung vị dưới 35.000đ (gộp hai mốc "dưới 20k" và "20–35k")|
|Check-in|Cách quán ≤ 100 m, 1 lần / quán / ngày|
|"Sinh viên hay ăn"|≥ 10 người khác nhau / 30 ngày, mỗi người tối đa 1 lượt / quán / 7 ngày, top 20% trong 3 km|
|"Mới mở"|Duyệt trong 30 ngày|
|Nhắc xác nhận còn hoạt động|Sau 90 ngày, hạn 7 ngày|
|Dấu hiệu khai sai loại|Menu > 40 món · mở > 14 giờ/ngày · hạn chuyển loại 7 ngày|
|Đặt bàn|Cách lúc đặt ≥ 1 giờ · trước tối đa 7 ngày · 1–20 người · quán xác nhận trong min(30 phút, giờ hẹn − 30 phút) · giữ bàn 15 phút · hủy sát giờ < 1 giờ|
|Khóa đặt bàn|3 lần bỏ hẹn / 30 ngày → 7 ngày|
|Bàn đã xác nhận mà quán không bấm gì|Hết giờ giữ bàn + 24 giờ → tự đóng (không tính bỏ hẹn, không cấp nhãn 🍽)|
|Bán kính giao|1–5 km (quán chọn)|
|Quán xác nhận đơn|5 phút · chuông nhắc lại sau 2 phút|
|Tự tạm ngưng nhận đơn|3 lần quá hạn / ngày|
|Tỷ lệ nhận đơn · tỷ lệ giữ bàn|Tính 30 ngày|
|Quán chậm|Quá giờ dự kiến sẵn sàng + 30 phút|
|Giao lâu|"Đang giao" quá 60 phút|
|Hẹn giờ nhận món|Cách hiện tại 30 phút – 2 giờ, trước giờ đóng cửa của ca đang mở|
|Khách không tới lấy sau|30 phút từ "Sẵn sàng"|
|Nút "Chưa nhận được món" (đến lấy)|Từ thời điểm nhận món dự kiến (T_lấy: giờ hẹn, hoặc giờ dự kiến sẵn sàng quán ghi khi nhận đơn), không ân hạn thêm|
|Phản đối "Khách không nhận" · giữ tiền thêm|24 giờ · 24 giờ|
|Khiếu nại / "Chưa nhận được món" · quán trả lời|24 giờ từ khi có bằng chứng giao / nhận · 2 giờ|
|Tự hoàn tất đơn trả trên app|24 giờ sau khi có bằng chứng giao / nhận · nhắc sau 1 giờ và khi còn 1 giờ|
|Mã nhận món (đến lấy)|4 chữ số, mỗi đơn 1 mã|
|Chưa có bằng chứng giao / nhận → gắn cờ chuyển admin|6 giờ từ "Sẵn sàng" / "Đang giao"|
|Tiền mặt khi nhận|Đơn dưới 200.000đ|
|Bom hàng|2 lần / 30 ngày → mất tiền mặt · 3 lần → khóa đặt món 7 ngày|
|Khiếu nại sai sự thật|3 lần bị bác / 30 ngày → khóa đặt món trả trên app 30 ngày|
|Đánh giá tối đa|10 / tài khoản / ngày|
|Chờ thanh toán|15 phút|
|GPS lệch bao nhiêu thì gắn cờ|200 m|
|Bán kính lọc|300 m · 500 m · 1 km · 2 km · 3 km · 5 km|
|Báo cáo được tính|Đã OTP, tài khoản ≥ 7 ngày tuổi|
|Gắn cờ ưu tiên do báo cáo (không tự ẩn)|3 người khác số điện thoại|
|Ẩn tạm đánh giá / tin nhắn|3 báo cáo cùng lý do "xúc phạm / lộ thông tin cá nhân" (không tính vi phạm, admin khôi phục được)|
|Báo cáo tối đa · báo cáo sai|10 / người / ngày · 3 lần sai → khóa báo cáo 30 ngày|
|Nhận xét đánh giá|≥ 20 ký tự, ≤ 5 ảnh|
|Tỷ lệ phản hồi|Trả lời trong 24 giờ, tính 30 ngày gần nhất|
|Mục tiêu admin xử lý|24 giờ · khiếu nại tiền 12 giờ · báo cáo "xúc phạm / lộ thông tin" 24 giờ|
|Khiếu nại treo → cờ khẩn|72 giờ|
|Kháng nghị|Gửi trong 7 ngày · admin trả lời trong 48 giờ · 1 lần / quyết định · tối đa 3 bằng chứng|
|Bộ đếm vi phạm|Cửa sổ trượt 30 ngày, theo số điện thoại|

## 3.17 Dữ liệu cần lưu

> Danh sách **thông tin module cần lưu**, viết bằng lời. Tên bảng, tên trường, kiểu dữ liệu do người code đặt, nhưng **phải lưu đủ những thông tin dưới đây**. Mọi mốc hạn đều lưu thành **thời điểm cụ thể** để app tự xử lý khi tới hạn. Dữ liệu của module này **tách riêng** khỏi module khác; chỉ dùng chung tài khoản và xác nhận người thật (mục 4.6). Mã trạng thái dùng đúng như mục 3.2 và 3.5.

|Nhóm dữ liệu|Cần lưu những gì|
|---|---|
|**Quán**|Chủ quán · tên · **loại quán** (hộ kinh doanh / bán lẻ) · loại món · mô tả · số điện thoại · địa chỉ + vị trí ghim · bán lưu động không, ghi chú chỗ bán · chữ tìm kiếm không dấu (tên quán + tên món + đường + phường, cập nhật khi menu đổi) · **giờ mở cửa theo tuần** (mỗi ngày tối đa 2 ca, ca qua nửa đêm tính cho ngày bắt đầu) · tạm nghỉ tới lúc · tạm ngưng nhận đơn tới lúc · **hình thức phục vụ** (ăn tại quán có / không · mang đi có / không) · tiện ích · nhận đặt bàn không (chỉ hộ kinh doanh) · **cài đặt đặt món** (bật không, đến lấy, giao tận nơi, bán kính giao, phí giao, đơn tối thiểu, thời gian chuẩn bị, cho tiền mặt không — chỉ hộ kinh doanh) · ảnh mặt tiền (chụp trong app, kèm GPS; ảnh đầu là ảnh bìa) · ảnh thư viện · mã số thuế, đã đối chiếu chưa · trạng thái · lý do từ chối · bản chỉnh sửa chờ duyệt · cờ nghi khai sai loại (lý do, hạn chuyển loại) · lần hoạt động gần nhất, hạn xác nhận còn hoạt động · số liệu tự tính (số món, giá P25 / trung vị / P75, điểm xác minh (tổng thể + **từng tiêu chí**), số lượt đánh giá, điểm chưa xác minh, số người khác nhau trong 30 ngày, nhãn "Sinh viên hay ăn", tỷ lệ nhận đơn, tỷ lệ giữ bàn, đang có khuyến mãi không, ngày duyệt)|
|**Nhóm món**|Quán · tên · thứ tự · là nhóm đồ uống / món thêm không|
|**Món**|Quán, nhóm · tên · mô tả · giá · ảnh · món nổi bật không · còn hàng không · thứ tự · nhóm tùy chọn (tên, bắt buộc không, chọn tối đa mấy, các lựa chọn và giá cộng thêm)|
|**Khuyến mãi**|Quán · loại (giảm % / giảm tiền / combo / giờ vàng / ưu đãi sinh viên) · tiêu đề · mức giảm, giảm tối đa, đơn tối thiểu · combo: các món, số lượng, giá combo · giờ vàng: khung giờ, các ngày · bắt đầu, kết thúc · trạng thái (đang chạy / đã dừng / hết hạn)|
|**Check-in**|Sinh viên · quán · vị trí GPS, khoảng cách tới quán, có giả lập không · ảnh, cảm nghĩ · có công khai không · có tính vào "Sinh viên hay ăn" không · lúc nào (mỗi người 1 lần / quán / ngày)|
|**Đặt bàn**|Quán, chủ quán, sinh viên · giờ đặt, số người, ghi chú · trạng thái · hạn quán xác nhận (min(gửi + 30 phút, giờ hẹn − 30 phút)) · hủy sát giờ không · ai ghi nhận khách đến (quán / check-in) · lúc xác nhận|
|**Đơn món**|Mã đơn · quán, chủ quán, sinh viên · **các món đã chốt giá** (tên, giá, số lượng, tùy chọn, ghi chú, thành tiền) — không đổi khi menu đổi · đến lấy / giao tận nơi · địa chỉ giao, khoảng cách · **càng sớm càng tốt / hẹn giờ** và giờ hẹn · số điện thoại, ghi chú cho quán · tiền món, giảm combo, giảm giá, phí giao, tổng (hệ thống tính) · khuyến mãi đã áp (chốt lúc tạo đơn) · **cách trả: trên app / tiền mặt** · khoản tiền liên quan (chỉ đơn trả trên app) · trạng thái · lý do hủy · hạn thanh toán, hạn quán nhận · giờ dự kiến sẵn sàng, lúc mở nút "Hủy vì quán chậm" · lúc bắt đầu giao · **mã nhận món** (đến lấy) và lúc quán nhập đúng mã · **ảnh giao hàng** (chụp trong app, GPS, khoảng cách tới điểm giao) · lúc ghi nhận bằng chứng, **hạn khiếu nại / tự hoàn tất** (+ 24 giờ) · **thời điểm nhận món dự kiến** (đến lấy, mốc mở nút "Chưa nhận được món") · **cờ quá hạn chưa có bằng chứng** (+ 6 giờ từ "Sẵn sàng" / "Đang giao") · **cờ rà soát do quán bị kết luận lừa đảo** · quyết định của admin · "Khách không nhận" (ảnh GPS, lúc báo, hạn phản đối + 24 giờ) · khiếu nại (loại, lý do, ảnh, lúc mở, mốc cờ khẩn, trả lời và đề nghị hoàn của quán, quyết định, số tiền hoàn, có tính bom hàng không) · dòng thời gian · lúc hoàn tất|
|**Hồ sơ trong module**|Mỗi tài khoản có hồ sơ riêng trong Quán ăn: chỉ số chủ quán (tỷ lệ phản hồi, tỷ lệ nhận đơn, tỷ lệ giữ bàn, số lần cảnh cáo) · các khóa đang áp trong module kèm thời hạn (đặt món, đặt bàn, tiền mặt, báo cáo) · **địa chỉ đã lưu** · điểm gốc tìm kiếm · cài đặt thông báo|
|**Khoản tiền**|Người trả · người nhận (chủ quán) · cho đơn món nào · cổng (PayPal / MoMo) · mã giao dịch của cổng · mã chống trả 2 lần · số tiền VND · PayPal: số USD đã thu và tỷ giá · **trạng thái tiền** (chờ trả · đang giữ · đã chuyển · đã hoàn · hoàn một phần · hết hạn · thất bại) · số đã hoàn · hết hạn lúc · lịch sử từng lần đổi trạng thái|
|**Ví chủ quán**|Số tiền đang giữ · đã nhận (chỉ để hiển thị)|
|**Chat**|Hai người trong cuộc trò chuyện (**mỗi cặp 1 cuộc** trong module) · ai đã chặn ai · tin cuối · số tin chưa đọc|
|**Tin nhắn**|Người gửi · loại: chữ / ảnh / thẻ tin · nội dung · nội dung đã bỏ dấu (để lọc từ khóa) · từ khóa bị cảnh báo · thẻ tin trỏ tới đâu · đã xem lúc · trạng thái hiển thị (hiện / tạm ẩn do báo cáo / ẩn)|
|**Đánh giá**|Quán được đánh giá · người viết · **điểm món ăn · điểm giá cả · điểm vệ sinh · điểm phục vụ** (đủ 4, mỗi điểm 1–5) · **điểm tổng thể** (app tự tính = trung bình 4, không cho nhập) · thẻ nhanh · nhận xét · ảnh · **nhãn xác minh** · có được tính vào điểm không · bằng chứng · trả lời của chủ · đã cập nhật chưa · trạng thái hiển thị (hiện / tạm ẩn / ẩn)|
|**Lưu ❤️**|Ai lưu · quán nào · có nhận thông báo không|
|**Báo cáo**|Người báo · báo cái gì · lý do, ghi chú · ưu tiên cao hay thường · có được tính vào ngưỡng gắn cờ không · trạng thái xử lý, ai xử lý|
|**Lần vi phạm**|Tài khoản và **số điện thoại** · loại (bỏ hẹn đặt bàn / bom hàng / báo cáo sai / khiếu nại sai) · từ giao dịch nào · lúc nào · còn hiệu lực hay đã gỡ. Mỗi giao dịch chỉ sinh **tối đa 1** lần vi phạm cùng loại|
|**Kháng nghị**|Người gửi · kháng nghị quyết định nào · lý do, bằng chứng · trạng thái · kết quả · ai xử lý|
|**Thông báo**|Gửi cho ai · loại · tiêu đề, nội dung · bấm vào thì mở đâu · đã đọc lúc · cài đặt thông báo của module|
|**Nhật ký admin**|Admin nào · làm gì · với cái gì · ghi chú · lúc nào|

## 3.18 Quy tắc khi làm

1. **Con số không viết cứng:** mọi thời hạn, giới hạn lấy từ bảng 3.16 (để trong file cấu hình của module).
2. **Mọi danh sách** có đủ 3 trạng thái: đang tải · trống · lỗi (mục 3.19).
3. **Giá tiền** lưu dạng số, chỉ định dạng "35.000đ" khi hiển thị.
4. **Hệ thống quyết định, không tin app:** giá, tổng tiền, trạng thái thanh toán, khoảng cách GPS, giờ, quyền của người bấm, trạng thái hiện tại và hạn đều do hệ thống kiểm tra. Nút bị ẩn trên app nhưng cũng phải bị chặn ở hệ thống.
5. **Không tự giao dịch với quán của mình:** chủ quán không được dùng các chức năng của sinh viên (đặt món, đặt bàn, check-in, đánh giá, lưu ❤️, nhắn tin) với quán của chính mình.
6. **Hạn tự động:** mỗi hạn lưu thành một thời điểm cụ thể. Tới hạn thì hệ thống tự chuyển trạng thái; mở lại một giao dịch đã quá hạn thì thấy ngay trạng thái sau hạn. Việc tự xử lý chạy lại nhiều lần **không được** hoàn tiền 2 lần, chuyển tiền 2 lần, tính vi phạm 2 lần hay gửi thông báo 2 lần.
7. **Hai người thao tác cùng lúc:** chỉ chuyển trạng thái khi trạng thái hiện tại còn đúng như lúc bấm; thao tác đến trước thắng (tình huống cụ thể: mục 3.5k).
8. **Không dùng code, dữ liệu, màn hình của module khác.** Chỉ dùng chung tài khoản và xác nhận người thật (Phần 4), model `User` trong `shared/`, và các tiện ích chung trong `core/utils`, `core/services` (cây thư mục: mục 3.21).
9. **Không để mật khẩu, khóa bí mật** (chuỗi kết nối, khóa thanh toán…) trong code hay gửi qua chat — repo đang public.
10. Làm đúng **1 task mỗi lần**, xong thì kiểm tra theo mục 3.23 rồi mới sang task tiếp.

## 3.19 Giao diện riêng của module (xanh biển – trắng)

> Bộ giao diện **riêng của module Quán ăn**. Mọi màu, chữ, khoảng cách khai báo **một lần** trong file `widgets/quan_an_theme.dart` của module (mục 3.21), các màn hình của module chỉ dùng lại. Module khác có bộ giao diện riêng; hiện cả hai cùng tông xanh biển – trắng nhưng **được đổi độc lập**.

### Bảng màu

**Màu chính (xanh biển)**

|Tên token|Mã màu|Dùng cho|
|---|---|---|
|`primary`|`#1565C0`|Nút chính, liên kết, tab đang chọn, icon đang chọn, ghim bản đồ|
|`primaryDark`|`#0D47A1`|Nút chính khi nhấn giữ, tiêu đề lớn có màu|
|`primaryLight`|`#E3F0FF`|Nền chip đang chọn, nền thẻ được chọn, nền huy hiệu xác thực|
|`primarySoft`|`#BBD8FA`|Viền ô đang nhập, thanh tiến trình nền|
|`accent`|`#29B6F6`|**Chỉ trang trí** (minh họa, gradient banner). Không đặt chữ trắng lên màu này vì không đủ tương phản|

**Màu nền và chữ**

|Tên token|Mã màu|Dùng cho|
|---|---|---|
|`white`|`#FFFFFF`|Nền thẻ, nền thanh trên, nền bảng bộ lọc|
|`background`|`#F4F8FD`|Nền màn hình (trắng ánh xanh nhẹ để thẻ trắng nổi lên)|
|`border`|`#D6E4F5`|Viền thẻ, đường kẻ phân cách|
|`textPrimary`|`#0F1C2E`|Chữ chính|
|`textSecondary`|`#5B6B80`|Chữ phụ, mô tả, thời gian|
|`textDisabled`|`#A9B6C6`|Chữ khi bị vô hiệu|

**Màu trạng thái**

|Tên token|Mã màu|Nền nhạt|Dùng cho|
|---|---|---|---|
|`success`|`#137333`|`#E8F6EE`|Đang mở cửa, đã xác thực, thanh toán thành công|
|`warning`|`#B45309`|`#FFF4E0`|Sắp đóng cửa, sắp hết hạn, đang khiếu nại, chờ xác nhận nhận món|
|`danger`|`#C62828`|`#FDECEC`|Đóng cửa, lỗi, hủy, cảnh báo lừa đảo|
|`info`|`#1565C0`|`#E3F0FF`|Thông tin chung (dùng lại màu chính)|

**Quy tắc màu**
- Mỗi màn hình **tối đa 1 nút chính** (nền xanh đặc) cho hành động chính của ngữ cảnh. Mọi hành động khác dùng nút phụ (viền). Ví dụ trang quán: "Xem giỏ" là nút chính, "Đặt bàn" là nút phụ.
- Chữ trên nền xanh `primary` luôn là **trắng**. Chữ trên nền trắng tối thiểu là `textSecondary`.
- Tương phản chữ tối thiểu **4,5 : 1** (chuẩn WCAG). Đã tính cho các cặp đang dùng:

|Cặp màu (chữ / nền)|Tỷ lệ|Kết quả|
|---|---|---|
|Trắng / `primary` `#1565C0`|5,75|Đạt|
|Trắng / `primaryDark` `#0D47A1`|8,63|Đạt|
|`textPrimary` `#0F1C2E` / trắng · / `background`|17,13 · 16,06|Đạt|
|`textSecondary` `#5B6B80` / trắng · / `background`|5,44 · 5,10|Đạt|
|`primary` / trắng · / `primaryLight` · / `background`|5,75 · 4,97 · 5,39|Đạt|
|`success` `#137333` / nền nhạt `#E8F6EE`|5,34|Đạt|
|`warning` `#B45309` / nền nhạt `#FFF4E0`|4,61|Đạt|
|`danger` `#C62828` / nền nhạt `#FDECEC` · trắng / `danger`|4,92 · 5,62|Đạt|
|Trắng / ghim xám `#64748B`|4,76|Đạt|
|Trắng / nút vô hiệu `#C9D6E6` · `textDisabled` `#A9B6C6` / trắng|1,47 · 2,06|**Ngoại lệ hợp lệ**: thành phần đang vô hiệu được miễn theo WCAG|
|Trắng / `accent` `#29B6F6`|2,30|**Không dùng** cho chữ (accent chỉ để trang trí)|
- **Không dùng màu làm tín hiệu duy nhất:** trạng thái luôn có **chữ hoặc icon** đi kèm (ví dụ 🟢 + "Đang mở cửa").

### Chữ

- **Font:** **Be Vietnam Pro** (hiển thị tiếng Việt có dấu đẹp, miễn phí trên Google Fonts). Dự phòng: font mặc định hệ thống.

|Kiểu|Cỡ / Độ đậm|Dùng cho|
|---|---|---|
|`display`|28 / Bold|Tiêu đề màn hình chào, số tiền lớn|
|`h1`|22 / Bold|Tiêu đề trang (tên quán)|
|`h2`|18 / SemiBold|Tiêu đề khối (Tiện ích, Menu, Đánh giá)|
|`h3`|16 / SemiBold|Tiêu đề thẻ, tên món|
|`body`|15 / Regular|Nội dung chính|
|`bodySmall`|13 / Regular|Mô tả phụ, địa chỉ, thời gian|
|`label`|14 / SemiBold|Chữ trên nút, chip, tab|
|`price`|16 / Bold, màu `primary`|Giá tiền|

### Khoảng cách, bo góc, đổ bóng

- **Lưới 4 điểm:** khoảng cách chỉ dùng 4 · 8 · 12 · 16 · 20 · 24 · 32.
- **Lề màn hình:** 16. Khoảng cách giữa các thẻ: 12.
- **Bo góc:** nút 12 · thẻ 16 · ô nhập 12 · chip **bo tròn hẳn** · bảng kéo từ dưới lên 24 (góc trên).
- **Đổ bóng:** nhẹ, màu xanh rất nhạt (`#1565C0` độ mờ 8%), chỉ dùng cho thẻ và thanh dưới cùng.

### Nút

|Loại|Hình dáng|Khi nào dùng|
|---|---|---|
|**Chính**|Nền `primary`, chữ trắng, cao 48, bo 12, rộng hết hàng trên điện thoại|Tối đa 1 / màn hình: "Xem giỏ / Đặt món", "Đặt bàn", "Gửi duyệt"|
|**Phụ**|Nền trắng, viền `primary` 1.5, chữ `primary`|"Đặt bàn", "Nhắn tin", "Lưu nháp", "Xem trên bản đồ"|
|**Chữ**|Không nền, chữ `primary`|"Xem tất cả", "Bỏ qua"|
|**Nguy hiểm**|Nền `danger`, chữ trắng (hoặc viền đỏ nếu là hành động phụ)|"Từ chối đơn", "Xóa món", "Hủy bàn"|
|**Icon tròn**|40×40, nền trắng, icon `primary`|❤️ lưu, chia sẻ, quay lại trên ảnh bìa|

**Trạng thái nút:** bình thường · **nhấn** (đậm hơn: `primaryDark`) · **vô hiệu** (nền `#C9D6E6`, chữ trắng) · **đang xử lý** (vòng xoay trắng thay chữ, không bấm lại được — chống bấm 2 lần khi thanh toán).

**Thanh hành động dưới cùng** (trang chi tiết quán, giỏ món): nền trắng, đổ bóng phía trên, chứa giá bên trái + nút chính bên phải.

### Ô nhập, chip, công tắc

- **Ô nhập:** nền trắng, viền `border`, cao 48. Đang nhập: viền `primary` 1.5. Lỗi: viền `danger` + dòng lỗi màu đỏ bên dưới. Nhãn luôn nằm **trên** ô (không chỉ dùng chữ mờ gợi ý).
- **Ô tìm kiếm:** bo tròn hẳn, nền `primaryLight`, icon kính lúp `primary`.
- **Chip lọc:** chưa chọn = nền trắng viền `border` chữ `textPrimary`; đã chọn = nền `primaryLight` viền `primary` chữ `primary` + dấu ✓.
- **Công tắc, ô tick:** bật = `primary`.
- **Thanh tiến trình form nhiều bước:** nền `primarySoft`, phần đã xong `primary`, kèm chữ "Bước 2/5".

### Thẻ (card)

**Thẻ ở danh sách** (nội dung thẻ: mục 3.4 Bước 1). **Ảnh bìa luôn là hình chụp tại chỗ** (ảnh mặt tiền quán) — mục 1.3.
- Ảnh bìa 16:9 ở trên, bo góc trên; nút ❤️ tròn trắng ở góc phải ảnh; nhãn nhỏ (🏷 🛵 🔥 🆕) ở góc dưới ảnh.
- Phần chữ bên dưới: tên (`h3`) + huy hiệu xanh · dòng phụ ★, khoảng cách, phường (`bodySmall`, `textSecondary`) · giá (`price`) · nhãn trạng thái.
- Nền trắng, bo 16, viền `border`, đổ bóng nhẹ. Bấm vào thu nhỏ nhẹ (98%).

**Huy hiệu (badge)**
|Huy hiệu|Kiểu|
|---|---|
|✔ Đã xác thực danh tính / Đã xác thực kinh doanh / Đã xác thực chủ quán|Nền `primaryLight`, chữ + icon `primary`|
|🟢 Đang mở cửa|Nền `success` nhạt, chữ `success`|
|🟠 Sắp đóng cửa · Tạm ngưng nhận đơn|Nền `warning` nhạt, chữ `warning`|
|🔴 Đã đóng cửa|Nền `danger` nhạt, chữ `danger`|
|🛵 Đã đặt món · 🍽 Đã đến theo đặt bàn · 📍 Check-in tại quán (trên đánh giá)|Nền xám xanh nhạt, chữ `primary`|

### Điều hướng

**Thanh điều hướng dưới của module — 4 mục**
`🔍 Khám phá` · `💬 Tin nhắn` · `🔔 Thông báo` · `👤 Của tôi` (tin nhắn, thông báo chỉ của module Quán ăn)
- Mục đang chọn: icon đặc + chữ `primary`; mục khác: icon viền + `textSecondary`.
- Nền trắng, đổ bóng nhẹ phía trên. Số tin chưa đọc: chấm đỏ `danger`.
- Góc trên có nút **về trang chủ của app** (trang chủ chỉ là lưới icon các module, do nhóm làm, không thuộc tài liệu này).

**Thanh trên (app bar):** nền trắng, tiêu đề `h2` màu `textPrimary`, nút quay lại `primary`. Trang chi tiết có ảnh bìa: thanh trong suốt, nút tròn trắng nổi trên ảnh.

**Máy tính (màn hình rộng):** thanh điều hướng chuyển sang **cột bên trái**; sảnh hiện **danh sách bên trái + bản đồ bên phải** cùng lúc; trang quản lý và admin dùng bảng nhiều cột. Các chức năng chỉ có trên điện thoại (chụp ảnh mặt tiền, chụp giấy tờ, check-in, chụp bằng chứng) hiện thông báo "Vui lòng dùng app trên điện thoại" — bảng "Điện thoại và máy tính" bên dưới.

### Bản đồ

- Ghim quán: **viên thuốc** (pill) nền `primary`, chữ trắng, hiện giá ("25–40k").
- Đã đóng cửa: ghim **xám** `#64748B`.
- Đang chọn: ghim **to hơn** + viền trắng dày.
- Cụm: vòng tròn `primary` với số ở giữa.
- Điểm gốc: chấm xanh `#29B6F6` có quầng sáng + vòng tròn bán kính viền `primary` nét đứt, nền mờ 8%.

### Trạng thái màn hình

|Trạng thái|Hiển thị|
|---|---|
|**Đang tải**|**Khung xương (skeleton)** màu `#E6EEF8` nhấp nháy, đúng hình dạng thẻ thật. Không dùng màn hình trắng có vòng xoay|
|**Rỗng**|Hình minh họa nét xanh + 1 dòng giải thích + 1 nút gợi ý (vd "Không tìm thấy quán phù hợp" + [Xóa bộ lọc])|
|**Lỗi**|Icon cảnh báo + "Không tải được dữ liệu" + [Thử lại]|
|**Thành công**|Thông báo nổi (snackbar) nền `textPrimary`, chữ trắng, kèm ✓ xanh lá; thao tác về tiền dùng **màn hình kết quả riêng**|
|**Cảnh báo lừa đảo**|Khung nền `danger` nhạt, viền trái đỏ, icon ⚠️|

### Icon, ảnh, chuyển động

- **Icon:** bộ **Material Symbols Rounded**, nét bo tròn, cỡ 24 (trong nút 20).
- **Ảnh:** tỷ lệ 16:9 cho ảnh bìa, 1:1 cho ảnh món; luôn có ảnh giữ chỗ màu `primaryLight` khi đang tải.
- **Chuyển động:** ngắn (150–250 ms), nhẹ nhàng: chuyển trang trượt ngang, bảng lọc trượt từ dưới lên, ❤️ nảy nhẹ khi bấm. Không dùng hiệu ứng rườm rà.

### Khả năng tiếp cận

- Vùng bấm tối thiểu **48×48**.
- Hỗ trợ **phóng to chữ** của hệ điều hành (giao diện không vỡ khi chữ lớn 130%).
- Ảnh có mô tả thay thế cho trình đọc màn hình.
- Mọi biểu mẫu báo lỗi **bằng chữ**, không chỉ đổi màu viền.

### Điện thoại và máy tính

App Flutter chạy trên **điện thoại** (đủ chức năng) và **máy tính Windows** (xem và quản lý). Theo hiểu biết hiện tại, một số thư viện chưa chạy trên Windows (cần kiểm tra lại trên pub.dev):

|Chức năng|Điện thoại|Máy tính|
|---|---|---|
|Xem, tìm, lọc, chi tiết, chat, đánh giá|✅|✅|
|Quản lý quán, menu, xử lý đơn, đặt bàn|✅|✅|
|Admin duyệt, xử lý khiếu nại, kháng nghị|✅|✅ (nên dùng)|
|Thanh toán|✅|✅ (mở trang của cổng thanh toán)|
|Bản đồ|Google Maps|Nếu không hỗ trợ: dùng bản đồ thay thế (ví dụ bản đồ mở OpenStreetMap) hoặc chỉ hiện danh sách + nút mở bản đồ|
|Chụp mặt tiền, chụp giấy tờ, check-in, chụp bằng chứng|✅|❌ — hiện "Vui lòng dùng app trên điện thoại"|
|Thông báo đẩy|✅|Nếu không hỗ trợ: cập nhật khi app đang mở|

## 3.20 Danh sách màn hình

|Mã|Màn hình|Ai dùng|
|---|---|---|
|QA-SV-01|Sảnh — danh sách|Khách, SV|
|QA-SV-02|Bảng bộ lọc|Khách, SV|
|QA-SV-03|Sảnh — bản đồ|Khách, SV|
|QA-SV-04|Chi tiết quán (thông tin, hình thức phục vụ, khuyến mãi, menu, đánh giá: điểm tổng + 4 tiêu chí)|Khách, SV|
|QA-SV-05|Chi tiết món (tùy chọn, ghi chú, thêm vào giỏ)|SV|
|QA-SV-06|Giỏ hàng|SV|
|QA-SV-07|Đặt món (hình thức, địa chỉ, càng sớm càng tốt / hẹn giờ 30 phút – 2 giờ, thanh toán; báo khi giá đổi)|SV|
|QA-SV-08|Theo dõi đơn (dòng thời gian, hủy vì quán chậm, chưa nhận được món — đơn đến lấy bấm được từ thời điểm nhận món dự kiến, trước đó nút mờ kèm giải thích, **mã nhận món 4 số**, "Chờ xác nhận nhận món" đếm ngược 24 giờ, đã nhận món)|SV|
|QA-SV-09|Khiếu nại đơn · phản đối "khách không nhận"|SV|
|QA-SV-10|Đặt bàn|SV|
|QA-SV-11|Check-in|SV|
|QA-SV-12|Của tôi — Quán ăn|SV|
|QA-SV-13|Viết đánh giá (chấm đủ 4 tiêu chí, nhận xét, ảnh, thẻ nhanh)|SV|
|QA-CQ-01|Đăng quán (5 phần)|Chủ quán|
|QA-CQ-02|Chụp ảnh mặt tiền (GPS)|Chủ quán|
|QA-CQ-03|Quản lý — Đơn hàng (chuông, đếm ngược, **nhập mã nhận món**, **"Đã giao" + chụp ảnh giao GPS**, khách không nhận kèm ảnh)|Chủ quán|
|QA-CQ-04|Quản lý — Đặt bàn|Chủ quán|
|QA-CQ-05|Quản lý — Menu|Chủ quán|
|QA-CQ-06|Quản lý — Khuyến mãi|Chủ quán|
|QA-CQ-07|Quản lý — Giờ mở cửa / tạm nghỉ (hộp cảnh báo đơn, bàn bị ảnh hưởng)|Chủ quán|
|QA-CQ-08|Quản lý — Doanh thu|Chủ quán|
|QA-CQ-09|Sửa thông tin quán · nâng cấp lên hộ kinh doanh|Chủ quán|
|QA-CQ-10|Cài đặt đặt món|Chủ quán hộ KD|
|QA-AD-01|Duyệt quán / bản chỉnh sửa / nâng cấp · cờ khai sai loại|Admin Quán ăn|
|QA-AD-02|Khiếu nại đơn · phản đối "khách không nhận" · đơn quá hạn chưa có bằng chứng giao / nhận|Admin Quán ăn|
|QA-AD-03|Đình chỉ quán|Admin Quán ăn|
|QA-SV-14|Chat của module (danh sách, cuộc trò chuyện, thẻ tin, câu hỏi nhanh)|SV, chủ quán|
|QA-SV-15|Thông báo của module + cài đặt thông báo|SV, chủ quán|
|QA-SV-16|Báo cáo · kháng nghị (gửi, xem kết quả)|SV, chủ quán|
|QA-SV-17|Thanh toán (chuyển sang cổng, màn hình kết quả) · địa chỉ đã lưu|SV|
|QA-CQ-11|Ví chủ quán: tiền đang giữ, đã nhận|Chủ quán|
|QA-AD-04|Hàng chờ admin Quán ăn (lọc theo loại, cờ khẩn)|Admin Quán ăn|
|QA-AD-05|Xử lý báo cáo · kháng nghị · khóa chức năng người dùng|Admin Quán ăn|

## 3.21 Cây thư mục

> Khớp **sườn chung của nhóm**: module nằm ở `lib/features/quan_an/` và **chỉ có đúng 4 thư mục con** `models/ · services/ · screens/ · widgets/` (file cấu hình nằm trong `models/`, điều hướng trong `screens/`, giao diện riêng trong `widgets/`). Thư mục **riêng** của module gồm cả giao diện, thanh toán, **chat, đánh giá** (mỗi module tự có, không dùng chung vì đánh giá phòng trọ và đánh giá quán khác tiêu chí, khác nhãn; chat gắn với phòng / đơn của từng module), báo cáo, kháng nghị, thông báo. Từ phần chung của app chỉ dùng: `shared/` → **chỉ model `User`** · `core/utils` (định dạng giá, ngày…) · `core/services` (kết nối chung) · `features/auth/` (tài khoản, xác nhận người thật — Phần 4). Giao diện **không** dùng `core/theme` mà dùng theme riêng của module. Trong `screens/` chia theo **vai trò**. Mã màn hình ở cuối dòng khớp với mục 3.20. Con số quy định (bảng 3.16) để trong file cấu hình, **không viết cứng**. **Không dùng code của module khác**; chỉ gọi phần tài khoản và xác nhận người thật (Phần 4).

```
lib/features/quan_an/                # Module Quán ăn
├── models/
│   ├── quan_an_config.dart          # Bảng 3.16 (không viết cứng số trong code)
│   ├── quan_an.dart                 # Quán, cài đặt đặt món, bản chỉnh sửa, số liệu (3.17)
│   ├── gio_mo_cua.dart              # Lịch tuần, ca qua nửa đêm, tạm nghỉ
│   ├── nhom_mon.dart
│   ├── mon_an.dart
│   ├── khuyen_mai.dart
│   ├── gio_hang.dart
│   ├── don_mon.dart                 # Đơn món + trạng thái (3.5i), mã nhận món, ảnh giao, cờ 6 giờ
│   ├── dat_ban.dart                 # Đặt bàn + trạng thái (3.5j)
│   ├── check_in.dart
│   ├── quan_an_filter.dart
│   ├── thanh_toan.dart
│   ├── tin_nhan.dart
│   ├── danh_gia.dart
│   ├── bao_cao.dart
│   ├── khang_nghi.dart
│   └── thong_bao.dart
├── services/
│   ├── quan_an_service.dart         # Sảnh, chi tiết, tạo/sửa, tạm nghỉ, nâng cấp loại
│   ├── menu_service.dart
│   ├── khuyen_mai_service.dart
│   ├── gio_hang_service.dart
│   ├── don_mon_service.dart         # Tính giá, tạo đơn, thao tác, bằng chứng giao / nhận, cờ 6 giờ, khiếu nại, phản đối
│   ├── dat_ban_service.dart
│   ├── check_in_service.dart
│   ├── thanh_toan_service.dart
│   ├── chat_service.dart
│   ├── danh_gia_service.dart
│   ├── bao_cao_service.dart
│   ├── khang_nghi_service.dart
│   └── thong_bao_service.dart
├── screens/
│   ├── quan_an_routes.dart          # Điều hướng giữa các màn hình của module
│   ├── sinh_vien/
│   │   ├── quan_an_sanh_screen.dart # QA-SV-01
│   │   ├── quan_an_bo_loc_sheet.dart # QA-SV-02
│   │   ├── quan_an_ban_do_screen.dart # QA-SV-03
│   │   ├── quan_an_detail_screen.dart # QA-SV-04
│   │   ├── mon_an_detail_sheet.dart # QA-SV-05
│   │   ├── gio_hang_screen.dart     # QA-SV-06
│   │   ├── dat_mon_screen.dart      # QA-SV-07
│   │   ├── theo_doi_don_screen.dart # QA-SV-08
│   │   ├── khieu_nai_don_screen.dart # QA-SV-09
│   │   ├── dat_ban_screen.dart      # QA-SV-10
│   │   ├── check_in_screen.dart     # QA-SV-11
│   │   ├── cua_toi_quan_an_screen.dart # QA-SV-12
│   │   └── danh_gia_quan_screen.dart # QA-SV-13
│   ├── tuong_tac/
│   │   ├── chat_screen.dart         # QA-SV-14
│   │   ├── thong_bao_screen.dart    # QA-SV-15
│   │   ├── bao_cao_khang_nghi_screen.dart # QA-SV-16
│   │   └── thanh_toan_screen.dart   # QA-SV-17
│   ├── chu_quan/
│   │   ├── dang_quan_screen.dart    # QA-CQ-01
│   │   ├── chup_mat_tien_screen.dart # QA-CQ-02
│   │   ├── quan_ly_don_screen.dart  # QA-CQ-03
│   │   ├── quan_ly_dat_ban_screen.dart # QA-CQ-04
│   │   ├── quan_ly_menu_screen.dart # QA-CQ-05
│   │   ├── quan_ly_khuyen_mai_screen.dart # QA-CQ-06
│   │   ├── quan_ly_gio_mo_cua_screen.dart # QA-CQ-07
│   │   ├── doanh_thu_screen.dart    # QA-CQ-08
│   │   ├── sua_thong_tin_quan_screen.dart # QA-CQ-09
│   │   ├── cai_dat_dat_mon_screen.dart # QA-CQ-10
│   │   └── vi_screen.dart           # QA-CQ-11
│   └── admin/
│       ├── duyet_quan_screen.dart   # QA-AD-01
│       ├── khieu_nai_don_screen.dart # QA-AD-02
│       ├── dinh_chi_quan_screen.dart # QA-AD-03
│       ├── hang_cho_admin_screen.dart # QA-AD-04
│       └── bao_cao_khang_nghi_admin_screen.dart # QA-AD-05
└── widgets/
    ├── quan_an_theme.dart           # Giao diện riêng của module (mục 3.19)
    ├── quan_an_card.dart
    ├── trang_thai_mo_cua_badge.dart
    ├── mon_an_tile.dart
    ├── nhom_mon_tab_bar.dart
    ├── tuy_chon_mon_group.dart
    ├── khuyen_mai_banner.dart
    ├── gio_hang_bar.dart
    ├── don_timeline.dart
    ├── don_dem_nguoc_tile.dart
    ├── diem_danh_gia_box.dart       # Điểm xác minh + điểm chưa xác minh (nhạt)
    └── quan_map_marker.dart

test/features/quan_an/
├── models/
├── services/
└── logic/                           # Giờ mở cửa (ca qua nửa đêm, tạm nghỉ), tính khuyến mãi, bảng 3.5i
```


## 3.22 Thứ tự làm

> Mỗi task ≈ 1 buổi code; làm xong, kiểm tra theo mục 3.23 rồi mới sang task tiếp. Cần phần tài khoản và xác nhận người thật (mục 4.8) có trước, hoặc tạm dùng tài khoản giả.

**Giai đoạn 1 — Nền của module**
- [ ] QA-1.1 Giao diện của module (mục 3.19): màu, chữ, nút, thẻ, ô nhập, trạng thái tải / rỗng / lỗi
- [ ] QA-1.2 Tải ảnh lên (công khai + riêng tư)
- [ ] QA-1.3 Điểm gốc + bản đồ (mục 3.7)
- [ ] QA-1.4 Tự xử lý hạn + chặn hai người thao tác cùng lúc (mục 3.18)
- [ ] QA-1.5 Thông báo đẩy + danh sách thông báo của module (mục 3.11)
- [ ] QA-1.6 Bộ đếm lần vi phạm 30 ngày theo số điện thoại
- [ ] QA-1.7 Thanh toán sandbox PayPal / MoMo + giữ tiền + chỉ tin kết quả từ cổng + chống trừ tiền 2 lần + tiền đến muộn (mục 3.6)

**Giai đoạn 2 — Tìm quán**
- [ ] QA-2.1 Dữ liệu quán, giờ mở cửa, nhóm món, menu (mục 3.17) + dữ liệu mẫu
- [ ] QA-2.2 Tính trạng thái mở cửa (nhiều ca, qua nửa đêm, tạm nghỉ, nghỉ dài ngày)
- [ ] QA-2.3 Sảnh + bộ lọc (kể cả ăn tại quán, mang đi, giao hàng, điểm đánh giá) + tìm theo tên món + mức giá P25–P75
- [ ] QA-2.4 Bản đồ quán + chi tiết quán + menu
- [ ] QA-2.5 Đăng quán 5 bước (2 loại hình) + mã số thuế + admin duyệt + cờ khai sai + nâng cấp loại
- [ ] QA-2.6 Quản lý menu, giờ mở cửa, sửa thông tin (bản chỉnh sửa chờ duyệt)
- [ ] QA-2.7 Khuyến mãi: tạo, hết hạn, hiển thị
- [ ] QA-2.8 Check-in GPS + "Sinh viên hay ăn" + nhắc 90 ngày

**Giai đoạn 3 — Đặt bàn, đặt món**
- [ ] QA-3.1 Đặt bàn + quản lý đặt bàn + bảo vệ bằng check-in
- [ ] QA-3.2 Cài đặt đặt món + giỏ hàng + chi tiết món (tùy chọn)
- [ ] QA-3.3 Hệ thống tự tính giá + 7 quy tắc khuyến mãi (combo, giờ vàng)
- [ ] QA-3.4 Đặt món (càng sớm càng tốt / hẹn giờ 30 phút – 2 giờ, chốt giá, báo giá đổi) + thanh toán (thanh toán của module, mục 3.6) + tiền mặt khi nhận
- [ ] QA-3.5 Quản lý đơn của chủ quán (chuông, đếm ngược 5 phút, tự tạm ngưng, **nhập mã nhận món**, **chụp ảnh giao có GPS**) + máy trạng thái đơn (bảng 3.5i)
- [ ] QA-3.6 Theo dõi đơn + "Hủy vì quán chậm" + "Chưa nhận được món" (đến lấy: từ thời điểm nhận món dự kiến) + **bằng chứng giao / nhận (mã 4 số, ảnh GPS)** + chờ xác nhận nhận món 24 giờ (cả đơn tiền mặt giao tận nơi) + giải ngân (chỉ đơn app) + cờ quá 6 giờ chưa có bằng chứng
- [ ] QA-3.7 Khiếu nại đơn + admin hoàn toàn phần / một phần
- [ ] QA-3.8 "Khách không nhận" + phản đối 24 giờ + bom hàng

**Giai đoạn 4 — Tương tác và hoàn thiện**
- [ ] QA-4.1 Chat của module + thẻ tin + câu hỏi nhanh + cảnh báo từ khóa + chặn (mục 3.8)
- [ ] QA-4.2 Đánh giá có cấu trúc 4 tiêu chí + điểm tổng tự tính + điểm từng tiêu chí của quán (nhãn xác minh, điểm chỉ tính đánh giá xác minh) (mục 3.9)
- [ ] QA-4.3 Lưu ❤️ + cài đặt thông báo
- [ ] QA-4.4 Báo cáo + gắn cờ ưu tiên + ẩn tạm đánh giá / tin nhắn (xúc phạm / lộ thông tin) và admin khôi phục + admin của module (mục 3.10, 3.12)
- [ ] QA-4.5 Kháng nghị + admin xử lý (mục 3.15)
- [ ] QA-4.6 Ẩn / khóa khi còn giao dịch đang chạy (mục 3.14)
- [ ] QA-4.7 Giao diện máy tính: chỉ xem và quản lý
- [ ] QA-4.8 Kiểm thử theo mục 3.23

**Nếu thiếu thời gian:**
- **Mức 1:** lùi toàn bộ **đặt món** (Giai đoạn 3 trừ QA-3.1, và QA-1.7) sang mục 3.24. Quán ăn vẫn đủ: tìm quán, menu, khuyến mãi hiển thị, đặt bàn, check-in, đánh giá.
- **Mức 2:** lùi **combo / giờ vàng** (một phần QA-3.3). Khuyến mãi còn loại giảm %, giảm tiền, ưu đãi sinh viên.


## 3.23 Tiêu chí nghiệm thu

> Một chức năng được coi là **xong** khi đạt hết các tiêu chí dưới đây và tuân thủ quy tắc chung ở mục 3.18. Con số lấy từ bảng 3.16 và 4.5; khi test được phép **rút ngắn thời hạn qua file cấu hình**.

**Đăng quán, loại hình**
- [ ] Quán bán lẻ không thấy và không bật được: nhận đặt món, nhận đặt bàn.
- [ ] Hộ kinh doanh không nhập mã số thuế thì không gửi duyệt được.
- [ ] Ảnh mặt tiền và giấy tờ **không** chọn được từ thư viện; ảnh lệch > 200 m bị gắn cờ; ảnh bìa là ảnh mặt tiền.
- [ ] Bán lẻ không thấy lựa chọn "Nhận đặt bàn". Bán lẻ tick máy lạnh / chỗ ngồi trong nhà, menu > 40 món hoặc mở > 14 giờ/ngày → bị gắn cờ ở admin.
- [ ] Nâng cấp lên hộ kinh doanh: phải gửi mã số thuế + ảnh giấy chứng nhận; chỉ sau khi duyệt mới bật được đặt món, đặt bàn.
- [ ] Quán lưu động đổi chỗ bán thường xuyên: bắt buộc chụp lại ảnh mặt tiền và gửi duyệt lại.
- [ ] Quán có < 3 món không hiện ở sảnh.

**Giờ mở cửa, sảnh**
- [ ] Trạng thái Đang mở / Sắp đóng / Đã đóng đúng theo lịch tuần, kể cả quán 2 ca và **ca qua nửa đêm** (ví dụ 18:00–02:00: lúc 01:00 ngày hôm sau vẫn "Đang mở").
- [ ] "Tạm nghỉ hôm nay" hết hiệu lực ở ca mở kế tiếp tính từ ngày mai.
- [ ] Tạm nghỉ khi đang có đơn / bàn: hiện hộp cảnh báo; xác nhận thì xử lý theo mục 3.14.
- [ ] Mức giá quán = P25–P75 của món chính (bỏ nhóm đồ uống / món thêm); quán không có món chính thì tính mọi món; lọc giá theo trung vị.
- [ ] Lọc "Đang mở cửa" + "Dưới 35k" + bán kính cho kết quả đúng; tìm theo **tên món** ra đúng quán.
- [ ] Lọc "Giao hàng (đặt qua app)" chỉ ra quán giao tới được điểm gốc (hoặc có đến lấy); quán bán lẻ / vỉa hè không bao giờ có trong kết quả này.
- [ ] Lọc "Mang đi" chỉ ra quán khai mang đi; lọc "Ăn tại quán" chỉ ra quán khai ăn tại quán. Tạo quán không chọn hình thức phục vụ nào: không gửi duyệt được.
- [ ] Lọc "Từ ★4 trở lên": chỉ ra quán có điểm tổng thể đã xác minh ≥ 4; quán chưa có đánh giá xác minh không hiện.
- [ ] Quán 90 ngày không hoạt động: chủ được nhắc; 7 ngày không bấm "Quán vẫn hoạt động" → quán bị ẩn.

**Khuyến mãi**
- [ ] Khuyến mãi hết hạn tự ẩn, không còn được áp.
- [ ] Combo: giỏ đủ món combo thì áp giá combo, phần dư tính giá thường.
- [ ] Giờ vàng: đặt trong khung giờ (giờ của hệ thống) thì áp, ngoài khung thì không.
- [ ] Mỗi đơn chỉ áp combo + 1 khuyến mãi có lợi nhất; mức giảm không vượt tiền món, không áp lên phí giao.
- [ ] Giá hiện trên app khớp giá hệ thống tính lại; sửa số tiền gửi từ app không có tác dụng.

**Đặt món, thanh toán**
- [ ] Giỏ chỉ chứa món 1 quán; món hết không thêm được; chưa đủ đơn tối thiểu thì không đặt được.
- [ ] Địa chỉ ngoài bán kính giao không chọn được.
- [ ] Hẹn giờ: dưới 30 phút, quá 2 giờ tới hoặc sau giờ đóng ca đều không chọn được; quán đang tạm ngưng nhận đơn thì không hẹn được.
- [ ] Đang đặt mà món vừa hết / quán vừa tạm ngưng / khuyến mãi vừa hết hạn / giá vừa đổi: không tạo đơn, không tạo giao dịch; giá đổi thì app hiện tổng mới để sinh viên xác nhận lại.
- [ ] Đơn đã tạo: quán đổi giá món, xóa khuyến mãi → tổng tiền của đơn **không đổi**.
- [ ] Cổng thanh toán báo "đã trả" 2 lần cho cùng một đơn: chỉ 1 đơn, tiền chỉ giữ 1 lần.
- [ ] Thanh toán sandbox thành công → đơn `placed`, giao dịch `held`; cổng ghi nhận thành công sau hạn → `refunded`; ghi nhận trước hạn nhưng báo về sau hạn → vẫn đúng hạn.
- [ ] Quán không nhận trong 5 phút → `expired_accept`, hoàn 100%; 3 lần / ngày → quán tự "Tạm ngưng nhận đơn".
- [ ] SV hủy khi `placed`: hoàn 100%; sau `accepted` không còn nút hủy thường.
- [ ] Quá giờ dự kiến sẵn sàng (đơn hẹn giờ: giờ hẹn) + 30 phút: hiện nút "Hủy vì quán chậm" → `cancelled_restaurant` (`restaurant_late`), hoàn 100%, giảm tỷ lệ nhận đơn quán.
- [ ] "Đang giao" quá 60 phút: hiện nút "Chưa nhận được món" → mở khiếu nại.
- [ ] Đơn đến lấy, T_lấy = 18:00, quán báo "Sẵn sàng" lúc 17:30: từ 17:30 tới trước 18:00 nút "Chưa nhận được món" **mờ** kèm giải thích, hệ thống chặn; từ 18:00 bấm được ngay (không ân hạn, không chờ 6 giờ) → đơn app: `disputed`, tiền giữ, **không** tự hoàn; đơn tiền mặt: tranh chấp giao nhận, admin xác minh.
- [ ] Đơn "càng sớm càng tốt" đến lấy: T_lấy = giờ dự kiến sẵn sàng quán ghi khi nhận đơn, không bao giờ để trống.
- [ ] Đơn đến lấy: SV thấy mã 4 số khi đơn "Sẵn sàng"; quán nhập sai mã → không ghi nhận; nhập đúng → `delivered` (đơn app) / `completed` (tiền mặt, có nhãn 🛵).
- [ ] Đơn giao: bấm "Đã giao" mà không chụp ảnh trong app, hoặc GPS lệch quá ngưỡng so với điểm giao → không ghi nhận; có ảnh hợp lệ → `delivered` (cả đơn app và **đơn tiền mặt**; đơn tiền mặt **không** hoàn tất ngay, chờ 24 giờ không phản đối mới `completed` và mới có nhãn 🛵).
- [ ] Đơn trả trên app có bằng chứng: tiền **vẫn `held`**, SV thấy "Chờ xác nhận nhận món" và được nhắc sau 1 giờ, khi còn 1 giờ.
- [ ] Bấm "Đã nhận món" hoặc hết 24 giờ sau `delivered` không phản đối → `completed`, giải ngân, nhắc đánh giá. Phản đối / khiếu nại trong 24 giờ → `disputed`, tiền giữ.
- [ ] Đơn ở "Sẵn sàng" / "Đang giao" quá 6 giờ không có bằng chứng, không ai bấm gì → gắn cờ vào hàng chờ admin; tiền vẫn `held`, **không** tự hoàn, **không** tự giải ngân. Admin quyết hoàn 100% hoặc chuyển tiền cho quán.
- [ ] Tự hoàn tất và SV mở khiếu nại cùng lúc: chỉ một bên thắng; nếu khiếu nại thắng thì tiền không giải ngân.
- [ ] Khiếu nại thiếu / sai món không có ảnh chụp trong app thì không gửi được; đang khiếu nại không giải ngân; admin hoàn một phần đúng số.
- [ ] Quán không trả lời khiếu nại trong 2 giờ → chuyển admin quyết.
- [ ] Khiếu nại sai sự thật bị bác 3 lần / 30 ngày → khóa đặt món trả trên app 30 ngày.
- [ ] Quán tạm nghỉ / bị ẩn / bị đình chỉ: đơn đang chờ xác nhận → `cancelled_restaurant`, hoàn 100%; bàn đã xác nhận bị hủy, không tính lỗi sinh viên (mục 3.14).
- [ ] Quán bị **khóa bán**: không nhận đơn mới. Đơn đã có bằng chứng giao / nhận vẫn chạy tiếp 24 giờ, không phản đối thì hoàn tất và giải ngân cho quán; đơn đang tranh chấp do admin quyết; đơn đã hoàn tất không đổi. **Không** có đơn nào tự hoàn chỉ vì quán bị khóa.

**Tiền mặt, bom hàng**
- [ ] Đơn từ 200.000đ trở lên không chọn được tiền mặt.
- [ ] Đơn tiền mặt: không có khoản tiền qua app, không có giữ tiền, hoàn tiền, chuyển tiền, khiếu nại tiền. Đến lấy: hoàn tất khi quán nhập đúng mã. Giao tận nơi: có ảnh GPS → `delivered`, 24 giờ SV không báo "Chưa nhận được món" → `completed`; SV báo → admin xác minh (đã giao → `completed` + nhãn 🛵, không giao → `cancelled_restaurant`). Không có bằng chứng → quá 6 giờ gắn cờ admin.
- [ ] Đơn đến lấy: `ready` quá 30 phút mới bấm được "Khách không nhận", ảnh chụp tại quán. Đơn giao: bấm khi đang giao, ảnh chụp tại điểm giao. Cả hai đều bắt buộc ảnh chụp trong app có GPS.
- [ ] Đơn tiền mặt bị "Khách không nhận" và sinh viên phản đối: admin quyết tính bom hàng → `completed`, không tính → `cancelled_restaurant`.
- [ ] "Khách không nhận" (đơn trả trên app): tiền giữ thêm 24 giờ; SV phản đối trong 24 giờ → `disputed`; không phản đối → `completed`, lúc đó mới tính 1 lần bom hàng.
- [ ] Admin chấp nhận phản đối → hoàn cho SV, không tính bom hàng.
- [ ] 2 lần bom hàng / 30 ngày → mất lựa chọn tiền mặt; 3 lần → khóa đặt món 7 ngày.
- [ ] Mỗi chuyển trạng thái trong bảng 3.5i có ít nhất 1 test tự động.

**Khách, ngừng kinh doanh**
- [ ] Khách không thấy số điện thoại chủ quán; bấm đặt món / đặt bàn / check-in / chat thì bắt đăng nhập rồi quay lại đúng trang.
- [ ] "Ngừng kinh doanh" bị chặn khi còn giao dịch đang chạy; không còn thì quán → `closed`, không hiện ở sảnh.

**Đặt bàn, check-in, đánh giá**
- [ ] Không đặt bàn được giờ cách lúc đặt dưới 1 giờ, giờ quán đóng hoặc quá 7 ngày.
- [ ] Quán không xác nhận trong min(30 phút, giờ hẹn − 30 phút) → `expired`.
- [ ] Hủy bàn **đã xác nhận** dưới 1 giờ trước giờ hẹn: tính 1 lần bỏ hẹn; hủy khi quán **chưa xác nhận** thì không tính dù sát giờ; 3 lần / 30 ngày → khóa đặt bàn 7 ngày.
- [ ] SV có check-in hợp lệ trong giờ giữ bàn → nút "Khách không đến" của quán bị vô hiệu.
- [ ] Quán chỉ bấm được "Khách không đến" sau 15 phút giữ bàn; quán hủy bàn đã xác nhận → giảm tỷ lệ giữ bàn.
- [ ] Bàn đã xác nhận mà quán không bấm gì: hết giờ giữ bàn + 24 giờ thì tự đóng, không tính bỏ hẹn, không cấp nhãn 🍽.
- [ ] Quán bấm "Khách đã đến" mà SV không check-in: bàn `arrived` nhưng đánh giá **không** có nhãn 🍽. SV check-in hợp lệ trong giờ giữ bàn → có nhãn 🍽.
- [ ] Check-in ngoài 100 m hoặc ngoài giờ mở bị từ chối; check-in lần 2 trong ngày bị từ chối.
- [ ] Đánh giá quán cần đã xác nhận email; mỗi người chỉ 1 đánh giá / quán, tối đa 10 đánh giá / ngày; chủ quán không đánh giá được quán mình.
- [ ] Điểm sao chỉ tính đánh giá đã xác minh; đánh giá chưa xác minh hiện điểm riêng (nhạt).
- [ ] Viết đánh giá thiếu 1 trong 4 tiêu chí: không gửi được; không có ô nhập điểm tổng.
- [ ] Chấm Món ăn 5 · Giá cả 4 · Vệ sinh 3 · Phục vụ 4 → điểm tổng thể của đánh giá = 4,0.
- [ ] Trang quán hiện điểm tổng thể, số lượt đánh giá và điểm trung bình đúng của từng tiêu chí; thẻ quán ở danh sách chỉ hiện điểm tổng thể.
- [ ] Sửa đánh giá: điểm tổng thể và điểm từng tiêu chí của quán được tính lại.
- [ ] Nhãn đúng nguồn: đơn hoàn tất **có bằng chứng phía sinh viên / giao nhận hợp lệ** (SV bấm "Đã nhận món", mã nhận món đúng, hoặc ảnh giao GPS + 24 giờ không phản đối; cả đơn tiền mặt) → 🛵 "Đã đặt món"; đơn hoàn tất do "Khách không nhận" → không có nhãn; admin kết luận đã giao → 🛵; đơn tiền mặt giao tận nơi có ảnh nhưng chưa hết 24 giờ → **chưa** có nhãn; đặt bàn có **SV check-in hợp lệ** gắn với lượt đặt → 🍽 "Đã đến theo đặt bàn"; quán chỉ bấm "Khách đã đến" → **không** có 🍽; chỉ có check-in → 📍 "Check-in tại quán"; có nhiều nguồn thì hiện nhãn mạnh nhất.
- [ ] "Sinh viên hay ăn" đếm số người khác nhau, mỗi người tối đa 1 lượt / quán / 7 ngày.


**Thanh toán**
- [ ] Bấm thanh toán 2 lần chỉ tạo 1 giao dịch, không bị trừ 2 lần.
- [ ] Cổng thanh toán báo về với chữ ký sai: bị từ chối, không đổi trạng thái gì.
- [ ] Quá 15 phút chưa trả: đơn `expired`, không gửi quán.
- [ ] Cổng thanh toán **ghi nhận** thành công **sau** hạn: tiền tự hoàn 100%, người dùng nhận thông báo. Ghi nhận trước hạn mà báo về sau hạn: vẫn đúng hạn.
- [ ] PayPal hoàn một phần: số USD hoàn = tỷ lệ VND hoàn / VND thu × USD đã thu, làm tròn 2 chữ số; lịch sử khoản tiền ghi lại lần hoàn.

**Hạn tự động**
- [ ] Mở lại một giao dịch đã quá hạn mà chưa được tự xử lý: app vẫn hiện đúng trạng thái sau hạn.
- [ ] Việc tự xử lý hạn chạy 2 lần hoặc chạy trễ: không hoàn tiền 2 lần, không chuyển tiền 2 lần, không ghi vi phạm 2 lần, không gửi thông báo 2 lần.

**Chat**
- [ ] Mỗi cặp người dùng chỉ có 1 cuộc trò chuyện.
- [ ] Mở chat từ quán: thẻ tin hiện đầu cuộc trò chuyện.
- [ ] Gõ "chuyển khoản", "chuyen khoan", "CK trước", "c.k" đều hiện cảnh báo (văn bản đã chuẩn hóa).
- [ ] Gõ "check", "tick" **không** bị cảnh báo ("CK" khớp nguyên từ). Gõ "trả bằng momo trên app" **không** cảnh báo; "chuyển momo trước cho anh" **có** cảnh báo.
- [ ] Chặn người dùng: người bị chặn không gửi tin được nữa.
- [ ] Tỷ lệ phản hồi của chủ quán = phần trăm cuộc trò chuyện mới được trả lời trong 24 giờ, tính 30 ngày gần nhất.
- [ ] Tin nhắn của module này không hiện trong module khác và ngược lại.

**Đánh giá**
- [ ] Nhận xét dưới 20 ký tự hoặc quá 5 ảnh không gửi được.
- [ ] Chủ quán chỉ trả lời 1 lần mỗi đánh giá; không đánh giá được quán của mình.
- [ ] Nhãn xác minh chỉ có khi người viết đã OTP và thỏa điều kiện của module.
- [ ] Điểm, nhãn, danh sách đánh giá chỉ tính trong module này.

**Báo cáo**
- [ ] Báo cáo từ tài khoản chưa OTP hoặc dưới 7 ngày tuổi không được tính vào ngưỡng gắn cờ.
- [ ] 3 báo cáo từ 3 số điện thoại khác nhau: tin **được gắn cờ** lên đầu hàng chờ admin nhưng **vẫn hiển thị**, không tự ghi vi phạm; chỉ ẩn khi admin quyết.
- [ ] Đánh giá và tin nhắn **không** tự ẩn, trừ 3 báo cáo cùng lý do "xúc phạm / lộ thông tin" → ẩn tạm, không ghi vi phạm; admin bác báo cáo → khôi phục.
- [ ] Quá 10 báo cáo / ngày bị chặn; 3 lần báo cáo sai → khóa báo cáo 30 ngày.

**Thông báo**
- [ ] Tắt một nhóm thông báo thì không nhận nhóm đó; thông báo về **tiền, đơn hàng, đặt bàn, khiếu nại, kháng nghị** không tắt được.

**Kháng nghị**
- [ ] Nút "Kháng nghị" có ở thông báo phạt và trong "Của tôi"; quá 7 ngày thì nút biến mất.
- [ ] Mỗi quyết định chỉ kháng nghị 1 lần; tối đa 3 bằng chứng chụp trong app.
- [ ] Đang kháng nghị thì hình phạt vẫn còn hiệu lực.
- [ ] Admin chấp nhận "xóa lần vi phạm": lần vi phạm chuyển sang "đã gỡ", bộ đếm 30 ngày giảm, khóa được gỡ nếu dưới ngưỡng.
- [ ] Lần vi phạm cũ hơn 30 ngày không còn được tính (cửa sổ trượt).

**Admin**
- [ ] Hàng chờ admin sắp theo: cờ khẩn → khiếu nại tiền và báo cáo ưu tiên cao → hồ sơ bị gắn cờ → còn lại theo thời gian; lọc được loại "Đơn quá 6 giờ chưa có bằng chứng", "Chỉnh sửa / nâng cấp loại chờ duyệt", "Quán nghi khai sai loại", "Kháng nghị".
- [ ] Khiếu nại treo quá 72 giờ tự có cờ khẩn.
- [ ] Mọi quyết định của admin được ghi vào nhật ký admin (ai, lúc nào, lý do).
- [ ] Admin kết luận chủ quán lừa đảo: **không** có đơn nào tự hoàn hay tự giải ngân; quán không nhận đơn mới; bàn đã xác nhận bị hủy không tính lỗi sinh viên; đề nghị khóa cả tài khoản được gửi tới admin danh tính (mục 3.14, 4.4).
- [ ] Đơn đã hoàn tất trước khi quán bị kết luận lừa đảo: không đổi. Đơn đang "Chờ xác nhận nhận món" có ảnh GPS: tiền vẫn `held`, đơn vào hàng chờ admin; admin chọn đã giao → `completed`, bằng chứng giả → `refunded`, chưa đủ căn cứ → `disputed`. Đơn chưa có bằng chứng: không tự coi là đã giao.
- [ ] Admin của module này không thấy, không xử lý được hồ sơ, báo cáo, khiếu nại của module khác.

**Không tự giao dịch**
- [ ] Chủ quán không dùng được các chức năng của sinh viên với quán của chính mình (hệ thống chặn, không chỉ ẩn nút); mở chat với quán của mình bị chặn.

**Bảo mật**
- [ ] Không mật khẩu, khóa bí mật nào nằm trong code hay repo.

## 3.24 Hướng phát triển

|Tính năng|Mô tả|
|---|---|
|Dời chỗ bán trong ngày cho quán lưu động|Xe đẩy cập nhật vị trí đang đứng trong ngày, không cần duyệt lại, có giới hạn khoảng cách so với chỗ bán thường xuyên|
|Nhân viên quán (nhiều tài khoản)|Chủ quán thêm nhân viên, phân quyền nhận đơn / xác nhận bàn / sửa menu|
|Đặt món trước nhiều giờ|Hẹn giờ xa hơn 2 giờ, có giới hạn số đơn theo khung giờ|
|Shipper bên ngoài|Kết nối dịch vụ giao hàng bên thứ ba|
|Theo dõi người giao|Xem vị trí người giao trên bản đồ theo thời gian thực|
|Cọc giữ bàn|Thu tiền cọc nhỏ khi đặt bàn đông người|
|Đặt món và thanh toán trên app|Chỉ khi bị cắt ở Mức 1 (mục 3.22)|
|Thanh toán tiền thật|Chuyển từ bản thử nghiệm sang giao dịch thật, hợp tác đơn vị trung gian thanh toán được cấp phép|
|Rút tiền cho chủ quán|Chủ quán rút tiền đã nhận về tài khoản ngân hàng|
|Tìm kiếm thông minh hơn|Gõ sai chính tả vẫn ra kết quả, xếp theo độ liên quan|
|Khoảng cách theo đường đi|Tính theo đường đi thực tế thay cho đường thẳng|
|Gợi ý cá nhân hóa|Gợi ý quán theo lịch sử tìm kiếm, lưu, đặt món|
|Chống gian lận nâng cao|Phát hiện cụm tài khoản liên quan để chặn đánh giá ảo, báo cáo ảo|
|Đầy đủ chức năng trên máy tính|Chụp ảnh mặt tiền, chụp giấy tờ, check-in trên máy tính khi thư viện hỗ trợ|
|Bản web|Phiên bản chạy trên trình duyệt|
|Chế độ tối|Bộ màu tối cho module|

## 3.25 Đánh giá module Quán ăn

|Tiêu chí|Điểm|Nhận xét|
|---|---|---|
|Có nhiều quán|⭐⭐⭐⭐⭐|Cả vỉa hè, xe đẩy cũng lên app — đúng nơi sinh viên hay ăn|
|Uy tín khi đặt món|⭐⭐⭐⭐|Chỉ hộ kinh doanh đã đối chiếu mã số thuế mới nhận đơn; tiền giữ tới khi nhận món; mọi quyết định một phía có đường phản đối|
|Dễ dùng cho sinh viên|⭐⭐⭐⭐⭐|Lọc theo món, giá, đang mở, khoảng cách; tìm theo tên món; đặt món, đặt bàn một chỗ|
|Dễ dùng cho chủ quán|⭐⭐⭐⭐|Bán lẻ đăng ký gọn; hộ kinh doanh thêm mã số thuế; nhận đơn cần nhanh|
|Đánh giá đáng tin|⭐⭐⭐⭐|Điểm chính chỉ tính đánh giá đã xác minh; đánh giá chưa xác minh vẫn hiện nhưng tách riêng; chấm theo 4 tiêu chí nên thấy rõ quán mạnh / yếu ở đâu|
|Độ khó khi làm|Rất khó|Giờ mở cửa nhiều ca, giỏ hàng có tùy chọn, tính khuyến mãi, trạng thái đơn, thanh toán|
|Khả năng làm xong|⭐⭐⭐|Đặt món nặng nhất (thêm bằng chứng giao / nhận); làm tìm quán trước, đặt món sau (mục 3.22)|

**Rủi ro còn lại**

|Rủi ro|Ghi chú|
|---|---|
|GPS giả (giả lập vị trí) vượt qua được ngưỡng khoảng cách|Gắn cờ khi thư viện định vị báo vị trí giả lập (cần kiểm tra lại); admin vẫn xem ảnh mặt tiền / ảnh check-in|
|Né bộ lọc chat bằng cách viết lách|Chuẩn hóa trước khi quét, danh sách từ khóa ở file cấu hình để bổ sung dần|
|Số điện thoại chủ quán hiện cho người đã đăng nhập → có thể bị rủ chuyển tiền ngoài app|Cảnh báo trong chat, nút báo cáo ưu tiên cao, nhắc "chỉ được bảo vệ khi trả qua app"|
|Quán mới chưa có đánh giá xác minh nên điểm trống|Chấp nhận; hiện "Chưa có đánh giá xác minh", khuyến khích check-in|
|Check-in bằng GPS giả lập để đẩy "Sinh viên hay ăn"|Đếm người khác nhau, 1 lượt / 7 ngày, gắn cờ giả lập (cần kiểm tra lại)|
|Quán bấm đã giao khi chưa giao để nhận tiền|Bắt buộc bằng chứng: mã nhận món 4 số (đến lấy) hoặc ảnh giao hàng có GPS (giao); sinh viên còn 24 giờ phản đối; không bằng chứng thì không tự giải ngân|
|Sinh viên đã nhận món nhưng cố tình không xác nhận để được hoàn|Không có luật tự hoàn khi quá hạn; có bằng chứng thì 24 giờ sau tự hoàn tất; không có bằng chứng thì admin quyết|
|Đơn tiền mặt không được bảo vệ tiền|Giới hạn giá trị đơn, chỉ cho người không có tiền sử bom hàng|

---

# PHẦN 4. TÀI KHOẢN VÀ XÁC NHẬN NGƯỜI THẬT (PHẦN CHUNG DUY NHẤT)

> Đây là **thứ duy nhất** hai module dùng chung: **1 tài khoản** và **1 lần xác nhận người thật**. Mọi thứ khác (đăng ký nhà trọ / quán, thanh toán, chat, đánh giá, báo cáo, thông báo, kháng nghị, admin, giao diện) **riêng từng module** (Phần 2, Phần 3).

> **🌟 Điểm nổi bật:** **"Xác nhận người thật một lần, dùng cho mọi module"** — người bán chỉ chứng minh danh tính 1 lần, nhưng **mỗi module vẫn duyệt hồ sơ kinh doanh riêng**; ai lừa đảo ở đâu thì bị khóa cả tài khoản.

## 4.1 Tài khoản (1 tài khoản cho mọi module)

**Đăng ký, đăng nhập**
- Đăng ký bằng email + mật khẩu, **tick đồng ý Điều khoản sử dụng và Chính sách quyền riêng tư** (lưu thời điểm và phiên bản đã đồng ý), xác nhận qua email.
- **Email trường** (đuôi `.edu.vn`): đăng ký bằng email trường, **hoặc bổ sung email trường sau** trong hồ sơ (xác nhận qua email đó) → có huy hiệu **"Email trường"**. Đổi tên từ "Sinh viên" vì đuôi `.edu.vn` gồm cả giảng viên, nhân viên. Module nào cần (ví dụ ưu đãi sinh viên, mục 3.3 Bước 4) tự đọc huy hiệu này.
- **Quên mật khẩu:** nhận link đặt lại qua email. **Đổi mật khẩu** trong trang cá nhân.
- **Đăng xuất:** xóa mã nhận thông báo của thiết bị đó.
- Nhập sai mật khẩu nhiều lần thì bị khóa đăng nhập tạm thời.

**Hồ sơ chung:** họ tên, ảnh đại diện, số điện thoại, giới thiệu ngắn. Những thứ còn lại (địa chỉ đã lưu, cài đặt thông báo, chỉ số người bán, các khóa chức năng) nằm trong **hồ sơ riêng của từng module** (mục 2.17, 3.17).

**Xác thực số điện thoại bằng mã OTP**
- **Bắt buộc với chủ trọ, chủ quán.**
- **Bắt buộc với sinh viên khi module yêu cầu** (mỗi module tự liệt kê: Tìm trọ mục 2.4, 2.10; Quán ăn mục 3.4, 3.10). Module chỉ hỏi phần này "số điện thoại đã OTP chưa".
- **Mỗi số điện thoại chỉ gắn với 1 tài khoản.** Đổi số phải xác thực lại, số mới không được trùng tài khoản khác.
- **Hình phạt của từng module** (khóa chức năng, bộ đếm vi phạm) do module đó quản lý riêng, nhưng **gắn với số điện thoại đã xác thực**, nên tạo tài khoản mới không né được phạt. Bị phạt ở module này **không** ảnh hưởng module kia, trừ khóa cả tài khoản (mục 4.4). Số điện thoại của tài khoản bị **khóa cả tài khoản** (mục 4.4) **không đăng ký lại được**.

**Xóa tài khoản**
- **Không cho xóa** khi ở **bất kỳ module nào** còn giao dịch đang chạy, tiền đang giữ, khiếu nại hoặc kháng nghị chưa xong (mục 2.14, 3.14). App hỏi từng module trước khi cho xóa.
- Khi xóa: ảnh giấy tờ và **video thử thách khuôn mặt** xóa ngay (nếu còn); **bản mã hóa của số CCCD bị xóa**; **chỉ giữ bản băm** nếu số CCCD đó đang thuộc **danh sách bị chặn** (cần kiểm tra lại quy định về dữ liệu cá nhân); hồ sơ được ẩn danh hóa; bản ghi giao dịch và đánh giá giữ lại ở dạng ẩn danh.

## 4.2 Xác thực người thật (1 lần cho mỗi tài khoản)

Đây chỉ là bước chứng minh **người đứng sau tài khoản là người thật** (CCCD + khuôn mặt). Làm **1 lần cho mỗi tài khoản**, ai muốn làm người bán ở bất kỳ module nào cũng phải qua bước này.

**Đăng ký kinh doanh thì riêng từng module, không dùng chung:** một người có thể vừa cho thuê trọ vừa bán quán ăn, nhưng
- muốn cho thuê trọ → đăng ký **nhà trọ** theo kiểu của module Tìm trọ (giấy tờ nhà, video khu trọ, video phòng… — mục 2.3), admin duyệt riêng;
- muốn bán quán → đăng ký **quán** theo kiểu của module Quán ăn (loại quán, mã số thuế, ảnh mặt tiền, menu… — mục 3.3), admin duyệt riêng.

Được duyệt bên này **không** có nghĩa được duyệt bên kia. Bị khóa nhà trọ không tự khóa quán, trừ khi admin kết luận **lừa đảo hoặc giấy tờ giả** (khi đó khóa cả tài khoản, mục 4.4).

**Các bước:**
1. Bấm "Đăng tin cho thuê" hoặc "Đăng ký quán" lần đầu.
2. Điền hồ sơ, xác thực số điện thoại bằng OTP.
3. Đọc và tick **đồng ý xử lý dữ liệu cá nhân**: app thu ảnh CCCD và **ảnh khuôn mặt (dữ liệu nhạy cảm)**, để xác minh người bán là người thật và chống lừa đảo, chỉ **admin danh tính** xem, **ảnh và video khuôn mặt xóa sau 30 ngày kể từ khi duyệt**, **số CCCD được lưu ở dạng mã hóa trong suốt thời gian tài khoản còn tồn tại** để chống đăng ký trùng và chặn gian lận. Cần đối chiếu Nghị định 13/2023/NĐ-CP và Luật Bảo vệ dữ liệu cá nhân hiện hành (cần kiểm tra lại).
4. **Chụp CCCD mặt trước và mặt sau** — chỉ chụp trong app, không chọn ảnh có sẵn. Nhập số CCCD.
5. **Kiểm tra người thật:** hệ thống cấp **thử thách ngẫu nhiên** (ví dụ "quay trái → chớp mắt → quay phải", thứ tự ngẫu nhiên, có hạn dùng), app quay khuôn mặt làm theo. Chống dùng ảnh in hoặc phát lại video cũ.
6. Tick **cam kết thông tin đúng sự thật** → Gửi.
7. **Admin danh tính duyệt:** so khuôn mặt với ảnh CCCD bằng mắt, kiểm tra số CCCD.

**Kết quả:**
- Đạt → huy hiệu **"Đã xác thực danh tính"**, được bắt đầu đăng ký nhà trọ hoặc quán ở module tương ứng. Phần này chỉ cung cấp cho admin các module **họ tên đã xác thực** và trạng thái xác thực (không có ảnh, không có số CCCD) để đối chiếu với giấy tờ kinh doanh.
- Không đạt → báo lý do, sửa và gửi lại.
- Trong lúc chờ duyệt: **được soạn nháp** nhà trọ / phòng / quán, **chưa gửi duyệt** được.

**Bảo vệ dữ liệu:**
- Ảnh CCCD và khuôn mặt nằm ở vùng lưu trữ riêng tư, chỉ admin danh tính mở được bằng link có thời hạn. **Mỗi lần admin mở ảnh đều được ghi nhật ký.**
- Ảnh CCCD, ảnh khuôn mặt và **video thử thách khuôn mặt** **tự xóa sau 30 ngày** kể từ khi duyệt (cùng lúc).
- **Số CCCD không lưu dạng chữ thường:** lưu bản băm (để tra trùng, tra danh sách chặn), bản mã hóa (để admin đối chiếu khi cần) và 4 số cuối (để hiển thị).

## 4.3 Kiểm tra CCCD giả

Không hệ thống nào phát hiện được 100% giấy tờ giả. App **không tin vào tấm ảnh giấy tờ**, mà **đối chiếu chéo**. Mục này chỉ nói về **CCCD**; giấy tờ kinh doanh do từng module tự kiểm tra: **giấy tờ nhà** ở mục 2.5j, **mã số thuế hộ kinh doanh** ở mục 3.5g.

|Giấy tờ|Đối chiếu với|Mức chắc chắn|
|---|---|---|
|**CCCD** (mục 4.2)|Số nhập vào khớp số in trên thẻ · khớp thông tin ngầm trong số (nơi đăng ký, giới tính, năm sinh) · khuôn mặt khớp ảnh · số không nằm trong danh sách bị chặn|Trung bình|

**Các lớp bảo vệ thêm:**
- CCCD **chỉ chụp trong app** → chặn ảnh đã chỉnh sửa bằng phần mềm.
- Người dùng báo cáo "giấy tờ sai sự thật" ở module nào thì admin module đó chuyển cho admin danh tính xét lại.
- Phát hiện giấy tờ giả (CCCD hoặc giấy tờ kinh doanh ở bất kỳ module nào) → **khóa cả tài khoản** (mục 4.4).
- Sau 30 ngày xóa ảnh CCCD **và video thử thách khuôn mặt**, nhưng vẫn giữ số CCCD (dạng băm / mã hóa) và kết quả đối chiếu làm bằng chứng. Ảnh đã xóa mà cần xét lại (ví dụ có báo cáo giấy tờ sai) → admin danh tính xét dựa trên **số CCCD và kết quả đối chiếu đã lưu**; thật sự cần xem lại hình thì **yêu cầu người dùng chụp lại** trong app. Không kéo dài thời gian lưu ảnh / dữ liệu khuôn mặt.

## 4.4 Khóa cả tài khoản

- Chỉ dùng khi: admin danh tính phát hiện CCCD giả (mục 4.3), hoặc admin của một module kết luận **lừa đảo** hoặc **giấy tờ kinh doanh giả** (giấy tờ nhà, mã số thuế) và đề nghị khóa.
- Admin module **đề nghị**, **admin danh tính** quyết. Khi khóa: **chặn số CCCD** và **chặn số điện thoại**, tài khoản không dùng được **module nào**, không đăng ký lại được.
- Mỗi module tự xử lý giao dịch đang chạy của mình theo mục 2.14 / 3.14 (Tìm trọ: hoàn khoản cọc đang giữ; Quán ăn: hoàn tiền, hủy bàn, hủy đơn…).
- **Kháng nghị khóa tài khoản / chặn CCCD:** gửi trong 7 ngày, tối đa 3 bằng chứng, 1 lần / quyết định, admin danh tính trả lời trong 48 giờ; đang kháng nghị thì vẫn bị khóa.
- Hình phạt thường (bỏ hẹn đặt bàn, bom hàng, khóa cọc trên app, khóa đặt món…) **không** làm khóa tài khoản và **không** ảnh hưởng module khác.

## 4.5 Các con số

|Quy định|Con số|
|---|---|
|OTP: số lần gửi · hiệu lực mã · nhập sai|Tối đa 5 lần / giờ / số · 5 phút · sai 5 lần → khóa 15 phút|
|Đăng nhập sai mật khẩu|5 lần → khóa 15 phút|
|Email xác nhận / quên mật khẩu|Tối đa 3 lần / giờ · link hiệu lực 24 giờ|
|Thử thách kiểm tra người thật|Hiệu lực 2 phút|
|Xóa ảnh CCCD, khuôn mặt sau khi duyệt|30 ngày|
|Mục tiêu duyệt danh tính|24 giờ|
|Kháng nghị khóa tài khoản|Gửi trong 7 ngày · trả lời trong 48 giờ · 1 lần · tối đa 3 bằng chứng|

## 4.6 Dữ liệu cần lưu

> Viết bằng lời. Chỉ gồm dữ liệu của tài khoản và xác nhận người thật; dữ liệu của từng module ở mục 2.17, 3.17.

|Nhóm dữ liệu|Cần lưu những gì|
|---|---|
|**Người dùng**|Email (đã xác nhận chưa) · mật khẩu (chỉ lưu dạng mã hóa một chiều) · lần đồng ý điều khoản (thời điểm, phiên bản) · họ tên, ảnh, giới thiệu · số điện thoại (đã OTP chưa, **không trùng** tài khoản khác) · vai trò: sinh viên / chủ trọ / chủ quán / admin danh tính / admin Tìm trọ / admin Quán ăn · email trường (huy hiệu "Email trường", đăng ký hoặc bổ sung sau) · trạng thái xác thực người thật · **họ tên đã xác thực** (cho admin module đối chiếu) · **số CCCD: không lưu dạng đọc được** — dạng băm (tra trùng, tra chặn), dạng mã hóa (admin đối chiếu) và 4 số cuối · khóa cả tài khoản (có / không, lý do, module đề nghị, admin danh tính quyết) · số lần đăng nhập sai · thời điểm xóa tài khoản|
|**Mã OTP**|Số điện thoại · mã (dạng băm) · hết hạn lúc · số lần nhập sai · số lần gửi trong giờ · khóa tới lúc|
|**Link email**|Loại (xác nhận / đặt lại mật khẩu) · mã (dạng băm) · hết hạn lúc · đã dùng chưa · số lần gửi trong giờ|
|**Thiết bị**|Tài khoản · mã nhận thông báo của thiết bị · lần đăng nhập gần nhất|
|**Hồ sơ xác nhận người thật**|Của ai · ảnh CCCD, khuôn mặt, **video thử thách khuôn mặt** (**vùng riêng tư**, xóa cùng lúc sau 30 ngày) · kết quả kiểm tra người thật · lần đồng ý xử lý dữ liệu, lần tick cam kết · kết quả đối chiếu · cờ cảnh báo · người duyệt, lúc duyệt, lý do từ chối · ngày xóa ảnh (duyệt + 30 ngày)|
|**Danh sách chặn**|CCCD bị chặn (dạng băm) · số điện thoại bị chặn · lý do, đề nghị từ module nào, ai chặn, lúc nào|
|**Kháng nghị khóa tài khoản**|Người gửi · lý do, bằng chứng · trạng thái · kết quả · ai xử lý|
|**Nhật ký admin danh tính**|Admin nào · làm gì (kể cả **mỗi lần mở ảnh CCCD**) · với ai · lúc nào|

## 4.7 Màn hình

|Mã|Màn hình|Ai dùng|
|---|---|---|
|TK-01|Đăng ký (đồng ý điều khoản) · đăng nhập · xác nhận email|Mọi người|
|TK-02|Quên mật khẩu · đặt lại mật khẩu · đổi mật khẩu|Mọi người|
|TK-03|Xác thực số điện thoại (OTP)|Đã đăng nhập|
|TK-04|Xác nhận người thật (đồng ý dữ liệu, chụp CCCD, kiểm tra người thật, trạng thái)|Người muốn làm chủ trọ / chủ quán|
|TK-05|Hồ sơ chung (bổ sung email trường) · xóa tài khoản · kháng nghị khóa tài khoản|Đã đăng nhập|
|TK-AD-01|Duyệt danh tính (xem ảnh có ghi nhật ký)|Admin danh tính|
|TK-AD-02|Khóa tài khoản · danh sách chặn CCCD / số điện thoại · kháng nghị khóa tài khoản|Admin danh tính|

Chụp CCCD, kiểm tra người thật chỉ có trên điện thoại; máy tính hiện "Vui lòng dùng app trên điện thoại".

Cây thư mục: `lib/features/auth/` (theo sườn chung của nhóm; người phụ trách: câu hỏi số 5 ở mục 5.2) — tài liệu này không đặc tả chi tiết.

## 4.8 Thứ tự làm

> Làm **trước** cả 2 module.

- [ ] TK-1 Đăng ký, đăng nhập, xác nhận email, quên / đổi mật khẩu, khóa đăng nhập tạm khi sai nhiều lần
- [ ] TK-2 OTP số điện thoại (OTP thử nghiệm khi demo), mỗi số 1 tài khoản, đổi số
- [ ] TK-3 Hồ sơ chung + email trường (đăng ký hoặc bổ sung sau) + huy hiệu "Email trường"
- [ ] TK-4 Xóa tài khoản: kiểm tra giao dịch đang chạy ở từng module, xóa / ẩn danh dữ liệu
- [ ] TK-5 Chụp CCCD trong app + nhập số + đồng ý xử lý dữ liệu cá nhân
- [ ] TK-6 Kiểm tra người thật (thử thách ngẫu nhiên, quay khuôn mặt)
- [ ] TK-7 Admin danh tính duyệt + bảo vệ số CCCD (băm, mã hóa, 4 số cuối) + tự xóa ảnh / video sau 30 ngày + nhật ký mở ảnh
- [ ] TK-8 Khóa cả tài khoản, danh sách chặn CCCD / số điện thoại, nhận đề nghị từ admin module
- [ ] TK-9 Kháng nghị khóa tài khoản
- [ ] TK-10 Kiểm thử theo mục 4.9

## 4.9 Tiêu chí nghiệm thu

**Tài khoản**
- [ ] 1 số điện thoại chỉ gắn được 1 tài khoản; số đã dùng báo lỗi rõ ràng.
- [ ] Gửi OTP quá 5 lần / giờ bị chặn; nhập sai 5 lần khóa 15 phút; mã quá 5 phút hết hiệu lực.
- [ ] Đăng nhập sai mật khẩu 5 lần khóa 15 phút. Đăng xuất xóa mã nhận thông báo của thiết bị đó.
- [ ] Quên mật khẩu: nhận link, đặt mật khẩu mới; link quá 24 giờ hoặc đã dùng thì không dùng lại được. Đổi mật khẩu trong trang cá nhân hoạt động.
- [ ] Chưa tick đồng ý điều khoản thì không đăng ký được.
- [ ] Gửi email xác nhận / quên mật khẩu quá 3 lần / giờ bị chặn.
- [ ] Chưa OTP: hành động mà module yêu cầu OTP bị chặn; app dẫn sang màn hình OTP rồi quay lại đúng chỗ.
- [ ] Xóa tài khoản bị chặn khi còn giao dịch đang chạy, tiền đang giữ, khiếu nại hoặc kháng nghị (mục 2.14, 3.14); khi được xóa, dữ liệu cá nhân bị xóa / ẩn danh.

**Xác nhận người thật**
- [ ] Màn hình chụp CCCD **không có** lựa chọn lấy từ thư viện.
- [ ] Kiểm tra người thật dùng thử thách ngẫu nhiên do hệ thống cấp; thử thách quá 2 phút bị từ chối.
- [ ] CCCD hoặc số điện thoại nằm trong danh sách chặn không đăng ký / xác thực lại được.
- [ ] Không nơi nào lưu số CCCD ở dạng đọc được: chỉ có dạng băm, dạng mã hóa và 4 số cuối (mục 4.2).
- [ ] Ảnh CCCD, khuôn mặt: người khác và chính người gửi sau khi gửi đều không mở được link; chỉ admin danh tính xem; mỗi lần mở đều ghi vào nhật ký admin danh tính.
- [ ] Ảnh CCCD, ảnh khuôn mặt và video thử thách bị xóa cùng lúc, 30 ngày sau khi duyệt. Sau đó xét lại chỉ dựa trên số CCCD + kết quả đối chiếu đã lưu, hoặc yêu cầu chụp lại.
- [ ] Đăng ký bằng email `.edu.vn`, hoặc bổ sung và xác nhận email `.edu.vn` sau khi đăng ký → có huy hiệu "Email trường"; email khác không có.
- [ ] Đổi số điện thoại phải OTP lại; số mới trùng tài khoản khác bị từ chối.
- [ ] Admin module chỉ gửi được đề nghị khóa; chỉ admin danh tính khóa được cả tài khoản.
- [ ] Khi được xóa tài khoản: ảnh CCCD / khuôn mặt / video thử thách xóa ngay; **bản mã hóa số CCCD bị xóa**, chỉ giữ bản băm nếu số đó nằm trong danh sách chặn; giao dịch và đánh giá giữ ở dạng ẩn danh.
- [ ] Một tài khoản đã xác nhận người thật: đăng ký nhà trọ và đăng ký quán **không phải** làm lại bước này, nhưng mỗi bên vẫn phải gửi hồ sơ kinh doanh và được duyệt riêng.

**Khóa tài khoản**
- [ ] Khóa cả tài khoản: không vào được module nào; CCCD và số điện thoại bị chặn, không đăng ký lại được.
- [ ] Bị khóa cọc trên app ở Tìm trọ vẫn đặt món ở Quán ăn bình thường (và ngược lại).
- [ ] Kháng nghị khóa tài khoản: gửi trong 7 ngày, 1 lần, tối đa 3 bằng chứng; đang kháng nghị vẫn bị khóa.

## 4.10 Hướng phát triển

|Tính năng|Mô tả|
|---|---|
|Xác thực tự động (eKYC)|Dùng dịch vụ eKYC được cấp phép: đọc CCCD, so khớp khuôn mặt, kiểm tra người thật tự động, thay cho admin duyệt bằng tay|
|Quét chip CCCD (NFC)|Đọc và xác minh chip CCCD, gần như không làm giả được|

## 4.11 Đánh giá phần chung

|Tiêu chí|Điểm|Nhận xét|
|---|---|---|
|Chống lừa đảo|⭐⭐⭐⭐|Xác nhận người thật, đối chiếu CCCD, chặn theo CCCD và số điện thoại|
|Dễ dùng|⭐⭐⭐⭐|Xác nhận nhiều bước nhưng chỉ làm 1 lần cho mọi module|
|Độ khó khi làm|Trung bình|Khó nhất: kiểm tra người thật, bảo vệ số CCCD|
|Khả năng làm xong|⭐⭐⭐|Chặn đầu cả dự án; kiểm tra người thật, OTP, bảo vệ số CCCD đều khó và còn phụ thuộc dịch vụ OTP, người phụ trách chưa chốt (mục 5.2)|

|Rủi ro|Cách giảm|
|---|---|
|Kiểm tra người thật bị phát lại video|Thử thách ngẫu nhiên do hệ thống cấp, có hạn dùng; admin vẫn so khuôn mặt bằng mắt|
|Một người dùng nhiều số điện thoại để lập nhiều tài khoản|1 số / 1 tài khoản; người bán phải xác nhận CCCD, CCCD chỉ gắn 1 tài khoản|

---

# PHẦN 5. KẾ HOẠCH, CÂU HỎI MỞ VÀ LỊCH SỬ THAY ĐỔI

## 5.1 Thứ tự làm tổng thể

**Cần chốt trước khi bắt đầu** (mục 5.2, phần "Nhóm tự quyết")
- [ ] Người phụ trách phần tài khoản và xác nhận người thật
- [ ] Dịch vụ gửi OTP SMS và email (tạm dùng OTP thử nghiệm)
- [ ] Tài khoản sandbox PayPal / MoMo cho từng module

|Thứ tự|Làm gì|Ở đâu|
|---|---|---|
|1|Tài khoản và xác nhận người thật|Mục 4.8|
|2|Module Tìm trọ (Giai đoạn 1 → 4)|Mục 2.22|
|2|Module Quán ăn (Giai đoạn 1 → 4) — **song song** với Tìm trọ|Mục 3.22|

Hai module **độc lập**: làm xong module nào thì chạy được module đó, không phải chờ module kia.

## 5.2 Câu hỏi đã chốt và việc nhóm tự quyết

**Đã chốt** (đặc tả viết theo kết quả này; đổi lại thì sửa các mục ở cột cuối):

|#|Câu hỏi|Đã chốt|Sửa ở đâu nếu đổi|
|---|---|---|---|
|1|Sinh viên bấm "Không thuê nữa" thì mất 100% cọc. Có hoàn một phần (ví dụ 50%) khi báo sớm, trước thời điểm nhận phòng ≥ 48 giờ?|✅ Không hoàn (ngoài 30 phút đầu)|2.5a, 2.5h, 2.16, 2.23|
|2|Ảnh bìa bắt buộc lấy từ video / ảnh mặt tiền chụp trong app: chủ trọ / chủ quán có thể thấy bất tiện vì không chọn được ảnh đẹp. Giữ hay nới?|✅ Giữ bắt buộc|1.3, 2.3, 3.3, 2.19, 3.19|
|3|Quán lưu động dời chỗ bán trong ngày: có đưa vào đồ án?|✅ Để sau (mục 3.24)|3.3, 3.17|
|7|Các con số mặc định có cần chỉnh theo thực tế? Khóa thanh toán 15 phút · thời điểm nhận phòng 2 giờ – 14 ngày · hủy cọc miễn phí 30 phút, 2 lần / 30 ngày · yêu cầu thay đổi (> 24 giờ trước, chủ trả lời 24 giờ) · phản đối "không đến" 12 giờ · nhắc cuối 24 giờ, tự hoàn tất 48 giờ · vi phạm chủ trọ 3 lần / 90 ngày · quán chậm +30 phút · giao 60 phút · tự hoàn tất đơn 24 giờ sau bằng chứng giao / nhận · quá 6 giờ không bằng chứng → gắn cờ admin · ân hạn "không đến" 3 giờ · hẹn giờ đặt món 30 phút – 2 giờ · giữ tiền "khách không nhận" 24 giờ · trần cọc 1 tháng · kháng nghị 7 ngày / 48 giờ|✅ Giữ như bảng 2.16, 3.16 (đổi qua file cấu hình)|2.16, 3.16|
|8|Tự hoàn tất sau **48 giờ** kể từ thời điểm nhận phòng: đủ để sinh viên báo vấn đề, hay nên dài hơn (ví dụ 72 giờ)?|✅ 48 giờ (nhắc cuối lúc 24 giờ)|2.4, 2.5h, 2.16|

**Nhóm tự quyết** (không đổi luật của app):

|#|Việc|Hiện tại|Sửa ở đâu|
|---|---|---|---|
|4|Dịch vụ gửi OTP SMS và email|Chưa chốt; demo dùng OTP thử nghiệm (số test, mã cố định)|4.1|
|5|Ai phụ trách phần tài khoản và xác nhận người thật?|Chưa chốt|5.1, 4.7|
|6a|Tìm trọ: có cắt giao diện máy tính, lưu ❤️ (Mức 2)?|Làm đủ|2.22, 2.24|
|6b|Quán ăn: có cắt Mức 1 (đặt món) / Mức 2 (combo, giờ vàng)?|Làm đủ|3.22, 3.24|
|9|Pháp lý: lưu số CCCD lâu dài, dữ liệu khuôn mặt, mã số thuế cá nhân trùng số định danh, quy định hộ kinh doanh và bán hàng rong, giữ tiền hộ khi chuyển sang tiền thật|Ghi chú "(cần kiểm tra lại)"|4.1, 4.2, 4.3, 2.5j, 3.2, 3.5g, 2.24, 3.24|

## 5.3 Các chỗ cần kiểm tra lại với tài liệu

|Mục|Nội dung cần đối chiếu|
|---|---|
|4.1|Ẩn danh hóa dữ liệu khi xóa tài khoản, giữ bản ghi giao dịch|
|4.2|Lưu số CCCD và ảnh khuôn mặt — Nghị định 13/2023/NĐ-CP, Luật Bảo vệ dữ liệu cá nhân|
|3.5g|Từ 01/07/2025 mã số thuế cá nhân, hộ kinh doanh dùng số định danh cá nhân|
|2.3, 3.3, 2.25, 3.25|Thư viện định vị Flutter có báo được vị trí giả lập (Android) không|
|2.6, 3.6|PayPal không hỗ trợ VND, cách quy đổi USD; hoàn một phần (chỉ Quán ăn)|
|2.2, 2.5a, 2.5h|**Thuật ngữ "đặt cọc" (CHƯA CHỐT):** kiểm tra quy định pháp luật Việt Nam về đặt cọc, đặc biệt **Điều 328 Bộ luật Dân sự 2015** và trường hợp "các bên có thỏa thuận khác"; xác định cơ chế "chủ trọ hủy → hoàn 100%, không phạt thêm" có phù hợp không; cân nhắc tiếp tục gọi là "đặt cọc" hay dùng thuật ngữ khác như "tiền giữ chỗ". Tài liệu **chưa đưa ra kết luận pháp lý** nào về điểm này|
|3.2|Trường hợp bán hàng rong, lưu động không bắt buộc đăng ký hộ kinh doanh|
|2.19, 3.19, 4.7|Thư viện camera, nhận diện khuôn mặt, thông báo đẩy, Google Maps có chạy trên Windows không (pub.dev)|

## 5.4 Lịch sử thay đổi

|Phiên bản|Nội dung chính|
|---|---|
|3.16|Cây thư mục khớp sườn chung của nhóm: mỗi module chỉ đúng 4 thư mục con (config → `models/`, routes → `screens/`, theme → `widgets/`) · chat, đánh giá riêng từng module, từ `shared/` chỉ dùng `User` · được dùng `core/utils`, `core/services` · Phần 4 ở `features/auth/`|
|3.15|Tìm trọ: ghi rõ **ngoại lệ có chủ đích** khi chủ trọ bị kết luận lừa đảo — khoản cọc app còn giữ, chưa xác nhận nhận phòng → hoàn 100%; khoản đã hoàn tất / đã xác minh nhận phòng không bị đảo ngược|
|3.14|Quán ăn: quán bị kết luận **lừa đảo không tự hoàn mọi đơn** — admin rà soát từng đơn theo bằng chứng (đã hoàn tất: không đổi · đang chờ xác nhận có bằng chứng: giữ tiền, admin xét · chưa có bằng chứng: theo trạng thái thực tế) · nút **"Chưa nhận được món" của đơn đến lấy chỉ mở từ thời điểm nhận món dự kiến**|
|3.13|Chốt 6 mâu thuẫn: đơn tiền mặt giao tận nơi có ảnh GPS vẫn phải qua **24 giờ** phản đối mới hoàn tất và có nhãn 🛵 · nhãn 🍽 **chỉ khi sinh viên check-in** (quán bấm "Khách đã đến" chỉ để quản lý bàn) · **admin kết luận đã giao → đơn đã xác minh** (nhãn 🛵) · tự hoàn tất 48 giờ ở Tìm trọ không nhãn, không tính điểm · đơn đến lấy có nút **"Chưa nhận được món" ngay từ "Sẵn sàng"** (6 giờ chỉ là dự phòng) · **khóa bán không tự hoàn** các đơn đã phát sinh|
|3.12|Sửa theo bảng đánh giá: Quán ăn bắt buộc **bằng chứng giao / nhận** (mã nhận món 4 số khi đến lấy, ảnh GPS khi giao; cả đơn tiền mặt), hạn phản đối 24 giờ, quá 6 giờ không bằng chứng → gắn cờ admin (không tự hoàn / không tự giải ngân) · Tìm trọ: **ân hạn 3 giờ** trước khi chủ báo "không đến", **"Yêu cầu thay đổi thời điểm nhận phòng"** (sớm hơn hoặc muộn hơn), cọc trực tiếp không được miễn hết hạn tin · nhãn xác minh chỉ khi chính sinh viên xác nhận (tự hoàn tất 48 giờ không có nhãn "✔ Đã thuê") · đúng / trễ hạn thanh toán xét theo giờ cổng ghi nhận · **bỏ tự ẩn theo số báo cáo** (chỉ gắn cờ ưu tiên) · ghi chú pháp lý thuật ngữ "đặt cọc" (chưa chốt) · sửa nhiều lỗi nhất quán (email trường, dữ liệu CCCD, từ khóa chat, xóa phòng, múi giờ UTC+7, tách task Phần 4)|
|3.11|Quán ăn: thêm bộ lọc **ăn tại quán, mang đi, điểm đánh giá**; "Đặt món qua app" đổi tên thành "Giao hàng (đặt qua app)" · đánh giá có cấu trúc **4 tiêu chí bắt buộc** (món ăn, giá cả, vệ sinh, phục vụ — bỏ "Không gian"), điểm tổng tự tính, trang quán hiện điểm từng tiêu chí|
|3.10|Tìm trọ: thêm **nội quy nhà trọ** 4 tiêu chí (giờ giấc ra vào, nuôi thú cưng, ở qua đêm, báo trước khi trả phòng) bắt buộc khi đăng, **bộ lọc theo nội quy**; nội quy lưu vào bản chụp lúc cọc; chỉ tính vi phạm khi **nội quy đã sai ngay tại thời điểm giao dịch / nhận phòng** (chủ đổi nội quy sau đó không tính): tiền còn giữ → khiếu nại (có thể hoàn 100%), đã hoàn tất → báo cáo (không hoàn tiền, ghi vi phạm chủ), không giới hạn thời gian báo cáo. Chuyển từ hướng phát triển vào làm luôn|
|3.9|Tìm trọ: **bỏ hoàn toàn lịch xem** (đặt lịch, giữ chỗ, "Tôi đã tới nơi", "Tôi muốn thuê", hàng chờ, no-show, công tắc cọc từ xa) · nguyên tắc **"chưa cọc thì chưa giữ phòng — ai cọc hợp lệ trước thì giữ"** · cọc chọn **thời điểm nhận phòng** (ngày + giờ, 2 giờ – 14 ngày), lưu bản chụp thông tin phòng · **chỉ sinh viên xin dời** (1 lần, > 24 giờ trước, chủ trả lời 24 giờ, quá hạn hoàn 100%) · nhận phòng: sinh viên "Đã nhận phòng" / "Chủ trọ không thực hiện đúng cam kết", chủ "Sinh viên không đến nhận phòng" + 12 giờ phản đối, nhắc cuối 24 giờ, tự hoàn tất 48 giờ · cọc trực tiếp do chủ trọ xác nhận · vi phạm chủ trọ 3 lần / 90 ngày|
|3.8|Mỗi module là **mini app độc lập**: thanh toán, chat, đánh giá, báo cáo, thông báo, kháng nghị, admin, dữ liệu, giao diện, thư mục code **riêng**; chỉ chung **tài khoản + xác nhận người thật** (Phần 4); đăng ký nhà trọ / quán duyệt riêng; lừa đảo thì khóa cả tài khoản|
|3.7|Tách rõ **2 module riêng biệt**: Tìm trọ (Phần 2) và Quán ăn (Phần 3), mỗi module tự đủ luồng, luật, dữ liệu, màn hình, cây thư mục, thứ tự làm, nghiệm thu, hướng phát triển, đánh giá; phần dùng chung tách riêng (Phần 4); ghi rõ các module khác do thành viên khác làm|
|3.6|Viết lại thành đặc tả nghiệp vụ, bỏ phần kỹ thuật (database, API, server); dữ liệu viết bằng lời; rà soát toàn file|
|3.5|Lịch xem chỉ giữ phòng từ giờ hẹn − 60 phút · "Tôi muốn thuê" 4 giờ · tách cọc trên app và cọc trực tiếp · hủy cọc miễn phí 30 phút, 2 lần / 30 ngày · đơn hẹn giờ, chốt giá · tự hoàn tất đơn sau 6 giờ · tách đơn tiền mặt · nhãn đánh giá quán mới|
|3.4|Sửa theo bản đánh giá: khóa thanh toán phòng, tiền đến muộn tự hoàn, cửa sổ xử lý khi dọn vào, ẩn / khóa khi còn giao dịch, kháng nghị|
|≤ 3.3|Gộp 1 file, thêm Quán ăn, đặt món, thanh toán, giao diện, cây thư mục, bảng đánh giá|
