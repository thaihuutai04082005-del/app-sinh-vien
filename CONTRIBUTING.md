# Quy ước làm việc nhóm

Để khi gộp code các thành viên khớp nhau, **mọi người bám đúng `docs/mo-hinh-app-sinh-vien.md` (mục 7)**.

## Chia việc
Mỗi người nhận 1 module, chỉ làm trong thư mục của module đó:
`lib/features/<module>/{models,screens,widgets,services}`

| Module (mục trong file mô hình) | Thư mục | Phụ trách |
|---|---|---|
| Khung chung: đăng nhập, hồ sơ, điều hướng, `core/`, `shared/` | `features/auth`, `features/home` | Thái Hữu Tài |
| 3.1 Tìm trọ | `features/tro` | Thái Hữu Tài |
| 3.2 Quán ăn | `features/quan_an` | Thái Hữu Tài |
| 3.3 Xe dọn trọ | `features/xe_don_tro` | Trần Chí Hướng |
| 3.4 Shop quần áo giá rẻ | `features/shop` | Trần Chí Hướng |
| 3.5 Điểm vui chơi | `features/vui_choi` | Thành (PThanhSinhVieen) |

Upload ảnh/video, hạn mức chống spam và `firestore.rules` / `storage.rules` do Trần Chí Hướng viết;
khung chung và quy tắc `users`, `phong_tro` do Thái Hữu Tài. Cần sửa phần của người khác thì báo người đó trước.

## Quy tắc để không xung đột
1. **Không import code của module khác.** Cần dùng chung thì đưa vào `lib/shared/` hoặc `lib/core/` (và báo cả nhóm).
2. **Tên collection** lấy từ `Collections` trong `lib/core/constants/app_constants.dart`; **tên field** khớp 100% mục 7.3 (tiếng Anh, camelCase).
3. Màn hình danh sách phải có đủ loading / rỗng / lỗi (dùng `lib/core/widgets/async_state_view.dart`).
4. Giá tiền lưu dạng number; hiển thị bằng `formatPrice()`.
5. Ảnh upload Firebase Storage, chỉ lưu URL vào Firestore.
6. Không sửa `core/`, `shared/`, `main.dart`, `home_screen.dart` mà không báo nhóm — đây là chỗ dễ conflict nhất.

## Git
- Nhánh chung: `develop`. Mỗi người làm nhánh riêng `feature/<module>-<tên>`, tạo Pull Request vào `develop`.
- Trước khi tạo PR chạy: `flutter analyze && flutter test`.

## Firebase
- Project dùng chung: `app-sinh-vien-b6ea4` (thêm thành viên ở Project settings → Users and permissions).
- Quy tắc bảo mật nằm ở `firestore.rules` và `storage.rules`. Sau khi sửa phải deploy thì mới có hiệu lực:
  ```
  firebase login
  firebase deploy --only firestore:rules --project app-sinh-vien-b6ea4
  ```
- Collection mới phải được khai báo trong `firestore.rules`, nếu không sẽ bị chặn (mặc định từ chối tất cả).
- Upload ảnh/video dùng Firebase Storage; bật Storage yêu cầu gói Blaze của Firebase.
- Hạn mức chống spam: tối đa 10 tin và 30 ảnh/video mỗi ngày cho mỗi tài khoản (`DailyQuota`, khớp với rules).
