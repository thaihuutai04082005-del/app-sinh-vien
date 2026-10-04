# Server Dùng vercel kết hợp API
Vercel không trực tiếp chạy hay đóng gói (build) ứng dụng di động (file .apk cho Android hay .ipa cho iOS). Tuy nhiên, Vercel đóng vai trò cực kỳ quan trọng trong mô hình kiến trúc ứng dụng di động hiện đại.Dưới đây là ý tưởng cốt lõi và kiến trúc thực tế khi dùng Vercel để xây dựng một ứng dụng mobile hoàn chỉnh:Mô hình Kiến trúc Cốt lõi (Core Architecture)
```text
┌────────────────────────┐         REST / GraphQL API        ┌────────────────────────────────┐
│   Mobile App (Client)  │  ───────────────────────────────> │      Vercel (Serverless)       │
│                        │                                   │  - Backend Node.js / Express   │
│  - Flutter             │ <───────────────────────────────  │  - Edge / Serverless Functions │
│  - React Native        │          Dữ liệu JSON             └────────────────────────────────┘
│  - Swift / Kotlin      │                                                   │
└────────────────────────┘                                                   │ Kết nối DB
                                                                             ▼
                                                                  ┌─────────────────────┐
                                                                  │   Database Cloud    │
                                                                  │  - MongoDB Atlas    │
                                                                  │  - Supabase / Postgres│
                                                                  └─────────────────────┘
```

3 Vai trò Cốt lõi của Vercel khi làm App Mobile1. Đóng vai trò là Server Backend (Serverless Backend)Ý tưởng: Thay vì phải thuê máy chủ VPS (như Nginx, Ubuntu Server) tốn chi phí và mất công quản lý, bạn viết Backend bằng Node.js / Express (hoặc Next.js API Routes).Cách hoạt động: Đưa code Backend lên Vercel. Vercel biến các đoạn code của bạn thành Serverless Functions.Ưu điểm: Mỗi khi Mobile App gửi yêu cầu (request), Vercel mới kích hoạt server chạy để xử lý và tự động tắt đi khi xong, giúp xử lý hàng triệu request mà không lo sập server.2. Nơi xử lý và lưu trữ dữ liệu tập trung (Data Gateway)Ý tưởng: Mobile App cần đăng nhập, lưu danh sách sinh viên, đăng bài viết... Mobile App sẽ gửi request tới domain Vercel cấp (ví dụ: [https://my-app-api.vercel.app/api/login](https://my-app-api.vercel.app/api/login)).Cách hoạt động: Vercel nhận yêu cầu $\rightarrow$ Xử lý logic $\rightarrow$ Truy vấn vào Database (như MongoDB Atlas, Supabase, hoặc PostgreSQL) $\rightarrow$ Trả kết quả JSON về lại cho Mobile App hiển thị.3. Cung cấp Web Dashboard / Trang quản trị (Admin Panel)Ý tưởng: Hầu hết app mobile đều cần 1 trang web CMS cho người quản trị (Admin) để quản lý người dùng, xem thống kê, duyệt bài...Cách hoạt động: Bạn build trang Web Admin (bằng React, Next.js, Vue...) và deploy thẳng lên Vercel. Trang Web Admin và Mobile App sẽ dùng chung nguồn dữ liệu API trên Vercel.Tóm tắt Ưu điểm khi chọn Vercel làm Backend cho Mobile AppMiễn phí & Tiết kiệm: Gói Hobby miễn phí đáp ứng đủ cho dự án sinh viên, đồ án tốt nghiệp hoặc ứng dụng khởi nghiệp giai đoạn đầu.Auto-Scaling (Tự động mở rộng): Không cần cấu hình load balancer hay hạ tầng phức tạp.Tốc độ triển khai cực nhanh: Mỗi lần bạn git push code Backend lên GitHub, Vercel tự động cập nhật API mới chỉ sau vài giây.Bảo mật: Dễ dàng quản lý biến môi trường (MONGO_URI, JWT_SECRET, API_KEY...) an toàn trên đám mây.
