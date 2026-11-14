# Luồng xác nhận giao và tất toán dịch vụ (UC04 – QĐ4)

**Trạng thái tài liệu:** thủ tục `sp_XacNhanGiaoDong` đã chạy thật ở v2 (ca TC10, TC11a, TC11b, EX02: PASS).
**Quyết định áp dụng:** Q03 phương án A (đã chốt, xem `payment-decision.md`).

## 1. Trạng thái và chuyển trạng thái

| Đối tượng | Giá trị | Ghi chú |
| --- | --- | --- |
| Dòng dịch vụ (`CT_PHIEU_DICH_VU.tinh_trang`) | `Chưa giao` → `Đã giao` | Chỉ một chiều. Mặc định `Chưa giao` khi lập phiếu |
| Phiếu (`PHIEU_DICH_VU.tinh_trang`) | `Chưa hoàn thành` → `Hoàn thành` | Tự tính: `Hoàn thành` khi mọi dòng đều `Đã giao` (QĐ4) |

Không có chiều ngược lại: đặc tả không có "hủy giao" (đã chốt: không làm). Phiếu luôn có ít nhất 1 dòng nên không có phiếu rỗng ở trạng thái `Hoàn thành`.

## 2. Điều kiện xác nhận giao một dòng

1. Người dùng có quyền `XAC_NHAN_GIAO` (mã 6): NV bán hàng và Quản lý. NV kho chỉ tra cứu.
2. Dòng đang `Chưa giao`.
3. Khách đã trả đủ phần còn lại. Phần mềm không xử lý thanh toán; người dùng xác nhận ở hộp thoại (UI08).

## 3. Các bước trong một giao dịch (`sp_XacNhanGiaoDong`)

| Bước | Việc | Nếu lỗi |
| --- | --- | --- |
| 1 | Kiểm tra quyền 6 | 50011 |
| 2 | Mở giao dịch | |
| 3 | Khóa dòng (`UPDLOCK, HOLDLOCK`) rồi kiểm tra còn `Chưa giao` | 50012 nếu không có dòng; 50013 nếu đã giao |
| 4 | Ghi nhận tiền: `tra_truoc = thanh_tien`, `con_lai = 0` (Q03-A) | |
| 5 | Cập nhật dòng thành `Đã giao` với điều kiện `tinh_trang = 'Chưa giao'`; số dòng bị ảnh hưởng phải bằng 1 | 50014 |
| 6 | Tính lại phiếu: `tong_tien`, `tong_tra_truoc`, `tong_con_lai`, `tinh_trang` | |
| 7 | Hoàn tất giao dịch; lỗi ở bước nào thì hoàn tác toàn bộ | |

Nhờ khóa ở bước 3 và điều kiện ở bước 5, bấm xác nhận hai lần hoặc hai người cùng bấm chỉ có một lần thành công; lần còn lại nhận lỗi 50013 và không ghi tiền lần hai.

## 4. Ví dụ cho phiếu 2 dòng

| Sự kiện | Dòng 1 | Dòng 2 | Phiếu |
| --- | --- | --- | --- |
| Vừa lập | Chưa giao | Chưa giao | Chưa hoàn thành |
| Giao dòng 1 | Đã giao | Chưa giao | Chưa hoàn thành |
| Giao dòng 2 | Đã giao | Đã giao | Hoàn thành; `tong_tra_truoc = tong_tien`, `tong_con_lai = 0` |
| Xác nhận lại dòng 2 | | Lỗi 50013 | Không đổi |

## 5. Mã lỗi giao diện cần xử lý (UI08)

| Mã | Thông báo từ CSDL |
| --- |  --- |
| 50011 | Bạn không có quyền lập phiếu dịch vụ. |
| 50012 | Không tìm thấy dòng dịch vụ. |
| 50013 | Dòng dịch vụ này đã được giao, không thể xác nhận lại. |
| 50014 | Cập nhật dòng dịch vụ thất bại. |

Sau khi xác nhận thành công (hoặc nhận 50013), giao diện phải tải lại các dòng và tình trạng phiếu để người dùng thấy trạng thái thật.

## 6. Kiểm thử liên quan

TC10 (giao dòng 1, phiếu vẫn Chưa hoàn thành), TC11a (giao dòng cuối, phiếu Hoàn thành), TC11b (xác nhận lại bị 50013), EX02 (NV kho bị 50011).

## 7. Điểm còn mở

- **Q08 (tạm theo đề xuất):** `ngay_giao` là ngày hẹn giao và không đổi khi giao; chưa lưu ngày giao thực tế. Nếu nhóm cần ngày giao thực tế thì thêm một cột và gán ngày hiện tại ở bước 5.
- Nếu sau này đổi Q03 sang phương án B hoặc C, chỉ bước 4 và các CHECK về `con_lai` thay đổi (xem `payment-decision.md`).

---
*Nhóm 28 – SE104 – Nhập môn Công nghệ Phần mềm. Soạn bởi Nguyễn Hoàng Thiên Phúc (Data 3). Mục nào ghi "tạm theo đề xuất" là chưa đủ người xác nhận.*
