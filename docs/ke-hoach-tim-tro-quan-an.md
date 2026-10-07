# Kế hoạch triển khai Tìm trọ và Quán ăn

Đặc tả gốc: [`dac-ta-tim-tro-quan-an.md`](dac-ta-tim-tro-quan-an.md) (v3.16). Người phụ trách: Thái Hữu Tài.

## Các quyết định đã chốt
1. **Thứ tự:** làm xong **Tìm trọ** (4 giai đoạn, mục 2.22) rồi mới sang **Quán ăn**; Quán ăn dùng lại khung đã làm.
2. **Thanh toán / giữ tiền cọc:** làm bằng **cổng thanh toán giả lập** chạy trên Cloud Functions (đủ luồng cọc, giữ tiền, hoàn tiền, hết hạn). Sau này thay bằng PayPal / MoMo sandbox mà không phải sửa luồng. Không để khóa bí mật trong repo (repo public).
3. **Camera / GPS / xác thực CCCD + khuôn mặt:** làm sau (cần máy Android thật). Giai đoạn đầu cho đăng video bằng link / tải lên; xác thực người thật do admin duyệt tay trong Firebase, không lưu ảnh CCCD thật.
4. **Bản đồ:** OpenStreetMap (`flutter_map`) vì Google Maps Platform không bán cho tài khoản thanh toán tại Việt Nam; đặc tả mục 2.19 cho phép phương án này.
5. **Giao diện:** mỗi module có theme riêng (`widgets/tro_theme.dart`), mở bằng `troRoute` trong `screens/tro_routes.dart`.

## Tiến độ Tìm trọ (mục 2.22)
- [x] TR-1.1 Giao diện riêng của module (màu, chữ, nút, huy hiệu, khung xương / rỗng / lỗi)
- [ ] TR-1.2 Tải ảnh / video lên
- [ ] TR-1.3 Điểm gốc + bản đồ
- [ ] TR-1.4 Tự xử lý hạn + chặn thao tác đồng thời
- [ ] TR-1.5 Thông báo
- [ ] TR-1.6 Bộ đếm vi phạm
- [ ] TR-1.7 Thanh toán giả lập + giữ tiền
- [ ] Giai đoạn 2 (xem và đăng), 3 (cọc và nhận phòng), 4 (tương tác, hoàn thiện)

## Khác biệt so với bản đầu của app
- `phong_tro` phẳng hiện có sẽ được thay bằng `nha_tro` + `phong` (+ `dat_coc`, …) theo mục 2.17 ở Giai đoạn 2. Dữ liệu hiện có chỉ là dữ liệu thử.
