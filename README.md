<div align="center">
  <h3>
    🇻🇳 Tiếng Việt | <a href="README_EN.md">🇺🇸 English</a>
  </h3>
</div>

<div align="center">
  <img src="assets/images/logo.png" alt="appCarParking Logo" width="120"/>
  <h1>appCarParking</h1>
  <p><strong>Hệ Sinh Thái Quản Lý Bãi Đỗ Xe Thông Minh (Mobile & Web)</strong></p>
  
  <p>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white" alt="Flutter"></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=flat&logo=dart&logoColor=white" alt="Dart"></a>
    <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=white" alt="Firebase"></a>
    <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white" alt="Supabase"></a>
    <a href="#"><img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20Web-lightgrey" alt="Platform"></a>
  </p>
</div>

---

## 📖 Tổng Quan

**appCarParking** là một hệ sinh thái toàn diện được thiết kế để giải quyết bài toán quản lý và tìm kiếm bãi đỗ xe. Được xây dựng bằng Flutter, dự án cung cấp ứng dụng di động cho khách hàng (Customer), nhân viên bảo vệ (Guard) và hệ thống quản trị trên nền web (Web Admin). Kiến trúc module hóa giúp hệ thống dễ dàng mở rộng, bảo trì và triển khai.

## ✨ Tính Năng Hệ Thống

Hệ thống được chia thành 3 phân hệ chính:

### 1. Phân hệ Khách hàng (Customer App)
- **📍 Bản đồ & Tìm kiếm:** Tích hợp OpenStreetMap giúp tìm kiếm bãi đỗ xe xung quanh theo thời gian thực.
- **📅 Đặt chỗ (Booking):** Cho phép đặt trước vị trí đỗ xe, quản lý lịch sử đặt chỗ.
- **⭐ Yêu thích:** Lưu lại các bãi đỗ xe thường xuyên sử dụng.
- **🗺️ Điều hướng:** Hỗ trợ chỉ đường đến bãi đỗ xe đã chọn.

### 2. Phân hệ Bảo vệ (Guard App)
- **🔍 Quét mã QR:** Quét mã QR booking của khách hàng để check-in/check-out nhanh chóng.
- **📋 Quản lý lịch sử:** Xem lịch sử xe ra vào bãi.
- **📊 Thống kê tức thời:** Theo dõi số lượng xe đang có trong bãi.

### 3. Phân hệ Quản trị (Web Admin)
- **📈 Dashboard:** Cung cấp cái nhìn tổng quan về doanh thu, số lượng người dùng và lượt đặt chỗ.
- **🏢 Quản lý Bãi đỗ & Chủ bãi:** Thêm, sửa, xóa thông tin bãi đỗ xe và chủ sở hữu.
- **👥 Quản lý Người dùng & Đặt chỗ:** Quản lý danh sách khách hàng và các giao dịch đặt chỗ.
- **💰 Quản lý Doanh thu:** Thống kê và báo cáo doanh thu chi tiết.
- **🚗 Mô phỏng Giao thông (Simulation):** Tính năng mô phỏng luồng giao thông và hoạt động của bãi đỗ xe.

## 🛠️ Công Nghệ Sử Dụng

*   **Frontend & Mobile:** Flutter (Dart)
*   **State Management:** BLoC & GetX
*   **Backend & Cơ sở dữ liệu:** Supabase (PostgreSQL), Firebase
*   **Bản đồ:** OpenStreetMap, Flutter Map

## 📂 Kiến Trúc & Cấu Trúc Thư Mục

Dự án áp dụng kiến trúc Feature-Driven, phân chia rõ ràng các module cho từng đối tượng người dùng:

```text
lib/
 ├── core/              # Các cấu hình cốt lõi: Theme, constants, biến môi trường (env)
 ├── features/          # Các chức năng chính của ứng dụng
 │   ├── auth/          # Xử lý xác thực người dùng (Login, Register)
 │   ├── customer/      # Phân hệ khách hàng (Account, Booking, Home, Map)
 │   ├── guard/         # Phân hệ bảo vệ (History, Home, Scanner)
 │   └── web_admin/     # Phân hệ quản trị web (Dashboard, Parking, Revenue, Simulation...)
 ├── model/             # Định nghĩa cấu trúc dữ liệu (Booking, ParkingLot, User...)
 ├── routes/            # Quản lý điều hướng (Routing)
 ├── services/          # Tầng giao tiếp với Backend (SupabaseService)
 └── main.dart          # Điểm khởi chạy của ứng dụng
```

## 📸 Ảnh Chụp Màn Hình

<div align="center">
  <img src="assets/screenshots/image1.jpg" width="200"/>
  <img src="assets/screenshots/image2.jpg" width="200"/>
  <img src="assets/screenshots/image3.jpg" width="200"/>
  <img src="assets/screenshots/image4.jpg" width="200"/>
  <img src="assets/screenshots/image6.png" width="200"/>
  <img src="assets/screenshots/image7.png" width="200"/>
  <img src="assets/screenshots/image8.png" width="200"/>
  <img src="assets/screenshots/image9.png" width="200"/>
  <img src="assets/screenshots/image10.png" width="200"/>
  <img src="assets/screenshots/image11.png" width="200"/>
  <img src="assets/screenshots/image12.png" width="200"/>
  <img src="assets/screenshots/image13.png" width="200"/>
  <img src="assets/screenshots/image14.png" width="200"/>
</div>

## 🎥 Video Demo

<div align="center">
  <a href="https://youtu.be/a_uk1ptQd1U">
    <img src="https://img.youtube.com/vi/a_uk1ptQd1U/maxresdefault.jpg" alt="Video Demo" width="600"/>
  </a>
</div>

## 🚀 Hướng Dẫn Cài Đặt

Thực hiện các bước sau để thiết lập môi trường phát triển và chạy thử dự án.

### Yêu Cầu Hệ Thống

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản stable mới nhất)
*   Android Studio / Xcode / VS Code
*   Cấu hình Supabase & Firebase CLI

### Các Bước Cài Đặt

1.  **Clone mã nguồn**
    ```bash
    git clone https://github.com/XkingzX/appCarParking.git
    cd appCarParking
    ```

2.  **Cài đặt các gói phụ thuộc (Dependencies)**
    ```bash
    flutter pub get
    ```

3.  **Thiết Lập Môi Trường**
    *   Tạo file `.env` tại thư mục gốc và cấu hình các key của Supabase.
    *   (Nếu dùng Firebase) Cấu hình file `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) cho Firebase.

4.  **Khởi chạy ứng dụng**
    *   Cho Mobile (Android/iOS):
        ```bash
        flutter run
        ```
    *   Cho Web Admin:
        ```bash
        flutter run -d chrome
        ```

## 🔮 Cải Tiến Trong Tương Lai

- [ ] Tích hợp AI để dự đoán tỷ lệ trống của bãi đỗ xe.
- [ ] Triển khai cổng thanh toán trực tuyến (Stripe/PayPal/VNPay).
- [ ] Tích hợp tính năng nhận diện biển số thông minh (ALPR) qua Camera.
- [ ] Tích hợp hệ thống phần cứng IoT (Cảm biến nhận diện xe, thanh chắn Barrier tự động, v.v.).
- [ ] Mở rộng đa ngôn ngữ (Localization) cho nhiều quốc gia khác.

## 🤝 Đóng Góp Ý Kiến

Mọi đóng góp, báo cáo lỗi (issues), và đề xuất tính năng đều được chào đón. Vui lòng tham khảo [issues page](https://github.com/XkingzX/appCarParking/issues) trước khi tiến hành đóng góp.

## 👤 Tác Giả: **Ngô Tiến Tới**

- 💼 LinkedIn: [Ngô Tiến Tới](https://www.linkedin.com/in/ngotientoi/)
- 🐙 GitHub: [@Xk1ngzX](https://github.com/XkingzX)
- ✉️ Email: ngotientoi21@gmail.com

---
<div align="center">
  <sub>Phát triển bằng cả trái tim, mong người xem sẽ thích nó ❤️.</sub>
</div>
