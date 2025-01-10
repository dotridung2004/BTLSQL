-------------------------------------------------------------Users---------------------------------------------------------------------------------
create table Users (
	User_id int identity(1,1) primary key,
    Username nvarchar(50) NOT NULL unique,
    Password nvarchar(255) NOT NULL,
    Email nvarchar(100) NOT NULL unique,
	Address nvarchar(100),
    Role nvarchar(10) check (Role IN ('user', 'admin')) default 'user',
    Status nvarchar(10) check (Status IN ('active', 'locked')) default 'active',
    Created_at datetime default GETDATE()
);
Alter table Users add times int default 0
INSERT INTO Users (username, password, email, address, role, status)
VALUES 
('user22', 'password22', 'user22@example.com', 'Address 22', 'user', 'locked');
Update Users set Status = 'locked' where UserID = 3023
--Trigger
--1.Trigger này không cho phép xóa tài khoản này nếu như tài khoản này đang ở trạng thái active
Create trigger users_delete_bystatus
on users for delete
as
begin
	Declare @X nvarchar(50)
	Select @X = status from deleted
	if(@X = 'active')
	begin
		rollback tran
		print N'Không thể xóa khách hàng đang ở trạng thái hoạt động'
	end
end
Delete from users where username = 'user22'
SELECT * FROM users;
SELECT * FROM orders;

--2.Trigger này tự động khóa các tài khoản không hoạt động(trạng thái 'active')
--nếu đã quá 365 ngày kể từ khi tạo tài khoản
Create trigger trg_AutoLockInactiveAccounts
on Users
for UPDATE
as
begin
    update Users
    set status = 'locked'
    where DATEDIFF(DAY, created_at, GETDATE()) > 365 AND status = 'active';
end
Select * from users
INSERT INTO Users (username, password, email, address, created_at)
VALUES
('user30', 'password30', 'user30@example.com', 'Address 30', DATEADD(DAY, -400, GETDATE())), -- Hơn 365 ngày trước
('user31', 'password31', 'user31@example.com', 'Address 31', DATEADD(DAY, -300, GETDATE())), -- Trong vòng 365 ngày
('user32', 'password31', 'user32@example.com', 'Address 32', DATEADD(DAY, -500, GETDATE())); -- Hơn 365 ngày trước
UPDATE Users
SET address = address
WHERE userid > 0;
Select * from Users where status = 'locked'
Drop trigger trg_AutoLockInactiveAccounts

--Function
--1.Hàm này để thống kê xem có bao nhiêu tài khoản đang hoạt động
--hoặc bị khóa dựa vào tham số đầu vào là status
Create function total_users_active(@status nvarchar(10))
returns int
as
begin
	Declare @X int
	Select @X = Count(*) from Users where status = @status
	return @X
end
Select dbo.total_users_active('active')
Select * from users where status = 'active'
--2.Hàm để mã hóa mật khẩu
Create function encrypt_password(@password nvarchar(255))
returns nvarchar(64)
as
begin
	Declare @HashedPassword nvarchar(64)
	set @HashedPassword = Convert(nvarchar(64),HASHBYTES('SHA2_256',@password),2)
	return @HashedPassword
end
Select dbo.encrypt_password('password3'); 
Select * from users

--View
--1.Hiển thị thông tin cơ bản của khách hàng
Alter view v_users
as
Select userid,username,password,email,status,role from users
Select * from v_users
--2.Hiển thị thông tin khách hàng đăng kí tài khoản mới 
--trong tháng hiện tại
Create view v_users_created_this_month
as
select userid,username,password,email,created_at
from users
where month(created_at) = month(GetDate())
and year(created_at) = year(GetDate())
Select * from v_users_created_this_month

--Proc
--1.Tạo thủ tục kiểm tra mật khẩu nếu mật khẩu sai quá 3 lần thì sửa trạng thái
--đang active thành locked với tham số đầu vào là username và password
Alter proc check_password
@username nvarchar(50),
@password nvarchar(50)
as
begin
	Declare @store_password nvarchar(255)
	Declare @status nvarchar(10)
	Declare @times int
	Select @store_password = password,@status = status,@times = times from Users where username = @username
	if(@status = 'locked')
	begin
		print N'Tài khoản của bạn hiện tại đang bị khóa'
		return
	end
	if(HASHBYTES('SHA2_256', @password) = HASHBYTES('SHA2_256', @store_password))
	begin
		Update users set times = 0 where username = @username
		print N'Đăng nhập thành công'
	end
	else
	begin
		Update users set times = times + 1 where username = @username
		Select @times = times from Users where username = @username
		if(@times >= 3)
		begin
			Update users set status = 'locked' where username = @username
			print N'Tài khoản của bạn tạm bị khóa do nhập sai mật khẩu quá 3 lần'
		end
		else
		begin
			print N'Mật khẩu không đúng'
		end
	end
end
Exec check_password @username = 'user6', @password = 'password3';
Drop proc check_password
Select * from users where username = 'user1'
--2.Tạo thủ tục để mở khóa tài khoản sử dụng con trỏ
Create proc Unlock_account
@username nvarchar(50)
as
begin
	Declare @id int,@status nvarchar(10),@times int
	Declare cur_unlockaccount cursor
	for
	Select userid,status,times from users where username = @username
	Open cur_unlockaccount
	Fetch next from cur_unlockaccount into @id,@status,@times
	while(@@FETCH_STATUS = 0)
	begin
		if (@status is not null)
		begin
			Update users set status = 'active',times = 0 where userid = @id
			print N'Mở khóa tài khoản thành công'
		end
		Fetch next from cur_unlockaccount into @id,@status,@times
	end
	Close cur_unlockaccount
	Deallocate cur_unlockaccount
end
Exec Unlock_account @username = 'user3'
Select username, status, times from users where username = 'user5';

--con trỏ
--1.Con trỏ thiết lập lại các tài khoản ở trạng thái = 'locked' thành mật
--khẩu mặc định('1234') dựa theo id của tài khoản
Declare @id int
Declare reset_password_cursor cursor
for
Select userid
from Users
where status = 'locked';
Open reset_password_cursor;
Fetch next from reset_password_cursor into @id
while (@@FETCH_STATUS = 0)
begin
    update Users
	set password = Convert(nvarchar(64), HASHBYTES('SHA2_256', '1234'), 2)
	where userid = @id
    print 'Password reset for user with ID ' + Convert(nvarchar(10),@id) + '.'
    Fetch next from reset_password_cursor into @id
end
Close reset_password_cursor;
Deallocate reset_password_cursor;
Select * from users where status = 'locked'
--2.Con trỏ để mở khóa tài khoản
Declare @id INT, @status NVARCHAR(10)
Declare cur_unlockaccount cursor for
Select userid, status
from users
where username = 'user18'
Open cur_unlockaccount
Fetch next from cur_unlockaccount into @id, @status
While (@@FETCH_STATUS = 0)
Begin
    if (@status IS NOT NULL)
    begin
        UPDATE users
        SET status = 'active', times = 0
        WHERE userid = @id

        PRINT N'Mở khóa tài khoản thành công'
    end
    Fetch next from cur_unlockaccount into @id, @status
end
close cur_unlockaccount
Deallocate cur_unlockaccount
Select * from users where username = 'user18'

------------------------------------------------------------GameModel----------------------------------------------------------------------------------------------------------------
--Nguyễn Thị Huyền Trang
Create table GameModel(
	GameModel_id int identity(1,1) primary key,
	Name nvarchar(100),
	Price float,
	Description nvarchar(200),
	Stock int,
	Image nvarchar(50),
	Rating float null,
	Created_at datetime default GetDate()
)
INSERT INTO GameModel (name, price, description, stock, image, rating)
VALUES 
('Game 1', 19.99, 'Exciting adventure game', 100, 'game1.jpg', 4.5),
('Game 2', 29.99, 'Thrilling action-packed gameplay', 200, 'game2.jpg', 4.7),
('Game 3', 15.99, 'Fun puzzle-solving experience', 150, 'game3.jpg', 4.2),
('Game 4', 49.99, 'Intense RPG with a rich storyline', 80, 'game4.jpg', 4.8),
('Game 5', 39.99, 'Challenging strategy game', 120, 'game5.jpg', 4.3),
('Game 6', 25.99, 'Fast-paced racing action', 90, 'game6.jpg', 4.6),
('Game 7', 19.99, 'Classic platformer game', 200, 'game7.jpg', 4.1),
('Game 8', 59.99, 'Highly immersive open-world game', 50, 'game8.jpg', 4.9),
('Game 9', 14.99, 'Casual arcade fun', 300, 'game9.jpg', 3.9),
('Game 10', 34.99, 'Sci-fi shooter with advanced AI', 70, 'game10.jpg', 4.4),
('Game 11', 19.99, 'Family-friendly party game', 250, 'game11.jpg', 4.0),
('Game 12', 24.99, 'Classic sports simulation', 150, 'game12.jpg', 4.2),
('Game 13', 29.99, 'Historical strategy game', 120, 'game13.jpg', 4.5),
('Game 14', 39.99, 'Fantasy adventure with co-op mode', 80, 'game14.jpg', 4.6),
('Game 15', 9.99, 'Relaxing puzzle game', 500, 'game15.jpg', 3.8),
('Game 16', 49.99, 'Highly detailed flight simulator', 40, 'game16.jpg', 4.7),
('Game 17', 19.99, 'Indie platformer with unique art', 180, 'game17.jpg', 4.4),
('Game 18', 29.99, 'Exciting horror survival game', 70, 'game18.jpg', 4.5),
('Game 19', 22.99, 'Sci-fi strategy with multiplayer', 100, 'game19.jpg', 4.3),
('Game 20', 39.99, 'Open-world RPG with deep lore', 60, 'game20.jpg', 4.8);

--VIEW
--1. Viết 1 view để hiển thị mô hình game nào có xếp hạng cao >=4.5
CREATE VIEW view_1 
AS
SELECT GameModelID, name, price, rating
FROM GameModel
WHERE rating >= 4.5;

select * from view_1

--2.Viết 1 view để hiển thị số lượng trong kho có số lượng hàng <50
CREATE VIEW view_2 
AS
SELECT GameModelID, name, stock
FROM GameModel
WHERE stock < 50;

select * from view_2

--TRIGGER
--1.Viết 1 trigger để tự động xếp hạng mặc định cho mô hình game mới 
CREATE TRIGGER trig_1
ON GameModel
FOR INSERT
AS
BEGIN
    UPDATE GameModel
    SET rating = 3.0
    WHERE rating IS NULL AND GameModelID IN (SELECT GameModelID FROM inserted);
END;

INSERT INTO GameModel (name, price, description, stock, image)
VALUES ('Game 21', 10.0, 'Puzzle game', 50, 'game21.jpg');

select * from GameModel

--2.Viết 1 trigger để không cho thêm mô hình game có tên có tên "game 23"
CREATE TRIGGER trig_2
ON GameModel
FOR INSERT
AS
BEGIN
    IF EXISTS ( select * from inserted where name='Game 23')
    BEGIN
		PRINT 'Không cho thêm trò chơi game 23.';
        ROLLBACK TRAN;
        
    END
END;


INSERT INTO GameModel (name, price, description, stock, image, rating)
VALUES ('Game 23', 28.05, 'Folk games', 100, 'game23.jpg', 4.8);

select * from GameModel


--PROC
--1.Tạo 1 hàm để thêm mô hình game mới
CREATE PROCEDURE proc_1
    @name NVARCHAR(100),
    @price FLOAT,
    @description NVARCHAR(200),
    @stock INT,
    @image NVARCHAR(50),
    @rating FLOAT = NULL
AS
BEGIN
    INSERT INTO GameModel (name, price, description, stock, image, rating)
    VALUES (@name, @price, @description, @stock, @image, @rating);
END;

EXEC proc_1 'Game 24', 20.0, 'Great game description', 100, 'game24.jpg', 4.8;

select * from GameModel


--2.Viết 1 hàm để cập nhật số lượng hàng trong kho cho mô hình game
CREATE PROCEDURE proc_2
    @gameId INT,
    @newStock INT
AS
BEGIN
    UPDATE GameModel
    SET stock = @newStock
    WHERE GameModelID = @gameId;
END;

EXEC proc_2 1, 150;

select * from GameModel



--CURSORS
--1.Sử dụng con trỏ hiển thị tất cả các mô hình game có số lượng trong kho dưới 100
DECLARE CUR_soluong CURSOR FOR
SELECT name, stock
FROM GameModel
WHERE stock < 100;

OPEN CUR_soluong;

DECLARE @gameName NVARCHAR(100), @stock INT;

FETCH NEXT FROM CUR_soluong INTO @gameName, @stock;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Game: ' + @gameName + ', Stock: ' + CAST(@stock AS NVARCHAR);
    FETCH NEXT FROM CUR_soluong INTO @gameName, @stock;
END;

CLOSE CUR_soluong;
DEALLOCATE CUR_soluong;


--2.Sử dụng con trỏ để giảm giá 10% cho các mô hình game có giá trên 30
DECLARE @GameID INT, @CurrentPrice FLOAT;
DECLARE PriceCursor CURSOR FOR
SELECT GameModelID, price
FROM GameModel
WHERE price > 30;
OPEN PriceCursor;

FETCH NEXT FROM PriceCursor INTO @GameID, @CurrentPrice;

WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE GameModel
    SET price = @CurrentPrice * 0.9
    WHERE GameModelID = @GameID;

    PRINT 'Đa giam gia 10% cho tro choi co ID = ' + CAST(@GameID AS NVARCHAR);

    FETCH NEXT FROM PriceCursor INTO @GameID, @CurrentPrice;
END;

CLOSE PriceCursor;
DEALLOCATE PriceCursor;


select * from GameModel



--FUNCTION
--1.Viết 1 hàm trả về xếp hạng trung bình của tất cả các mô hình game
CREATE FUNCTION XHTB()
RETURNS FLOAT
AS
BEGIN
    DECLARE @avgRating FLOAT;
    SELECT @avgRating = AVG(rating)
    FROM GameModel;
    RETURN @avgRating;
END;

SELECT dbo.XHTB();

--2.viết 1 hàm để kiểm tra kho game bằng ID
CREATE FUNCTION CheckStock(@gameId INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @stock INT, @result NVARCHAR(50);
    SELECT @stock = stock
    FROM GameModel
    WHERE GameModelID = @gameId;

    IF @stock < 50
        SET @result = 'So luong thap';
    ELSE
        SET @result = 'So luong du';

    RETURN @result;
END;

SELECT dbo.CheckStock(1);


--------------------------------------------------------------------------Orders-------------------------------------------------------------------------------------------------------
--Trần Trung Dũng
Create table Orders(
	Orders_id int identity(1,1) primary key,
	User_id int,
	Order_date datetime default GetDate(),
	Note nvarchar(200),
	Foreign key (user_id) references users(user_id)
)

INSERT INTO Orders (userid, order_date, note)
VALUES 
(1, GETDATE() - 20, 'Fast delivery requested'),
(2, GETDATE() - 18, 'Gift wrap this order'),
(3, GETDATE() - 17, 'Please include a thank you card'),
(4, GETDATE() - 15, 'Urgent order'),
(5, GETDATE() - 14, 'Call me before delivery'),
(6, GETDATE() - 13, 'Deliver to the front desk'),
(7, GETDATE() - 12, 'Leave package at the door'),
(8, GETDATE() - 10, 'No plastic packaging'),
(9, GETDATE() - 9, 'Add a birthday note'),
(10, GETDATE() - 8, 'Pack securely for travel'),
(11, GETDATE() - 7, 'Customer will pick up'),
(12, GETDATE() - 6, 'Include assembly instructions'),
(13, GETDATE() - 5, 'Special handling required'),
(14, GETDATE() - 4, 'Deliver before noon'),
(15, GETDATE() - 3, 'No special requests'),
(16, GETDATE() - 2, 'Notify by email when shipped'),
(17, GETDATE() - 1, 'Confirm by phone before shipping'),
(18, GETDATE(), 'Leave package with neighbor if not home'),
(19, GETDATE() + 1, 'Contact me for further details'),
(20, GETDATE() + 2, 'Add promotional materials if available');

--TRIGGER--
--1.Viết trigger không cho đặt hàng nếu như tài khoản người dùng đang ở trạng thái khóa (locked)
CREATE TRIGGER trg_prevent_order_if_locked
ON Orders
INSTEAD OF INSERT
AS
BEGIN
    -- Kiểm tra trạng thái của user trước khi thêm
    IF EXISTS (SELECT * FROM inserted i
        JOIN Users u ON i.userid = u.UserID
        WHERE u.status = 'locked'
    )
    BEGIN
        -- Nếu status của user là 'locked', không cho phép thêm order
        PRINT N'Không thể tạo đơn hàng khi tài khoản người dùng đang ở trạng thái locked.'
        ROLLBACK tran ;
    END
    ELSE
    BEGIN
        -- Nếu không, chèn dữ liệu vào bảng Orders
        INSERT INTO Orders (userid, order_date, note)
        SELECT userid, order_date, note
        FROM inserted;
    END
END

insert into Orders(userid, order_date, note)
values (3, GETDATE() - 17, 'Please include a thank you card')

insert into Orders(userid, order_date, note)
values (2, GETDATE(), 'Gift wrap this order')
Select * from orders

--2.viết trigger không cho phép tạo đơn hàng khi không điền địa chỉ nhà
CREATE TRIGGER trg_PreventOrderWithoutAddress
ON Orders
FOR INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem người dùng có địa chỉ nhà hay không
    IF EXISTS (
        SELECT *
        FROM inserted i
        JOIN Users u ON i.userid = u.UserID
        WHERE u.address IS NULL OR u.address = ''
    )
    BEGIN
        -- Nếu người dùng không có địa chỉ nhà, hủy giao dịch và hiển thị thông báo lỗi
        print N'Không thể tạo đơn hàng vì người dùng chưa điền địa chỉ nhà.'
        ROLLBACK TRAN; -- Hủy giao dịch
        RETURN; -- Dừng trigger
    END

    PRINT N'Đơn hàng được thêm thành công.';
END

INSERT INTO Users (username, password, email, address, role, status)
VALUES 
('user45', 'password45', 'user45@example.com', ' ','user', 'active')
INSERT INTO Orders (userid, order_date, note)
VALUES 
(25, GETDATE() , 'Fast delivery requested')
select * from Users
INSERT INTO Orders (userid, order_date, note)
VALUES 
(1, GETDATE() - 20, 'Fast delivery requested')

--FUNCTION--
--1.Viết 1 hàm tính tổng số đơn hàng của người dùng trong một khoảng thời gian
CREATE FUNCTION GetTotalOrdersByUser (
    @user_id INT,
    @start_date DATETIME,
    @end_date DATETIME
)
RETURNS INT
AS
BEGIN
    DECLARE @total_orders INT;

    -- Tính tổng số đơn hàng trong khoảng thời gian cho người dùng cụ thể
    SELECT @total_orders = COUNT(*)
    FROM Orders
    WHERE userid = @user_id
      AND order_date BETWEEN @start_date AND @end_date;

    -- Trả về kết quả
    RETURN @total_orders;
END;
select * from Orders
select dbo.GetTotalOrdersByUser (2,'2024-12-01','2024-12-31')

--2.Viết 1 hàm lấy danh sách đơn hàng trong một ngày cụ thể
CREATE FUNCTION GetOrdersBySpecificDate(@OrderDate DATETIME)
RETURNS TABLE
AS
RETURN 
(
    SELECT 
        o.Userid AS OrderID,
        o.userid AS UserID,
        o.order_date AS OrderDate,
        o.note AS Note
    FROM 
        Orders o
    WHERE 
        CAST(o.order_date AS DATE) = CAST(@OrderDate AS DATE)
);
select * from dbo.GetOrdersBySpecificDate('2024-12-28')

--VIEW--
--1.Viết 1 view trả về một bảng chứa tất cả các đơn hàng của người dùng đó.
CREATE VIEW View_OrdersWithUser
AS
    SELECT  orders.Userid, order_date, note
    FROM Orders,Users WHERE Users.UserID = Orders.Userid

select * from View_OrdersWithUser


--2.Viết 1 view hiển thị các đơn hàng có ghi chú (note) không rỗng

CREATE VIEW View_OrdersWithNotes
AS
SELECT 
    o.Userid AS OrderID,
    o.order_date AS OrderDate,
    o.note AS Note,
    u.username AS Username
FROM 
    Orders o
JOIN 
    Users u ON o.userid = u.UserID
WHERE 
    o.note IS NOT NULL AND o.note <> '';

select * from View_OrdersWithNotes

--PROC--
--1.Viết thủ tục cập nhập ghi chú(note) cho một đơn hàng sử dụng con trỏ
CREATE PROC UpdateOrderNote
    @OrderID INT,
    @NewNote NVARCHAR(200)
AS
BEGIN
    -- Kiểm tra xem đơn hàng có tồn tại hay không
    IF NOT EXISTS (SELECT * FROM Orders WHERE Userid = @OrderID)
    BEGIN
        PRINT N'OrderID không tồn tại';
        RETURN;
    END

    -- Khai báo biến cho con trỏ
    DECLARE @OrderIDCursor INT, @CurrentNote NVARCHAR(200);

    -- Khai báo con trỏ để duyệt qua các đơn hàng
    DECLARE order_cursor CURSOR FOR
    SELECT Userid, note
    FROM Orders
    WHERE Userid = @OrderID;

    -- Mở con trỏ
    OPEN order_cursor;

    -- Lấy dữ liệu đầu tiên từ con trỏ
    FETCH NEXT FROM order_cursor INTO @OrderIDCursor, @CurrentNote;

    -- Kiểm tra con trỏ có dữ liệu hay không
    IF @@FETCH_STATUS = 0
    BEGIN
        -- Cập nhật ghi chú cho đơn hàng
        UPDATE Orders
        SET note = @NewNote
        WHERE Userid = @OrderIDCursor;

        PRINT N'Ghi chú của đơn hàng ID ' + CAST(@OrderIDCursor AS NVARCHAR) + ' đã được cập nhật';
    END
    ELSE
    BEGIN
        PRINT N'Không tìm thấy đơn hàng với OrderID: ' + CAST(@OrderID AS NVARCHAR);
    END

    -- Đóng và giải phóng con trỏ
    CLOSE order_cursor;
    DEALLOCATE order_cursor;
END
EXEC UpdateOrderNote @OrderID = 1, @NewNote = 'Updated note for this order'
EXEC UpdateOrderNote @OrderID = 3, @NewNote = 'Updated note for this order...'
select * from Orders

--2.viết thủ tục lấy thông tin chi tiết đơn hàng theo OrderID sử dụng con trỏ
CREATE PROC GetOrderDetailsByOrderID
    @OrderID INT
AS
BEGIN
    -- Kiểm tra xem đơn hàng có tồn tại hay không
    IF NOT EXISTS (SELECT * FROM Orders WHERE Userid = @OrderID)
    BEGIN
        PRINT N'OrderID không tồn tại';
        RETURN;
    END

    -- Khai báo biến cho con trỏ
    DECLARE @OrderIDCursor INT, @OrderDate DATETIME, @Note NVARCHAR(200), 
            @UserID INT, @Username NVARCHAR(50), @Email NVARCHAR(100), 
            @Address NVARCHAR(100), @UserStatus NVARCHAR(10);

    -- Khai báo con trỏ để duyệt qua đơn hàng và người dùng tương ứng
    DECLARE order_cursor CURSOR FOR
    SELECT o.Userid, o.order_date, o.note, u.Userid, u.username, u.email, u.address, u.status
    FROM Orders o
    JOIN Users u ON o.userid = u.Userid
    WHERE o.Userid = @OrderID;

    -- Mở con trỏ
    OPEN order_cursor;

    -- Lấy dữ liệu đầu tiên từ con trỏ
    FETCH NEXT FROM order_cursor INTO @OrderIDCursor, @OrderDate, @Note, 
                                      @UserID, @Username, @Email, @Address, @UserStatus;

    -- Kiểm tra con trỏ có dữ liệu hay không
    IF @@FETCH_STATUS = 0
    BEGIN
        -- In thông tin đơn hàng và người dùng
        PRINT 'OrderID: ' + CAST(@OrderIDCursor AS NVARCHAR) +
              ', Order Date: ' + CAST(@OrderDate AS NVARCHAR) +
', Note: ' + ISNULL(@Note, 'No Note') +
              ', UserID: ' + CAST(@UserID AS NVARCHAR) +
              ', Username: ' + @Username +
              ', Email: ' + @Email +
              ', Address: ' + ISNULL(@Address, 'No Address') +
              ', User Status: ' + @UserStatus;
    END
    ELSE
    BEGIN
        PRINT N'Không tìm thấy thông tin cho OrderID: ' + CAST(@OrderID AS NVARCHAR);
    END
 -- Đóng con trỏ và giải phóng tài nguyên
    CLOSE order_cursor;
    DEALLOCATE order_cursor;
END
 
exec GetOrderDetailsByOrderID 2



-----------------------------------------------------------------------------Order_details-------------------------------------------------------------------------------------------
--Đỗ Minh Đức
Create table Order_details(
	Order_details_Id int identity(1,1) primary key,
	Order_id int,
	Game_model_id int,
	Quantity int,
	Unit_price float,
	Total_price float,
	Status nvarchar(50),check (Status IN ('completed', 'not_completed')),
	foreign key (order_id) references orders(OrdersId),
	foreign key (game_model_id) references GameModel(GameModelID)
)
INSERT INTO Order_details (order_id, game_model_id,quantity,unit_price, total_price,status)
VALUES 
(1, 1, 1,NULL, NULL,'completed'),
(1, 2,3, NULL, NULL,'completed'),
(2, 3,4, NULL, NULL,'not_completed'),
(2, 4,2, NULL, NULL,'completed'),
(3, 5,1,NULL, NULL,'completed'),
(3, 6,1, NULL, NULL,'not_completed'),
(4, 7,2, NULL, NULL,'not_completed'),
(4, 8,2, NULL, NULL,'completed'),
(5, 9,3, NULL, NULL,'completed'),
(5, 10,1, NULL, NULL,'not_completed'),
(6, 11,2, NULL, NULL,'not_completed'),
(6, 12,4, NULL, NULL,'completed'),
(7, 13,6, NULL, NULL,'completed'),
(7, 14,1, NULL, NULL,'not_completed'),
(8, 15,2, NULL, NULL,'completed'),
(8, 16,2, NULL, NULL,'completed'),
(9, 17,3, NULL, NULL,'not_completed'),
(9, 18,5, NULL, NULL,'completed'),
(10, 19,3, NULL, NULL,'not_completed'),
(10, 20,2, NULL, NULL,'not_completed');
Select * from Order_details

--trigger
--1.Viết trigger con trỏ tính tổng tiền
create TRIGGER trg_TotalPrice
ON Order_details
FOR INSERT, UPDATE
AS
BEGIN
    -- Khai báo con trỏ
    DECLARE @OrderID INT, @GameModelID INT, @Quantity INT, @UnitPrice FLOAT, @TotalPrice FLOAT;

    -- Khai báo con trỏ để duyệt qua các bản ghi trong bảng inserted
    DECLARE order_cursor CURSOR FOR
	SELECT order_id, game_model_id, quantity, unit_price
	FROM Order_details;

    -- Mở con trỏ
    OPEN order_cursor;

    -- Lấy giá trị đầu tiên từ con trỏ
    FETCH NEXT FROM order_cursor INTO @OrderID, @GameModelID, @Quantity, @UnitPrice;

    -- Duyệt qua các bản ghi của bảng inserted
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Tính toán tổng tiền và cập nhật vào bảng Order_details
        UPDATE Order_details
        SET @TotalPrice = @Quantity * @UnitPrice

       -- Cập nhật lại bảng Order_details với giá trị total_price mới
    UPDATE Order_details
    SET total_price = @TotalPrice
    WHERE order_id = @OrderID AND game_model_id = @GameModelID;
        -- Lấy giá trị tiếp theo từ con trỏ
        FETCH NEXT FROM order_cursor INTO @OrderID, @GameModelID, @Quantity, @UnitPrice;
END

    -- Đóng và giải phóng con trỏ
    CLOSE order_cursor;
    DEALLOCATE order_cursor;
END;


UPDATE Order_details
SET unit_price = 30.99
WHERE Order_id = 1; 
--2.viết trigger và con trỏ không cho xóa khi đơn hàng đã hoàn thành
create TRIGGER deleteorder
ON Order_details
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @id INT;
    DECLARE @status NVARCHAR(50);
    
    -- Khai báo con trỏ để duyệt qua các bản ghi trong bảng deleted
    DECLARE delete_cursor CURSOR FOR
    SELECT Order_id, status
    FROM deleted;

    OPEN delete_cursor;

    -- Lấy giá trị đầu tiên từ con trỏ
    FETCH NEXT FROM delete_cursor INTO @id, @status;

    -- Duyệt qua các bản ghi của bảng deleted
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Kiểu tra nếu hoàn thành thì không được xóa
        IF @status = 'completed'
        BEGIN
            PRINT N'Không thể xóa đơn hàng khi đã hoàn thành';
        END
        ELSE
        BEGIN
            -- Xóa dữ liệu từ bảng Order_details 
            DELETE FROM Order_details
            WHERE Order_id = @id;
            PRINT N'Xóa thành công';
        END

        -- Lấy giá trị tiếp theo từ con trỏ
        FETCH NEXT FROM delete_cursor INTO @id, @status;
    END

    -- Đóng và giải phóng con trỏ
    CLOSE delete_cursor;
    DEALLOCATE delete_cursor;
END;
select * from Order_details
DELETE FROM Order_details WHERE Order_id = 20;
--function
--1.viết 1 hàm in ra các mặt hàng bán chạy nhất
create FUNCTION GetBestSellingItem(@Top INT)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@Top)
        GameModel.GameModelID AS GameModelID,
        GameModel.name AS GameModelName,
        COUNT(DISTINCT order_id) AS TotalBuyers,
        SUM(quantity) AS TotalQuantitySold,
        SUM(total_price) AS TotalRevenue
    FROM Order_details 
    INNER JOIN GameModel  ON Order_details.game_model_id = GameModel.GameModelID
	WHERE status = 'Completed'
    GROUP BY GameModel.GameModelID,GameModel.name
    ORDER BY TotalQuantitySold DESC, TotalRevenue DESC
);
SELECT * FROM GetBestSellingItem(5);
--2.Hàm tính tổng doanh thu theo khoảng thời gian
CREATE FUNCTION dbo.GetRevenueByDateRange
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @TotalRevenue FLOAT;

    SELECT @TotalRevenue = SUM(total_price)
    FROM Order_details
    WHERE status = 'Completed'
    AND order_id IN (SELECT Order_id FROM orders WHERE order_date BETWEEN @StartDate AND @EndDate);

    RETURN ISNULL(@TotalRevenue, 0);
END;
SELECT dbo.GetRevenueByDateRange('2024-12-08', '2025-12-09') AS TotalRevenue;
--view
--1. viết View phân tích tỷ lệ hoàn thành đơn hàng
CREATE VIEW OrderStatusPercentage AS
SELECT 
    status,
    COUNT(Order_details_ID) AS TotalOrders,
    CAST(COUNT(Order_details_ID) * 100.0 / SUM(COUNT(Order_details_ID)) OVER () AS DECIMAL(5, 2)) AS Percentage
FROM 
    Order_details
GROUP BY 
    status
select * from OrderStatusPercentage
select * from Order_details
--1.Viết 1 view hiện thị danh sách trạng thái đơn hàng theo từng khách hàng
Create VIEW CustomerOrderStatus AS
SELECT 
    Orders.userid,
    Users.username AS customer_name,
    Order_details.order_id,
    Order_details.status,
    COUNT(*) AS total_items,
    SUM(CASE WHEN Order_details.status = 'not_completed' THEN 0 ELSE Order_details.total_price END) AS total_order_value
FROM 
    Order_details 
INNER JOIN 
    Orders  ON Order_details.order_id = Orders.OrdersId
INNER JOIN 
    Users  ON Orders.userid = Users.UserID
GROUP BY 
    Orders.userid, Users.username, Order_details.order_id, Order_details.status;
select * from CustomerOrderStatus
--2.View phân tích khách hàng theo giá trị đơn hàng
Create VIEW CustomerOrderValueAnalysis AS
SELECT 
    Orders.userid,
    Users.username,  
    COUNT(Order_details.Order_details_ID) AS TotalOrders,
    SUM(Order_details.total_price) AS TotalSpent,
    AVG(Order_details.total_price) AS AverageOrderValue,
    MAX(Order_details.total_price) AS MaxOrderValue,
    MIN(Order_details.total_price) AS MinOrderValue
FROM 
    Order_details
JOIN 
    Orders  ON Order_details.order_id = Orders.OrdersId
JOIN
    Users   ON Orders.userid = Users.UserID
GROUP BY 
    Orders.userid, Users.username
SELECT * FROM CustomerOrderValueAnalysis
ORDER BY TotalSpent DESC
--proc
--1.viết 1 thủ tục hiển thị thông tin sản phầm theo mã đơn hàng
Create PROCEDURE GetOrderProducts
    @OrderID INT
AS
BEGIN
    SELECT 
        order_id,game_model_id,name,description,stock,image,rating,quantity,price as unit_price,total_price ,created_at 
    FROM 
        Order_details
    INNER JOIN 
        GameModel  ON Order_details.game_model_id = GameModel.GameModelID
    WHERE 
        Order_details.order_id = @OrderID;
END;
EXEC GetOrderProducts @OrderID = 1;
--2.Viết thủ tục cập nhật số lượng sản phẩm trong đơn hàng 
Create PROCEDURE UpdateOrderDetailQuantity
(
    @order_detail_id INT,
    @new_quantity INT
)
AS
BEGIN
    DECLARE @message NVARCHAR(50);
    if NOT EXISTS (SELECT Order_details_ID FROM Order_details WHERE Order_details_ID = @order_detail_id)
    BEGIN
        SET @message = N'Lỗi:ID không tồn tại.';
        PRINT @message;  
        RETURN;
    END
    IF @new_quantity <= 0
    BEGIN
        SET @message = N'Lỗi:Số lượng phải lớn hơn 0.';
        PRINT @message;
        RETURN;
    END
--cập nhật số lượng sản phẩm trong đơn hàng
    UPDATE Order_details
    SET quantity = @new_quantity
    WHERE Order_details_ID = @order_detail_id;
    SET @message = N'Số lượng được cập nhật thành công.';
    PRINT @message;
END;
EXEC UpdateOrderDetailQuantity @order_detail_id = 30, @new_quantity = 30;

----------------------------------------------------------------------------------Delivery-------------------------------------------------------------------------------------------
--Vũ Tùng Dương
Create table Delivery(
	DeliveryID int identity(1,1) primary key,
	OrderID int,
	Delivery_date datetime,
	Delivere_date datetime,
	Status nvarchar(50) check (status in ('non-delivery','shipped','delivered')) default 'non-delivery',
	Delivery_address nvarchar(100),
	Name_shipper nvarchar(100),
	foreign key (orderID) references orders(OrdersID)
)

INSERT INTO Delivery (order_id, delivery_date, delivere_date, status, delivery_address, name_shipper)
VALUES 
(1, GETDATE() - 10, GETDATE() - 9, 'delivered', '123 Main St, City A', 'John Doe'),
(2, GETDATE() - 8, GETDATE() - 7, 'shipped', '456 Oak Rd, City B', 'Jane Smith'),
(3, GETDATE() - 6, GETDATE() - 5, 'delivered', '789 Pine Ave, City C', 'Robert Brown'),
(4, GETDATE() - 4, GETDATE() - 3, 'shipped', '101 Maple Dr, City D', 'Mary Johnson'),
(5, GETDATE() - 2, GETDATE() - 1, 'delivered', '202 Birch Ln, City E', 'Michael Davis'),
(6, GETDATE() - 7, GETDATE() - 6, 'shipped', '303 Cedar Blvd, City F', 'Emily Clark'),
(7, GETDATE() - 5, GETDATE() - 4, 'non-delivery', '404 Elm St, City G', 'David Wilson'),
(8, GETDATE() - 3, GETDATE() - 2, 'delivered', '505 Cherry Ave, City H', 'Sarah Miller'),
(9, GETDATE() - 1, GETDATE(), 'shipped', '606 Walnut Dr, City I', 'Chris Taylor'),
(10, GETDATE(), NULL, 'non-delivery', '707 Ash Blvd, City J', 'Patricia Anderson'),
(11, GETDATE() - 9, GETDATE() - 8, 'delivered', '808 Palm St, City K', 'James Harris'),
(12, GETDATE() - 6, GETDATE() - 5, 'shipped', '909 Cedar Rd, City L', 'Elizabeth Lewis'),
(13, GETDATE() - 4, GETDATE() - 3, 'delivered', '1010 Fir Ave, City M', 'Daniel Scott'),
(14, GETDATE() - 2, GETDATE() - 1, 'shipped', '1111 Oak Ln, City N', 'Laura Hall'),
(15, GETDATE() - 10, GETDATE() - 9, 'delivered', '1212 Pine Blvd, City O', 'Mark Allen'),
(16, GETDATE() - 8, GETDATE() - 7, 'shipped', '1313 Maple Rd, City P', 'Susan Young'),
(17, GETDATE() - 6, GETDATE() - 5, 'non-delivery', '1414 Birch St, City Q', 'Paul King'),
(18, GETDATE() - 3, GETDATE() - 2, 'delivered', '1515 Elm Dr, City R', 'Jessica Green'),
(19, GETDATE() - 1, GETDATE(), 'shipped', '1616 Oak Blvd, City S', 'William Adams'),
(20, GETDATE(), NULL, 'non-delivery', '1717 Pine Rd, City T', 'Olivia Baker');

--Trigger
--Kiểm tra ngày giao hàng không được trước ngày đặt hàng
CREATE TRIGGER CheckDeliveryDate
ON Delivery
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT *
        FROM inserted 
        JOIN Orders  ON inserted.order_id = Orders.Userid
        WHERE inserted.delivery_date < Orders.order_date
    )
    BEGIN
        ROLLBACK TRANSACTION
        PRINT N'Ngày giao hàng không thể trước ngày đặt hàng!'
    END
END
select * from Delivery

UPDATE Delivery
SET delivery_date = '2024-12-07'
WHERE DeliveryID = 1

--Ngăn chặn cập nhật trạng thái từ 'delivered' về trạng thái khác
create TRIGGER PreventStatusChange
ON Delivery
FOR UPDATE
AS
BEGIN
    DECLARE @TrangThaiCu NVARCHAR(50), @TrangThaiMoi NVARCHAR(50)
    SELECT @TrangThaiCu = status FROM deleted
    SELECT @TrangThaiMoi = status FROM inserted

    IF @TrangThaiCu = 'delivered' AND @TrangThaiMoi <> 'delivered'
    BEGIN
        ROLLBACK TRANSACTION
        PRINT N'Không thể thay đổi trạng thái từ delivered về trạng thái khác!'
    END
END

-- <> ở đây là khác 
UPDATE Delivery
SET status = 'shipped'
WHERE order_id = 5;

drop trigger PreventStatusChange

--View
--View danh sách các đơn hàng đã giao
Create VIEW DeliveredOrders AS
SELECT 
    Delivery.DeliveryID AS DeliveryID ,Orders.OrdersId AS OrderID ,Orders.order_date ,Delivery.delivere_date ,Delivery.delivery_address ,Delivery.name_shipper 
FROM Delivery JOIN Orders ON Delivery.order_id = Orders.OrdersId
WHERE Delivery.status = 'delivered';

select * from DeliveredOrders

-- View đơn hàng chưa giao hoặc đang vận chuyển
CREATE VIEW PendingOrShippedOrders AS
SELECT 
    Delivery.DeliveryID AS DeliveryID,Orders.OrdersId AS OrderID,Orders.order_date ,Delivery.delivery_date,Delivery.status ,Delivery.delivery_address ,Delivery.name_shipper 
FROM Delivery JOIN Orders ON Delivery.order_id = Orders.OrdersId
WHERE 
    Delivery.status IN ('non-delivery', 'shipped');

SELECT * FROM PendingOrShippedOrders;

--Thủ tục
--Thủ tục xoá đơn hàng theo ID
--Xóa một đơn giao hàng dựa trên DeliveryID nếu trạng thái của nó là 'non-delivery'.

CREATE PROCEDURE DeleteDelivery
    @DeliveryID INT
AS
BEGIN
    -- Kiểm tra DeliveryID có tồn tại không
    IF NOT EXISTS (SELECT * FROM Delivery WHERE DeliveryID = @DeliveryID)
    BEGIN
        PRINT N'DeliveryID không tồn tại.';
        RETURN;
    END

    -- Kiểm tra trạng thái đơn giao hàng
    DECLARE @Status NVARCHAR(50);
    SELECT @Status = status FROM Delivery WHERE DeliveryID = @DeliveryID;

    IF @Status <> 'non-delivery'
    BEGIN
        PRINT N'Không thể xóa đơn hàng không có trạng thái ''non-delivery''.';
        RETURN;
    END

    -- Xóa đơn giao hàng
    DELETE FROM Delivery WHERE DeliveryID = @DeliveryID;

    PRINT N'Xóa đơn giao hàng thành công.';
END;

EXEC DeleteDelivery @DeliveryID = 20;
EXEC DeleteDelivery @DeliveryID = 30;
EXEC DeleteDelivery @DeliveryID = 1;



--Thủ tục này cho phép cập nhật trạng thái giao hàng và ngày giao thực tế dựa trên DeliveryID.
Create PROCEDURE UpdateDeliveryStatus
    @DeliveryID INT,
    @NewStatus NVARCHAR(50),
    @ActualDeliveryDate DATETIME = NULL
AS
BEGIN
    -- Kiểm tra DeliveryID có tồn tại không
    IF NOT EXISTS (SELECT * FROM Delivery WHERE DeliveryID = @DeliveryID)
    BEGIN
        PRINT N'DeliveryID không tồn tại.';
        RETURN;
    END

    -- Kiểm tra giá trị trạng thái hợp lệ
    IF @NewStatus NOT IN ('non-delivery', 'shipped', 'delivered')
    BEGIN
        PRINT N'Trạng thái không hợp lệ. Chỉ chấp nhận ''non-delivery'', ''shipped'' hoặc ''delivered''.';
        RETURN;
    END

    -- Cập nhật trạng thái và ngày giao thực tế
    UPDATE Delivery
    SET 
        status = @NewStatus,
        delivere_date = CASE 
                           WHEN @NewStatus = 'delivered' THEN ISNULL(@ActualDeliveryDate, GETDATE())
                           ELSE NULL
                        END
    WHERE DeliveryID = @DeliveryID;

    PRINT N'Cập nhật trạng thái giao hàng thành công.';
END;


-- Cập nhật trạng thái sang 'delivered' với ngày giao thực tế cụ thể
EXEC UpdateDeliveryStatus @DeliveryID = 3, @NewStatus = 'delivered', @ActualDeliveryDate = '2024-06-20';
--Cập nhật trạng thái sang 'pending'
EXEC UpdateDeliveryStatus @DeliveryID = 5, @NewStatus = 'pending';

--Con trỏ
-- Cập nhật trạng thái giao hàng chậm trễ
--  kiểm tra xem những đơn hàng nào chưa được giao (có trạng thái 'non-delivery'),
--đồng thời in ra thông tin về đơn hàng đó, bao gồm tên người giao hàng và ngày giao dự kiến.
CREATE PROCEDURE GetNonDeliveryOrders
AS
BEGIN
    DECLARE @order_id INT
    DECLARE @delivery_date DATETIME
    DECLARE @name_shipper NVARCHAR(100)
    DECLARE @status NVARCHAR(50)

    -- Khai báo con trỏ để duyệt qua các bản ghi của bảng Delivery với trạng thái 'non-delivery'
    DECLARE delivery_cursor CURSOR FOR
    SELECT order_id, delivery_date, name_shipper, status
    FROM Delivery
    WHERE status = 'non-delivery'

    -- Mở con trỏ
    OPEN delivery_cursor

    -- Lấy bản ghi đầu tiên
    FETCH NEXT FROM delivery_cursor INTO @order_id, @delivery_date, @name_shipper, @status

    -- Duyệt qua tất cả các bản ghi
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- In ra thông tin về đơn hàng chưa giao
        PRINT 'Order ID: ' + CAST(@order_id AS NVARCHAR) + 
              ', Delivery Date: ' + CAST(@delivery_date AS NVARCHAR) +
              ', Shipper: ' + @name_shipper +
              ', Status: ' + @status

        -- Lấy bản ghi tiếp theo
        FETCH NEXT FROM delivery_cursor INTO @order_id, @delivery_date, @name_shipper, @status
    END

    -- Đóng con trỏ
    CLOSE delivery_cursor
    DEALLOCATE delivery_cursor
END

EXEC GetNonDeliveryOrders;
select * from Delivery

--Thủ tục sử dụng con trỏ để cập nhật trạng thái đơn hàng từ 'non-delivery' sang 'shipped' nếu ngày giao dự kiến (delivery_date) đã qua
CREATE PROCEDURE UpdateDeliveryStatus
AS
BEGIN
    DECLARE @id INT
    DECLARE @delivery_date DATETIME
    DECLARE @status NVARCHAR(50)

    -- Khai báo con trỏ
    DECLARE delivery_cursor CURSOR FOR
    SELECT DeliveryID, delivery_date, status
    FROM Delivery
    WHERE status = 'non-delivery'

    -- Mở con trỏ
    OPEN delivery_cursor

    -- Đọc bản ghi đầu tiên
    FETCH NEXT FROM delivery_cursor INTO @id, @delivery_date, @status

    -- Duyệt qua từng bản ghi
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Kiểm tra ngày giao dự kiến đã qua chưa
        IF @delivery_date < GETDATE()
        BEGIN
            -- Cập nhật trạng thái thành 'shipped'
            UPDATE Delivery
            SET status = 'shipped'
            WHERE DeliveryID = @id
        END

        -- Lấy bản ghi tiếp theo
        FETCH NEXT FROM delivery_cursor INTO @id, @delivery_date, @status
    END

    -- Đóng và giải phóng con trỏ
    CLOSE delivery_cursor
    DEALLOCATE delivery_cursor
END

drop proc UpdateDeliveryStatus
EXEC UpdateDeliveryStatus
select * from Delivery

-- Hàm
-- Hàm tính số lượng đơn giao hàng theo trạng thái
create FUNCTION NumberOfOrders (@status NVARCHAR(50))
RETURNS INT
AS
BEGIN
DECLARE @count INT;

    SELECT @count = COUNT(*)
    FROM Delivery
    WHERE status = @status;

    RETURN @count;
END
-- Đếm số lượng đơn hàng đã được giao
SELECT dbo.NumberOfOrders('delivered') AS DeliveredCount;

-- Đếm số lượng đơn hàng chưa giao
SELECT dbo.NumberOfOrders('non-delivery') AS NonDeliveryCount;

-- Hàm tính tổng số ngày giao hàng thực tế so với ngày dự kiến
CREATE FUNCTION ToTal ()
RETURNS INT
AS
BEGIN
    DECLARE @tong INT;

    SELECT @tong = SUM(ABS(DATEDIFF(DAY, delivery_date, delivere_date)))
    FROM Delivery
    WHERE delivere_date IS NOT NULL;

    RETURN @tong;
END

drop function ToTal

-- Kiểm tra tổng số ngày chênh lệch giữa ngày dự kiến và thực tế
SELECT dbo.ToTal() AS TotalDaysDifference;

select * from Delivery




--Giao dịch
-- Giao dịch cập nhật thông tin người dùng
begin tran capnhatnguoidung
    insert into Users (Username, Password, Email, Address, Role, Status)
    values (N'testuser', CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', '123456'), 2), N'testuser@gmail.com', N'Hanoi', N'user', N'active');
    update Users
    set Status = 'locked'
    where Username = N'admin'
    -- Tạo độ trễ để kiểm tra giao dịch
    waitfor delay '00:00:10';
rollback tran;

-- Giao dịch kiểm tra thông tin người dùng
begin tran thongtinnguoidung
    set transaction isolation level serializable;
    select * from Users;
commit tran;


--Tạo login 
--1.Admin
sp_addlogin 'admin','admin123'
sp_addrole 'AdminRole'
grant all on Users to AdminRole
grant all on GameModel to AdminRole
grant all on Orders to AdminRole
grant all on Order_details to AdminRole
grant all on Delivery to AdminRole
sp_addrolemember 'AdminRole' , 'admin'

--2.Người dùng
sp_addlogin 'user','user123'
sp_addrole 'UserRole'
grant select on Users to UserRole
grant select on GameModel to UserRole
grant select on Orders to UserRole
grant select on Order_details to UserRole
grant select on Delivery to UserRole
sp_addrolemember 'UserRole', 'user'

--3.Quản lý người dùng
sp_addlogin 'user_manager','user_manager123'
sp_addrole 'UserManagerRole'
grant all on Users to UserManagerRole
sp_addrolemember 'UserManagerRole', 'user_manager'

--4.Quản lý sản phẩm
sp_addlogin 'product_manager','product_manager123'
sp_addrole 'ProductManagerRole'
grant all on GameModel to ProductManagerRole
sp_addrolemember 'ProductManagerRole', 'product_manager'

--5.Quản lý đơn hàng
sp_addlogin 'order_manager','order_manager123'
sp_addrole 'OrderManagerRole'
grant all on Orders to OrderManagerRole
grant all on Order_details to OrderManagerRole
grant select,update on Delivery to OrderManagerRole
sp_addrolemember 'OrderManagerRole','order_manager'

--6.Nhân viên giao hàng
sp_addlogin 'delivery_staff','delivery_staff123'
sp_addrole 'DeliveryStaffRole'
grant select on Orders to DeliveryStaffRole
grant select,update on Delivery to DeliveryStaffRole
sp_addrolemember 'DeliveryStaffRole','delivery_staff'

