WITH cancelled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
), delivered_orders AS (
    SELECT order_id
    FROM courier_actions
    WHERE action = 'deliver_order'
), orders_t AS (
    SELECT
        creation_time AS time,
        order_id,
        CASE
            WHEN order_id IN (SELECT order_id FROM delivered_orders) THEN TRUE
            ELSE FALSE
        END is_delivered,
        CASE
            WHEN order_id IN (SELECT order_id FROM cancelled_orders) THEN TRUE
            ELSE FALSE
        END is_cancelled
    FROM orders
), orders_metrics AS (
    SELECT
        EXTRACT(HOUR FROM time)::INTEGER AS hour,
        COUNT(order_id) FILTER (WHERE is_delivered = TRUE) successful_orders,
        COUNT(order_id) FILTER (WHERE is_cancelled = TRUE) canceled_orders
    FROM orders_t
    GROUP BY EXTRACT(HOUR FROM time)::INTEGER
    ORDER BY EXTRACT(HOUR FROM time)::INTEGER

)

SELECT
    hour,
    successful_orders,
    canceled_orders,
    ROUND(canceled_orders::DECIMAL/(successful_orders+canceled_orders),3) cancel_rate
FROM orders_metrics

