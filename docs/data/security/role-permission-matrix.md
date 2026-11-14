# Ma trận quyền (UC07, UC08, UC09)

Nguồn: Bảng 1.10 và mục 1.2.5 của báo cáo. Mã quyền là số cố định trong bảng `QUYEN`; code kiểm quyền ánh xạ theo số này (xem mục 3). Đăng nhập (UC09) dành cho cả 4 vai trò nên không là một quyền.

## 1. Ma trận (X = có quyền)

| ma_quyen | Mã chức năng | Chức năng | Quản trị HT | Quản lý | NV bán hàng | NV kho | Nguồn |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | QL_TAI_KHOAN | Quản lý tài khoản và nhóm quyền (UC07, UC08) | X | | | | Bảng 1.10 dòng 1 |
| 2 | LAP_PHIEU_MUA | Lập phiếu mua hàng (UC02) | | X | | X | Bảng 1.10 dòng 2 |
| 3 | LAP_PHIEU_BAN | Lập phiếu bán hàng (UC01) | | X | X | | Bảng 1.10 dòng 3 |
| 4 | LAP_PHIEU_DV | Lập phiếu dịch vụ (UC03) | | X | X | | Bảng 1.10 dòng 4 |
| 5 | TRA_CUU | Tra cứu sản phẩm và phiếu dịch vụ (UC04, chỉ xem) | | X | X | X | Bảng 1.10 dòng 5 |
| 6 | XAC_NHAN_GIAO | Xác nhận giao dòng dịch vụ (UC04 luồng A2) | | X | X | | UC04; **đã chốt tách riêng** (7a) |
| 7 | BAO_CAO_TON | Lập báo cáo tồn kho (UC05) | | X | | X | Bảng 1.10 dòng 6 |
| 8 | QL_DANH_MUC | Quản lý danh mục (UC06) | | X | | | Bảng 1.10 dòng 7 |
| 9 | THEM_NHANH_KH | Thêm nhanh khách hàng (UC01, UC03) | | X | X | | Mục 1.2.5 |
| 10 | THEM_NHANH_NCC | Thêm nhanh nhà cung cấp (UC02) | | X | | X | Mục 1.2.5 |
| 11 | DOI_QUY_DINH | Thay đổi quy định (UC10) | | X | | | Bảng 1.10 dòng 9 |

## 2. Các quyết định

| Mục | Quyết định | Trạng thái |
| --- | --- | --- |
| 7a | Tách `XAC_NHAN_GIAO` (mã 6): chỉ NV bán hàng và Quản lý; NV kho chỉ xem | Đã chốt (Truyền, 10/11/2026) |
| 7b | Quản lý được gán rõ ràng cả `THEM_NHANH_KH` và `THEM_NHANH_NCC` | Tạm theo đề xuất (chờ Hoàng) |
| 7c | Code ánh xạ quyền theo số `ma_quyen` cố định, không thêm cột mã chữ vào `QUYEN` | Tạm theo đề xuất (chờ Hoàng) |
| 7d | Cho xóa nhóm mặc định, chỉ chặn khi nhóm còn người dùng | Đã chốt (Truyền, 10/11/2026) |

## 3. Quy ước dùng trong code

- `fn_CoQuyen(@ma_nguoi_dung, @ma_quyen)` trả 1 nếu tài khoản **đang hoạt động** và nhóm của tài khoản có quyền đó. Tài khoản bị khóa không có quyền nào.
- Mọi thủ tục nghiệp vụ tự kiểm quyền (lỗi 50011); giao diện ẩn nút chỉ là lớp thứ hai.
- Số quyền không đổi sau khi phát hành. Thêm quyền mới thì dùng số tiếp theo, không dùng lại số cũ.

## 4. Quyền mà từng thủ tục yêu cầu

| Thủ tục | Quyền |
| --- | --- |
| `sp_LapPhieuDichVu` | 4 (LAP_PHIEU_DV) |
| `sp_XacNhanGiaoDong` | 6 (XAC_NHAN_GIAO) |
| `sp_DoiTyLeTraTruoc` | 11 (DOI_QUY_DINH) |
| `sp_ThemTaiKhoan, sp_SuaTaiKhoan, sp_KhoaMoKhoaTaiKhoan` | 1 (QL_TAI_KHOAN) |
| `sp_ThemNhom, sp_SuaNhom, sp_XoaNhom` | 1 (QL_TAI_KHOAN) |
| `sp_LayNguoiDungDeDangNhap, sp_LayQuyenCuaNhom` | không cần |

## 5. Việc cần cập nhật ở tài liệu khác

Theo ghi chú của Truyền: Bảng 1.10 và Bảng 2.1 của báo cáo chưa có `XAC_NHAN_GIAO`, `THEM_NHANH_KH`, `THEM_NHANH_NCC`; cần báo Hoàng cập nhật.

---
*Nhóm 28 – SE104 – Nhập môn Công nghệ Phần mềm. Soạn bởi Nguyễn Hoàng Thiên Phúc (Data 3). Mục nào ghi "tạm theo đề xuất" là chưa đủ người xác nhận.*
