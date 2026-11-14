# Bảng THAM_SO và UC10 (phần của Phúc)

## 1. Bảng THAM_SO

Theo slide Chương 4, tham số lưu ở dạng "mỗi tham số một dòng". Bảng 1.14 của báo cáo cũng dùng cách này.

| Cột | Kiểu | Giá trị / ghi chú |
| --- | --- | --- |
| `ma_tham_so` | varchar(50), PK | `'TyLeTraTruocToiThieu'` |
| `gia_tri_so` | decimal(5,2), NOT NULL, CHECK ≥ 0 | 50 khi khởi tạo |
| `don_vi` | nvarchar(20) | `'%'` |
| `mo_ta` | nvarchar(200) | Tỷ lệ trả trước tối thiểu trên thành tiền từng dòng dịch vụ |

## 2. Quy tắc

| Nội dung | Quy tắc | Nơi thực hiện |
| --- | --- | --- |
| Miền giá trị | 0 ≤ `gia_tri_so` ≤ 100. Kiểu decimal(5,2) chứa được tới 999,99 nên miền 0–100 phải kiểm riêng | `sp_DoiTyLeTraTruoc` (lỗi 50021); `sp_LapPhieuDichVu` (lỗi 50004 nếu dữ liệu đã sai) |
| Quyền đổi | Quyền `DOI_QUY_DINH` (mã 11): chỉ Quản lý | `sp_DoiTyLeTraTruoc` (lỗi 50011) |
| Thiếu bản ghi | Từ chối lưu phiếu, báo lỗi cấu hình, không tự dùng 50% ngầm | Lỗi 50003 (ca EX09: PASS) |
| Đọc tỷ lệ | Đọc ngay trong giao dịch lưu phiếu và giữ khóa đến hết giao dịch (`HOLDLOCK`), nên Quản lý không đổi được tỷ lệ giữa chừng | `sp_LapPhieuDichVu` |
| Hiệu lực | Chỉ áp dụng cho phiếu lập sau khi đổi. `tra_truoc` là số tiền đã lưu, không bao giờ tính lại | Ca TC15a: PASS |
| Thao tác DB | Ứng dụng chỉ nên có quyền `SELECT` và `UPDATE` trên bảng này, không `INSERT`/`DELETE` | Cấp quyền khi triển khai; dòng gốc nằm trong seed |
| So sánh trả trước tối thiểu | `tra_truoc × 100 ≥ thanh_tien × gia_tri_so`, không làm tròn (đã chốt) | `sp_LapPhieuDichVu` |

## 3. Thủ tục `sp_DoiTyLeTraTruoc(@ma_nguoi_dung, @gia_tri)`

1. Kiểm tra quyền 11, nếu không có thì lỗi 50011.
2. Kiểm tra `0 ≤ @gia_tri ≤ 100`, nếu không thì lỗi 50021.
3. `UPDATE THAM_SO` dòng `TyLeTraTruocToiThieu`; nếu không có dòng nào thì lỗi 50003.

## 4. Ví dụ

Đổi 50% lên 60%: phiếu cũ (trả trước 500.000 trên thành tiền 1.000.000) giữ nguyên; phiếu mới trả trước 550.000 bị từ chối (tối thiểu 600.000), 600.000 được chấp nhận (ca TC15a, TC15b, TC15c).

## 5. Kiểm thử

TC15a–TC15e, EX09, TC08a–TC08d, TC09b.

Ma trận toàn bộ quy định UC10 xem `uc10-rule-matrix.md`.

---
*Nhóm 28 – SE104 – Nhập môn Công nghệ Phần mềm. Soạn bởi Nguyễn Hoàng Thiên Phúc (Data 3). Mục nào ghi "tạm theo đề xuất" là chưa đủ người xác nhận.*
