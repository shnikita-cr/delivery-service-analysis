WITH cancelled_orders AS (SELECT order_id
                          FROM user_actions
                          WHERE action = 'cancel_order'),
     orders_sum AS (SELECT order_id,
                           SUM(price) order_sum
                    FROM (SELECT order_id,
                                 UNNEST(product_ids) product_id
                          FROM orders) q1
                             JOIN products USING (product_id)
                    GROUP BY order_id),
     daily_orders_sum AS (SELECT time::DATE     date,
                                 SUM(order_sum) revenue
                          FROM user_actions
                                   JOIN orders_sum USING (order_id)
                          WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
                            AND action = 'create_order'
                          GROUP BY time::DATE),
     daily_users AS (SELECT time::DATE              date,
                            COUNT(DISTINCT user_id) users_day_count
                     FROM user_actions
                     GROUP BY time::DATE),
     daily_orders AS (SELECT time::DATE               date,
                             COUNT(DISTINCT order_id) orders_day_count,
                             COUNT(DISTINCT user_id)  active_users_day_count
                      FROM user_actions
                      WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
                      GROUP BY time::DATE)

SELECT date,
       ROUND(revenue::DECIMAL / users_day_count, 2)        arpu,
       ROUND(revenue::DECIMAL / active_users_day_count, 2) arppu,
       ROUND(revenue::DECIMAL / orders_day_count, 2)       aov
FROM daily_orders_sum
         JOIN daily_users USING (date)
         JOIN daily_orders USING (date)
ORDER BY date