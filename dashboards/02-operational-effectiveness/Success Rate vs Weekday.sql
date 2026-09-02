SELECT DATE_PART('isodow', time)::INTEGER AS weekday_number,
       to_char(time, 'Dy')                AS weekday,
       COUNT(DISTINCT order_id) FILTER (
           WHERE
           action = 'create_order'
           )                              AS created_orders,
       COUNT(DISTINCT order_id) FILTER (
           WHERE
           action = 'cancel_order'
           )                              AS canceled_orders,
       COUNT(DISTINCT order_id) FILTER (
           WHERE
           action = 'create_order'
           ) - COUNT(DISTINCT order_id) FILTER (
           WHERE
           action = 'cancel_order'
           )                              AS actual_orders,
       ROUND((COUNT(DISTINCT order_id) FILTER (
           WHERE
           action = 'create_order'
           ) - COUNT(DISTINCT order_id) FILTER (
           WHERE
           action = 'cancel_order'
           )) / COUNT(DISTINCT order_id) FILTER (
           WHERE
           action = 'create_order'
           ):: DECIMAL, 3)                AS success_rate
FROM user_actions
WHERE time >= '2022-08-24'
  AND time <= '2022-09-07'
GROUP BY weekday_number,
         weekday
ORDER BY weekday_number
