# Ma trận quy định UC10

UC10 chỉ đổi giá trị cho **giao dịch lập sau đó**, không tính lại phiếu lịch sử, không tạo hay xóa danh mục, và chỉ Quản lý có quyền (`DOI_QUY_DINH`).

| # | Quy định | Lưu ở (theo ERD) | Chủ sở hữu dữ liệu | Áp dụng cho | Không được làm | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Tỷ lệ lợi nhuận | `LOAI_SAN_PHAM.ty_le_loi_nhuan` decimal(5,2), ≥ 0 | Hoàng | Phiếu bán lập sau đó | Tính lại phiếu bán cũ; `CT_PHIEU_BAN` đã lưu `don_gia_ban` riêng | Chờ Hoàng viết thủ tục |
| 2 | Đơn vị tính áp dụng | `LOAI_SAN_PHAM.ma_dvt` | Hoàng | Giao dịch sau đó | Đổi khi loại còn tồn kho hoặc đã có chứng từ mà chưa có quy đổi an toàn (E2) | Quy tắc E2 tạm theo đề xuất, chờ Hoàng |
| 3 | Đơn giá dịch vụ | `LOAI_DICH_VU.don_gia_dv` decimal(18,0), ≥ 0 | Hoàng | Phiếu dịch vụ lập sau đó | Sửa `don_gia_dv` ở dòng phiếu cũ (dòng đã chụp giá riêng; ca EX08: PASS) | Chờ Hoàng viết thủ tục |
| 4 | Tỷ lệ trả trước tối thiểu | `THAM_SO.gia_tri_so`, dòng `TyLeTraTruocToiThieu` | **Phúc** | Phiếu dịch vụ lập sau đó | Sửa `tra_truoc`, `con_lai` của phiếu cũ | Đã làm: `sp_DoiTyLeTraTruoc` (đã test) |

## Quy tắc E2 (đổi đơn vị tính) – tạm theo đề xuất

Một loại sản phẩm **không được đổi** `ma_dvt` khi có ít nhất một trong hai điều kiện:

1. Có sản phẩm thuộc loại đó với `so_luong_ton > 0`.
2. Có sản phẩm thuộc loại đó xuất hiện trong `CT_PHIEU_MUA` hoặc `CT_PHIEU_BAN`.

Đơn vị tính mới phải đang hoạt động (`trang_thai = 1`). Khi bị chặn, thông báo nên nêu số sản phẩm của loại, tổng tồn, và việc loại đã hay chưa phát sinh chứng từ. Phần này thuộc bảng của Hoàng nên Hoàng cần xác nhận và viết thủ tục; ca TC16 (Hoàng, Nguyên, Truyền) kiểm tra quy tắc này.

## Phân công

| Phần | Người làm |
| --- | --- |
| Dòng 4 (THAM_SO) | Phúc |
| Dòng 1–3 (danh mục) và quy tắc E2 | Hoàng; Nguyên review tác động tồn kho |
| Màn hình UI13 | Truyền |

---
*Nhóm 28 – SE104 – Nhập môn Công nghệ Phần mềm. Soạn bởi Nguyễn Hoàng Thiên Phúc (Data 3). Mục nào ghi "tạm theo đề xuất" là chưa đủ người xác nhận.*
