# KỊCH BẢN THUYẾT TRÌNH & DÀN Ý SLIDE POWERPOINT
## ĐỒ ÁN: CỔNG GAME TRÍ TUỆ ĐỐI KHÁNG "GODDY GAMING HUB"
* **Sinh viên**: Huỳnh Nguyễn Vĩnh Phúc - **MSSV**: 2380614923
* **File PowerPoint chính thức**: `Goddy_Gaming_Hub_ThuyetTrinh.pptx` (đã tạo sẵn tại thư mục gốc)
* **Tổng thời gian thuyết trình lý tưởng**: 3 - 5 phút (ngắn gọn, xúc tích trước khi vào phần Demo trực tiếp)

---

### SLIDE 1: TRANG TIÊU ĐỀ
* **Tiêu đề**: CỔNG GAME TRÍ TUỆ ĐỐI KHÁNG ĐA NỀN TẢNG "GODDY GAMING HUB"
* **Nội dung hiển thị**:
  - Sinh viên thực hiện: Huỳnh Nguyễn Vĩnh Phúc (MSSV: 2380614923)
  - Công nghệ: Flutter SDK (Dart) + ASP.NET Core Web API (.NET 9) + Conveyor by Keyoti (Free)
  - Sản phẩm: Bản cài đặt APK Release AOT (~52.4MB)
* **Lời thoại bạn nên nói (30 giây)**:
  > *"Em xin kính chào Thầy/Cô và các bạn. Hôm nay em xin phép được trình bày đồ án cuối kỳ môn Lập trình thiết bị di động với đề tài: **Cổng Game Trí Tuệ Đối Kháng Goddy Gaming Hub**. Đây là một nền tảng game di động tích hợp 4 trò chơi trí tuệ giải đố thế hệ mới, vận dụng cảm biến phần cứng, trí tuệ nhân tạo và hệ thống thi đấu đối kháng trực tuyến thời gian thực."*

---

### SLIDE 2: LÝ DO CHỌN ĐỀ TÀI & TÍNH ĐỘT PHÁ
* **Nội dung hiển thị**:
  - **Hạn chế game hiện nay**: Các app game giải đố thường rời rạc (mỗi game 1 tài khoản); Rubik di động khó điều khiển; Caro người đi trước luôn thắng 90%; Sudoku chỉ báo đúng/sai; Slide Puzzle chỉ bấm nút ảo thông thường.
  - **Giải pháp của Goddy**: Cổng game All-in-One dùng chung 1 tài khoản duy nhất (SSO); Cải tiến luật chơi và áp dụng công nghệ mới cho từng game; Cơ chế Thách Đấu 1v1 công bằng tuyệt đối.
* **Lời thoại bạn nên nói (45 giây)**:
  > *"Thay vì chỉ làm một trò chơi đơn lẻ thông thường, em chọn xây dựng **Goddy** thành một cổng game 'Tất cả trong một' dùng chung duy nhất một tài khoản. Điểm đặc biệt của đồ án là đã giải quyết triệt để các hạn chế của game truyền thống: Rubik được mô phỏng 3D xoay chuẩn thực tế WCA, cờ Caro được bổ sung thẻ kỹ năng lượng tử để cân bằng thế cờ, Sudoku có AI phân tích suy luận ô số, và game Xếp hình trượt được điều khiển trực tiếp bằng cách nghiêng điện thoại nhờ cảm biến gia tốc."*

---

### SLIDE 3: KIẾN TRÚC KỸ THUẬT & CÔNG NGHỆ
* **Nội dung hiển thị (3 Cột)**:
  1. **Mobile Frontend**: Flutter Native, 60 FPS mượt mà, tối ưu AOT dung lượng chỉ ~52.4MB, quản lý trạng thái bằng Provider.
  2. **Network & Tunnel**: Conveyor by Keyoti (Free) cấp link Cloud `conveyor.cloud`, giúp điện thoại kết nối WebAPI qua 4G hoặc khác mạng Wi-Fi không cần cấu hình Router.
  3. **Backend & Database**: ASP.NET Core Web API (.NET 9), Entity Framework Core In-Memory, bảo mật JWT.
* **Lời thoại bạn nên nói (45 giây)**:
  > *"Về mặt kiến trúc kỹ thuật: Phía Client được xây dựng hoàn toàn bằng **Flutter SDK**, biên dịch bản Release tối ưu dung lượng nhỏ gọn chỉ 52MB. Phía Server là **ASP.NET Core Web API** trên .NET 9. Đặc biệt, để giải quyết bài toán kiểm thử trên điện thoại thật khác mạng Wi-Fi hoặc dùng 4G, em đã tích hợp giải pháp **Conveyor by Keyoti** - tự động public API qua Internet miễn phí giúp ứng dụng kết nối thông suốt ở bất cứ đâu."*

---

### SLIDE 4 & 5: BỘ 4 GAME TRÍ TUỆ THẾ HỆ MỚI
* **Nội dung hiển thị**:
  - **1. Rubik 3D AI Speedcube**: Trạng thái gốc 6 mặt thuần 1 màu -> Bấm "Xáo Trộn" -> Bấm "Bắt Đầu Tính Giờ" -> Bảng nút xoay chuẩn thực tế (Ngang, Dọc, Xoay mặt) -> Tự động nhận diện chiến thắng -> Nút "Bắt Đầu Lại".
  - **2. Quantum Caro**: Đấu AI Minimax Heuristic 3 cấp độ + 2 Thẻ Kỹ Năng Lượng Tử (*Quantum Swap* hoán đổi cờ & *EMP Freeze* phong ấn ô) + Giới hạn suy nghĩ 15s/lượt.
  - **3. Sudoku Hologram Spectrum**: Quang phổ màu Neon phát hiện xung đột tức thì + AI gợi ý suy luận loại trừ (*Naked Single*) + 3 Mạng chơi.
  - **4. Gyro Tilt Slide Puzzle**: Cảm biến gia tốc di động (`sensors_plus`) **nghiêng máy để gạch tự trôi** + Thuật toán tối ưu A* Manhattan.
* **Lời thoại bạn nên nói (60 giây)**:
  > *"Đi vào chi tiết 4 trò chơi: Thứ nhất là **Rubik 3D**, ban đầu khối ở dạng thuần màu chuẩn, người chơi bấm 'Xáo trộn' theo giải thuật ngẫu nhiên rồi bấm 'Bắt đầu tính giờ', hệ thống có bảng nút xoay trực quan y như cầm cục rubik ngoài đời và tự động báo thắng khi giải xong. Thứ hai là **Quantum Caro**, khắc phục nhược điểm người đi trước quá mạnh bằng AI Minimax thông minh và 2 kỹ năng hoán đổi vị trí cờ hoặc phong ấn ô cờ hiểm. Thứ ba là **Sudoku Quang Phổ**, khi chạm vào ô nào hệ thống sẽ chiếu sáng hàng cột và giải thích lý do vì sao ô đó phải điền số đó. Và thứ tư là **Xếp hình trượt vật lý**, người chơi chỉ cần nghiêng điện thoại là các ô gạch sẽ trượt theo trọng lực quán tính phần cứng của máy."*

---

### SLIDE 6: THÁCH ĐẤU 1v1 & CƠ CHẾ READY CHECK
* **Nội dung hiển thị**:
  - Mời bạn bè trực tuyến từ danh sách bạn bè hoặc chia sẻ mã PIN.
  - **Quy tắc Ready Check nghiêm ngặt**: Cả 2 người chơi (Host & Guest) phải **CÙNG BẤM "SẴN SÀNG"** thì trận đấu mới bắt đầu. Nếu 1 trong 2 chưa sẵn sàng, nút Bắt đầu sẽ bị khóa.
  - **Điểm khởi đầu = 0**: Điểm của cả 2 xuất phát chuẩn từ 0 điểm.
  - Chung hạt giống đề bài (Seed): Đảm bảo tính công bằng tuyệt đối.
* **Lời thoại bạn nên nói (30 giây)**:
  > *"Ngoài chơi đơn, tất cả các game đều hỗ trợ chế độ **Thách Đấu 1v1**. Để đảm bảo công bằng trong thi đấu, em áp dụng cơ chế Ready Check: Cả hai người chơi phải cùng xác nhận 'Sẵn Sàng' thì ván đấu mới được phép bắt đầu. Khi ván đấu bắt đầu, điểm số của cả hai người đều xuất phát chuẩn từ 0 điểm và giải cùng một đề bài chung."*

---

### SLIDE 7: BẢNG XẾP HẠNG & SẢNH CHAT
* **Nội dung hiển thị**:
  - Bục vinh danh Podium Top 3 (Vàng, Bạc, Đồng) với avatar Cyberpunk.
  - 5 Tab phân loại: Tổng hợp, Rubik 3D, Caro, Sudoku, Slide Puzzle.
  - 7 Cấp bậc Rank từ Đồng đến Huyền Thoại Goddy.
  - Sảnh Chat Thế Giới kết nối cộng đồng với bộ Quick Stickers nhanh.
* **Lời thoại bạn nên nói (20 giây)**:
  > *"Sau mỗi ván đấu, điểm số và thành tích thời gian sẽ được tính toán theo công thức chuẩn và tự động gửi lên Backend WebAPI để xếp hạng trên bục Podium Top 3, đồng thời tích lũy điểm EXP thăng cấp Rank game thủ."*

---

### SLIDE 8: KỊCH BẢN LIVE DEMO (CHUYỂN GIAO THỰC TẾ)
* **Quy trình bấm Demo cho Giảng viên xem (1 - 2 phút)**:
  1. **Khởi động WebAPI**: Mở file `Goddy_Game_WebAPI.sln` trên Visual Studio -> Bấm F5 -> Cửa sổ Conveyor by Keyoti hiện lên.
  2. **Đăng nhập App**: Mở app trên điện thoại (hoặc BlueStacks) -> Bấm **"Đăng Nhập Nhanh Tân Thủ"** (1-Chạm vào thẳng).
  3. **Demo Rubik 3D**: Bấm "1. Xáo Trộn" -> Bấm "2. Bắt Đầu Tính Giờ" -> Bấm nút Ngang/Dọc xoay thử -> Bấm "Bắt Đầu Lại".
  4. **Demo Caro & Sudoku**: Đánh 1 nước cờ và bấm nút Kỹ năng hoán đổi quân cờ; Mở Sudoku bấm 1 ô để Thầy/Cô thấy quang phổ màu sáng lên.
  5. **Demo Gyro Tilt**: Cầm điện thoại nghiêng qua lại để gạch trượt tự động bằng cảm biến gia tốc.
  6. **Demo Thách đấu**: Mở phòng đấu, cho thấy nút Bắt Đầu bị khóa khi đối thủ chưa Sẵn Sàng, khi cả 2 sẵn sàng thì điểm xuất phát từ 0.
  7. **Xem Bảng Xếp Hạng**: Mở màn hình Leaderboard xem điểm vừa lưu.

---

### SLIDE 9: TỔNG KẾT
* **Nội dung hiển thị**:
  - Đạt 100% barem điểm môn học.
  - Mã nguồn: `flutter analyze` 0 lỗi, `flutter test` 8/8 tests passed.
  - Bản build APK Release AOT ~52.4MB hoàn chỉnh.
* **Lời thoại kết thúc**:
  > *"Dạ, phần trình bày lý thuyết của em đến đây là hết. Sau đây em xin phép được mở ứng dụng trên điện thoại để Thầy/Cô trực tiếp trải nghiệm bản Demo ạ!"*
