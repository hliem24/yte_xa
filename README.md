<h2 align="center">
    <a href="https://dainam.edu.vn/vi/khoa-cong-nghe-thong-tin">
    🎓 Faculty of Information Technology (DaiNam University)
    </a>
</h2>

<h2 align="center">
   ỨNG DỤNG QUẢN LÝ KHO Y TẾ XÃ (WMS_YTE_XA_AI)
</h2>

<div align="center">
    <p align="center">
        <img src="docs/aiotlab_logo.png" alt="AIoTLab Logo" width="170"/>
        <img src="docs/fitdnu_logo.png" alt="FIT DNU Logo" width="180"/>
        <img src="docs/dnu_logo.png" alt="DaiNam University Logo" width="200"/>
    </p>

[![AIoTLab](https://img.shields.io/badge/AIoTLab-green?style=for-the-badge)](https://www.facebook.com/DNUAIoTLab)
[![Faculty of Information Technology](https://img.shields.io/badge/Faculty%20of%20Information%20Technology-blue?style=for-the-badge)](https://dainam.edu.vn/vi/khoa-cong-nghe-thong-tin)
[![DaiNam University](https://img.shields.io/badge/DaiNam%20University-orange?style=for-the-badge)](https://dainam.edu.vn)

</div>

---

## 📘 1. Giới thiệu hệ thống

**WMS_YTE_XA_AI** là ứng dụng di động quản lý kho thuốc & vật tư y tế tại các **trạm y tế xã**, được xây dựng bằng **Flutter (Material 3, Riverpod)**.  
Ứng dụng cho phép cán bộ y tế, nhân viên và quản trị viên theo dõi, nhập – xuất – tồn kho **trực quan, chính xác và có tích hợp AI hỗ trợ thông minh**.

### ⚙️ Thành phần hệ thống

- **Người dùng (Staff/Admin):**
  - Đăng nhập, đăng xuất bằng tài khoản phân quyền.
  - Nhân viên gửi yêu cầu nhập kho; quản trị viên duyệt và ghi nhận.
  - Thực hiện xuất kho có lý do cụ thể, theo quy định.
  - Xem tồn kho hiện tại, thống kê thuốc sắp hết hạn, thuốc tồn thấp.

- **AI Trợ lý thông minh (AI Agent):**
  - Phân tích dữ liệu kho và trả lời truy vấn như:
    - “Tổng tồn kho hiện tại là bao nhiêu?”
    - “Nhập 10 hộp PARA500”
    - “Cho tôi xem thuốc sắp hết hạn”
  - Tích hợp mô hình **Ollama Llama3.2** qua gateway nội bộ (http://10.0.2.2:11434).
  - Có thể trả lời **câu hỏi y tế thường gặp** (ví dụ: “bị cúm nên uống thuốc gì?”) một cách tự nhiên, nhưng **không thay thế tư vấn y tế**.

- **Lưu trữ cục bộ:**
  - `SharedPreferences` lưu dữ liệu JSON:
    - Danh mục thuốc (`medicines`)
    - Lịch sử nhập xuất (`movements`)
    - Phiếu yêu cầu (`requests`)
    - Người dùng đăng nhập (`user`)
  - Dữ liệu được nạp lại khi khởi động ứng dụng, đảm bảo **offline-first**.

---

## 🧩 2. Công nghệ sử dụng

| Thành phần | Công nghệ |
|-------------|------------|
| **Ngôn ngữ** | Dart |
| **Framework** | Flutter (Material 3) |
| **State Management** | Riverpod |
| **Local Storage** | SharedPreferences |
| **AI Integration** | OpenAI / Ollama local gateway |
| **Architecture** | MVVM (Models – State – Features – Widgets) |
| **Giao diện** | Material 3, dark/light theme tự động |

---

## 🚀 3. Các chức năng chính

1. **Đăng nhập / Đăng xuất**
   - Hỗ trợ phân quyền **Admin** và **Nhân viên**.
   - Dữ liệu người dùng lưu trong Local Storage.

2. **Quản lý kho**
   - Hiển thị danh mục thuốc & vật tư (tên, hạn dùng, đơn vị, số lượng tồn).
   - Cho phép **nhập kho** (admin trực tiếp nhập) hoặc **gửi yêu cầu nhập** (staff gửi để admin duyệt).
   - Cho phép **xuất kho** với lý do rõ ràng.
   - Tự động tính toán số lượng tồn, hiển thị cảnh báo:
     - “Sắp hết hạn (≤30 ngày)”
     - “Tồn thấp (<20 đơn vị)”

3. **Phiếu yêu cầu nhập**
   - Nhân viên gửi yêu cầu nhập kho (số lượng, ghi chú).
   - Quản trị viên duyệt / từ chối phiếu.

4. **Lịch sử nhập/xuất**
   - Ghi lại toàn bộ giao dịch (ngày giờ, loại, lý do).
   - Hiển thị theo dạng thẻ (Card) với biểu tượng mũi tên màu:
     - 🟢 **Nhập kho**
     - 🔴 **Xuất kho**

5. **Trợ lý AI**
   - Trả lời bằng ngôn ngữ tự nhiên tiếng Việt.
   - Phân tích hành động WMS (stockInRequest, stockOut, quickReport...).
   - Cập nhật dữ liệu **realtime** theo hành động.
   - Nhận biết và tách biệt:
     - Câu hỏi y tế (trả lời tự nhiên).
     - Câu lệnh kho (thực thi hành động).

---

## 🧠 4. Giao diện ứng dụng

<p align="center">
  <img src="docs/project photo/1..jpg" width="400"/>
</p>
<p align="center"><em>Đăng nhập hệ thống kho</em></p>

<p align="center">
  <img src="docs/project photo/2..jpg" width="400"/>
</p>
<p align="center"><em>Tổng quan tồn kho & thống kê</em></p>

<p align="center">
  <img src="docs/project photo/3..jpg" width="400"/>
</p>
<p align="center"><em>Giao diện kho: nhập/xuất và phiếu chờ duyệt</em></p>

<p align="center">
  <img src="docs/project photo/4..jpg" width="400"/>
</p>
<p align="center"><em>Nhân viên gửi yêu cầu nhập kho</em></p>

<p align="center">
  <img src="docs/project photo/5...jpg" width="400"/>
</p>
<p align="center"><em>Lịch sử nhập/xuất thuốc & vật tư</em></p>

---

## ⚙️ 5. Hướng dẫn cài đặt và chạy ứng dụng

### 🔧 Yêu cầu hệ thống

- **Flutter SDK:** >= 3.22  
- **Dart SDK:** >= 3.3  
- **Thiết bị:** Android 8+ / iOS 14+  
- **Dung lượng:** ~50MB  
- **Kết nối:** Có thể hoạt động offline, AI yêu cầu mạng nội bộ khi bật Ollama.

---

## 📦 Cài đặt

### 🔧 Yêu cầu hệ thống
- **Flutter SDK:** Phiên bản 3.22 trở lên  
- **Dart SDK:** Phiên bản 3.3 trở lên  
- **Thiết bị:** Android 8+ / iOS 14+  
- **Dung lượng:** ~50MB  
- **Mạng:** Có thể hoạt động offline; nếu dùng AI thì cần kết nối mạng nội bộ hoặc Internet để client và server giao tiếp qua TCP (ví dụ với Ollama Gateway)

---

### ⚙️ Các bước cài đặt và chạy ứng dụng

1. **Clone mã nguồn:**
   ```bash
   git clone https://github.com/yourname/wms_yte_xa_ai.git
   cd wms_yte_xa_ai
2. **Cài dependency:**
   ```bash
   flutter pub get
3. **Chạy ứng dụng (debug mode):**
   ```bash
   flutter run
1. **Build APK (phiên bản phát hành):**
   ```bash
   flutter build apk --release

## 💬 6. Hướng dẫn sử dụng

### 🔑 Đăng nhập
Ứng dụng có sẵn hai loại tài khoản:

| Vai trò | Tên đăng nhập | Mật khẩu | Quyền hạn |
|----------|----------------|-----------|------------|
| **Admin** | `admin` | `123456` | Nhập kho trực tiếp, duyệt yêu cầu nhân viên, xem toàn bộ lịch sử kho. |
| **Nhân viên** | `ytx` | `123456` | Gửi yêu cầu nhập kho, xuất kho có lý do, xem thống kê và báo cáo tồn kho. |

---

### 🏠 Tổng quan
Sau khi đăng nhập, người dùng được chuyển đến **màn hình tổng quan**, tại đây hiển thị:

- Danh mục thuốc & vật tư y tế trong kho.  
- Tổng số lượng tồn (hiển thị rõ theo đơn vị).  
- Danh sách **thuốc sắp hết hạn (≤ 30 ngày)** và **thuốc tồn thấp (< 20 đơn vị)**.  
- Nút **“Xem tất cả”** để mở danh sách đầy đủ.

---

### 📦 Nhập kho / Xuất kho

#### 🔹 Admin:
- Có thể **nhập kho trực tiếp** bằng cách chọn thuốc, nhập số lượng và nhấn **“Nhập kho”**.  
- Có thể **duyệt hoặc từ chối yêu cầu nhập** từ nhân viên (trong mục “Phiếu yêu cầu nhập”).  

#### 🔹 Nhân viên:
- Gửi **phiếu yêu cầu nhập kho**, ghi chú rõ ràng lý do hoặc ghi chú kèm theo.  
- Thực hiện **xuất kho** phải điền “Lý do xuất” trước khi xác nhận.  
- Tất cả thao tác đều được lưu lại trong phần **“Lịch sử nhập/xuất”**.

---

### 🤖 AI Trợ lý
AI tích hợp trong hệ thống giúp tự động hóa thao tác và trả lời thông minh:

- **Truy vấn báo cáo kho:**
  - “Cho tôi xem tổng kho.”
  - “Thuốc nào sắp hết hạn?”
  - “Nhập 10 PARA500.”

- **Hỏi đáp y tế thông thường:**
  - “Bị cảm cúm nên uống thuốc gì?”
  - “Thuốc hạ sốt dùng thế nào?”

> ⚠️ *Lưu ý:* AI không thay thế tư vấn y tế. Các câu trả lời về sức khỏe chỉ mang tính tham khảo.

---

### 📁 Lưu trữ và đồng bộ
- Dữ liệu kho (thuốc, phiếu, lịch sử, người dùng) được lưu cục bộ bằng `SharedPreferences`.
- Khi khởi động ứng dụng, dữ liệu sẽ tự động được tải lại.
- Các thao tác AI liên quan đến kho sẽ **đồng bộ tức thời** vào hệ thống.

---


## 👜Thông tin cá nhân
**Họ tên**: Nguyễn Hoàng Liêm.  
**Lớp**: CNTT 16-03.  
**Email**: liemnguyenhoang22@gmail.com.

© 2025 AIoTLab, Faculty of Information Technology, DaiNam University. All rights reserved.

---