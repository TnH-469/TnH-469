/* =====================================================================
   MODULE DỊCH VỤ + PHÂN QUYỀN  – PHIÊN BẢN v3  (Nhóm 28 – SE104 – Phúc, Data 3)
   Bao gồm: PHIEU_DICH_VU, CT_PHIEU_DICH_VU, THAM_SO,
            NGUOI_DUNG, NHOM_NGUOI_DUNG, QUYEN, PHAN_QUYEN
   Hệ quản trị: SQL Server 2016 SP1 trở lên (dùng CREATE OR ALTER, THROW).

   v3 so với v2: thêm sp_ThemTaiKhoan và sp_SuaNhom (theo yêu cầu của UI11, UI12).
   Đã chạy thật trên SQL Server 2022 Express: v2 33/33 ca PASS (09/11/2026); v3 59/59 ca PASS (12/11/2026, phủ 28/29 mã lỗi nghiệp vụ).

   QUYẾT ĐỊNH ĐANG DÙNG (xem sheet 'Cần xác nhận'):
     Q02 (đã chốt, chờ Nguyên): cho phép nhiều dòng cùng loại dịch vụ; khóa dòng = (so_phieu, stt).
     Q03 (đã chốt): phương án A – khi giao, ghi đè tra_truoc = thanh_tien, con_lai = 0.
     Q05 (tạm theo đề xuất): các cột tổng và tinh_trang của phiếu là cột LƯU, cập nhật
          trong cùng transaction với thao tác lưu phiếu / xác nhận giao.
     Q08 (tạm theo đề xuất): ngay_giao là NGÀY HẸN GIAO, giữ nguyên khi giao;
          chưa lưu ngày giao thực tế.

   MÃ LỖI (THROW):
     50001 Khách hàng không tồn tại hoặc ngừng sử dụng
     50002 Phiếu không có dòng nào
     50003 Thiếu cấu hình tỷ lệ trả trước tối thiểu
     50004 Tỷ lệ cấu hình ngoài 0–100
     50005 Loại dịch vụ không tồn tại hoặc ngừng sử dụng
     50006 Số lượng < 1
     50007 Chi phí riêng < 0
     50008 Ngày giao < ngày lập
     50009 Trả trước thấp hơn mức tối thiểu
     50010 Trả trước âm hoặc vượt thành tiền
     50011 Không có quyền
     50012 Không tìm thấy dòng dịch vụ
     50013 Dòng đã được giao
     50014 Cập nhật dòng thất bại
     50015 Tài khoản không tồn tại
     50016 Không được tự khóa chính mình
     50017 Không được chuyển nhóm tài khoản quản trị hệ thống hoạt động cuối cùng
     50018 Nhóm đang có người dùng
     50019 Nhóm phải có ít nhất 1 quyền
     50020 Nhóm không tồn tại
     50021 Tỷ lệ mới ngoài 0–100
     50022 Tên nhóm đã tồn tại
     50023 Tên nhóm trống
     50024 Có mã quyền không tồn tại
     50025 Họ tên trống
     50026 Tên đăng nhập không hợp lệ (3–50 ký tự; chỉ chữ cái không dấu, số, dấu chấm, gạch dưới)
     50027 Chuỗi băm mật khẩu trống (độ dài mật khẩu 6–50 do lớp nghiệp vụ kiểm trước khi băm)
     50028 Tên đăng nhập đã được sử dụng
     50029 Không được bỏ quyền quản lý tài khoản khỏi nhóm của chính tài khoản đang đăng nhập
   ===================================================================== */
SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   0. BẢNG PHỤ THUỘC CỦA HOÀNG (chỉ tạo nếu chưa có, để module chạy độc lập)
      XÓA phần này khi ghép vào schema.sql chính.
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.KHACH_HANG', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.KHACH_HANG (
        ma_kh          int IDENTITY(1,1) NOT NULL CONSTRAINT PK_KHACH_HANG PRIMARY KEY,
        ho_ten         nvarchar(100) NOT NULL,
        so_dien_thoai  varchar(15)   NULL,
        dia_chi        nvarchar(200) NULL,
        trang_thai     bit NOT NULL CONSTRAINT DF_KHACH_HANG_trang_thai DEFAULT (1)
    );
END
GO

IF OBJECT_ID(N'dbo.LOAI_DICH_VU', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LOAI_DICH_VU (
        ma_loai_dv   int IDENTITY(1,1) NOT NULL CONSTRAINT PK_LOAI_DICH_VU PRIMARY KEY,
        ten_loai_dv  nvarchar(50) NOT NULL,
        don_gia_dv   decimal(18,0) NOT NULL CONSTRAINT CK_LOAI_DICH_VU_don_gia CHECK (don_gia_dv >= 0),
        trang_thai   bit NOT NULL CONSTRAINT DF_LOAI_DICH_VU_trang_thai DEFAULT (1)
    );
END
GO

/* ---------------------------------------------------------------------
   1. PHÂN QUYỀN: NHOM_NGUOI_DUNG, QUYEN, PHAN_QUYEN, NGUOI_DUNG
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.NHOM_NGUOI_DUNG', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NHOM_NGUOI_DUNG (
        ma_nhom   int IDENTITY(1,1) NOT NULL CONSTRAINT PK_NHOM_NGUOI_DUNG PRIMARY KEY,
        ten_nhom  nvarchar(50) NOT NULL CONSTRAINT UQ_NHOM_NGUOI_DUNG_ten UNIQUE
    );
END
GO

/* ma_quyen KHÔNG tự tăng: giá trị cố định, code ánh xạ theo số (xem seed). */
IF OBJECT_ID(N'dbo.QUYEN', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.QUYEN (
        ma_quyen   int NOT NULL CONSTRAINT PK_QUYEN PRIMARY KEY,
        ten_quyen  nvarchar(100) NOT NULL CONSTRAINT UQ_QUYEN_ten UNIQUE
    );
END
GO

IF OBJECT_ID(N'dbo.PHAN_QUYEN', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PHAN_QUYEN (
        ma_nhom   int NOT NULL,
        ma_quyen  int NOT NULL,
        CONSTRAINT PK_PHAN_QUYEN PRIMARY KEY (ma_nhom, ma_quyen),
        CONSTRAINT FK_PHAN_QUYEN_nhom  FOREIGN KEY (ma_nhom)  REFERENCES dbo.NHOM_NGUOI_DUNG (ma_nhom),
        CONSTRAINT FK_PHAN_QUYEN_quyen FOREIGN KEY (ma_quyen) REFERENCES dbo.QUYEN (ma_quyen)
    );
END
GO

/* mat_khau chỉ chứa CHUỖI BĂM (đã gồm muối nếu dùng bcrypt). trang_thai: 1 = hoạt động, 0 = bị khóa */
IF OBJECT_ID(N'dbo.NGUOI_DUNG', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NGUOI_DUNG (
        ma_nguoi_dung  int IDENTITY(1,1) NOT NULL CONSTRAINT PK_NGUOI_DUNG PRIMARY KEY,
        ten_dang_nhap  varchar(50)   NOT NULL CONSTRAINT UQ_NGUOI_DUNG_ten UNIQUE,
        mat_khau       nvarchar(255) NOT NULL,
        ho_ten         nvarchar(100) NOT NULL,
        trang_thai     bit NOT NULL CONSTRAINT DF_NGUOI_DUNG_trang_thai DEFAULT (1),
        ma_nhom        int NOT NULL,
        CONSTRAINT FK_NGUOI_DUNG_nhom FOREIGN KEY (ma_nhom) REFERENCES dbo.NHOM_NGUOI_DUNG (ma_nhom)
    );
END
GO

/* ---------------------------------------------------------------------
   2. THAM_SO
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.THAM_SO', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.THAM_SO (
        ma_tham_so  varchar(50)   NOT NULL CONSTRAINT PK_THAM_SO PRIMARY KEY,
        gia_tri_so  decimal(5,2)  NOT NULL CONSTRAINT CK_THAM_SO_gia_tri CHECK (gia_tri_so >= 0),
        don_vi      nvarchar(20)  NULL,
        mo_ta       nvarchar(200) NULL
    );
END
GO

/* ---------------------------------------------------------------------
   3. PHIEU_DICH_VU, CT_PHIEU_DICH_VU
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.PHIEU_DICH_VU', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PHIEU_DICH_VU (
        so_phieu        int IDENTITY(1,1) NOT NULL CONSTRAINT PK_PHIEU_DICH_VU PRIMARY KEY,
        ngay_lap        date NOT NULL CONSTRAINT DF_PHIEU_DICH_VU_ngay_lap DEFAULT (CAST(GETDATE() AS date)),
        ma_kh           int  NOT NULL,
        tong_tien       decimal(18,0) NOT NULL CONSTRAINT DF_PDV_tong_tien DEFAULT (0),
        tong_tra_truoc  decimal(18,0) NOT NULL CONSTRAINT DF_PDV_tong_tra_truoc DEFAULT (0),
        tong_con_lai    decimal(18,0) NOT NULL CONSTRAINT DF_PDV_tong_con_lai DEFAULT (0),
        tinh_trang      nvarchar(20)  NOT NULL CONSTRAINT DF_PDV_tinh_trang DEFAULT (N'Chưa hoàn thành'),
        CONSTRAINT FK_PHIEU_DICH_VU_kh FOREIGN KEY (ma_kh) REFERENCES dbo.KHACH_HANG (ma_kh),
        CONSTRAINT CK_PDV_tong_khong_am CHECK (tong_tien >= 0 AND tong_tra_truoc >= 0 AND tong_con_lai >= 0),
        CONSTRAINT CK_PDV_tong_con_lai  CHECK (tong_con_lai = tong_tien - tong_tra_truoc),
        CONSTRAINT CK_PDV_tinh_trang    CHECK (tinh_trang IN (N'Hoàn thành', N'Chưa hoàn thành'))
    );
END
GO

/* Khóa (so_phieu, stt): stt là số thứ tự dòng trong phiếu, không đánh lại sau khi lưu.
   Các CHECK dưới đây chỉ kiểm quan hệ giữa các cột của CÙNG dòng.
   Kiểm tra tỷ lệ trả trước tối thiểu phụ thuộc THAM_SO nên nằm ở sp_LapPhieuDichVu. */
IF OBJECT_ID(N'dbo.CT_PHIEU_DICH_VU', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CT_PHIEU_DICH_VU (
        so_phieu       int NOT NULL,
        stt            int NOT NULL,
        ma_loai_dv     int NOT NULL,
        so_luong       int NOT NULL,
        ngay_giao      date NOT NULL,
        don_gia_dv     decimal(18,0) NOT NULL,   -- bản chụp giá lúc lập phiếu
        chi_phi_rieng  decimal(18,0) NOT NULL CONSTRAINT DF_CT_PDV_chi_phi DEFAULT (0),
        don_gia_tinh   decimal(18,0) NOT NULL,
        thanh_tien     decimal(18,0) NOT NULL,
        tra_truoc      decimal(18,0) NOT NULL,
        con_lai        decimal(18,0) NOT NULL,
        tinh_trang     nvarchar(20)  NOT NULL CONSTRAINT DF_CT_PDV_tinh_trang DEFAULT (N'Chưa giao'),
        CONSTRAINT PK_CT_PHIEU_DICH_VU PRIMARY KEY (so_phieu, stt),
        CONSTRAINT FK_CT_PDV_phieu FOREIGN KEY (so_phieu)   REFERENCES dbo.PHIEU_DICH_VU (so_phieu),
        CONSTRAINT FK_CT_PDV_loai  FOREIGN KEY (ma_loai_dv) REFERENCES dbo.LOAI_DICH_VU (ma_loai_dv),
        CONSTRAINT CK_CT_PDV_stt        CHECK (stt >= 1),
        CONSTRAINT CK_CT_PDV_so_luong   CHECK (so_luong >= 1),
        CONSTRAINT CK_CT_PDV_gia        CHECK (don_gia_dv >= 0 AND chi_phi_rieng >= 0),
        CONSTRAINT CK_CT_PDV_don_gia_tinh CHECK (don_gia_tinh = don_gia_dv + chi_phi_rieng),
        CONSTRAINT CK_CT_PDV_thanh_tien CHECK (thanh_tien = so_luong * don_gia_tinh),
        CONSTRAINT CK_CT_PDV_tra_truoc  CHECK (tra_truoc >= 0 AND tra_truoc <= thanh_tien),
        CONSTRAINT CK_CT_PDV_con_lai    CHECK (con_lai = thanh_tien - tra_truoc),
        CONSTRAINT CK_CT_PDV_tinh_trang CHECK (tinh_trang IN (N'Chưa giao', N'Đã giao'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PHIEU_DICH_VU_ngay_lap' AND object_id = OBJECT_ID(N'dbo.PHIEU_DICH_VU'))
    CREATE INDEX IX_PHIEU_DICH_VU_ngay_lap ON dbo.PHIEU_DICH_VU (ngay_lap);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PHIEU_DICH_VU_tinh_trang' AND object_id = OBJECT_ID(N'dbo.PHIEU_DICH_VU'))
    CREATE INDEX IX_PHIEU_DICH_VU_tinh_trang ON dbo.PHIEU_DICH_VU (tinh_trang);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PHIEU_DICH_VU_ma_kh' AND object_id = OBJECT_ID(N'dbo.PHIEU_DICH_VU'))
    CREATE INDEX IX_PHIEU_DICH_VU_ma_kh ON dbo.PHIEU_DICH_VU (ma_kh);
GO

/* ---------------------------------------------------------------------
   4. KIỂU BẢNG DÙNG ĐỂ TRUYỀN DANH SÁCH VÀO THỦ TỤC
   --------------------------------------------------------------------- */
IF TYPE_ID(N'dbo.DongDichVuType') IS NULL
    CREATE TYPE dbo.DongDichVuType AS TABLE (
        stt            int NOT NULL PRIMARY KEY,
        ma_loai_dv     int NOT NULL,
        so_luong       int NOT NULL,
        chi_phi_rieng  decimal(18,0) NOT NULL DEFAULT (0),
        tra_truoc      decimal(18,0) NOT NULL,
        ngay_giao      date NOT NULL
    );
GO

IF TYPE_ID(N'dbo.DanhSachQuyenType') IS NULL
    CREATE TYPE dbo.DanhSachQuyenType AS TABLE (
        ma_quyen int NOT NULL PRIMARY KEY
    );
GO

/* ---------------------------------------------------------------------
   5. DỮ LIỆU KHỞI TẠO (seed)
   --------------------------------------------------------------------- */
-- 5.1 Tham số: đúng 1 dòng. Ứng dụng chỉ nên được SELECT và UPDATE bảng này.
IF NOT EXISTS (SELECT 1 FROM dbo.THAM_SO WHERE ma_tham_so = 'TyLeTraTruocToiThieu')
    INSERT dbo.THAM_SO (ma_tham_so, gia_tri_so, don_vi, mo_ta)
    VALUES ('TyLeTraTruocToiThieu', 50, N'%',
            N'Tỷ lệ trả trước tối thiểu trên thành tiền từng dòng dịch vụ');
GO

-- 5.2 Quyền: mã cố định, code ánh xạ theo số này
INSERT dbo.QUYEN (ma_quyen, ten_quyen)
SELECT v.ma_quyen, v.ten_quyen
FROM (VALUES
    (1,  N'QL_TAI_KHOAN – Quản lý tài khoản và nhóm quyền (UC07, UC08)'),
    (2,  N'LAP_PHIEU_MUA – Lập phiếu mua hàng (UC02)'),
    (3,  N'LAP_PHIEU_BAN – Lập phiếu bán hàng (UC01)'),
    (4,  N'LAP_PHIEU_DV – Lập phiếu dịch vụ (UC03)'),
    (5,  N'TRA_CUU – Tra cứu sản phẩm và phiếu dịch vụ (UC04)'),
    (6,  N'XAC_NHAN_GIAO – Xác nhận giao dòng dịch vụ (UC04, luồng A2)'),
    (7,  N'BAO_CAO_TON – Lập báo cáo tồn kho (UC05)'),
    (8,  N'QL_DANH_MUC – Quản lý danh mục (UC06)'),
    (9,  N'THEM_NHANH_KH – Thêm nhanh khách hàng (UC01, UC03)'),
    (10, N'THEM_NHANH_NCC – Thêm nhanh nhà cung cấp (UC02)'),
    (11, N'DOI_QUY_DINH – Thay đổi quy định (UC10)')
) AS v(ma_quyen, ten_quyen)
WHERE NOT EXISTS (SELECT 1 FROM dbo.QUYEN q WHERE q.ma_quyen = v.ma_quyen);
GO

-- 5.3 Bốn nhóm mặc định
INSERT dbo.NHOM_NGUOI_DUNG (ten_nhom)
SELECT v.ten_nhom
FROM (VALUES (N'Nhân viên Bán hàng'), (N'Nhân viên Kho'), (N'Quản lý Cửa hàng'), (N'Quản trị hệ thống')) AS v(ten_nhom)
WHERE NOT EXISTS (SELECT 1 FROM dbo.NHOM_NGUOI_DUNG n WHERE n.ten_nhom = v.ten_nhom);
GO

-- 5.4 Phân quyền theo Bảng 1.10 (và mục 1.2.5 cho thêm nhanh)
INSERT dbo.PHAN_QUYEN (ma_nhom, ma_quyen)
SELECT n.ma_nhom, v.ma_quyen
FROM (VALUES
    (N'Quản trị hệ thống', 1),
    (N'Quản lý Cửa hàng', 2), (N'Quản lý Cửa hàng', 3), (N'Quản lý Cửa hàng', 4), (N'Quản lý Cửa hàng', 5),
    (N'Quản lý Cửa hàng', 6), (N'Quản lý Cửa hàng', 7), (N'Quản lý Cửa hàng', 8), (N'Quản lý Cửa hàng', 9),
    (N'Quản lý Cửa hàng', 10), (N'Quản lý Cửa hàng', 11),
    (N'Nhân viên Bán hàng', 3), (N'Nhân viên Bán hàng', 4), (N'Nhân viên Bán hàng', 5),
    (N'Nhân viên Bán hàng', 6), (N'Nhân viên Bán hàng', 9),
    (N'Nhân viên Kho', 2), (N'Nhân viên Kho', 5), (N'Nhân viên Kho', 7), (N'Nhân viên Kho', 10)
) AS v(ten_nhom, ma_quyen)
JOIN dbo.NHOM_NGUOI_DUNG n ON n.ten_nhom = v.ten_nhom
WHERE NOT EXISTS (SELECT 1 FROM dbo.PHAN_QUYEN p WHERE p.ma_nhom = n.ma_nhom AND p.ma_quyen = v.ma_quyen);
GO

/* 5.5 Tài khoản DEMO. Mật khẩu của cả 4 tài khoản: Demo@12345
       Chuỗi băm là bcrypt (có muối trong chuỗi). Nếu nhóm chọn thuật toán khác ở H04
       thì phải tạo lại chuỗi băm. KHÔNG dùng các tài khoản này ngoài môi trường demo. */
INSERT dbo.NGUOI_DUNG (ten_dang_nhap, mat_khau, ho_ten, trang_thai, ma_nhom)
SELECT v.ten_dang_nhap, N'$2b$12$MQkLqml.3tp4V4Ta04j0s.iAjNJIDCaFo7.26qQsmCXCLyH6XDyji',
       v.ho_ten, 1, n.ma_nhom
FROM (VALUES
    ('admin',  N'Quản trị hệ thống (demo)', N'Quản trị hệ thống'),
    ('quanly', N'Quản lý cửa hàng (demo)',  N'Quản lý Cửa hàng'),
    ('nvban',  N'Nhân viên bán hàng (demo)', N'Nhân viên Bán hàng'),
    ('nvkho',  N'Nhân viên kho (demo)',     N'Nhân viên Kho')
) AS v(ten_dang_nhap, ho_ten, ten_nhom)
JOIN dbo.NHOM_NGUOI_DUNG n ON n.ten_nhom = v.ten_nhom
WHERE NOT EXISTS (SELECT 1 FROM dbo.NGUOI_DUNG u WHERE u.ten_dang_nhap = v.ten_dang_nhap);
GO

/* ---------------------------------------------------------------------
   6. HÀM VÀ THỦ TỤC NGHIỆP VỤ
      Đây là bản tham chiếu luật nghiệp vụ để kiểm thử ở mức CSDL.
      Lớp Business bằng C# vẫn phải kiểm quyền và luật; không chỉ dựa vào UI.
   --------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION dbo.fn_CoQuyen (@ma_nguoi_dung int, @ma_quyen int)
RETURNS bit
AS
BEGIN
    RETURN CASE WHEN EXISTS (
                    SELECT 1
                    FROM dbo.NGUOI_DUNG u
                    JOIN dbo.PHAN_QUYEN pq ON pq.ma_nhom = u.ma_nhom
                    WHERE u.ma_nguoi_dung = @ma_nguoi_dung
                      AND u.trang_thai = 1
                      AND pq.ma_quyen = @ma_quyen)
                THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
END
GO

-- UC09: lấy thông tin để ứng dụng tự kiểm tra băm mật khẩu và trang_thai.
-- Ứng dụng phải từ chối nếu không có dòng nào, sai mật khẩu hoặc trang_thai = 0.
CREATE OR ALTER PROCEDURE dbo.sp_LayNguoiDungDeDangNhap
    @ten_dang_nhap varchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ma_nguoi_dung, ten_dang_nhap, mat_khau, ho_ten, trang_thai, ma_nhom
    FROM dbo.NGUOI_DUNG
    WHERE ten_dang_nhap = @ten_dang_nhap;
END
GO

-- UC09/UI02: danh sách quyền của nhóm để dựng menu theo vai trò
CREATE OR ALTER PROCEDURE dbo.sp_LayQuyenCuaNhom
    @ma_nhom int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT q.ma_quyen, q.ten_quyen
    FROM dbo.PHAN_QUYEN p
    JOIN dbo.QUYEN q ON q.ma_quyen = p.ma_quyen
    WHERE p.ma_nhom = @ma_nhom
    ORDER BY q.ma_quyen;
END
GO

-- UC03: lập phiếu dịch vụ (QĐ3). @ngay_lap = NULL nghĩa là hôm nay.
-- Giao diện không cho người dùng sửa ngày lập; tham số này chỉ để kiểm thử.
CREATE OR ALTER PROCEDURE dbo.sp_LapPhieuDichVu
    @ma_nguoi_dung int,
    @ma_kh         int,
    @ngay_lap      date,
    @dong          dbo.DongDichVuType READONLY,
    @so_phieu      int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @so_phieu = NULL;
    SET @ngay_lap = ISNULL(@ngay_lap, CAST(GETDATE() AS date));

    DECLARE @ty_le decimal(5,2), @tt decimal(18,0), @min_tra bigint, @msg nvarchar(400);

    BEGIN TRY
        IF dbo.fn_CoQuyen(@ma_nguoi_dung, 4) = 0
            THROW 50011, N'Bạn không có quyền lập phiếu dịch vụ.', 1;
        IF NOT EXISTS (SELECT 1 FROM @dong)
            THROW 50002, N'Phiếu dịch vụ phải có ít nhất 01 dòng dịch vụ.', 1;

        BEGIN TRANSACTION;

        -- Kiểm tra lại danh mục còn hoạt động tại thời điểm lưu
        IF NOT EXISTS (SELECT 1 FROM dbo.KHACH_HANG WITH (HOLDLOCK) WHERE ma_kh = @ma_kh AND trang_thai = 1)
            THROW 50001, N'Khách hàng không tồn tại hoặc đã ngừng sử dụng.', 1;

        -- Đọc tỷ lệ và giữ khóa đến hết giao dịch: Quản lý không đổi được giữa chừng
        SELECT @ty_le = gia_tri_so FROM dbo.THAM_SO WITH (HOLDLOCK) WHERE ma_tham_so = 'TyLeTraTruocToiThieu';
        IF @ty_le IS NULL
            THROW 50003, N'Chưa cấu hình tỷ lệ trả trước tối thiểu (THAM_SO).', 1;
        IF @ty_le < 0 OR @ty_le > 100
            THROW 50004, N'Tỷ lệ trả trước tối thiểu trong THAM_SO phải nằm từ 0 đến 100.', 1;

        SELECT d.stt, d.ma_loai_dv, d.so_luong, d.chi_phi_rieng, d.tra_truoc, d.ngay_giao,
               l.don_gia_dv, l.trang_thai AS loai_trang_thai
        INTO #dong
        FROM @dong AS d
        LEFT JOIN dbo.LOAI_DICH_VU AS l WITH (HOLDLOCK) ON l.ma_loai_dv = d.ma_loai_dv;

        IF EXISTS (SELECT 1 FROM #dong WHERE don_gia_dv IS NULL OR loai_trang_thai = 0)
            THROW 50005, N'Loại dịch vụ không tồn tại hoặc đã ngừng sử dụng.', 1;
        IF EXISTS (SELECT 1 FROM #dong WHERE so_luong < 1)
            THROW 50006, N'Số lượng của mỗi dòng phải từ 1 trở lên.', 1;
        IF EXISTS (SELECT 1 FROM #dong WHERE chi_phi_rieng < 0)
            THROW 50007, N'Chi phí riêng không được âm.', 1;
        IF EXISTS (SELECT 1 FROM #dong WHERE ngay_giao < @ngay_lap)
            THROW 50008, N'Ngày giao không được nhỏ hơn ngày lập phiếu.', 1;

        SELECT *,
               don_gia_dv + chi_phi_rieng                  AS don_gia_tinh,
               so_luong * (don_gia_dv + chi_phi_rieng)     AS thanh_tien
        INTO #dong2
        FROM #dong;

        IF EXISTS (SELECT 1 FROM #dong2 WHERE tra_truoc < 0 OR tra_truoc > thanh_tien)
            THROW 50010, N'Tiền trả trước không được âm hoặc vượt thành tiền của dòng.', 1;

        -- So sánh không làm tròn: tra_truoc * 100 >= thanh_tien * ty_le
        SELECT TOP (1) @tt = thanh_tien
        FROM #dong2
        WHERE tra_truoc * 100 < thanh_tien * @ty_le
        ORDER BY stt;
        IF @@ROWCOUNT > 0
        BEGIN
            SET @min_tra = CAST(CEILING(@tt * @ty_le / 100.0) AS bigint);
            SET @msg = CONCAT(N'Tiền trả trước tối thiểu của dòng là ', @min_tra,
                              N' (', @ty_le, N'%% của thành tiền ', CAST(@tt AS bigint), N').');
            THROW 50009, @msg, 1;
        END

        INSERT dbo.PHIEU_DICH_VU (ngay_lap, ma_kh, tong_tien, tong_tra_truoc, tong_con_lai, tinh_trang)
        SELECT @ngay_lap, @ma_kh, SUM(thanh_tien), SUM(tra_truoc), SUM(thanh_tien - tra_truoc), N'Chưa hoàn thành'
        FROM #dong2;
        SET @so_phieu = SCOPE_IDENTITY();

        INSERT dbo.CT_PHIEU_DICH_VU
            (so_phieu, stt, ma_loai_dv, so_luong, ngay_giao, don_gia_dv, chi_phi_rieng,
             don_gia_tinh, thanh_tien, tra_truoc, con_lai, tinh_trang)
        SELECT @so_phieu, stt, ma_loai_dv, so_luong, ngay_giao, don_gia_dv, chi_phi_rieng,
               don_gia_tinh, thanh_tien, tra_truoc, thanh_tien - tra_truoc, N'Chưa giao'
        FROM #dong2;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @so_phieu = NULL;
        THROW;
    END CATCH
END
GO

-- UC04 luồng A2: xác nhận giao một dòng (QĐ4). Theo giả định Q03 phương án A.
CREATE OR ALTER PROCEDURE dbo.sp_XacNhanGiaoDong
    @ma_nguoi_dung int,
    @so_phieu      int,
    @stt           int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @tinh_trang nvarchar(20);

    BEGIN TRY
        IF dbo.fn_CoQuyen(@ma_nguoi_dung, 6) = 0
            THROW 50011, N'Bạn không có quyền xác nhận giao dịch vụ.', 1;

        BEGIN TRANSACTION;

        -- Khóa dòng: hai lần bấm hoặc hai người cùng bấm chỉ một lần thành công
        SELECT @tinh_trang = tinh_trang
        FROM dbo.CT_PHIEU_DICH_VU WITH (UPDLOCK, HOLDLOCK)
        WHERE so_phieu = @so_phieu AND stt = @stt;
        IF @@ROWCOUNT = 0
            THROW 50012, N'Không tìm thấy dòng dịch vụ.', 1;
        IF @tinh_trang <> N'Chưa giao'
            THROW 50013, N'Dòng dịch vụ này đã được giao, không thể xác nhận lại.', 1;

        UPDATE dbo.CT_PHIEU_DICH_VU
        SET tra_truoc = thanh_tien,
            con_lai   = 0,
            tinh_trang = N'Đã giao'
        WHERE so_phieu = @so_phieu AND stt = @stt AND tinh_trang = N'Chưa giao';
        IF @@ROWCOUNT <> 1
            THROW 50014, N'Cập nhật dòng dịch vụ thất bại.', 1;

        -- Đồng bộ các cột tổng và tình trạng phiếu (QĐ4, Q05)
        UPDATE p
        SET tong_tien      = x.tong_tien,
            tong_tra_truoc = x.tong_tra_truoc,
            tong_con_lai   = x.tong_con_lai,
            tinh_trang     = CASE WHEN x.so_chua_giao = 0 THEN N'Hoàn thành' ELSE N'Chưa hoàn thành' END
        FROM dbo.PHIEU_DICH_VU AS p
        CROSS APPLY (
            SELECT SUM(thanh_tien) AS tong_tien,
                   SUM(tra_truoc)  AS tong_tra_truoc,
                   SUM(con_lai)    AS tong_con_lai,
                   SUM(CASE WHEN tinh_trang = N'Chưa giao' THEN 1 ELSE 0 END) AS so_chua_giao
            FROM dbo.CT_PHIEU_DICH_VU
            WHERE so_phieu = p.so_phieu
        ) AS x
        WHERE p.so_phieu = @so_phieu;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- UC10: đổi tỷ lệ trả trước tối thiểu. Chỉ ảnh hưởng phiếu lập sau đó.
CREATE OR ALTER PROCEDURE dbo.sp_DoiTyLeTraTruoc
    @ma_nguoi_dung int,
    @gia_tri       decimal(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    IF dbo.fn_CoQuyen(@ma_nguoi_dung, 11) = 0
        THROW 50011, N'Bạn không có quyền thay đổi quy định.', 1;
    IF @gia_tri IS NULL OR @gia_tri < 0 OR @gia_tri > 100
        THROW 50021, N'Tỷ lệ trả trước tối thiểu phải nằm từ 0 đến 100.', 1;

    UPDATE dbo.THAM_SO SET gia_tri_so = @gia_tri WHERE ma_tham_so = 'TyLeTraTruocToiThieu';
    IF @@ROWCOUNT = 0
        THROW 50003, N'Chưa cấu hình tỷ lệ trả trước tối thiểu (THAM_SO).', 1;
END
GO

-- UC07: khóa (@khoa = 1) hoặc mở khóa (@khoa = 0). Hộp thoại xác nhận nằm ở giao diện.
CREATE OR ALTER PROCEDURE dbo.sp_KhoaMoKhoaTaiKhoan
    @ma_nguoi_thuc_hien int,
    @ma_nguoi_dung      int,
    @khoa               bit
AS
BEGIN
    SET NOCOUNT ON;
    IF dbo.fn_CoQuyen(@ma_nguoi_thuc_hien, 1) = 0
        THROW 50011, N'Bạn không có quyền quản lý tài khoản.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.NGUOI_DUNG WHERE ma_nguoi_dung = @ma_nguoi_dung)
        THROW 50015, N'Tài khoản không tồn tại.', 1;
    IF @khoa = 1 AND @ma_nguoi_thuc_hien = @ma_nguoi_dung
        THROW 50016, N'Không thể tự khóa tài khoản đang đăng nhập.', 1;

    UPDATE dbo.NGUOI_DUNG
    SET trang_thai = CASE WHEN @khoa = 1 THEN 0 ELSE 1 END
    WHERE ma_nguoi_dung = @ma_nguoi_dung;
END
GO

-- UC07: sửa thông tin tài khoản, chặn chuyển nhóm tài khoản quản trị hệ thống hoạt động cuối cùng.
CREATE OR ALTER PROCEDURE dbo.sp_SuaTaiKhoan
    @ma_nguoi_thuc_hien int,
    @ma_nguoi_dung      int,
    @ho_ten             nvarchar(100),
    @ma_nhom_moi        int,
    @mat_khau_bam_moi   nvarchar(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ho_ten = LTRIM(RTRIM(@ho_ten));

    BEGIN TRY
        IF dbo.fn_CoQuyen(@ma_nguoi_thuc_hien, 1) = 0
            THROW 50011, N'Bạn không có quyền quản lý tài khoản.', 1;
        IF @ho_ten IS NULL OR @ho_ten = N''
            THROW 50025, N'Họ tên không được để trống.', 1;

        BEGIN TRANSACTION;

        DECLARE @ma_nhom_cu int, @trang_thai bit;
        SELECT @ma_nhom_cu = ma_nhom, @trang_thai = trang_thai
        FROM dbo.NGUOI_DUNG WITH (UPDLOCK, HOLDLOCK)
        WHERE ma_nguoi_dung = @ma_nguoi_dung;

        IF @@ROWCOUNT = 0
            THROW 50015, N'Tài khoản không tồn tại.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NHOM_NGUOI_DUNG WITH (HOLDLOCK) WHERE ma_nhom = @ma_nhom_moi)
            THROW 50020, N'Nhóm không tồn tại.', 1;

        -- Chặn chuyển nhóm nếu đây là tài khoản quản trị hệ thống đang hoạt động cuối cùng
        IF @trang_thai = 1
           AND EXISTS (SELECT 1 FROM dbo.PHAN_QUYEN WHERE ma_nhom = @ma_nhom_cu AND ma_quyen = 1)
           AND NOT EXISTS (SELECT 1 FROM dbo.PHAN_QUYEN WHERE ma_nhom = @ma_nhom_moi AND ma_quyen = 1)
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.NGUOI_DUNG u WITH (HOLDLOCK)
                JOIN dbo.PHAN_QUYEN pq ON pq.ma_nhom = u.ma_nhom
                WHERE u.ma_nguoi_dung <> @ma_nguoi_dung
                  AND u.trang_thai = 1
                  AND pq.ma_quyen = 1
            )
                THROW 50017, N'Không thể chuyển nhóm cho tài khoản quản trị hệ thống đang hoạt động cuối cùng.', 1;
        END

        UPDATE dbo.NGUOI_DUNG
        SET ho_ten   = @ho_ten,
            ma_nhom  = @ma_nhom_moi,
            mat_khau = ISNULL(@mat_khau_bam_moi, mat_khau)
        WHERE ma_nguoi_dung = @ma_nguoi_dung;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- UC08: thêm nhóm, bắt buộc có ít nhất 1 quyền (DB không tự ép được điều này)
CREATE OR ALTER PROCEDURE dbo.sp_ThemNhom
    @ma_nguoi_dung int,
    @ten_nhom      nvarchar(50),
    @ds_quyen      dbo.DanhSachQuyenType READONLY,
    @ma_nhom       int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ma_nhom = NULL;
    SET @ten_nhom = LTRIM(RTRIM(@ten_nhom));

    BEGIN TRY
        IF dbo.fn_CoQuyen(@ma_nguoi_dung, 1) = 0
            THROW 50011, N'Bạn không có quyền quản lý nhóm người dùng.', 1;
        IF @ten_nhom IS NULL OR @ten_nhom = N''
            THROW 50023, N'Tên nhóm không được để trống.', 1;
        IF NOT EXISTS (SELECT 1 FROM @ds_quyen)
            THROW 50019, N'Nhóm phải được cấp ít nhất 01 quyền.', 1;
        IF EXISTS (SELECT 1 FROM @ds_quyen AS q WHERE NOT EXISTS (SELECT 1 FROM dbo.QUYEN AS r WHERE r.ma_quyen = q.ma_quyen))
            THROW 50024, N'Danh sách có mã quyền không tồn tại.', 1;

        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.NHOM_NGUOI_DUNG WITH (UPDLOCK, HOLDLOCK) WHERE ten_nhom = @ten_nhom)
            THROW 50022, N'Tên nhóm đã tồn tại.', 1;

        INSERT dbo.NHOM_NGUOI_DUNG (ten_nhom) VALUES (@ten_nhom);
        SET @ma_nhom = SCOPE_IDENTITY();

        INSERT dbo.PHAN_QUYEN (ma_nhom, ma_quyen)
        SELECT @ma_nhom, ma_quyen FROM @ds_quyen;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ma_nhom = NULL;
        THROW;
    END CATCH
END
GO

-- UC08: xóa nhóm, từ chối nếu còn người dùng. FK NGUOI_DUNG -> nhóm không cascade,
-- nên nếu có người được gán vào nhóm sau bước kiểm tra thì lệnh xóa vẫn thất bại và hoàn tác.
CREATE OR ALTER PROCEDURE dbo.sp_XoaNhom
    @ma_nguoi_dung int,
    @ma_nhom       int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF dbo.fn_CoQuyen(@ma_nguoi_dung, 1) = 0
            THROW 50011, N'Bạn không có quyền quản lý nhóm người dùng.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NHOM_NGUOI_DUNG WHERE ma_nhom = @ma_nhom)
            THROW 50020, N'Nhóm không tồn tại.', 1;
        IF EXISTS (SELECT 1 FROM dbo.NGUOI_DUNG WHERE ma_nhom = @ma_nhom)
            THROW 50018, N'Nhóm đang có người dùng, không thể xóa.', 1;

        BEGIN TRANSACTION;
        DELETE FROM dbo.PHAN_QUYEN WHERE ma_nhom = @ma_nhom;
        DELETE FROM dbo.NHOM_NGUOI_DUNG WHERE ma_nhom = @ma_nhom;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- UC07: thêm tài khoản (UI11). Mật khẩu nhận vào là CHUỖI BĂM; lớp nghiệp vụ phải kiểm độ dài
-- mật khẩu gốc (6–50 ký tự) rồi băm trước khi gọi thủ tục này.
CREATE OR ALTER PROCEDURE dbo.sp_ThemTaiKhoan
    @ma_nguoi_thuc_hien int,
    @ten_dang_nhap      varchar(50),
    @mat_khau_bam       nvarchar(255),
    @ho_ten             nvarchar(100),
    @ma_nhom            int,
    @ma_nguoi_dung      int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ma_nguoi_dung = NULL;
    SET @ten_dang_nhap = LTRIM(RTRIM(@ten_dang_nhap));
    SET @ho_ten = LTRIM(RTRIM(@ho_ten));

    BEGIN TRY
        IF dbo.fn_CoQuyen(@ma_nguoi_thuc_hien, 1) = 0
            THROW 50011, N'Bạn không có quyền quản lý tài khoản.', 1;
        IF @ten_dang_nhap IS NULL OR LEN(@ten_dang_nhap) < 3
           OR @ten_dang_nhap COLLATE Latin1_General_BIN LIKE '%[^A-Za-z0-9._]%'
            THROW 50026, N'Tên đăng nhập phải từ 3 đến 50 ký tự, chỉ gồm chữ cái không dấu, số, dấu chấm và gạch dưới.', 1;
        IF @mat_khau_bam IS NULL OR LTRIM(RTRIM(@mat_khau_bam)) = N''
            THROW 50027, N'Mật khẩu không được để trống.', 1;
        IF @ho_ten IS NULL OR @ho_ten = N''
            THROW 50025, N'Họ tên không được để trống.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.NHOM_NGUOI_DUNG WITH (HOLDLOCK) WHERE ma_nhom = @ma_nhom)
            THROW 50020, N'Nhóm không tồn tại.', 1;
        IF EXISTS (SELECT 1 FROM dbo.NGUOI_DUNG WITH (UPDLOCK, HOLDLOCK) WHERE ten_dang_nhap = @ten_dang_nhap)
            THROW 50028, N'Tên đăng nhập đã được sử dụng.', 1;

        INSERT dbo.NGUOI_DUNG (ten_dang_nhap, mat_khau, ho_ten, trang_thai, ma_nhom)
        VALUES (@ten_dang_nhap, @mat_khau_bam, @ho_ten, 1, @ma_nhom);
        SET @ma_nguoi_dung = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ma_nguoi_dung = NULL;
        THROW;
    END CATCH
END
GO

-- UC08: sửa nhóm (đổi tên và thay toàn bộ danh sách quyền) – UI12.
-- Không cho bỏ quyền QL_TAI_KHOAN (mã 1) khỏi nhóm của chính người đang thực hiện,
-- nếu không người đó mất quyền ngay trong lúc sửa.
CREATE OR ALTER PROCEDURE dbo.sp_SuaNhom
    @ma_nguoi_thuc_hien int,
    @ma_nhom            int,
    @ten_nhom           nvarchar(50),
    @ds_quyen           dbo.DanhSachQuyenType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ten_nhom = LTRIM(RTRIM(@ten_nhom));

    BEGIN TRY
        IF dbo.fn_CoQuyen(@ma_nguoi_thuc_hien, 1) = 0
            THROW 50011, N'Bạn không có quyền quản lý nhóm người dùng.', 1;
        IF @ten_nhom IS NULL OR @ten_nhom = N''
            THROW 50023, N'Tên nhóm không được để trống.', 1;
        IF NOT EXISTS (SELECT 1 FROM @ds_quyen)
            THROW 50019, N'Nhóm phải được cấp ít nhất 01 quyền.', 1;
        IF EXISTS (SELECT 1 FROM @ds_quyen AS q WHERE NOT EXISTS (SELECT 1 FROM dbo.QUYEN AS r WHERE r.ma_quyen = q.ma_quyen))
            THROW 50024, N'Danh sách có mã quyền không tồn tại.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.NHOM_NGUOI_DUNG WITH (UPDLOCK, HOLDLOCK) WHERE ma_nhom = @ma_nhom)
            THROW 50020, N'Nhóm không tồn tại.', 1;
        IF EXISTS (SELECT 1 FROM dbo.NHOM_NGUOI_DUNG WHERE ten_nhom = @ten_nhom AND ma_nhom <> @ma_nhom)
            THROW 50022, N'Tên nhóm đã tồn tại.', 1;
        IF NOT EXISTS (SELECT 1 FROM @ds_quyen WHERE ma_quyen = 1)
           AND EXISTS (SELECT 1 FROM dbo.NGUOI_DUNG WHERE ma_nguoi_dung = @ma_nguoi_thuc_hien AND ma_nhom = @ma_nhom)
            THROW 50029, N'Không thể bỏ quyền quản lý tài khoản khỏi nhóm của tài khoản đang đăng nhập.', 1;

        UPDATE dbo.NHOM_NGUOI_DUNG SET ten_nhom = @ten_nhom WHERE ma_nhom = @ma_nhom;

        DELETE pq
        FROM dbo.PHAN_QUYEN AS pq
        WHERE pq.ma_nhom = @ma_nhom
          AND NOT EXISTS (SELECT 1 FROM @ds_quyen AS q WHERE q.ma_quyen = pq.ma_quyen);

        INSERT dbo.PHAN_QUYEN (ma_nhom, ma_quyen)
        SELECT @ma_nhom, q.ma_quyen
        FROM @ds_quyen AS q
        WHERE NOT EXISTS (SELECT 1 FROM dbo.PHAN_QUYEN AS pq WHERE pq.ma_nhom = @ma_nhom AND pq.ma_quyen = q.ma_quyen);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
