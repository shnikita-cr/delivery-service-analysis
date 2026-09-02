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
                          GROUP BY time::DATE)

SELECT date,
       revenue,
       total_revenue,
       ROUND(((revenue - LAG(revenue) OVER (ORDER BY date)) / LAG(revenue) OVER (ORDER BY date)::DECIMAL) * 100,
             2) revenue_change
FROM (SELECT date,
             revenue,
             SUM(revenue) OVER (ORDER BY date) total_revenue
      FROM daily_orders_sum) q2
ORDER BY date
