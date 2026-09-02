WITH cancelled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
), order_type AS (
    SELECT
        time,
        order_id,
        (ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY time) = 1) is_first,
        COUNT(order_id) OVER (PARTITION BY time::DATE) count_all
    FROM user_actions
    WHERE action = 'create_order' AND order_id NOT IN (SELECT * FROM cancelled_orders)
)

SELECT
    time::DATE date,
    CASE
        WHEN is_first = true THEN 'Первый'
        ELSE 'Повторный'
    END order_type,
    COUNT(order_id) orders_count,
    ROUND(COUNT(order_id)*1.0 / count_all, 2)  orders_share
FROM order_type
GROUP BY date, is_first, count_all
ORDER BY date, order_type