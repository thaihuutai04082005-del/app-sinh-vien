# Quy ước làm việc nhóm

Để khi gộp code các thành viên khớp nhau, **mọi người bám đúng `docs/mo-hinh-app-sinh-vien.md` (mục 7)**.

## Chia việc
Mỗi người nhận 1 module, chỉ làm trong thư mục của module đó:
`lib/features/<module>/{models,screens,widgets,services}`

| Module | Thư mục |
|---|---|
| Đăng nhập/tài khoản | `features/auth` |
| Tìm trọ | `features/tro` |
| Quán ăn | `features/quan_an` |
| Xe dọn trọ | `features/xe_don_tro` |
| Shop quần áo | `features/shop` |
| Vui chơi | `features/vui_choi` |

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
