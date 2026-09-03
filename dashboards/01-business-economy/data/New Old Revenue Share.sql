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
     user_actions_with_first_dates AS (SELECT time,
                                              user_id,
                                              order_id,
                                              action,
                                              MIN(time::DATE) OVER (PARTITION BY user_id) first_date
                                       FROM user_actions),
     daily_orders_sum AS (SELECT time::DATE     date,
                                 CASE
                                     WHEN time::DATE = first_date THEN 'new_user'
                                     ELSE 'old_user'
                                     END        user_type,
                                 SUM(order_sum) revenue
                          FROM user_actions_with_first_dates
                                   JOIN orders_sum USING (order_id)
                                   LEFT JOIN cancelled_orders USING (order_id)
                          WHERE action = 'create_order'
                            AND cancelled_orders.order_id IS NULL
                          GROUP BY time::DATE, user_type),
     new_old_revenue AS (SELECT date,
                                SUM(revenue) FILTER (WHERE user_type = 'new_user') new_users_revenue,
                                SUM(revenue) FILTER (WHERE user_type = 'old_user') old_users_revenue,
                                SUM(revenue)                                       revenue
                         FROM daily_orders_sum
                         GROUP BY date)

SELECT date,
       revenue,
       COALESCE(new_users_revenue, 0)                                    new_users_revenue,
       ROUND(COALESCE(new_users_revenue, 0)::DECIMAL / revenue * 100, 2) new_users_revenue_share,
       ROUND(COALESCE(old_users_revenue, 0)::DECIMAL / revenue * 100, 2) old_users_revenue_share
FROM new_old_revenue
ORDER BY date