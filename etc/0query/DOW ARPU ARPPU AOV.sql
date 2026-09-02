WITH cancelled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
      AND time::DATE BETWEEN '2022-08-26' AND '2022-09-08'
),

orders_sum AS (
    SELECT
        unpacked_orders.order_id,
        SUM(products.price) AS order_sum
    FROM (
        SELECT
            order_id,
            UNNEST(product_ids) AS product_id
        FROM orders
    ) AS unpacked_orders
    JOIN products USING(product_id)
    GROUP BY unpacked_orders.order_id
),

weekly_metrics_aggregated AS (
    SELECT
        to_char(user_actions.time, 'Day') AS weekday,
        DATE_PART('isodow', user_actions.time) AS weekday_number,

        SUM(CASE
            WHEN user_actions.action = 'create_order' AND user_actions.order_id NOT IN (SELECT order_id FROM cancelled_orders)
            THEN orders_sum.order_sum
            ELSE 0
        END) AS total_revenue,

        COUNT(DISTINCT CASE
            WHEN user_actions.action = 'create_order' AND user_actions.order_id NOT IN (SELECT order_id FROM cancelled_orders)
            THEN user_actions.order_id
        END) AS total_orders_count,

        COUNT(DISTINCT user_actions.user_id) AS total_users_count,

        COUNT(DISTINCT CASE
            WHEN user_actions.action = 'create_order' AND user_actions.order_id NOT IN (SELECT order_id FROM cancelled_orders)
            THEN user_actions.user_id
        END) AS total_active_users_count

    FROM user_actions
    LEFT JOIN orders_sum USING(order_id)
    WHERE user_actions.time::DATE BETWEEN '2022-08-26' AND '2022-09-08'
    GROUP BY to_char(user_actions.time, 'Day'), DATE_PART('isodow', user_actions.time)
)

SELECT
    weekday,
    weekday_number,
    ROUND(total_revenue::DECIMAL / total_users_count, 2) AS arpu,
    ROUND(total_revenue::DECIMAL / total_active_users_count, 2) AS arppu,
    ROUND(total_revenue::DECIMAL / total_orders_count, 2) AS aov
FROM weekly_metrics_aggregated
ORDER BY weekday_number;
