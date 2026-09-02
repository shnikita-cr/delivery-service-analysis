WITH cancelled_orders AS (SELECT order_id
                          FROM user_actions
                          WHERE action = 'cancel_order'),

     orders_sum AS (SELECT unpacked_orders.order_id,
                           SUM(products.price) AS order_sum
                    FROM (SELECT order_id,
                                 UNNEST(product_ids) AS product_id
                          FROM orders) AS unpacked_orders
                             JOIN products USING (product_id)
                    GROUP BY unpacked_orders.order_id),

     daily_financials AS (SELECT user_actions.time::DATE      AS date,
                                 SUM(orders_sum.order_sum)    AS revenue,
                                 COUNT(user_actions.order_id) AS orders_day_count
                          FROM user_actions
                                   JOIN orders_sum USING (order_id)
                          WHERE user_actions.action = 'create_order'
                            AND user_actions.order_id NOT IN (SELECT order_id FROM cancelled_orders)
                          GROUP BY user_actions.time::DATE),

     daily_new_users AS (SELECT date,
                                COUNT(user_id) FILTER (WHERE rn_all = 1)  AS users_day_count,
                                COUNT(user_id) FILTER (WHERE rn_paid = 1) AS active_users_day_count
                         FROM (SELECT time::DATE                                             AS date,
                                      user_id,
                                      ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY time) AS rn_all,
                                      CASE
                                          WHEN order_id NOT IN (SELECT order_id FROM cancelled_orders)
                                              THEN ROW_NUMBER()
                                                   OVER (PARTITION BY user_id, (order_id NOT IN (SELECT order_id FROM cancelled_orders)) ORDER BY time)
                                          END                                                AS rn_paid
                               FROM user_actions
                               WHERE action = 'create_order') AS users_with_rows
                         GROUP BY date),

     running_metrics AS (SELECT daily_financials.date,
                                SUM(daily_financials.revenue) OVER (ORDER BY daily_financials.date) AS total_revenue,
                                SUM(COALESCE(daily_new_users.users_day_count, 0))
                                OVER (ORDER BY daily_financials.date)                               AS total_users_day_count,
                                SUM(COALESCE(daily_new_users.active_users_day_count, 0))
                                OVER (ORDER BY daily_financials.date)                               AS total_active_users_day_count,
                                SUM(daily_financials.orders_day_count)
                                OVER (ORDER BY daily_financials.date)                               AS total_orders_day_count
                         FROM daily_financials
                                  LEFT JOIN daily_new_users USING (date))

SELECT date,
       ROUND(total_revenue::DECIMAL / total_users_day_count, 2)        AS running_arpu,
       ROUND(total_revenue::DECIMAL / total_active_users_day_count, 2) AS running_arppu,
       ROUND(total_revenue::DECIMAL / total_orders_day_count, 2)       AS running_aov
FROM running_metrics
ORDER BY date;
