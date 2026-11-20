CREATE TABLE dbo.menu (
    item  NVARCHAR(100) PRIMARY KEY,
    price DECIMAL(4, 2) NOT NULL
);

INSERT INTO dbo.menu (item, price)
VALUES
    (N'Cookie',   1.00),
    (N'Tea',      1.50),
    (N'Coffee',   2.00),
    (N'Cake',     3.00),
    (N'Juice',    3.00),
    (N'Sandwich', 4.00),
    (N'Smoothie', 4.00),
    (N'Salad',    5.00);
GO

CREATE VIEW dbo.cafe_clean
AS
WITH s1 AS ( -- recover price: own value, then menu, then total / quantity
    SELECT
        t.transaction_id,
        t.item,
        t.quantity,
        t.total,
        t.payment_method,
        t.location,
        t.txn_date,
        COALESCE(
            t.price,
            m.price,
            t.total / NULLIF(CAST(t.quantity AS DECIMAL(18, 4)), 0)
        ) AS price
    FROM dbo.stg_typed AS t
    LEFT JOIN dbo.menu AS m
        ON m.item = t.item
),
s2 AS ( -- recover quantity and total
    SELECT
        transaction_id,
        item,
        price,
        payment_method,
        location,
        txn_date,
        COALESCE(
            quantity,
            TRY_CAST(ROUND(total / NULLIF(price, 0), 0) AS INT)
        ) AS quantity,
        COALESCE(
            total,
            CAST(quantity AS DECIMAL(18, 2)) * price
        ) AS total
    FROM s1
)
SELECT
    transaction_id,
    COALESCE(
        item,
        CASE price
            WHEN 1.00 THEN N'Cookie'
            WHEN 1.50 THEN N'Tea'
            WHEN 2.00 THEN N'Coffee'
            WHEN 5.00 THEN N'Salad'
        END,
        N'Unknown'
    ) AS item,
    quantity,
    price,
    total,
    COALESCE(payment_method, N'Unknown') AS payment_method,
    COALESCE(location, N'Unknown')       AS location,
    txn_date
FROM s2;
GO