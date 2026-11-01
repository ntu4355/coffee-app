# VIDEO DEMO
video demo là file: VideoDemo.docx

# coffee_app

A new Flutter project.

## QDT Coffee App

## Getting Started

### Ứng dụng đặt cà phê di động

This project is a starting point for a Flutter application.
QDT Coffee App là một ứng dụng di động được xây dựng bằng Flutter, cho phép người dùng duyệt qua các sản phẩm cà phê, đặt hàng, quản lý hồ sơ và tương tác với hệ thống quản lý đơn hàng. Ứng dụng cũng bao gồm một bảng điều khiển quản trị (Admin Panel) để quản lý sản phẩm, người dùng và đơn hàng.

A few resources to get you started if this is your first Flutter project:

## Tính năng chính

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
- **Xác thực người dùng**: Đăng ký, đăng nhập, đăng xuất.
- **Duyệt sản phẩm**: Xem danh sách sản phẩm theo danh mục, tìm kiếm sản phẩm.
- **Chi tiết sản phẩm**: Xem thông tin chi tiết của từng sản phẩm và đặt hàng.
- **Ví tiền**: Quản lý số dư ví .
- **Hồ sơ người dùng**: Xem và chỉnh sửa thông tin cá nhân.
- **Admin Panel**:
  - Quản lý sản phẩm (thêm, sửa, xóa).
  - Quản lý người dùng (xem, xóa).
  - Quản lý đơn hàng (xem tất cả đơn hàng, cập nhật trạng thái).

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Công nghệ sử dụng

- **Flutter**: Framework UI để xây dựng ứng dụng di động đa nền tảng.
- **Firebase**:
  - **Firestore**: Cơ sở dữ liệu NoSQL để lưu trữ dữ liệu sản phẩm, người dùng, đơn hàng.
  - **Authentication**: Quản lý xác thực người dùng (email/password).
  - **Storage**: Lưu trữ hình ảnh sản phẩm (nếu có).

## Bắt đầu

Để chạy dự án này trên máy cục bộ của bạn, hãy làm theo các bước sau:

### Yêu cầu

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (phiên bản 3.x trở lên)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Một tài khoản Firebase và một dự án Firebase đã được tạo.

### Cài đặt

1.  **Clone repository:**

    ```bash
    git clone <URL_CỦA_REPOSITORY_CỦA_BẠN>
    cd coffee_app
    ```

2.  **Cài đặt các dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Thiết lập Firebase:**
    - Đảm bảo bạn đã cài đặt Firebase CLI và đăng nhập: `firebase login`
    - Cấu hình dự án Flutter với Firebase:
      ```bash
      flutterfire configure
      ```
      Lệnh này sẽ tạo file `lib/firebase_options.dart` cần thiết cho ứng dụng của bạn.
    - Thiết lập các quy tắc bảo mật cho Firestore và Storage (tham khảo tài liệu Firebase).

4.  **Chạy ứng dụng:**
    ```bash
    flutter run
    ```

## Cấu trúc dự án

- `lib/`: Mã nguồn chính của ứng dụng.
  - `admin/`: Các trang và logic cho bảng điều khiển quản trị.
  - `model/`: Các mô hình dữ liệu (ví dụ: `ProductModel`, `UserModel`).
  - `pages/`: Các trang giao diện người dùng chính.
  - `service/`: Các dịch vụ tương tác với Firebase và các logic nghiệp vụ khác.

## Đóng góp

Các đóng góp được hoan nghênh! Vui lòng tạo một pull request hoặc mở một issue nếu bạn có bất kỳ đề xuất hoặc tìm thấy lỗi nào.

## Giấy phép

Dự án này được cấp phép theo Giấy phép MIT. Xem file `LICENSE` để biết thêm chi tiết.
