# Nhật ký review giao diện (P05) – phần dịch vụ và quản trị

| Mục | Nội dung |
| --- | --- |
| Người review | Nguyễn Hoàng Thiên Phúc (Data 3) |
| Người được review | Lê Thanh Truyền (UI 2) |
| Tài liệu được review | `UI2_Nhom28_HoanChinh.docx`: UI05, UI06, UI07, UI08, UI11, UI12, UI13 (kèm hộp thoại UI05-D1, UI08-D1, UI11-D1, UI13-D1) |
| Đối chiếu với | `sql/services-security-v3.sql` (59/59 ca PASS), `docs/*.md`, ERD |
| Ngày | 12/11/2026 (soạn nháp; đổi thành ngày ký khi reviewer xác nhận) |
| Phạm vi và giới hạn | Chỉ đối chiếu tài liệu mô tả (bảng đối tượng, biến cố, lỗi, bảng mã lỗi). Chưa kiểm tra bản vẽ Figma, prototype hoặc ứng dụng đang chạy |

## 1. Kết luận

Thiết kế giao diện **khớp với SQL ở mọi quy tắc nghiệp vụ chính**. Có 2 điểm cần Truyền sửa (F1, F2), 3 điểm cần nhóm quyết định (F3–F5) và 1 điểm phụ thuộc Hoàng (F6). Không phát hiện chỗ nào làm giao diện cho phép thao tác trái QĐ3, QĐ4 hoặc cấp sai quyền.

## 2. Các điểm đã khớp

| # | Nội dung | Giao diện | SQL |
| --- | --- | --- | --- |
| 1 | Phân quyền theo nhóm (Bảng 3.3, 3.4) | 11 quyền, 4 nhóm | Giống hệt `role-permission-matrix.md` |
| 2 | UI08: xem khác với giao | Xem: TRA_CUU (5); giao: XAC_NHAN_GIAO (6); NV kho chỉ xem | `sp_XacNhanGiaoDong` yêu cầu quyền 6 |
| 3 | Công thức QĐ3 | Đơn giá tính, thành tiền, còn lại | Cùng công thức, có CHECK ở bảng |
| 4 | So sánh trả trước tối thiểu | `Trả trước × 100 ≥ Thành tiền × Tỷ lệ`, không làm tròn khi so sánh | `sp_LapPhieuDichVu` so sánh y hệt |
| 5 | Mức tối thiểu hiển thị | Làm tròn lên (L05) | `CEILING` trong thông báo 50009 |
| 6 | Nhiều dòng cùng loại dịch vụ | UI05 cho phép, mỗi dòng độc lập | Khóa `(so_phieu, stt)` |
| 7 | Q03 phương án A | UI08 chỉ kiểm tra số tiền thu bằng phần còn lại, không lưu cột riêng | `tra_truoc = thanh_tien`, `con_lai = 0` |
| 8 | Ngày giao là ngày hẹn (G13) | UI05 `dtpNgayGiao` = ngày hẹn giao | `ngay_giao` giữ nguyên khi giao |
| 9 | Chống xác nhận lần 2 | L40 | Lỗi 50013 |
| 10 | Tên đăng nhập (G08) | 3–50 ký tự, chữ không dấu, số, `.`, `_` | `sp_ThemTaiKhoan` lỗi 50026 |
| 11 | Mật khẩu (G09) | 6–50 ký tự, băm bcrypt ở lớp nghiệp vụ | SQL chỉ nhận chuỗi băm (50027 nếu rỗng) |
| 12 | Không tự khóa mình | L58 | Lỗi 50016 |
| 13 | Quản trị viên cuối cùng | L50 | Lỗi 50017 |
| 14 | Không bỏ quyền quản trị khỏi nhóm của chính mình (G11) | L64 | Lỗi 50029 (`sp_SuaNhom`) |
| 15 | Xóa nhóm còn người dùng | L65 | Lỗi 50018 |
| 16 | Tỷ lệ trả trước 0–100 | L74 | Lỗi 50021 |
| 17 | Quy tắc E2 khi đổi đơn vị tính | L76: loại còn tồn hoặc đã có chứng từ thì chặn | Khớp `uc10-rule-matrix.md` (tạm theo đề xuất, chờ Hoàng) |

## 3. Các điểm cần xử lý

| Mã | Mức | Phát hiện | Đề nghị | Người xử lý |
| --- | --- | --- | --- | --- |
| F1 | Cao | **Bảng 3.46 thiếu bốn mã của v3**: 50026, 50027, 50028, 50029. Bảng hiện dừng ở 50025 (viết theo v2), dù UI11 và UI12 đã dùng L52, L53, L56, L64 | Thêm 4 dòng: 50026 → L52 (UI11); 50027 → L56 (UI11); 50028 → L53 (UI11); 50029 → L64 (UI12) | Truyền |
| F2 | Vừa | Mã 50020 (nhóm không tồn tại) chỉ ánh xạ sang L66 (UI12), nhưng `sp_ThemTaiKhoan` và `sp_SuaTaiKhoan` cũng trả 50020 ở UI11 khi nhóm đã bị xóa giữa chừng | Thêm ánh xạ 50020 cho UI11, ví dụ dùng thông báo "Nhóm người dùng đã chọn không còn tồn tại, vui lòng chọn lại" | Truyền |
| F3 | Thấp | UI06, UI07, bộ lọc UI11 và cột đếm UI12 cần truy vấn danh sách. SQL chưa có thủ tục cho các truy vấn này | Chọn một: (a) tầng dữ liệu viết truy vấn theo bảng đặc tả trong `service-schema.md` mục 3 (đề xuất, vì đã có chỉ mục); (b) yêu cầu Phúc viết thủ tục | Nhóm (H04) |
| F4 | Thấp | UI11 "Đặt lại mật khẩu" gọi riêng `datLaiMatKhau()`, nhưng SQL chỉ có `sp_SuaTaiKhoan`, bắt buộc truyền họ tên và nhóm | Lớp nghiệp vụ truyền họ tên và nhóm hiện tại kèm chuỗi băm mới, hoặc Phúc thêm `sp_DatLaiMatKhau` | Phúc, nhóm code |
| F5 | Thấp | `sp_LapPhieuDichVu` nhận tham số `@ngay_lap` (chỉ để kiểm thử), trong khi UI05 `dtpNgayLap` chỉ đọc | Lớp nghiệp vụ luôn truyền `NULL` để lấy ngày hiện tại | Nhóm code |
| F6 | Thông tin | UI13 mục 1–3 và các lỗi L72, L73, L75–L78 dựa vào thủ tục UC10 của Hoàng (đổi tỷ lệ lợi nhuận, đơn vị tính kèm E2, đơn giá dịch vụ). Chưa có mã lỗi tầng dữ liệu cho các lỗi này nên chưa vào Bảng 3.46 | Bổ sung bảng đối chiếu khi Hoàng viết thủ tục | Hoàng, Truyền |

## 4. Bảng đối chiếu mã lỗi đề nghị cập nhật (thay Bảng 3.46)

| Mã tầng dữ liệu | Ý nghĩa | Mã giao diện | Màn hình | Ghi chú |
| --- | --- | --- | --- | --- |
| 50001, 50005 | Khách hàng hoặc loại dịch vụ đã ngừng sử dụng | L11 | UI05 | Đã có |
| 50002 | Phiếu không có dòng nào | L10 | UI05 | Đã có |
| 50003, 50004 | Thiếu hoặc sai tham số tỷ lệ trả trước | L13 | UI05 | Đã có |
| 50006 | Số lượng nhỏ hơn 1 | L03 | UI05 | Đã có |
| 50007 | Chi phí riêng âm | L04 | UI05 | Đã có |
| 50008 | Ngày giao nhỏ hơn ngày lập | L09 | UI05 | Đã có |
| 50009 | Trả trước dưới mức tối thiểu | L05 | UI05 | Đã có |
| 50010 | Trả trước âm hoặc vượt thành tiền | L06 | UI05 | Đã có |
| 50011 | Không có quyền | L14, L44, L60, L79 | UI05, UI08, UI11–UI13 | Đã có |
| 50012, 50014 | Không tìm thấy dòng hoặc cập nhật giao thất bại | L45, L46 | UI08 | Đã có |
| 50013 | Dòng đã được giao | L40 | UI08 | Đã có |
| 50015 | Tài khoản không tồn tại | L59 | UI11 | Đã có |
| 50016 | Tự khóa chính mình | L58 | UI11 | Đã có |
| 50017 | Chuyển nhóm quản trị viên cuối cùng | L50 | UI11 | Đã có |
| 50018 | Nhóm đang có người dùng | L65 | UI12 | Đã có |
| 50019 | Nhóm không có quyền nào | L63 | UI12 | Đã có |
| 50020, 50024 | Nhóm hoặc mã quyền không tồn tại | L66 | UI12 | Đã có; **thêm UI11** (F2) |
| 50021 | Tỷ lệ ngoài 0–100 | L74 | UI13 | Đã có |
| 50022, 50023 | Tên nhóm trùng hoặc trống | L62, L61 | UI12 | Đã có |
| 50025 | Họ tên trống | L54 | UI11 | Đã có |
| **50026** | Tên đăng nhập sai định dạng | **L52** | UI11 | **Thêm mới (F1)** |
| **50027** | Chuỗi băm mật khẩu rỗng | **L56** | UI11 | **Thêm mới (F1)**; thực tế lớp nghiệp vụ đã chặn L56 trước |
| **50028** | Tên đăng nhập đã được sử dụng | **L53** | UI11 | **Thêm mới (F1)** |
| **50029** | Bỏ quyền quản trị khỏi nhóm của chính mình | **L64** | UI12 | **Thêm mới (F1)** |

## 5. Việc tiếp theo

1. Truyền cập nhật Bảng 3.46 theo mục 4 (F1, F2).
2. Nhóm chọn cách xử lý F3, F4 ở bước thiết kế kiến trúc (H04).
3. Hoàng bổ sung thủ tục và mã lỗi UC10 (F6).
4. Reviewer ký trên bản này sau khi Truyền phản hồi.

---
*Nhóm 28 – SE104 – Nhập môn Công nghệ Phần mềm. Soạn nháp cho Nguyễn Hoàng Thiên Phúc (Data 3); người review cần kiểm lại và ký.*
