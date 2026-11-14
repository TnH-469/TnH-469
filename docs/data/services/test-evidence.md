# BÁO CÁO KẾT QUẢ KIỂM THỬ TỰ ĐỘNG (TEST EVIDENCE) – PHIÊN BẢN v3
**Module:** Dịch vụ & Phân quyền (Phiên bản v3: bổ sung sp_ThemTaiKhoan, sp_SuaNhom và hoàn thiện độ phủ mã lỗi)  
**Môn học:** SE104 – Nhập môn Công nghệ Phần mềm  
**Người thực hiện:** Nguyễn Hoàng Thiên Phúc (Data 3 – Nhóm 28)  
**Reviewer:** Hoàng, Truyền (Chờ review / Chờ ký)  
**Hệ quản trị CSDL:** Microsoft SQL Server 2022 (Express Edition, 64-bit, v16.0.1000.6)  
**Database kiểm thử:** `SE104_Test`  
**Ngày thực hiện:** 14/11/2026 (v3 hoàn thiện 59 ca), 11/11/2026 (54 ca), 09/11/2026 (v2 33 ca)  

---

## 1. TỔNG KẾT KẾT QUẢ KIỂM THỬ

| Chỉ số | Giá trị |
| :--- | :--- |
| **Tổng số ca kiểm thử** | **59** |
| **Số ca kiểm thử ĐẠT (PASS)** | **59** |
| **Số ca kiểm thử THẤT BẠI (FAIL)** | **0** |
| **Tỷ lệ thành công** | **100%** |
| **Độ phủ mã lỗi (50001–50029)** | **28/29 mã lỗi** (mã 50014 là phòng thủ do UPDLOCK) |

---

## 2. BẢNG CHI TIẾT 59 CA KIỂM THỬ (TEST CASES)

| STT | Mã ca | Mô tả kiểm thử | Kết quả mong đợi | Kết quả thực tế | Trạng thái |
|:---:|:---|:---|:---|:---|:---:|
| 1 | **TC08a** | Trả trước 490.000 < tối thiểu 500.000 | Lỗi 50009, thông báo nêu mức tối thiểu 500000 | 50009: Tiền trả trước tối thiểu của dòng là 500000 (50.00% của thành tiền 1000000). | **PASS** |
| 2 | **TC08b** | Trả trước đúng mức tối thiểu 500.000 (biên dưới) | Lưu thành công | lỗi=0 phiếu=64 | **PASS** |
| 3 | **TC08c** | Trả trước = thành tiền 1.000.000 (biên trên) | Lưu thành công, còn lại = 0 | lỗi=0 còn lại=0 | **PASS** |
| 4 | **TC08d** | Trả trước 1.000.001 > thành tiền | Lỗi 50010 | 50010: Tiền trả trước không được âm hoặc vượt thành tiền của dòng. | **PASS** |
| 5 | **TC09a** | Giá DV 600.000 + phí 100.000, SL 2, trả trước 700.000 | Đơn giá tính 700000; thành tiền 1400000 | lỗi=0 đơn giá=700000 thành tiền=1400000 | **PASS** |
| 6 | **TC09b** | Cùng dòng, trả trước 600.000 < tối thiểu 700.000 | Lỗi 50009 | 50009: Tiền trả trước tối thiểu của dòng là 700000 (50.00% của thành tiền 1400000). | **PASS** |
| 7 | **TC10a** | Phiếu mới 2 dòng | Phiếu Chưa hoàn thành | Chưa hoàn thành | **PASS** |
| 8 | **TC10** | Giao dòng 1 của phiếu 2 dòng | Dòng 1 Đã giao; phiếu vẫn Chưa hoàn thành | lỗi=0; dòng 1=Đã giao; phiếu=Chưa hoàn thành | **PASS** |
| 9 | **TC11a** | Giao dòng cuối (Quản lý xác nhận) | Phiếu Hoàn thành; tổng trả trước = tổng tiền (theo Q03-A) | lỗi=0; phiếu=Hoàn thành; trả trước=1600000; tổng tiền=1600000 | **PASS** |
| 10 | **TC11b** | Xác nhận lại dòng đã giao | Lỗi 50013, tiền không ghi lần hai | 50013: Dòng dịch vụ này đã được giao, không thể xác nhận lại. | **PASS** |
| 11 | **EX15** | Xác nhận giao phiếu không tồn tại | Lỗi 50012 | 50012: Không tìm thấy dòng dịch vụ. | **PASS** |
| 12 | **EX01** | NV kho lập phiếu dịch vụ | Lỗi 50011 | 50011: Bạn không có quyền lập phiếu dịch vụ. | **PASS** |
| 13 | **EX02** | NV kho xác nhận giao | Lỗi 50011; dòng vẫn Chưa giao | 50011; dòng=Chưa giao | **PASS** |
| 14 | **EX03** | Lưu phiếu không có dòng | Lỗi 50002 | 50002: Phiếu dịch vụ phải có ít nhất 01 dòng dịch vụ. | **PASS** |
| 15 | **EX04** | Số lượng = 0 | Lỗi 50006 | 50006: Số lượng của mỗi dòng phải từ 1 trở lên. | **PASS** |
| 16 | **EX04b** | Chi phí riêng âm (-1) | Lỗi 50007 | 50007: Chi phí riêng không được âm. | **PASS** |
| 17 | **EX05** | Ngày giao nhỏ hơn ngày lập | Lỗi 50008 | 50008: Ngày giao không được nhỏ hơn ngày lập phiếu. | **PASS** |
| 18 | **EX06** | Khách hàng có trang_thai = 0 | Lỗi 50001 | 50001: Khách hàng không tồn tại hoặc đã ngừng sử dụng. | **PASS** |
| 19 | **EX07** | Loại dịch vụ có trang_thai = 0 | Lỗi 50005 | 50005: Loại dịch vụ không tồn tại hoặc đã ngừng sử dụng. | **PASS** |
| 20 | **EX08** | Đổi đơn giá loại dịch vụ 600.000 -> 700.000 sau khi lập phiếu | don_gia_dv của dòng cũ vẫn 600000 | 600000 | **PASS** |
| 21 | **TC15a** | Sau khi đổi lên 60%, phiếu cũ (trả trước 500.000) | Phiếu cũ giữ nguyên trả trước 500000 | 500000 | **PASS** |
| 22 | **TC15b** | Phiếu mới ở 60%, trả trước 550.000 | Lỗi 50009, tối thiểu 600000 | 50009: Tiền trả trước tối thiểu của dòng là 600000 (60.00% của thành tiền 1000000). | **PASS** |
| 23 | **TC15c** | Phiếu mới ở 60%, trả trước 600.000 | Lưu thành công | lỗi=0 phiếu=70 | **PASS** |
| 24 | **TC15d** | NV bán hàng đổi quy định | Lỗi 50011 | 50011: Bạn không có quyền thay đổi quy định. | **PASS** |
| 25 | **TC15e** | Đổi tỷ lệ thành 101 | Lỗi 50021 | 50021: Tỷ lệ trả trước tối thiểu phải nằm từ 0 đến 100. | **PASS** |
| 26 | **EX09** | Thiếu dòng TyLeTraTruocToiThieu trong THAM_SO | Từ chối lưu, lỗi 50003 (không tự dùng 50 ngầm) | 50003: Chưa cấu hình tỷ lệ trả trước tối thiểu (THAM_SO). | **PASS** |
| 27 | **EX14** | Tỷ lệ trả trước tối thiểu trong THAM_SO > 100 (150%) | Lỗi 50004 | 50004: Tỷ lệ trả trước tối thiểu trong THAM_SO phải nằm từ 0 đến 100. | **PASS** |
| 28 | **TC13a** | Xóa nhóm đang có người dùng | Lỗi 50018; nhóm vẫn còn | 50018: Nhóm đang có người dùng, không thể xóa.; số nhóm còn=1 | **PASS** |
| 29 | **TC13b** | Xóa nhóm không có người dùng | Xóa thành công | lỗi=0; số nhóm còn=0 | **PASS** |
| 30 | **EX10** | Thêm nhóm không chọn quyền nào | Lỗi 50019, không tạo nhóm | 50019: Nhóm phải được cấp ít nhất 01 quyền. | **PASS** |
| 31 | **TC14a** | Khóa tài khoản test_u1 | trang_thai = 0 và không còn quyền nào | lỗi=0; trang_thai=0; có quyền TRA_CUU=0 | **PASS** |
| 32 | **TC14b** | Mở khóa tài khoản test_u1 | trang_thai = 1 và có lại quyền | lỗi=0; trang_thai=1 | **PASS** |
| 33 | **EX11** | Quản trị hệ thống tự khóa chính mình | Lỗi 50016; admin vẫn hoạt động | 50016: Không thể tự khóa tài khoản đang đăng nhập. | **PASS** |
| 34 | **EX12** | NV bán hàng khóa tài khoản người khác | Lỗi 50011 | 50011: Bạn không có quyền quản lý tài khoản. | **PASS** |
| 35 | **EX13** | Chuyển nhóm quản trị hệ thống cuối cùng sang nhóm thường | Lỗi 50017; admin vẫn giữ quyền quản trị | 50017: Không thể chuyển nhóm cho tài khoản quản trị hệ thống đang hoạt động cuối cùng. | **PASS** |
| 36 | **TK01** | Thêm tài khoản hợp lệ | Thành công; trang_thai = 1; lưu nguyên chuỗi băm; đúng nhóm | lỗi=0; mã=23 | **PASS** |
| 37 | **TK02** | Thêm tài khoản trùng tên đăng nhập | Lỗi 50028 | 50028: Tên đăng nhập đã được sử dụng. | **PASS** |
| 38 | **TK03** | Tên đăng nhập quá ngắn (2 ký tự) | Lỗi 50026 | 50026: Tên đăng nhập phải từ 3 đến 50 ký tự, chỉ gồm chữ cái không dấu, số, dấu chấm và gạch dưới. | **PASS** |
| 39 | **TK04** | Tên đăng nhập có khoảng trắng | Lỗi 50026 | 50026: Tên đăng nhập phải từ 3 đến 50 ký tự, chỉ gồm chữ cái không dấu, số, dấu chấm và gạch dưới. | **PASS** |
| 40 | **TK04b** | Tên đăng nhập có chữ có dấu | Lỗi 50026 | 50026: Tên đăng nhập phải từ 3 đến 50 ký tự, chỉ gồm chữ cái không dấu, số, dấu chấm và gạch dưới. | **PASS** |
| 41 | **TK05** | Họ tên chỉ có khoảng trắng | Lỗi 50025 | 50025: Họ tên không được để trống. | **PASS** |
| 42 | **TK06** | Thêm tài khoản vào nhóm không tồn tại | Lỗi 50020; không tạo tài khoản | 50020: Nhóm không tồn tại. | **PASS** |
| 43 | **TK07** | NV bán hàng thêm tài khoản | Lỗi 50011 | 50011: Bạn không có quyền quản lý tài khoản. | **PASS** |
| 44 | **TK08** | Chuỗi băm mật khẩu rỗng | Lỗi 50027 | 50027: Mật khẩu không được để trống. | **PASS** |
| 45 | **NH01** | Sửa nhóm: đổi tên và đổi quyền thành {2, 5} | Thành công; tên mới; đúng 2 quyền gồm quyền 2 | lỗi=0; số quyền=2 | **PASS** |
| 46 | **NH02** | Sửa nhóm nhưng không chọn quyền nào | Lỗi 50019; tên và quyền cũ giữ nguyên | 50019: Nhóm phải được cấp ít nhất 01 quyền. | **PASS** |
| 47 | **NH03** | Đổi tên nhóm trùng với nhóm khác | Lỗi 50022 | 50022: Tên nhóm đã tồn tại. | **PASS** |
| 48 | **NH04** | Admin bỏ quyền quản lý tài khoản khỏi nhóm của chính mình | Lỗi 50029; admin vẫn còn quyền | 50029: Không thể bỏ quyền quản lý tài khoản khỏi nhóm của tài khoản đang đăng nhập. | **PASS** |
| 49 | **NH05** | Sửa nhóm không tồn tại | Lỗi 50020 | 50020: Nhóm không tồn tại. | **PASS** |
| 50 | **NH06** | NV bán hàng sửa nhóm | Lỗi 50011 | 50011: Bạn không có quyền quản lý nhóm người dùng. | **PASS** |
| 51 | **NH07** | Thêm nhóm với tên nhóm chỉ có khoảng trắng | Lỗi 50023 | 50023: Tên nhóm không được để trống. | **PASS** |
| 52 | **NH08** | Thêm nhóm có mã quyền không tồn tại (999) | Lỗi 50024 | 50024: Danh sách có mã quyền không tồn tại. | **PASS** |
| 53 | **SK01** | Chuyển nhóm của quản trị viên khi còn quản trị viên khác | Thành công; tài khoản sang nhóm mới | lỗi=0 | **PASS** |
| 54 | **SK02** | Sửa tài khoản không tồn tại | Lỗi 50015 | 50015: Tài khoản không tồn tại. | **PASS** |
| 55 | **SK03** | Sửa tài khoản với họ tên trống | Lỗi 50025 | 50025: Họ tên không được để trống. | **PASS** |
| 56 | **SK04** | Sửa tài khoản sang nhóm không tồn tại | Lỗi 50020 | 50020: Nhóm không tồn tại. | **PASS** |
| 57 | **SK05** | Đổi họ tên, không đổi mật khẩu (tham số mật khẩu = NULL) | Thành công; họ tên mới; mật khẩu giữ nguyên | lỗi=0 | **PASS** |
| 58 | **SK06** | NV bán hàng sửa tài khoản | Lỗi 50011 | 50011: Bạn không có quyền quản lý tài khoản. | **PASS** |
| 59 | **Q05** | Các cột tổng và tinh_trang của mọi phiếu test khớp với dòng chi tiết | 0 phiếu bị lệch | 0 phiếu bị lệch trên tổng 7 phiếu | **PASS** |

---

## 3. CÁC LỆNH ĐÃ THỰC THI (POWERSHELL & SQLCMD)

```powershell
# 1. Tạo database kiểm thử
sqlcmd -S "." -E -Q "IF DB_ID('SE104_Test') IS NULL CREATE DATABASE SE104_Test;"

# 2. Khởi tạo schema, dữ liệu mẫu và thủ tục phiên bản v3
sqlcmd -S "." -E -d SE104_Test -f 65001 -i .\sql\services-security-v3.sql

# 3. Chạy toàn bộ 59 ca test tự động và xuất báo cáo
sqlcmd -S "." -E -d SE104_Test -f 65001 -i .\sql\service-security_tests-v3.sql -W
sqlcmd -S "." -E -d SE104_Test -f 65001 -i .\sql\service-security_tests-v3.sql -W -s "|" -o .\evidence\test-output.txt
```
