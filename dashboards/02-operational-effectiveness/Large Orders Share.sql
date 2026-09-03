SELECT COUNT(order_id) AS orders,
       COUNT(order_id) FILTER (
           WHERE
           ARRAY_LENGTH(product_ids, 1) >= 5
           )           AS large_orders,
       ROUND(
                       COUNT(order_id) FILTER (
                   WHERE
                   ARRAY_LENGTH(product_ids, 1) >= 5
                   ) / COUNT(order_id) :: DECIMAL,
                       2
       )               AS large_orders_share
FROM orders