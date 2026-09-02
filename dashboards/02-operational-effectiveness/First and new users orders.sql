WITH cancelled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
), user_days_num_t AS (
     SELECT
        time::DATE date,
        user_id,
        order_id,
        MIN(time::DATE) OVER (PARTITION BY user_id) first_day
    FROM user_actions
), user_orders_num_t AS (
    SELECT
        time::DATE date,
        user_id,
        order_id,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY time) order_number
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
), metrics_t AS (
    -- Объединяем пункты 2 и 3: одна группировка вместо трех CTE и LEFT JOIN
    SELECT
        uon.date,
        COUNT(DISTINCT uon.order_id) as orders,
        COUNT(CASE WHEN uon.order_number = 1 THEN uon.order_id END) as first_orders,
        COUNT(CASE WHEN udn.first_day = uon.date THEN uon.order_id END) as new_users_orders
    FROM user_orders_num_t uon
    LEFT JOIN user_days_num_t udn USING(order_id) -- подтягиваем истинный первый день
    GROUP BY uon.date
)

SELECT
    date,
    orders,
    first_orders,
    new_users_orders,
    ROUND(first_orders::DECIMAL / orders * 100, 2) as first_orders_share,
    ROUND(new_users_orders::DECIMAL / orders * 100, 2) as new_users_orders_share
FROM
    metrics_t
ORDER BY
    date;
