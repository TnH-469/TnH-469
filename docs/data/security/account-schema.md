# Tài khoản, nhóm và phân quyền – lược đồ và quy tắc (UC07, UC08, UC09)

**Trạng thái:** đã chạy thật trên SQL Server 2022 Express: 59/59 ca PASS (100%), gồm hai thủ tục thêm ở v3 (`sp_ThemTaiKhoan`, `sp_SuaNhom`) và các ca kiểm thử phủ 28/29 mã lỗi nghiệp vụ.

## 1. Bảng (theo ERD)

| Bảng | Cột | Ràng buộc |
| --- | --- | --- |
| `NHOM_NGUOI_DUNG` | `ma_nhom` int IDENTITY, `ten_nhom` nvarchar(50) | PK; `ten_nhom` UNIQUE NOT NULL |
| `QUYEN` | `ma_quyen` int, `ten_quyen` nvarchar(100) | PK (không tự tăng, mã cố định 1..11); `ten_quyen` UNIQUE |
| `PHAN_QUYEN` | `ma_nhom` int, `ma_quyen` int | PK ghép; hai FK; tách quan hệ n–n |
| `NGUOI_DUNG` | `ma_nguoi_dung` int IDENTITY, `ten_dang_nhap` varchar(50), `mat_khau` nvarchar(255), `ho_ten` nvarchar(100), `trang_thai` bit, `ma_nhom` int | PK; `ten_dang_nhap` UNIQUE NOT NULL; `ma_nhom` FK NOT NULL; `trang_thai` 1 = hoạt động, 0 = bị khóa |

## 2. Quy tắc

| Quy tắc | Nơi thực hiện |
| --- | --- |
| Tên đăng nhập duy nhất; 3–50 ký tự; chỉ chữ cái không dấu, số, dấu chấm, gạch dưới | `sp_ThemTaiKhoan` (50026, 50028) + UNIQUE |
| Họ tên không trống | `sp_ThemTaiKhoan`, `sp_SuaTaiKhoan` (50025) |
| Mật khẩu **không** lưu dạng rõ: cột `mat_khau` chỉ chứa chuỗi băm có muối (bcrypt, muối nằm trong chuỗi, vừa 255 ký tự) | Lớp nghiệp vụ băm; `sp_ThemTaiKhoan` từ chối chuỗi rỗng (50027) |
| Độ dài mật khẩu gốc 6–50 ký tự | **Lớp nghiệp vụ** kiểm trước khi băm (SQL chỉ thấy chuỗi băm) |
| Tài khoản bị khóa không đăng nhập được, không có quyền nào | `fn_CoQuyen`; ứng dụng kiểm `trang_thai` từ `sp_LayNguoiDungDeDangNhap` |
| Không tự khóa chính mình | `sp_KhoaMoKhoaTaiKhoan` (50016) |
| Không chuyển nhóm tài khoản quản trị hoạt động cuối cùng sang nhóm không có quyền quản trị | `sp_SuaTaiKhoan` (50017) |
| Không bỏ quyền `QL_TAI_KHOAN` khỏi nhóm của chính người đang sửa nhóm | `sp_SuaNhom` (50029) |
| Nhóm phải có ít nhất 1 quyền | `sp_ThemNhom`, `sp_SuaNhom` (50019) |
| Không xóa nhóm còn người dùng | `sp_XoaNhom` (50018) |
| Tên nhóm duy nhất, không trống | `sp_ThemNhom`, `sp_SuaNhom` (50022, 50023) |
| Khóa, mở khóa, đặt lại mật khẩu cần hộp thoại xác nhận | Giao diện (UI11) |

## 3. Thủ tục

| Thủ tục | UC | Mã lỗi có thể trả |
| --- | --- | --- |
| `sp_LayNguoiDungDeDangNhap(@ten_dang_nhap)` | UC09 | không có (trả rỗng nếu không có tài khoản) |
| `sp_LayQuyenCuaNhom(@ma_nhom)` | UC09 | không có |
| `sp_ThemTaiKhoan` (v3) | UC07 | 50011, 50020, 50025, 50026, 50027, 50028 |
| `sp_SuaTaiKhoan` | UC07 | 50011, 50015, 50017, 50020, 50025 |
| `sp_KhoaMoKhoaTaiKhoan` | UC07 | 50011, 50015, 50016 |
| `sp_ThemNhom` | UC08 | 50011, 50019, 50022, 50023, 50024 |
| `sp_SuaNhom` (v3) | UC08 | 50011, 50019, 50020, 50022, 50023, 50024, 50029 |
| `sp_XoaNhom` | UC08 | 50011, 50018, 50020 |

## 4. Bảng mã lỗi

| Mã | Thông báo từ CSDL |
| --- | --- |
| 50011 | Bạn không có quyền lập phiếu dịch vụ. |
| 50015 | Tài khoản không tồn tại. |
| 50016 | Không thể tự khóa tài khoản đang đăng nhập. |
| 50017 | Không thể chuyển nhóm cho tài khoản quản trị hệ thống đang hoạt động cuối cùng. |
| 50018 | Nhóm đang có người dùng, không thể xóa. |
| 50019 | Nhóm phải được cấp ít nhất 01 quyền. |
| 50020 | Nhóm không tồn tại. |
| 50022 | Tên nhóm đã tồn tại. |
| 50023 | Tên nhóm không được để trống. |
| 50024 | Danh sách có mã quyền không tồn tại. |
| 50025 | Họ tên không được để trống. |
| 50026 | Tên đăng nhập phải từ 3 đến 50 ký tự, chỉ gồm chữ cái không dấu, số, dấu chấm và gạch dưới. |
| 50027 | Mật khẩu không được để trống. |
| 50028 | Tên đăng nhập đã được sử dụng. |
| 50029 | Không thể bỏ quyền quản lý tài khoản khỏi nhóm của tài khoản đang đăng nhập. |

## 5. Dữ liệu khởi tạo

- 4 nhóm mặc định: Nhân viên Bán hàng, Nhân viên Kho, Quản lý Cửa hàng, Quản trị hệ thống; phân quyền theo `role-permission-matrix.md`.
- 4 tài khoản **demo** (`admin`, `quanly`, `nvban`, `nvkho`), mật khẩu `Demo@12345`, chuỗi băm bcrypt. Chỉ dùng cho demo; đổi trước khi dùng thật.

## 6. Kiểm thử

Đã chạy (v2 và v3): TC13a, TC13b, EX10, TC14a, TC14b, EX11, EX12, EX13.
Đã chạy (v3, PASS): TK01–TK08 và TK04b (thêm tài khoản), NH01–NH06 (sửa nhóm), SK01–SK06 (sửa tài khoản).

## 7. Điểm tạm theo đề xuất

Thuật toán bcrypt và việc kiểm tra mật khẩu ở lớp nghiệp vụ (chờ Hoàng, ở bước thiết kế kiến trúc H04); bảng quyền không có cột mã chữ (7c).

---
*Nhóm 28 – SE104 – Nhập môn Công nghệ Phần mềm. Soạn bởi Nguyễn Hoàng Thiên Phúc (Data 3). Mục nào ghi "tạm theo đề xuất" là chưa đủ người xác nhận.*
