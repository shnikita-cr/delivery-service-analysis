SELECT COUNT(DISTINCT user_id)  AS unique_users,
       COUNT(DISTINCT order_id) AS unique_orders,
       ROUND(
               COUNT(DISTINCT order_id) :: DECIMAL / COUNT(DISTINCT user_id),
               2
       )                        AS orders_per_user
FROM user_actions