-- KPIs
SELECT
    SUM(total)           AS revenue,
    COUNT(total)         AS priced_orders,
    ROUND(AVG(total), 2) AS aov,
    SUM(quantity)        AS units
FROM dbo.cafe_clean
WHERE total IS NOT NULL;

-- By item, with share of revenue (window function)
SELECT
    item,
    COUNT(*)    AS orders,
    SUM(quantity) AS units,
    SUM(total)    AS revenue,
    ROUND(
        100.0 * SUM(total) / NULLIF(SUM(SUM(total)) OVER (), 0),
        1
    ) AS share_pct
FROM dbo.cafe_clean
WHERE total IS NOT NULL
GROUP BY item
ORDER BY revenue DESC;

-- By month (dated rows only)
SELECT
    FORMAT(txn_date, 'yyyy-MM') AS [month],
    SUM(total)                  AS revenue
FROM dbo.cafe_clean
WHERE total IS NOT NULL
  AND txn_date IS NOT NULL
GROUP BY FORMAT(txn_date, 'yyyy-MM')
ORDER BY [month];

-- By weekday (ISO-style day-of-week independent of @@DATEFIRST)
SELECT
    DATENAME(weekday, txn_date) AS weekday,
    ((DATEPART(weekday, txn_date) + @@DATEFIRST - 2) % 7) + 1 AS iso_dow,
    SUM(total) AS revenue
FROM dbo.cafe_clean
WHERE total IS NOT NULL
  AND txn_date IS NOT NULL
GROUP BY
    DATENAME(weekday, txn_date),
    ((DATEPART(weekday, txn_date) + @@DATEFIRST - 2) % 7) + 1
ORDER BY iso_dow;

-- By payment method
SELECT
    payment_method,
    COUNT(*)             AS orders,
    round(SUM(total),3)           AS revenue,
    ROUND(AVG(total), 2) AS aov
FROM dbo.cafe_clean
WHERE total IS NOT NULL
GROUP BY payment_method
ORDER BY revenue DESC;

-- By quantity
SELECT
    quantity,
    COUNT(*)  AS orders,
    SUM(total) AS revenue
FROM dbo.cafe_clean
WHERE total IS NOT NULL
  AND quantity IS NOT NULL
GROUP BY quantity
ORDER BY quantity;

-- Pivot-style: item by location
SELECT
    item,
    SUM(CASE WHEN location = N'In-store' THEN total END) AS in_store,
    SUM(CASE WHEN location = N'Takeaway' THEN total END) AS takeaway
FROM dbo.cafe_clean
WHERE total IS NOT NULL
GROUP BY item
ORDER BY item;

-- Revenue with no date (reconciliation: expect 4173.50)
SELECT
    SUM(CASE WHEN txn_date IS NULL THEN total END) AS undated_revenue
FROM dbo.cafe_clean;