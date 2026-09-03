SELECT TO_CHAR(creation_time, 'Day')               AS Day,
       ROUND(AVG(ARRAY_LENGTH(product_ids, 1)), 2) AS avg_order_size
FROM orders
GROUP BY TO_CHAR(creation_time, 'Day'), DATE_PART('isodow', creation_time)
ORDER BY DATE_PART('isodow', creation_time)