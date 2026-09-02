WITH cancelled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
), courier_time AS (
    SELECT
        time::DATE date,
        action,
        MAX(time) OVER (PARTITION BY order_id ORDER BY time) - MIN(time) OVER (PARTITION BY order_id ORDER BY time) diff
    FROM courier_actions
    WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
), courier_time_stats AS (
    SELECT
        date,
        (EXTRACT (EPOCH FROM diff))/60 minutes
    FROM courier_time
    WHERE action = 'deliver_order'
)

SELECT
    date,
    ROUND(AVG(minutes)::DECIMAL)::INTEGER minutes_to_deliver
FROM courier_time_stats
GROUP BY date
ORDER BY date