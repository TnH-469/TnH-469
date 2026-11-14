# THIẾT KẾ DỮ LIỆU MODULE DỊCH VỤ & PHÂN QUYỀN (v3)
**Môn học:** SE104 – Nhập môn Công nghệ Phần mềm  
**Nhóm:** 28 | **Thực hiện:** Nguyễn Hoàng Thiên Phúc (Data 3)  
**Tài liệu kèm theo:** `service-erd.pdf`, `services-security-v3.sql`

---

## 1. DANH SÁCH CÁC BẢNG & KHÓA

### 1.1. Bảng thuộc phân hệ Dịch vụ
1. **`KHACH_HANG`** *(Bảng phụ thuộc từ Hoàng, dùng tạm độc lập)*
   - `ma_kh` (int, IDENTITY, PK)
   - `ho_ten` (nvarchar(100), NOT NULL)
   - `so_dien_thoai` (varchar(15), NULL)
   - `dia_chi` (nvarchar(200), NULL)
   - `trang_thai` (bit, NOT NULL, DEFAULT 1)

2. **`LOAI_DICH_VU`** *(Bảng phụ thuộc từ Hoàng)*
   - `ma_loai_dv` (int, IDENTITY, PK)
   - `ten_loai_dv` (nvarchar(50), NOT NULL)
   - `don_gia_dv` (decimal(18,0), NOT NULL, CHECK >= 0)
   - `trang_thai` (bit, NOT NULL, DEFAULT 1)

3. **`PHIEU_DICH_VU`**
   - `so_phieu` (int, IDENTITY, PK)
   - `ngay_lap` (date, NOT NULL, DEFAULT (CAST(GETDATE() AS date)))
   - `ma_kh` (int, NOT NULL, FK -> `KHACH_HANG.ma_kh`)
   - `tong_tien` (decimal(18,0), NOT NULL, DEFAULT 0, CHECK >= 0)
   - `tong_tra_truoc` (decimal(18,0), NOT NULL, DEFAULT 0, CHECK >= 0)
   - `tong_con_lai` (decimal(18,0), NOT NULL, DEFAULT 0, CHECK >= 0)
   - `tinh_trang` (nvarchar(20), NOT NULL, DEFAULT N'Chưa hoàn thành', CHECK IN (N'Hoàn thành', N'Chưa hoàn thành'))
   - *Ràng buộc:* `tong_con_lai = tong_tien - tong_tra_truoc`

4. **`CT_PHIEU_DICH_VU`**
   - `so_phieu` (int, NOT NULL, FK -> `PHIEU_DICH_VU.so_phieu`)
   - `stt` (int, NOT NULL, CHECK >= 1)
   - `ma_loai_dv` (int, NOT NULL, FK -> `LOAI_DICH_VU.ma_loai_dv`)
   - `so_luong` (int, NOT NULL, CHECK >= 1)
   - `ngay_giao` (date, NOT NULL) — *ngày hẹn giao; giữ nguyên khi giao (Q08, tạm theo đề xuất)*
   - `don_gia_dv` (decimal(18,0), NOT NULL, CHECK >= 0) — *bản chụp đơn giá lúc lập phiếu*
   - `chi_phi_rieng` (decimal(18,0), NOT NULL, DEFAULT 0, CHECK >= 0)
   - `don_gia_tinh` (decimal(18,0), NOT NULL) — *CHECK: don_gia_tinh = don_gia_dv + chi_phi_rieng*
   - `thanh_tien` (decimal(18,0), NOT NULL) — *CHECK: thanh_tien = so_luong * don_gia_tinh*
   - `tra_truoc` (decimal(18,0), NOT NULL, CHECK: 0 <= tra_truoc <= thanh_tien)
   - `con_lai` (decimal(18,0), NOT NULL) — *CHECK: con_lai = thanh_tien - tra_truoc*
   - `tinh_trang` (nvarchar(20), NOT NULL, DEFAULT N'Chưa giao', CHECK IN (N'Chưa giao', N'Đã giao'))
   - *Khóa chính:* `PK_CT_PHIEU_DICH_VU (so_phieu, stt)` (khớp Q02 và Q06)

---

### 1.2. Bảng thuộc phân hệ Phân quyền & Tham số
5. **`NHOM_NGUOI_DUNG`**
   - `ma_nhom` (int, IDENTITY, PK)
   - `ten_nhom` (nvarchar(50), NOT NULL, UNIQUE)

6. **`QUYEN`**
   - `ma_quyen` (int, PK) — *Mã cố định (1..11) phục vụ kiểm tra quyền trong code:*
     - 1: `QL_TAI_KHOAN` (Quản lý tài khoản và nhóm quyền - UC07, UC08)
     - 2: `LAP_PHIEU_MUA` (Lập phiếu mua hàng - UC02)
     - 3: `LAP_PHIEU_BAN` (Lập phiếu bán hàng - UC01)
     - 4: `LAP_PHIEU_DV` (Lập phiếu dịch vụ - UC03)
     - 5: `TRA_CUU` (Tra cứu sản phẩm và phiếu dịch vụ - UC04)
     - 6: `XAC_NHAN_GIAO` (Xác nhận giao dòng dịch vụ - UC04)
     - 7: `BAO_CAO_TON` (Lập báo cáo tồn kho - UC05)
     - 8: `QL_DANH_MUC` (Quản lý danh mục - UC06)
     - 9: `THEM_NHANH_KH` (Thêm nhanh khách hàng - UC01, UC03)
     - 10: `THEM_NHANH_NCC` (Thêm nhanh nhà cung cấp - UC02)
     - 11: `DOI_QUY_DINH` (Thay đổi quy định hệ thống - UC10)
   - `ten_quyen` (nvarchar(100), NOT NULL, UNIQUE)

7. **`PHAN_QUYEN`**
   - `ma_nhom` (int, NOT NULL, FK -> `NHOM_NGUOI_DUNG.ma_nhom`)
   - `ma_quyen` (int, NOT NULL, FK -> `QUYEN.ma_quyen`)
   - *Khóa chính:* `PK_PHAN_QUYEN (ma_nhom, ma_quyen)`

8. **`NGUOI_DUNG`**
   - `ma_nguoi_dung` (int, IDENTITY, PK)
   - `ten_dang_nhap` (varchar(50), NOT NULL, UNIQUE)
   - `mat_khau` (nvarchar(255), NOT NULL)
   - `ho_ten` (nvarchar(100), NOT NULL)
   - `trang_thai` (bit, NOT NULL, DEFAULT 1)
   - `ma_nhom` (int, NOT NULL, FK -> `NHOM_NGUOI_DUNG.ma_nhom`)

9. **`THAM_SO`**
   - `ma_tham_so` (varchar(50), PK)
   - `gia_tri_so` (decimal(5,2), NOT NULL, CHECK >= 0)
   - `don_vi` (nvarchar(20), NULL)
   - `mo_ta` (nvarchar(200), NULL)
   - *Bản ghi mặc định:* `('TyLeTraTruocToiThieu', 50.00, '%', N'Tỷ lệ trả trước tối thiểu của dòng dịch vụ')`

---

## 2. QUAN HỆ GIỮA CÁC THỰC THỂ (RELATIONSHIPS)

- `KHACH_HANG (1)` ──< `PHIEU_DICH_VU (N)` qua `ma_kh`
- `PHIEU_DICH_VU (1)` ──< `CT_PHIEU_DICH_VU (N)` qua `so_phieu`
- `LOAI_DICH_VU (1)` ──< `CT_PHIEU_DICH_VU (N)` qua `ma_loai_dv`
- `NHOM_NGUOI_DUNG (1)` ──< `NGUOI_DUNG (N)` qua `ma_nhom`
- `NHOM_NGUOI_DUNG (1)` ──< `PHAN_QUYEN (N)` qua `ma_nhom`
- `QUYEN (1)` ──< `PHAN_QUYEN (N)` qua `ma_quyen`

---

## 3. ÁNH XẠ BM4 VÀ TRA CỨU PHIẾU DỊCH VỤ (UC04, UI07)

### 3.1 Các cột của BM4 – danh sách phiếu dịch vụ

| Cột BM4 | Nguồn | Ghi chú |
| --- | --- | --- |
| STT | Không lưu | Đánh số khi hiển thị |
| Số phiếu | `PHIEU_DICH_VU.so_phieu` | |
| Ngày lập | `PHIEU_DICH_VU.ngay_lap` | Sắp xếp mặc định giảm dần |
| Khách hàng | `KHACH_HANG.ho_ten` qua `ma_kh` | Join, không lưu lặp |
| Tổng tiền | `PHIEU_DICH_VU.tong_tien` | Đọc trực tiếp (Q05: cột lưu) |
| Trả trước | `PHIEU_DICH_VU.tong_tra_truoc` | Đọc trực tiếp |
| Còn lại | `PHIEU_DICH_VU.tong_con_lai` | Đọc trực tiếp |
| Tình trạng | `PHIEU_DICH_VU.tinh_trang` | `Hoàn thành` hoặc `Chưa hoàn thành` (QĐ4) |

### 3.2 Tiêu chí tra cứu (kết hợp bằng điều kiện "và")

| Tiêu chí (UI07) | Cột | Phép so sánh | Chỉ mục hỗ trợ |
| --- | --- | --- | --- |
| Số phiếu | `PHIEU_DICH_VU.so_phieu` | Bằng | PK |
| Tên khách hàng | `KHACH_HANG.ho_ten` | Chứa chuỗi (không phân biệt hoa thường) | – |
| Số điện thoại | `KHACH_HANG.so_dien_thoai` | Chứa chuỗi | – |
| Từ ngày, Đến ngày | `PHIEU_DICH_VU.ngay_lap` | `>=` và `<=` (cho phép bỏ trống một đầu) | `IX_PHIEU_DICH_VU_ngay_lap` |
| Tình trạng phiếu | `PHIEU_DICH_VU.tinh_trang` | Bằng (hoặc Tất cả) | `IX_PHIEU_DICH_VU_tinh_trang` |

Chi tiết một phiếu (UI08): đọc `PHIEU_DICH_VU` và toàn bộ `CT_PHIEU_DICH_VU` theo `so_phieu`, sắp xếp theo `stt`; tên loại dịch vụ lấy từ `LOAI_DICH_VU.ten_loai_dv` qua `ma_loai_dv`.

## 4. CHỈ MỤC

- `IX_PHIEU_DICH_VU_ngay_lap (ngay_lap)`, `IX_PHIEU_DICH_VU_tinh_trang (tinh_trang)`, `IX_PHIEU_DICH_VU_ma_kh (ma_kh)` – phục vụ lọc ở màn hình tra cứu phiếu (UC04).

## 5. THỦ TỤC VÀ QUYỀN YÊU CẦU

| Thủ tục | UC | Quyền | Tài liệu chi tiết |
| --- | --- | --- | --- |
| `sp_LapPhieuDichVu` | UC03 | 4 (LAP_PHIEU_DV) | mục 1 (ràng buộc), `parameters-and-uc10.md` |
| `sp_XacNhanGiaoDong` | UC04 | 6 (XAC_NHAN_GIAO) | `delivery-state-machine.md` |
| `sp_DoiTyLeTraTruoc` | UC10 | 11 (DOI_QUY_DINH) | `parameters-and-uc10.md` |
| `sp_ThemTaiKhoan`, `sp_SuaTaiKhoan`, `sp_KhoaMoKhoaTaiKhoan` | UC07 | 1 (QL_TAI_KHOAN) | `account-schema.md` |
| `sp_ThemNhom`, `sp_SuaNhom`, `sp_XoaNhom` | UC08 | 1 (QL_TAI_KHOAN) | `account-schema.md` |
| `sp_LayNguoiDungDeDangNhap`, `sp_LayQuyenCuaNhom` | UC09 | không cần | `account-schema.md` |

## 6. QUYẾT ĐỊNH ĐANG ÁP DỤNG

| Mục | Quyết định | Trạng thái |
| --- | --- | --- |
| Q02 | Cho phép nhiều dòng cùng loại dịch vụ; khóa dòng `(so_phieu, stt)` | Đã chốt (Truyền); chờ Nguyên |
| Q03 | Khi giao ghi đè `tra_truoc = thanh_tien`, `con_lai = 0` | Đã chốt (`payment-decision.md`) |
| Q05 | Các cột tổng và `tinh_trang` của phiếu là cột lưu, cập nhật cùng giao dịch | Tạm theo đề xuất |
| Q08 | `ngay_giao` là ngày hẹn giao, giữ nguyên khi giao; chưa lưu ngày giao thực tế | Tạm theo đề xuất |
