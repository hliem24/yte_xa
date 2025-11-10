<h2 align="center">
    <a href="https://dainam.edu.vn/vi/khoa-cong-nghe-thong-tin">
    🎓 Faculty of Information Technology (DaiNam University)
    </a>
</h2>
<h2 align="center">
   ỨNG DỤNG TRẮC NHIỆM TRỰC TUYẾN 
</h2>
<div align="center">
    <p align="center">
        <img src="docs/aiotlab_logo.png" alt="AIoTLab Logo" width="170"/>
        <img src="docs/fitdnu_logo.png" alt="AIoTLab Logo" width="180"/>
        <img src="docs/dnu_logo.png" alt="DaiNam University Logo" width="200"/>
    </p>

[![AIoTLab](https://img.shields.io/badge/AIoTLab-green?style=for-the-badge)](https://www.facebook.com/DNUAIoTLab)
[![Faculty of Information Technology](https://img.shields.io/badge/Faculty%20of%20Information%20Technology-blue?style=for-the-badge)](https://dainam.edu.vn/vi/khoa-cong-nghe-thong-tin)
[![DaiNam University](https://img.shields.io/badge/DaiNam%20University-orange?style=for-the-badge)](https://dainam.edu.vn)

</div>

/*
## 📖 1. Giới thiệu hệ thống
Ứng dụng **trắc nghiệm Client–Server** sử dụng **TCP** cho phép nhiều người dùng làm bài trắc nghiệm qua mạng theo thời gian thực.

- **Server**: trung tâm xác thực tài khoản, cung cấp danh mục bộ đề, phát câu hỏi, chấm điểm và lưu kết quả.
- **Client (Java Swing)**: giao diện để **đăng ký/đăng nhập**, **chọn bộ đề**, **làm bài** (đồng hồ đếm ngược, thanh tiến độ, điều hướng Trước/Tiếp/Nộp), xem **tổng kết** và **lịch sử**.
- **Lưu trữ dạng tệp** (không dùng DB) để triển khai đơn giản:
  - `users.csv`: tài khoản (username, password_hash SHA-256, created_at).
  - `questions/<type>/<set>.csv` + `<set>.cfg`: ngân hàng câu hỏi & thời lượng đề.
  - `results.csv`: lịch sử kết quả thi (điểm, thời gian, bộ đề, IP…).

**Các chức năng chính:**
1) **Kết nối & xác thực**: Client kết nối Server qua IP/port (mặc định **5555**). Hỗ trợ nhiều Client đồng thời (đa luồng). Pha AUTH với 2 chế độ: `LOGIN` / `REGISTER` (mật khẩu băm SHA-256 trước khi gửi).
2) **Chọn bộ đề**: Server gửi **catalog** (Loại → Bộ đề). Client chọn loại/bộ đề qua hộp thoại “card style”.
3) **Phát câu hỏi & làm bài**: Server gửi lần lượt đối tượng `Question`. Client chọn đáp án **0..3** (A..D) rồi gửi về; Server trả kết quả **đúng/sai** theo thời gian thực. Thời lượng **đếm ngược toàn bài** lấy từ tệp `.cfg` (ví dụ `seconds=600`).
4) **Nộp bài / Hết giờ**: Người dùng có thể nộp sớm; hết giờ hệ thống tự nộp phần còn lại. Server trả `RESULT|username|correct/total` và ghi một dòng vào `results.csv`.
5) **Xem kết quả**: Client có trình xem `results.csv` (bảng lịch sử), giao diện đồng nhất với ứng dụng.

---

## 🔧 2. Công nghệ sử dụng

#### Java Core & Multithreading
#### Java Swing
#### Java Sockets
#### Hỗ trợ
- `MessageDigest` (SHA-256) để băm mật khẩu phía Client trước khi gửi.
- `SimpleDateFormat`/`LocalDateTime` để đóng dấu thời gian.
- `Collections`/`ArrayList` quản lý danh mục bộ đề, lịch sử câu hỏi/đáp án phía Client.

*/


## 🚀 3. Hình ảnh các chức năng

<p align="center">
  <img src="docs/project photo/1..png" alt="Ảnh 1" width="800"/>
</p>

<p align="center">
  <em>Giao diện khi vào ứng dụng  </em>
</p>

<p align="center">
  <img src="docs/project photo/2..png" alt="Ảnh 2" width="700"/>
</p>
<p align="center">
  <em>Client đăng nhập </em>
</p>


<p align="center">
  <img src="docs/project photo/3..png" alt="Ảnh 3" width="500"/>
 
</p>
<p align="center">
  <em> Client đăng ký </em>
</p>

<p align="center">
    <img src="docs/project photo/4..png" alt="Ảnh 4" width="450"/>
</p>
<p align="center">
  <em> Giao diện sau khi đăng nhập </em>
</p>
<p align="center">
    <img src="docs/project photo/5...png" alt="Ảnh 4" width="450"/>
</p>
<p align="center">
  <em> Client lịch sử làm bài  </em>
</p>
<p align="center">
    <img src="docs/project photo/6..png" alt="Ảnh 4" width="450"/>
</p>
<p align="center">
  <em> Client chọn bộ đề   </em>
</p>
<p align="center">
    <img src="docs/project photo/7..png" alt="Ảnh 4" width="450"/>
</p>
<p align="center">
  <em> Giao diện khi bắt đầu làm   </em>
</p>
<p align="center">
    <img src="docs/project photo/8..png" alt="Ảnh 4" width="450"/>
</p>
<p align="center">
  <em> Giao diện khi hoàn thành xong bài   </em>
</p>

## 📝 4. Hướng dẫn cài đặt và sử dụng

### 🔧 Yêu cầu hệ thống

- **Java Development Kit (JDK)**: Phiên bản 8 trở lên
- **Hệ điều hành**: Windows, macOS, hoặc Linux
- **Môi trường phát triển**: IDE (IntelliJ IDEA, Eclipse, VS Code) hoặc terminal/command prompt
- **Bộ nhớ**: Tối thiểu 512MB RAM
- **Dung lượng**: Khoảng 10MB cho mã nguồn và file thực thi
- **Mạng**: Yêu cầu kết nối mạng nội bộ hoặc Internet để client và server giao tiếp qua TCP

### 📦 Cài đặt và triển khai

#### Bước 1: Chuẩn bị môi trường

1. **Kiểm tra Java**: Mở terminal/command prompt và chạy:

   ```bash
   java -version
   javac -version
   ```
   Đảm bảo cả hai lệnh đều hiển thị phiên bản Java 8 trở lên.

2. **Tải mã nguồn**: Sao chép thư mục `UngDungTracNghiem_TCP` chứa các file:
   - `QuizServer.java`
   - `QuizClientSwing.java`
   - `Question.java`
   - `ResultsViewerSwing.java`

#### Bước 2: Biên dịch mã nguồn

1. **Mở terminal** và điều hướng đến thư mục chứa mã nguồn
2. **Biên dịch các file Java**:

   ```bash
   javac quiz/*.java
   ```
   Hoặc biên dịch từng file riêng lẻ:
   ```bash
    javac quiz/QuizServer.java
    javac quiz/QuizClientSwing.java
    javac quiz/Question.java
    javac quiz/ResultsViewerSwing.java
   ```

3. **Kiểm tra kết quả**: Nếu biên dịch thành công, sẽ tạo ra các file `.class` tương ứng.

#### Bước 3: Chạy ứng dụng

**Khởi động Server:**
```bash
java QuizServer.java
```
- Server sẽ khởi động trên port mặc định (5555)
- Console sẽ hiển thị log khi có client kết nối.
- Server sẽ tạo (nếu chưa có) file results.csv để lưu kết quả làm bài.

**Khởi động Client:**
```bash
java QuizClientSwing.java
```
- Mỗi client được mở trong một terminal/ứng dụng riêng.
- Nhập Host, Port và Username trên giao diện Swing.
- Client kết nối đến server và bắt đầu nhận câu hỏi trắc nghiệm.
- Sau khi hoàn thành, điểm số và kết quả sẽ được hiển thị ngay trên giao diện.
- Người dùng có thể chọn 📄 Xem kết quả để mở bảng thống kê kết quả từ file results.csv.

### 🚀 Sử dụng ứng dụng

1. **Kết nối**: Nhập Host, Port và Tên người dùng → bấm Kết nối để tham gia thi.
2. **Làm bài**: Chọn đáp án cho từng câu hỏi và nhấn Next/Finish.
3. **Phản hồi**: Sau mỗi câu, giao diện hiển thị kết quả đúng/sai và tiến độ.
4. **Kết quả cuối cùng**: Khi hoàn thành, client hiển thị điểm số và thống kê.
5. **Lưu trữ**: Server tự động lưu kết quả vào file results.csv.
6. **Xem lại**: Người dùng có thể nhấn 📄 Xem kết quả để mở bảng thống kê từ file.
7. **Ngắt kết nối**: Đóng cửa sổ client hoặc mất mạng sẽ tự động ngắt kết nối.

## 👜Thông tin cá nhân
**Họ tên**: Nguyễn Hoàng Liêm.  
**Lớp**: CNTT 16-03.  
**Email**: liemnguyenhoang22@gmail.com.

© 2025 AIoTLab, Faculty of Information Technology, DaiNam University. All rights reserved.

---