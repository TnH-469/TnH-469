/* =====================================================================
   BỘ TEST v3: MODULE DỊCH VỤ + PHÂN QUYỀN  (Nhóm 28 – SE104 – Phúc)
   Gồm 33 ca của v2, 21 ca ban đầu của v3, và 5 ca bổ sung (EX04b, EX14, EX15, NH07, NH08).
   Tổng cộng 59 ca kiểm thử phủ 28/29 mã lỗi nghiệp vụ (mã 50014 là phòng thủ).
   Chạy SAU KHI đã chạy services-security-v3.sql, trên CSDL TEST.
   Script tự tạo dữ liệu có tiền tố [TEST] / test_ và tự dọn ở đầu và cuối.
   Kết quả: bảng PASS/FAIL ở cuối (59 ca kiểm thử).
   ===================================================================== */
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#kq') IS NOT NULL DROP TABLE #kq;
CREATE TABLE #kq (
    seq      int IDENTITY(1,1),
    ma       nvarchar(20),
    mo_ta    nvarchar(200),
    mong_doi nvarchar(200),
    thuc_te  nvarchar(600),
    dat      bit
);

IF OBJECT_ID('tempdb..#login') IS NOT NULL DROP TABLE #login;
CREATE TABLE #login (
    ma_nguoi_dung int, ten_dang_nhap varchar(50), mat_khau nvarchar(255),
    ho_ten nvarchar(100), trang_thai bit, ma_nhom int
);

/* ---------- 0. Dọn dữ liệu test của lần chạy trước, bảo đảm THAM_SO ---------- */
DELETE c FROM dbo.CT_PHIEU_DICH_VU c
    JOIN dbo.PHIEU_DICH_VU p ON p.so_phieu = c.so_phieu
    JOIN dbo.KHACH_HANG k ON k.ma_kh = p.ma_kh
    WHERE LEFT(k.ho_ten, 6) = N'[TEST]';
DELETE p FROM dbo.PHIEU_DICH_VU p
    JOIN dbo.KHACH_HANG k ON k.ma_kh = p.ma_kh
    WHERE LEFT(k.ho_ten, 6) = N'[TEST]';
DELETE FROM dbo.NGUOI_DUNG WHERE LEFT(ten_dang_nhap, 5) = 'test_';
DELETE FROM dbo.PHAN_QUYEN WHERE ma_nhom IN (SELECT ma_nhom FROM dbo.NHOM_NGUOI_DUNG WHERE LEFT(ten_nhom, 6) = N'[TEST]');
DELETE FROM dbo.NHOM_NGUOI_DUNG WHERE LEFT(ten_nhom, 6) = N'[TEST]';
DELETE FROM dbo.KHACH_HANG WHERE LEFT(ho_ten, 6) = N'[TEST]';
DELETE FROM dbo.LOAI_DICH_VU WHERE LEFT(ten_loai_dv, 6) = N'[TEST]';

IF NOT EXISTS (SELECT 1 FROM dbo.THAM_SO WHERE ma_tham_so = 'TyLeTraTruocToiThieu')
    INSERT dbo.THAM_SO (ma_tham_so, gia_tri_so, don_vi, mo_ta)
    VALUES ('TyLeTraTruocToiThieu', 50, N'%', N'Tỷ lệ trả trước tối thiểu trên thành tiền từng dòng dịch vụ');
ELSE
    UPDATE dbo.THAM_SO SET gia_tri_so = 50 WHERE ma_tham_so = 'TyLeTraTruocToiThieu';

/* ---------- 1. Dữ liệu test ---------- */
INSERT dbo.KHACH_HANG (ho_ten, so_dien_thoai, dia_chi, trang_thai)
VALUES (N'[TEST] Khách A', '0900000001', N'Test', 1),
       (N'[TEST] Khách đã khóa', '0900000002', N'Test', 0);

INSERT dbo.LOAI_DICH_VU (ten_loai_dv, don_gia_dv, trang_thai)
VALUES (N'[TEST] DV 1.000.000', 1000000, 1),
       (N'[TEST] DV 600.000',   600000,  1),
       (N'[TEST] DV ngừng',     100000,  0);

DECLARE @ngay date = CAST(GETDATE() AS date);
DECLARE @kh      int = (SELECT ma_kh FROM dbo.KHACH_HANG WHERE ho_ten = N'[TEST] Khách A');
DECLARE @kh_khoa int = (SELECT ma_kh FROM dbo.KHACH_HANG WHERE ho_ten = N'[TEST] Khách đã khóa');
DECLARE @ldv1 int = (SELECT ma_loai_dv FROM dbo.LOAI_DICH_VU WHERE ten_loai_dv = N'[TEST] DV 1.000.000');
DECLARE @ldv2 int = (SELECT ma_loai_dv FROM dbo.LOAI_DICH_VU WHERE ten_loai_dv = N'[TEST] DV 600.000');
DECLARE @ldv3 int = (SELECT ma_loai_dv FROM dbo.LOAI_DICH_VU WHERE ten_loai_dv = N'[TEST] DV ngừng');

DECLARE @u_admin int = (SELECT ma_nguoi_dung FROM dbo.NGUOI_DUNG WHERE ten_dang_nhap = 'admin');
DECLARE @u_ql    int = (SELECT ma_nguoi_dung FROM dbo.NGUOI_DUNG WHERE ten_dang_nhap = 'quanly');
DECLARE @u_ban   int = (SELECT ma_nguoi_dung FROM dbo.NGUOI_DUNG WHERE ten_dang_nhap = 'nvban');
DECLARE @u_kho   int = (SELECT ma_nguoi_dung FROM dbo.NGUOI_DUNG WHERE ten_dang_nhap = 'nvkho');

DECLARE @d dbo.DongDichVuType;
DECLARE @p int, @p2 int, @p3 int, @p_cu int;
DECLARE @err int, @msg nvarchar(2048), @n int;
DECLARE @a decimal(18,0), @b decimal(18,0), @s nvarchar(20), @t nvarchar(20);

/* ---------- 2. TC08: trả trước tối thiểu 50% (QĐ3) – thành tiền 1.000.000 ---------- */
-- TC08a
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 490000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC08a', N'Trả trước 490.000 < tối thiểu 500.000',
    N'Lỗi 50009, thông báo nêu mức tối thiểu 500000', CONCAT(@err, N': ', @msg),
    IIF(@err = 50009 AND @msg LIKE N'%500000%' AND @p IS NULL, 1, 0));

-- TC08b
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 500000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC08b', N'Trả trước đúng mức tối thiểu 500.000 (biên dưới)',
    N'Lưu thành công', CONCAT(N'lỗi=', @err, N' phiếu=', @p), IIF(@err = 0 AND @p IS NOT NULL, 1, 0));

-- TC08c
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 1000000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
SELECT @a = con_lai FROM dbo.CT_PHIEU_DICH_VU WHERE so_phieu = @p AND stt = 1;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC08c', N'Trả trước = thành tiền 1.000.000 (biên trên)',
    N'Lưu thành công, còn lại = 0', CONCAT(N'lỗi=', @err, N' còn lại=', @a), IIF(@err = 0 AND @a = 0, 1, 0));

-- TC08d
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 1000001, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC08d', N'Trả trước 1.000.001 > thành tiền',
    N'Lỗi 50010', CONCAT(@err, N': ', @msg), IIF(@err = 50010 AND @p IS NULL, 1, 0));

/* ---------- 3. TC09: đơn giá được tính và thành tiền ---------- */
-- giá DV 600.000, chi phí riêng 100.000, SL 2 -> đơn giá tính 700.000, thành tiền 1.400.000, tối thiểu 700.000
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv2, 2, 100000, 700000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
SELECT @a = don_gia_tinh, @b = thanh_tien FROM dbo.CT_PHIEU_DICH_VU WHERE so_phieu = @p AND stt = 1;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC09a', N'Giá DV 600.000 + phí 100.000, SL 2, trả trước 700.000',
    N'Đơn giá tính 700000; thành tiền 1400000', CONCAT(N'lỗi=', @err, N' đơn giá=', @a, N' thành tiền=', @b),
    IIF(@err = 0 AND @a = 700000 AND @b = 1400000, 1, 0));

SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv2, 2, 100000, 600000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC09b', N'Cùng dòng, trả trước 600.000 < tối thiểu 700.000',
    N'Lỗi 50009', CONCAT(@err, N': ', @msg), IIF(@err = 50009 AND @p IS NULL, 1, 0));

/* ---------- 4. TC10, TC11: giao từng dòng và hoàn thành phiếu (QĐ4) ---------- */
SELECT @p2 = NULL;
DELETE FROM @d;
INSERT @d VALUES (1, @ldv1, 1, 0, 500000, @ngay), (2, @ldv2, 1, 0, 300000, @ngay);
EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p2 OUTPUT;

SELECT @s = tinh_trang FROM dbo.PHIEU_DICH_VU WHERE so_phieu = @p2;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC10a', N'Phiếu mới 2 dòng',
    N'Phiếu Chưa hoàn thành', @s, IIF(@s = N'Chưa hoàn thành', 1, 0));

-- TC10
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_XacNhanGiaoDong @u_ban, @p2, 1; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
SELECT @s = tinh_trang FROM dbo.CT_PHIEU_DICH_VU WHERE so_phieu = @p2 AND stt = 1;
SELECT @t = tinh_trang FROM dbo.PHIEU_DICH_VU WHERE so_phieu = @p2;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC10', N'Giao dòng 1 của phiếu 2 dòng',
    N'Dòng 1 Đã giao; phiếu vẫn Chưa hoàn thành', CONCAT(N'lỗi=', @err, N'; dòng 1=', @s, N'; phiếu=', @t),
    IIF(@err = 0 AND @s = N'Đã giao' AND @t = N'Chưa hoàn thành', 1, 0));

-- TC11a
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_XacNhanGiaoDong @u_ql, @p2, 2; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
SELECT @t = tinh_trang, @a = tong_tra_truoc, @b = tong_tien FROM dbo.PHIEU_DICH_VU WHERE so_phieu = @p2;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC11a', N'Giao dòng cuối (Quản lý xác nhận)',
    N'Phiếu Hoàn thành; tổng trả trước = tổng tiền (theo Q03-A)',
    CONCAT(N'lỗi=', @err, N'; phiếu=', @t, N'; trả trước=', @a, N'; tổng tiền=', @b),
    IIF(@err = 0 AND @t = N'Hoàn thành' AND @a = @b, 1, 0));

-- TC11b
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_XacNhanGiaoDong @u_ban, @p2, 2; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC11b', N'Xác nhận lại dòng đã giao',
    N'Lỗi 50013, tiền không ghi lần hai', CONCAT(@err, N': ', @msg), IIF(@err = 50013, 1, 0));

-- EX15: Xác nhận giao dòng không tồn tại
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_XacNhanGiaoDong @u_ban, 999999, 1; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX15', N'Xác nhận giao phiếu không tồn tại',
    N'Lỗi 50012', CONCAT(@err, N': ', @msg), IIF(@err = 50012, 1, 0));

/* ---------- 5. Quyền và dữ liệu đầu vào ---------- */
-- NV kho không lập được phiếu dịch vụ
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 500000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_kho, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX01', N'NV kho lập phiếu dịch vụ',
    N'Lỗi 50011', CONCAT(@err, N': ', @msg), IIF(@err = 50011 AND @p IS NULL, 1, 0));

-- NV kho không xác nhận giao được
SELECT @p3 = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 500000, @ngay);
EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p3 OUTPUT;
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_XacNhanGiaoDong @u_kho, @p3, 1; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
SELECT @s = tinh_trang FROM dbo.CT_PHIEU_DICH_VU WHERE so_phieu = @p3 AND stt = 1;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX02', N'NV kho xác nhận giao',
    N'Lỗi 50011; dòng vẫn Chưa giao', CONCAT(@err, N'; dòng=', @s), IIF(@err = 50011 AND @s = N'Chưa giao', 1, 0));

-- Phiếu rỗng
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d;
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX03', N'Lưu phiếu không có dòng',
    N'Lỗi 50002', CONCAT(@err, N': ', @msg), IIF(@err = 50002 AND @p IS NULL, 1, 0));

-- Số lượng 0
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 0, 0, 0, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX04', N'Số lượng = 0',
    N'Lỗi 50006', CONCAT(@err, N': ', @msg), IIF(@err = 50006 AND @p IS NULL, 1, 0));

-- EX04b: Chi phí riêng âm
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, -1, 500000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX04b', N'Chi phí riêng âm (-1)',
    N'Lỗi 50007', CONCAT(@err, N': ', @msg), IIF(@err = 50007 AND @p IS NULL, 1, 0));

-- Ngày giao trước ngày lập
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 500000, DATEADD(day, -1, @ngay));
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX05', N'Ngày giao nhỏ hơn ngày lập',
    N'Lỗi 50008', CONCAT(@err, N': ', @msg), IIF(@err = 50008 AND @p IS NULL, 1, 0));

-- Khách hàng ngừng sử dụng
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 500000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh_khoa, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX06', N'Khách hàng có trang_thai = 0',
    N'Lỗi 50001', CONCAT(@err, N': ', @msg), IIF(@err = 50001 AND @p IS NULL, 1, 0));

-- Loại dịch vụ ngừng sử dụng
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv3, 1, 0, 100000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX07', N'Loại dịch vụ có trang_thai = 0',
    N'Lỗi 50005', CONCAT(@err, N': ', @msg), IIF(@err = 50005 AND @p IS NULL, 1, 0));

-- Đổi đơn giá dịch vụ không làm đổi phiếu cũ (dòng 2 của @p2 lập khi giá = 600.000)
UPDATE dbo.LOAI_DICH_VU SET don_gia_dv = 700000 WHERE ma_loai_dv = @ldv2;
SELECT @a = don_gia_dv FROM dbo.CT_PHIEU_DICH_VU WHERE so_phieu = @p2 AND stt = 2;
UPDATE dbo.LOAI_DICH_VU SET don_gia_dv = 600000 WHERE ma_loai_dv = @ldv2;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX08', N'Đổi đơn giá loại dịch vụ 600.000 -> 700.000 sau khi lập phiếu',
    N'don_gia_dv của dòng cũ vẫn 600000', CAST(@a AS nvarchar(30)), IIF(@a = 600000, 1, 0));

/* ---------- 6. TC15: đổi tỷ lệ trả trước 50% -> 60% (UC10) ---------- */
SELECT @p_cu = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 500000, @ngay);
EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p_cu OUTPUT;   -- phiếu cũ, lập ở 50%

EXEC dbo.sp_DoiTyLeTraTruoc @u_ql, 60;

SELECT @a = tra_truoc FROM dbo.CT_PHIEU_DICH_VU WHERE so_phieu = @p_cu AND stt = 1;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC15a', N'Sau khi đổi lên 60%, phiếu cũ (trả trước 500.000)',
    N'Phiếu cũ giữ nguyên trả trước 500000', CAST(@a AS nvarchar(30)), IIF(@a = 500000, 1, 0));

SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 550000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC15b', N'Phiếu mới ở 60%, trả trước 550.000',
    N'Lỗi 50009, tối thiểu 600000', CONCAT(@err, N': ', @msg), IIF(@err = 50009 AND @msg LIKE N'%600000%', 1, 0));

SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 600000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC15c', N'Phiếu mới ở 60%, trả trước 600.000',
    N'Lưu thành công', CONCAT(N'lỗi=', @err, N' phiếu=', @p), IIF(@err = 0 AND @p IS NOT NULL, 1, 0));

EXEC dbo.sp_DoiTyLeTraTruoc @u_ql, 50;   -- khôi phục

SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_DoiTyLeTraTruoc @u_ban, 70; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC15d', N'NV bán hàng đổi quy định',
    N'Lỗi 50011', CONCAT(@err, N': ', @msg), IIF(@err = 50011, 1, 0));

SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_DoiTyLeTraTruoc @u_ql, 101; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC15e', N'Đổi tỷ lệ thành 101',
    N'Lỗi 50021', CONCAT(@err, N': ', @msg), IIF(@err = 50021, 1, 0));

/* ---------- 7. Thiếu dòng cấu hình THAM_SO ---------- */
DECLARE @gt decimal(5,2) = (SELECT gia_tri_so FROM dbo.THAM_SO WHERE ma_tham_so = 'TyLeTraTruocToiThieu');
DELETE FROM dbo.THAM_SO WHERE ma_tham_so = 'TyLeTraTruocToiThieu';
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 1000000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT dbo.THAM_SO (ma_tham_so, gia_tri_so, don_vi, mo_ta)
VALUES ('TyLeTraTruocToiThieu', ISNULL(@gt, 50), N'%', N'Tỷ lệ trả trước tối thiểu trên thành tiền từng dòng dịch vụ');
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX09', N'Thiếu dòng TyLeTraTruocToiThieu trong THAM_SO',
    N'Từ chối lưu, lỗi 50003 (không tự dùng 50 ngầm)', CONCAT(@err, N': ', @msg), IIF(@err = 50003 AND @p IS NULL, 1, 0));

-- EX14: Tỷ lệ trong THAM_SO > 100
UPDATE dbo.THAM_SO SET gia_tri_so = 150 WHERE ma_tham_so = 'TyLeTraTruocToiThieu';
SELECT @err = 0, @msg = NULL, @p = NULL;
DELETE FROM @d; INSERT @d VALUES (1, @ldv1, 1, 0, 500000, @ngay);
BEGIN TRY EXEC dbo.sp_LapPhieuDichVu @u_ban, @kh, @ngay, @d, @p OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
UPDATE dbo.THAM_SO SET gia_tri_so = 50 WHERE ma_tham_so = 'TyLeTraTruocToiThieu';
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX14', N'Tỷ lệ trả trước tối thiểu trong THAM_SO > 100 (150%)',
    N'Lỗi 50004', CONCAT(@err, N': ', @msg), IIF(@err = 50004 AND @p IS NULL, 1, 0));

/* ---------- 8. Tài khoản, nhóm, quyền (UC07, UC08, UC09) ---------- */
DECLARE @nA int, @nB int, @u_test int;
DECLARE @q dbo.DanhSachQuyenType;
DECLARE @q_rong dbo.DanhSachQuyenType;
INSERT @q VALUES (5);

EXEC dbo.sp_ThemNhom @u_admin, N'[TEST] Nhóm A', @q, @nA OUTPUT;
EXEC dbo.sp_ThemNhom @u_admin, N'[TEST] Nhóm B', @q, @nB OUTPUT;
INSERT dbo.NGUOI_DUNG (ten_dang_nhap, mat_khau, ho_ten, trang_thai, ma_nhom)
VALUES ('test_u1', N'x', N'[TEST] Người dùng', 1, @nA);
SET @u_test = (SELECT ma_nguoi_dung FROM dbo.NGUOI_DUNG WHERE ten_dang_nhap = 'test_u1');

-- TC13a: xóa nhóm đang có người dùng
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_XoaNhom @u_admin, @nA; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
SELECT @n = COUNT(*) FROM dbo.NHOM_NGUOI_DUNG WHERE ma_nhom = @nA;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC13a', N'Xóa nhóm đang có người dùng',
    N'Lỗi 50018; nhóm vẫn còn', CONCAT(@err, N': ', @msg, N'; số nhóm còn=', @n), IIF(@err = 50018 AND @n = 1, 1, 0));

-- TC13b: xóa nhóm không có người dùng
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_XoaNhom @u_admin, @nB; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
SELECT @n = COUNT(*) FROM dbo.NHOM_NGUOI_DUNG WHERE ma_nhom = @nB;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC13b', N'Xóa nhóm không có người dùng',
    N'Xóa thành công', CONCAT(N'lỗi=', @err, N'; số nhóm còn=', @n), IIF(@err = 0 AND @n = 0, 1, 0));

-- Nhóm không chọn quyền
SELECT @err = 0, @msg = NULL, @n = NULL;
BEGIN TRY EXEC dbo.sp_ThemNhom @u_admin, N'[TEST] Nhóm rỗng', @q_rong, @n OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX10', N'Thêm nhóm không chọn quyền nào',
    N'Lỗi 50019, không tạo nhóm', CONCAT(@err, N': ', @msg), IIF(@err = 50019 AND @n IS NULL
    AND NOT EXISTS (SELECT 1 FROM dbo.NHOM_NGUOI_DUNG WHERE ten_nhom = N'[TEST] Nhóm rỗng'), 1, 0));

-- TC14a: khóa tài khoản
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_KhoaMoKhoaTaiKhoan @u_admin, @u_test, 1; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
DELETE FROM #login; INSERT #login EXEC dbo.sp_LayNguoiDungDeDangNhap 'test_u1';
SELECT @n = CAST(trang_thai AS int) FROM #login;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC14a', N'Khóa tài khoản test_u1',
    N'trang_thai = 0 và không còn quyền nào', CONCAT(N'lỗi=', @err, N'; trang_thai=', @n, N'; có quyền TRA_CUU=', CAST(dbo.fn_CoQuyen(@u_test, 5) AS int)),
    IIF(@err = 0 AND @n = 0 AND dbo.fn_CoQuyen(@u_test, 5) = 0, 1, 0));

-- TC14b: mở khóa
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_KhoaMoKhoaTaiKhoan @u_admin, @u_test, 0; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
DELETE FROM #login; INSERT #login EXEC dbo.sp_LayNguoiDungDeDangNhap 'test_u1';
SELECT @n = CAST(trang_thai AS int) FROM #login;
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TC14b', N'Mở khóa tài khoản test_u1',
    N'trang_thai = 1 và có lại quyền', CONCAT(N'lỗi=', @err, N'; trang_thai=', @n),
    IIF(@err = 0 AND @n = 1 AND dbo.fn_CoQuyen(@u_test, 5) = 1, 1, 0));

-- Quản trị hệ thống tự khóa chính mình
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_KhoaMoKhoaTaiKhoan @u_admin, @u_admin, 1; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX11', N'Quản trị hệ thống tự khóa chính mình',
    N'Lỗi 50016; admin vẫn hoạt động', CONCAT(@err, N': ', @msg),
    IIF(@err = 50016 AND (SELECT trang_thai FROM dbo.NGUOI_DUNG WHERE ma_nguoi_dung = @u_admin) = 1, 1, 0));

-- NV bán hàng không quản lý được tài khoản
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_KhoaMoKhoaTaiKhoan @u_ban, @u_test, 1; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX12', N'NV bán hàng khóa tài khoản người khác',
    N'Lỗi 50011', CONCAT(@err, N': ', @msg), IIF(@err = 50011, 1, 0));

-- EX13: Chuyển nhóm tài khoản quản trị hệ thống cuối cùng sang nhóm không có quyền quản trị
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaTaiKhoan @u_admin, @u_admin, N'Quản trị hệ thống (demo)', @nA, NULL; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'EX13', N'Chuyển nhóm quản trị hệ thống cuối cùng sang nhóm thường',
    N'Lỗi 50017; admin vẫn giữ quyền quản trị', CONCAT(@err, N': ', @msg),
    IIF(@err = 50017 AND dbo.fn_CoQuyen(@u_admin, 1) = 1, 1, 0));

/* ---------- 8b. v3: thêm tài khoản (sp_ThemTaiKhoan), sửa nhóm (sp_SuaNhom), sửa tài khoản (sp_SuaTaiKhoan) ----------
   21 ca mới (kết quả nằm trong test-evidence.md; toàn bộ bộ test v3 đạt 59/59 PASS ngày 12/11/2026). */
DECLARE @nC int, @ma_ad int, @u_new int, @u_ad2 int;
DECLARE @q2 dbo.DanhSachQuyenType;
SET @ma_ad = (SELECT ma_nhom FROM dbo.NGUOI_DUNG WHERE ma_nguoi_dung = @u_admin);
EXEC dbo.sp_ThemNhom @u_admin, N'[TEST] Nhóm C', @q, @nC OUTPUT;   -- @q chỉ có quyền 5

-- TK01
SELECT @err = 0, @msg = NULL;
SET @u_new = NULL;
BEGIN TRY EXEC dbo.sp_ThemTaiKhoan @u_admin, 'test_new1', N'$2b$12$testhash', N'[TEST] Tài khoản mới', @nA, @u_new OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TK01', N'Thêm tài khoản hợp lệ',
    N'Thành công; trang_thai = 1; lưu nguyên chuỗi băm; đúng nhóm', CONCAT(N'lỗi=', @err, N'; mã=', @u_new),
    IIF(@err = 0 AND @u_new IS NOT NULL AND (SELECT COUNT(*) FROM dbo.NGUOI_DUNG WHERE ma_nguoi_dung = @u_new AND trang_thai = 1 AND mat_khau = N'$2b$12$testhash' AND ma_nhom = @nA) = 1, 1, 0));

-- TK02
SELECT @err = 0, @msg = NULL;
SET @u_new = NULL;
BEGIN TRY EXEC dbo.sp_ThemTaiKhoan @u_admin, 'test_new1', N'$2b$12$testhash', N'[TEST] Trùng', @nA, @u_new OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TK02', N'Thêm tài khoản trùng tên đăng nhập',
    N'Lỗi 50028', CONCAT(@err, N': ', @msg),
    IIF(@err = 50028 AND @u_new IS NULL, 1, 0));

-- TK03
SELECT @err = 0, @msg = NULL;
SET @u_new = NULL;
BEGIN TRY EXEC dbo.sp_ThemTaiKhoan @u_admin, 'ab', N'$2b$12$testhash', N'[TEST] Ngắn', @nA, @u_new OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TK03', N'Tên đăng nhập quá ngắn (2 ký tự)',
    N'Lỗi 50026', CONCAT(@err, N': ', @msg),
    IIF(@err = 50026, 1, 0));

-- TK04
SELECT @err = 0, @msg = NULL;
SET @u_new = NULL;
BEGIN TRY EXEC dbo.sp_ThemTaiKhoan @u_admin, 'test bad', N'$2b$12$testhash', N'[TEST] Cách', @nA, @u_new OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TK04', N'Tên đăng nhập có khoảng trắng',
    N'Lỗi 50026', CONCAT(@err, N': ', @msg),
    IIF(@err = 50026, 1, 0));

-- TK04b
SELECT @err = 0, @msg = NULL;
SET @u_new = NULL;
BEGIN TRY EXEC dbo.sp_ThemTaiKhoan @u_admin, N'test_ê', N'$2b$12$testhash', N'[TEST] Dấu', @nA, @u_new OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TK04b', N'Tên đăng nhập có chữ có dấu',
    N'Lỗi 50026', CONCAT(@err, N': ', @msg),
    IIF(@err = 50026, 1, 0));

-- TK05
SELECT @err = 0, @msg = NULL;
SET @u_new = NULL;
BEGIN TRY EXEC dbo.sp_ThemTaiKhoan @u_admin, 'test_new2', N'$2b$12$testhash', N'   ', @nA, @u_new OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TK05', N'Họ tên chỉ có khoảng trắng',
    N'Lỗi 50025', CONCAT(@err, N': ', @msg),
    IIF(@err = 50025, 1, 0));

-- TK06
SELECT @err = 0, @msg = NULL;
SET @u_new = NULL;
BEGIN TRY EXEC dbo.sp_ThemTaiKhoan @u_admin, 'test_new3', N'$2b$12$testhash', N'[TEST] Nhóm sai', -1, @u_new OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TK06', N'Thêm tài khoản vào nhóm không tồn tại',
    N'Lỗi 50020; không tạo tài khoản', CONCAT(@err, N': ', @msg),
    IIF(@err = 50020 AND NOT EXISTS (SELECT 1 FROM dbo.NGUOI_DUNG WHERE ten_dang_nhap = 'test_new3'), 1, 0));

-- TK07
SELECT @err = 0, @msg = NULL;
SET @u_new = NULL;
BEGIN TRY EXEC dbo.sp_ThemTaiKhoan @u_ban, 'test_new4', N'$2b$12$testhash', N'[TEST] Không quyền', @nA, @u_new OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TK07', N'NV bán hàng thêm tài khoản',
    N'Lỗi 50011', CONCAT(@err, N': ', @msg),
    IIF(@err = 50011, 1, 0));

-- TK08
SELECT @err = 0, @msg = NULL;
SET @u_new = NULL;
BEGIN TRY EXEC dbo.sp_ThemTaiKhoan @u_admin, 'test_new5', N'', N'[TEST] Rỗng', @nA, @u_new OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'TK08', N'Chuỗi băm mật khẩu rỗng',
    N'Lỗi 50027', CONCAT(@err, N': ', @msg),
    IIF(@err = 50027, 1, 0));

-- NH01
SELECT @err = 0, @msg = NULL;
DELETE FROM @q2; INSERT @q2 VALUES (2), (5);
BEGIN TRY EXEC dbo.sp_SuaNhom @u_admin, @nC, N'[TEST] Nhóm C2', @q2; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'NH01', N'Sửa nhóm: đổi tên và đổi quyền thành {2, 5}',
    N'Thành công; tên mới; đúng 2 quyền gồm quyền 2', CONCAT(N'lỗi=', @err, N'; số quyền=', (SELECT COUNT(*) FROM dbo.PHAN_QUYEN WHERE ma_nhom = @nC)),
    IIF(@err = 0 AND (SELECT ten_nhom FROM dbo.NHOM_NGUOI_DUNG WHERE ma_nhom = @nC) = N'[TEST] Nhóm C2' AND (SELECT COUNT(*) FROM dbo.PHAN_QUYEN WHERE ma_nhom = @nC) = 2 AND EXISTS (SELECT 1 FROM dbo.PHAN_QUYEN WHERE ma_nhom = @nC AND ma_quyen = 2), 1, 0));

-- NH02
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaNhom @u_admin, @nC, N'[TEST] Nhóm C3', @q_rong; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'NH02', N'Sửa nhóm nhưng không chọn quyền nào',
    N'Lỗi 50019; tên và quyền cũ giữ nguyên', CONCAT(@err, N': ', @msg),
    IIF(@err = 50019 AND (SELECT ten_nhom FROM dbo.NHOM_NGUOI_DUNG WHERE ma_nhom = @nC) = N'[TEST] Nhóm C2' AND (SELECT COUNT(*) FROM dbo.PHAN_QUYEN WHERE ma_nhom = @nC) = 2, 1, 0));

-- NH03
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaNhom @u_admin, @nC, N'[TEST] Nhóm A', @q2; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'NH03', N'Đổi tên nhóm trùng với nhóm khác',
    N'Lỗi 50022', CONCAT(@err, N': ', @msg),
    IIF(@err = 50022, 1, 0));

-- NH04
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaNhom @u_admin, @ma_ad, N'Quản trị hệ thống', @q; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'NH04', N'Admin bỏ quyền quản lý tài khoản khỏi nhóm của chính mình',
    N'Lỗi 50029; admin vẫn còn quyền', CONCAT(@err, N': ', @msg),
    IIF(@err = 50029 AND dbo.fn_CoQuyen(@u_admin, 1) = 1 AND EXISTS (SELECT 1 FROM dbo.PHAN_QUYEN WHERE ma_nhom = @ma_ad AND ma_quyen = 1), 1, 0));

-- NH05
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaNhom @u_admin, -1, N'[TEST] Không có', @q2; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'NH05', N'Sửa nhóm không tồn tại',
    N'Lỗi 50020', CONCAT(@err, N': ', @msg),
    IIF(@err = 50020, 1, 0));

-- NH06
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaNhom @u_ban, @nC, N'[TEST] Nhóm C4', @q2; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'NH06', N'NV bán hàng sửa nhóm',
    N'Lỗi 50011', CONCAT(@err, N': ', @msg),
    IIF(@err = 50011, 1, 0));

-- NH07: Thêm nhóm với tên nhóm chỉ có khoảng trắng
SELECT @err = 0, @msg = NULL, @n = NULL;
BEGIN TRY EXEC dbo.sp_ThemNhom @u_admin, N'   ', @q, @n OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'NH07', N'Thêm nhóm với tên nhóm chỉ có khoảng trắng',
    N'Lỗi 50023', CONCAT(@err, N': ', @msg),
    IIF(@err = 50023 AND @n IS NULL, 1, 0));

-- NH08: Thêm nhóm có mã quyền không tồn tại (999)
DECLARE @q_sai dbo.DanhSachQuyenType;
INSERT @q_sai VALUES (999);
SELECT @err = 0, @msg = NULL, @n = NULL;
BEGIN TRY EXEC dbo.sp_ThemNhom @u_admin, N'[TEST] Quyền sai', @q_sai, @n OUTPUT; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'NH08', N'Thêm nhóm có mã quyền không tồn tại (999)',
    N'Lỗi 50024', CONCAT(@err, N': ', @msg),
    IIF(@err = 50024 AND @n IS NULL, 1, 0));

-- Chuẩn bị cho SK01: tạo thêm một quản trị viên thứ hai
EXEC dbo.sp_ThemTaiKhoan @u_admin, 'test_admin2', N'$2b$12$testhash', N'[TEST] Quản trị 2', @ma_ad, @u_ad2 OUTPUT;

-- SK01
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaTaiKhoan @u_admin, @u_ad2, N'[TEST] Quản trị 2', @nA, NULL; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'SK01', N'Chuyển nhóm của quản trị viên khi còn quản trị viên khác',
    N'Thành công; tài khoản sang nhóm mới', CONCAT(N'lỗi=', @err),
    IIF(@err = 0 AND (SELECT ma_nhom FROM dbo.NGUOI_DUNG WHERE ma_nguoi_dung = @u_ad2) = @nA, 1, 0));

-- SK02
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaTaiKhoan @u_admin, -1, N'[TEST] Không có', @nA, NULL; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'SK02', N'Sửa tài khoản không tồn tại',
    N'Lỗi 50015', CONCAT(@err, N': ', @msg),
    IIF(@err = 50015, 1, 0));

-- SK03
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaTaiKhoan @u_admin, @u_test, N'   ', @nA, NULL; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'SK03', N'Sửa tài khoản với họ tên trống',
    N'Lỗi 50025', CONCAT(@err, N': ', @msg),
    IIF(@err = 50025, 1, 0));

-- SK04
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaTaiKhoan @u_admin, @u_test, N'[TEST] Người dùng', -1, NULL; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'SK04', N'Sửa tài khoản sang nhóm không tồn tại',
    N'Lỗi 50020', CONCAT(@err, N': ', @msg),
    IIF(@err = 50020, 1, 0));

-- SK05
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaTaiKhoan @u_admin, @u_test, N'[TEST] Tên mới', @nA, NULL; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'SK05', N'Đổi họ tên, không đổi mật khẩu (tham số mật khẩu = NULL)',
    N'Thành công; họ tên mới; mật khẩu giữ nguyên', CONCAT(N'lỗi=', @err),
    IIF(@err = 0 AND (SELECT ho_ten FROM dbo.NGUOI_DUNG WHERE ma_nguoi_dung = @u_test) = N'[TEST] Tên mới' AND (SELECT mat_khau FROM dbo.NGUOI_DUNG WHERE ma_nguoi_dung = @u_test) = N'x', 1, 0));

-- SK06
SELECT @err = 0, @msg = NULL;
BEGIN TRY EXEC dbo.sp_SuaTaiKhoan @u_ban, @u_test, N'[TEST] Người dùng', @nA, NULL; END TRY
BEGIN CATCH SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE(); END CATCH
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'SK06', N'NV bán hàng sửa tài khoản',
    N'Lỗi 50011', CONCAT(@err, N': ', @msg),
    IIF(@err = 50011, 1, 0));

/* ---------- 9. Đối chiếu các cột tổng lưu với tổng từ các dòng (Q05) ---------- */
SELECT @n = COUNT(*)
FROM dbo.PHIEU_DICH_VU AS p
CROSS APPLY (
    SELECT SUM(thanh_tien) AS st, SUM(tra_truoc) AS sttr, SUM(con_lai) AS scl,
           SUM(CASE WHEN tinh_trang = N'Chưa giao' THEN 1 ELSE 0 END) AS cg
    FROM dbo.CT_PHIEU_DICH_VU WHERE so_phieu = p.so_phieu
) AS x
WHERE p.ma_kh = @kh
  AND (p.tong_tien <> x.st OR p.tong_tra_truoc <> x.sttr OR p.tong_con_lai <> x.scl
       OR p.tinh_trang <> CASE WHEN x.cg = 0 THEN N'Hoàn thành' ELSE N'Chưa hoàn thành' END);
INSERT #kq (ma, mo_ta, mong_doi, thuc_te, dat) VALUES (N'Q05', N'Các cột tổng và tinh_trang của mọi phiếu test khớp với dòng chi tiết',
    N'0 phiếu bị lệch', CONCAT(@n, N' phiếu bị lệch trên tổng ', (SELECT COUNT(*) FROM dbo.PHIEU_DICH_VU WHERE ma_kh = @kh), N' phiếu'),
    IIF(@n = 0, 1, 0));

/* ---------- 10. Kết quả ---------- */
SELECT ma, mo_ta, mong_doi, thuc_te, CASE WHEN dat = 1 THEN N'PASS' ELSE N'FAIL' END AS ket_qua
FROM #kq ORDER BY seq;
SELECT SUM(CAST(dat AS int)) AS so_ca_dat, COUNT(*) AS tong_so_ca FROM #kq;

/* ---------- 11. Dọn dữ liệu test ---------- */
DELETE c FROM dbo.CT_PHIEU_DICH_VU c
    JOIN dbo.PHIEU_DICH_VU p ON p.so_phieu = c.so_phieu
    JOIN dbo.KHACH_HANG k ON k.ma_kh = p.ma_kh
    WHERE LEFT(k.ho_ten, 6) = N'[TEST]';
DELETE p FROM dbo.PHIEU_DICH_VU p
    JOIN dbo.KHACH_HANG k ON k.ma_kh = p.ma_kh
    WHERE LEFT(k.ho_ten, 6) = N'[TEST]';
DELETE FROM dbo.NGUOI_DUNG WHERE LEFT(ten_dang_nhap, 5) = 'test_';
DELETE FROM dbo.PHAN_QUYEN WHERE ma_nhom IN (SELECT ma_nhom FROM dbo.NHOM_NGUOI_DUNG WHERE LEFT(ten_nhom, 6) = N'[TEST]');
DELETE FROM dbo.NHOM_NGUOI_DUNG WHERE LEFT(ten_nhom, 6) = N'[TEST]';
DELETE FROM dbo.KHACH_HANG WHERE LEFT(ho_ten, 6) = N'[TEST]';
DELETE FROM dbo.LOAI_DICH_VU WHERE LEFT(ten_loai_dv, 6) = N'[TEST]';
UPDATE dbo.THAM_SO SET gia_tri_so = 50 WHERE ma_tham_so = 'TyLeTraTruocToiThieu';
