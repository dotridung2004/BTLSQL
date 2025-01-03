-------------------------------------------------------------Users---------------------------------------------------------------------------------
create table Users (
    id int identity(1,1) primary key,
    username nvarchar(50) NOT NULL unique,
    password nvarchar(255) NOT NULL,
    email nvarchar(100) NOT NULL unique,
	address nvarchar(100),
    role nvarchar(10) check (role IN ('user', 'admin')) default 'user',
    status nvarchar(10) check (status IN ('active', 'locked')) default 'active',
    created_at datetime default GETDATE()
);

INSERT INTO Users (username, password, email, address, role, status)
VALUES 
('user1', 'password1', 'user1@example.com', 'Address 1', 'user', 'active'),
('user2', 'password2', 'user2@example.com', 'Address 2', 'user', 'active'),
('user3', 'password3', 'user3@example.com', 'Address 3', 'user', 'locked'),
('user4', 'password4', 'user4@example.com', 'Address 4', 'user', 'active'),
('user5', 'password5', 'user5@example.com', 'Address 5', 'user', 'locked'),
('user6', 'password6', 'user6@example.com', 'Address 6', 'admin', 'active'),
('user7', 'password7', 'user7@example.com', 'Address 7', 'user', 'active'),
('user8', 'password8', 'user8@example.com', 'Address 8', 'user', 'active'),
('user9', 'password9', 'user9@example.com', 'Address 9', 'user', 'locked'),
('user10', 'password10', 'user10@example.com', 'Address 10', 'user', 'active'),
('user11', 'password11', 'user11@example.com', 'Address 11', 'admin', 'locked'),
('user12', 'password12', 'user12@example.com', 'Address 12', 'user', 'active'),
('user13', 'password13', 'user13@example.com', 'Address 13', 'user', 'active'),
('user14', 'password14', 'user14@example.com', 'Address 14', 'user', 'locked'),
('user15', 'password15', 'user15@example.com', 'Address 15', 'user', 'active'),
('user16', 'password16', 'user16@example.com', 'Address 16', 'admin', 'active'),
('user17', 'password17', 'user17@example.com', 'Address 17', 'user', 'active'),
('user18', 'password18', 'user18@example.com', 'Address 18', 'user', 'locked'),
('user19', 'password19', 'user19@example.com', 'Address 19', 'user', 'active'),
('user20', 'password20', 'user20@example.com', 'Address 20', 'user', 'active');

--Trigger
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
Delete from users where username = 'user20'
SELECT * FROM users;
SELECT * FROM orders;

Alter trigger users_password
on users for insert,update
as
begin
	Declare @X nvarchar(100),@Y nvarchar(100)
	Select @X = password from inserted
	Select @Y = password from deleted
	if(@X = @Y)
		begin
			rollback tran
			print N'Mật khẩu cũ và mới không được trùng nhau'
		end
	if Exists(Select * from users where password = @X)
		begin
			rollback tran
			print N'Mật khẩu đã tồn tại'
		end
end
INSERT INTO Users (username, password, email)
VALUES ('user21', 'password1', 'user21@example.com');

--function

--view

--proc

--con trỏ

------------------------------------------------------------UserLoginHistory-------------------------------------------------------------------------

------------------------------------------------------------GameModel-------------------------------------------------------------------------------
Create table GameModel(
	id int identity(1,1) primary key,
	name nvarchar(100),
	price float,
	description nvarchar(200),
	stock int,
	image nvarchar(50),
	rating float null,
	created_at datetime default GetDate()
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


Create table Orders(
	id int identity(1,1) primary key,
	userid int,
	order_date datetime default GetDate(),
	note nvarchar(200),
	foreign key (userid) references users(id)
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
Select * from orders

create table Order_details(
	id int identity(1,1) primary key,
	order_id int,
	game_model_id int,
	quantity int,
	unit_price float,
	total_price float,
	status nvarchar(50),check (status IN ('completed', 'not_completed')),
	foreign key (order_id) references orders(id),
	foreign key (game_model_id) references GameModel(id)
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
update Order_details
Set unit_price =(
select price from GameModel
where GameModel.id=Order_details.game_model_id
)
WHERE EXISTS (
    SELECT *
    FROM GameModel
    WHERE GameModel.id=Order_details.game_model_id
);
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
SET unit_price = 10.99
WHERE id = 1; 
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
    SELECT id, status
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
            WHERE id = @id;
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
DELETE FROM Order_details WHERE id = 20;
--function
--1.viết 1 hàm in ra các mặt hàng bán chạy nhất
create FUNCTION GetBestSellingItem(@Top INT)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@Top)
        GameModel.id AS GameModelID,
        GameModel.name AS GameModelName,
        COUNT(DISTINCT order_id) AS TotalBuyers,
        SUM(quantity) AS TotalQuantitySold,
        SUM(total_price) AS TotalRevenue
    FROM Order_details 
    INNER JOIN GameModel  ON Order_details.game_model_id = GameModel.id
	WHERE status = 'Completed'
    GROUP BY GameModel.id,GameModel.name
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
    AND order_id IN (SELECT id FROM orders WHERE order_date BETWEEN @StartDate AND @EndDate);

    RETURN ISNULL(@TotalRevenue, 0);
END;
SELECT dbo.GetRevenueByDateRange('2024-12-08', '2025-12-09') AS TotalRevenue;
--view
--1. viết View phân tích tỷ lệ hoàn thành đơn hàng
CREATE VIEW OrderStatusPercentage AS
SELECT 
    status,
    COUNT(id) AS TotalOrders,
    CAST(COUNT(id) * 100.0 / SUM(COUNT(id)) OVER () AS DECIMAL(5, 2)) AS Percentage
FROM 
    Order_details
GROUP BY 
    status
select * from OrderStatusPercentage
--1.Viết 1 view hiện thị danh sách trạng thái đơn hàng theo từng khách hàng
Alter VIEW CustomerOrderStatus AS
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
    Orders  ON Order_details.order_id = Orders.id
INNER JOIN 
    Users  ON Orders.userid = Users.id
GROUP BY 
    Orders.userid, Users.username, Order_details.order_id, Order_details.status;
select * from CustomerOrderStatus
--2.View phân tích khách hàng theo giá trị đơn hàng
ALTER VIEW CustomerOrderValueAnalysis AS
SELECT 
    Orders.userid,
    Users.username,  
    COUNT(Order_details.id) AS TotalOrders,
    SUM(Order_details.total_price) AS TotalSpent,
    AVG(Order_details.total_price) AS AverageOrderValue,
    MAX(Order_details.total_price) AS MaxOrderValue,
    MIN(Order_details.total_price) AS MinOrderValue
FROM 
    Order_details
JOIN 
    Orders  ON Order_details.order_id = Orders.id
JOIN
    Users   ON Orders.userid = Users.id  
GROUP BY 
    Orders.userid, Users.username
	ORDER BY TotalSpent DESC
SELECT * FROM CustomerOrderValueAnalysis
ORDER BY TotalSpent DESC
--proc
--1.viết 1 thủ tục hiển thị thông tin sản phầm theo mã đơn hàng
alter PROCEDURE GetOrderProducts
    @OrderID INT
AS
BEGIN
    SELECT 
        order_id,game_model_id,name,description,stock,image,rating,quantity,price as unit_price,total_price ,created_at 
    FROM 
        Order_details
    INNER JOIN 
        GameModel  ON Order_details.game_model_id = GameModel.id
    WHERE 
        Order_details.order_id = @OrderID;
END;
EXEC GetOrderProducts @OrderID = 1;
--2.Viết thủ tục cập nhật số lượng sản phẩm trong đơn hàng 
alter PROCEDURE UpdateOrderDetailQuantity
(
    @order_detail_id INT,
    @new_quantity INT
)
AS
BEGIN
    DECLARE @message NVARCHAR(50);
    if NOT EXISTS (SELECT id FROM Order_details WHERE id = @order_detail_id)
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
    WHERE id = @order_detail_id;
    SET @message = N'Số lượng được cập nhật thành công.';
    PRINT @message;
END;
EXEC UpdateOrderDetailQuantity @order_detail_id = 30, @new_quantity = 30;
--con trỏ(ở 2 trigger)

Create table Delivery(
	id int identity(1,1) primary key,
	order_id int,
	delivery_date datetime,
	delivere_date datetime,
	status nvarchar(50) check (status in ('non-delivery','shipped','delivered')) default 'non-delivery',
	delivery_address nvarchar(100),
	name_shipper nvarchar(100),
	foreign key (order_id) references orders(id)
)
-- Create Delivery table
CREATE TABLE Delivery (
    id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT,
    delivery_date DATETIME,
    delivere_date DATETIME,
    status NVARCHAR(50) CHECK (status IN ('non-delivery', 'shipped', 'delivered')) DEFAULT 'non-delivery',
    delivery_address NVARCHAR(100),
    name_shipper NVARCHAR(100),
    FOREIGN KEY (order_id) REFERENCES Orders(id)
);

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
