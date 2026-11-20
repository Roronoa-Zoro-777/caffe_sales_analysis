SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT transaction_id) AS distinct_ids
FROM dbo.raw_cafe_sales;

SELECT
    item,
    COUNT(*) AS row_count
FROM dbo.raw_cafe_sales
GROUP BY item
ORDER BY row_count DESC;

SELECT
    COUNT(CASE WHEN item IS NULL OR UPPER(LTRIM(RTRIM(item))) IN ('', 'ERROR', 'UNKNOWN') THEN 1 END) AS item_bad,
    COUNT(CASE WHEN payment_method IS NULL OR UPPER(LTRIM(RTRIM(payment_method))) IN ('', 'ERROR', 'UNKNOWN') THEN 1 END) AS payment_bad,
    COUNT(CASE WHEN location IS NULL OR UPPER(LTRIM(RTRIM(location))) IN ('', 'ERROR', 'UNKNOWN') THEN 1 END) AS location_bad
FROM dbo.raw_cafe_sales;

CREATE FUNCTION dbo.fn_clean_txt (@t NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @trimmed NVARCHAR(MAX) = LTRIM(RTRIM(@t));

    IF @trimmed IS NULL OR UPPER(@trimmed) IN (N'', N'ERROR', N'UNKNOWN')
        RETURN NULL;

    RETURN @trimmed;
END;
GO

CREATE VIEW dbo.stg_typed
AS
SELECT
    transaction_id,
    dbo.fn_clean_txt(item)                                    AS item,
    TRY_CAST(dbo.fn_clean_txt(quantity) AS INT)               AS quantity,
    TRY_CAST(dbo.fn_clean_txt(price_per_unit) AS DECIMAL(6, 2)) AS price,
    TRY_CAST(dbo.fn_clean_txt(total_spent) AS DECIMAL(8, 2))    AS total,
    dbo.fn_clean_txt(payment_method)                          AS payment_method,
    dbo.fn_clean_txt(location)                                AS location,
    TRY_CAST(dbo.fn_clean_txt(transaction_date) AS DATE)      AS txn_date
FROM dbo.raw_cafe_sales;
GO

-- One price per item?
SELECT
    item,
    price,
    COUNT(*) AS row_count
FROM dbo.stg_typed
WHERE item IS NOT NULL
  AND price IS NOT NULL
GROUP BY item, price
ORDER BY price, item;

-- Does quantity x price = total? (expect 0 rows violating)
SELECT
    COUNT(*) AS violating_rows
FROM dbo.stg_typed
WHERE quantity * price <> total;

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

SELECT
    COUNT(CASE WHEN item = N'Unknown' THEN 1 END)           AS item_unknown,
    COUNT(CASE WHEN quantity IS NULL THEN 1 END)             AS qty_null,
    COUNT(CASE WHEN price IS NULL THEN 1 END)                AS price_null,
    COUNT(CASE WHEN total IS NULL THEN 1 END)                AS total_null,
    COUNT(CASE WHEN payment_method = N'Unknown' THEN 1 END)  AS pay_unknown,
    COUNT(CASE WHEN location = N'Unknown' THEN 1 END)        AS loc_unknown,
    COUNT(CASE WHEN txn_date IS NULL THEN 1 END)             AS date_null
FROM dbo.cafe_clean;