WITH cancelled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
), users_orders_per_day_created AS (
    SELECT
        time::DATE date,
        COUNT(DISTINCT order_id) order_count,
        COUNT(DISTINCT user_id) user_count
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
    GROUP BY time::DATE
), active_couriers AS (
    SELECT
        time::DATE date,
        COUNT(DISTINCT courier_id) courier_count
    FROM courier_actions
    WHERE action = 'deliver_order'
        OR order_id IN
            (SELECT order_id
            FROM courier_actions
            WHERE action = 'deliver_order')
    GROUP BY time::DATE
)

SELECT
    date,
    ROUND(user_count::DECIMAL/courier_count,2) users_per_courier,
    ROUND(order_count::DECIMAL/courier_count,2) orders_per_courier
FROM users_orders_per_day_created JOIN active_couriers USING(date)
ORDER BY date