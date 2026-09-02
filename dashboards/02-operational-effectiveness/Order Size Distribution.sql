SELECT
    COALESCE(ARRAY_LENGTH(product_ids, 1), 0) AS order_size,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS frequency
FROM orders
GROUP BY 1
ORDER BY 1