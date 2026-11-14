# Quyết định Q03 – Ghi nhận tiền khi giao dịch vụ

| Mục | Nội dung |
| --- | --- |
| Câu hỏi | Khi khách nhận đồ và trả nốt tiền, hệ thống ghi nhận khoản tiền đó thế nào? |
| Người xác nhận | Phúc, Truyền |
| Quyết định | **Phương án A: ghi đè** (`tra_truoc = thanh_tien`, `con_lai = 0`) |
| Trạng thái | Đã chốt (Truyền ghi nhận 10/11/2026: khớp bản SQL đã test; UI08 chỉ kiểm tra số tiền thu bằng đúng phần còn lại, không lưu thành cột riêng, và tổng của phiếu tính lại trong cùng giao dịch) |

## 1. Các phương án đã cân nhắc

| Phương án | Cách ghi | Cần sửa ERD | Ưu | Nhược |
| --- | --- | --- | --- | --- |
| **A. Ghi đè (đã chọn)** | `tra_truoc = thanh_tien`; `con_lai = 0` | Không | Đơn giản; khớp ERD và UC04 luồng A2 | Mất thông tin khách đã cọc bao nhiêu lúc đầu |
| B. Giữ cọc | Thêm cột `tien_thu_khi_giao`; `tra_truoc` và `con_lai` giữ nguyên | Thêm 1–2 cột | Giữ lịch sử cọc | Phải sửa ERD, thủ tục, UI08 |
| C. Bảng thu tiền | Thêm bảng ghi từng lần thu | Thêm 1 bảng | Đầy đủ nhất | Nặng so với phạm vi đồ án |

## 2. Hệ quả của phương án A

- Sau khi giao, cột **Trả trước** trên BM4 bằng thành tiền, không còn là số tiền cọc ban đầu. Nên ghi chú rõ ở UI08 để người dùng không hiểu nhầm (đề xuất).
- Không truy lại được số tiền cọc ban đầu từ dữ liệu. Nếu cần truy vết thì phải dùng phương án B hoặc C.
- Các CHECK `tra_truoc <= thanh_tien` và `con_lai = thanh_tien - tra_truoc` vẫn đúng sau khi giao, nên dữ liệu luôn nhất quán.
- `tong_tra_truoc` của phiếu tăng theo từng dòng giao; khi giao hết, `tong_tra_truoc = tong_tien`.

## 3. Nếu sau này đổi sang B hoặc C

- **Không nới lỏng CHECK `con_lai = thanh_tien - tra_truoc`** để gán `con_lai = 0` mà giữ nguyên `tra_truoc`. Cách đó làm `con_lai` mất nghĩa và DB không còn bắt được dữ liệu mâu thuẫn.
- Với B: thêm cột `tien_thu_khi_giao` (bằng còn phải thu lúc giao); "còn phải thu" = `thanh_tien − tra_truoc − tien_thu_khi_giao`; sửa bước 4 của `sp_XacNhanGiaoDong`, bước 6 và các test TC11a.
- Với C: thêm bảng thu tiền (số phiếu, stt, số tiền, ngày thu, loại), ghi một dòng ở bước 4 trong cùng giao dịch.

## 4. Việc không thay đổi dù chọn phương án nào

Quy tắc chỉ được `Đã giao` khi đã thu đủ phần còn lại; chặn xác nhận hai lần; phiếu `Hoàn thành` khi mọi dòng `Đã giao`.

---
*Nhóm 28 – SE104 – Nhập môn Công nghệ Phần mềm. Soạn bởi Nguyễn Hoàng Thiên Phúc (Data 3). Mục nào ghi "tạm theo đề xuất" là chưa đủ người xác nhận.*
