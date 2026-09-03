WITH cancelled_orders AS (SELECT DISTINCT order_id
                          FROM user_actions
                          WHERE action = 'cancel_order'),
     order_products AS (SELECT o.creation_time::DATE AS date,
                               o.order_id,
                               p.name,
                               p.price
                        FROM orders o
                                 CROSS JOIN UNNEST(o.product_ids) AS product_id
                                 JOIN products p USING (product_id)
                        WHERE o.order_id NOT IN (SELECT order_id
                                                 FROM cancelled_orders)),
     revenue_tax_by_day AS (SELECT date,
                                   SUM(price) AS revenue,
                                   SUM(
                                           ROUND(
                                                   CASE
                                                       WHEN name IN (
                                                                     'сахар', 'сухарики', 'сушки', 'семечки',
                                                                     'масло льняное', 'виноград', 'масло оливковое',
                                                                     'арбуз', 'батон', 'йогурт', 'сливки', 'гречка',
                                                                     'овсянка', 'макароны', 'баранина', 'апельсины',
                                                                     'бублики', 'хлеб', 'горох', 'сметана',
                                                                     'рыба копченая', 'мука', 'шпроты', 'сосиски',
                                                                     'свинина', 'рис', 'масло кунжутное', 'сгущенка',
                                                                     'ананас', 'говядина', 'соль', 'рыба вяленая',
                                                                     'масло подсолнечное', 'яблоки', 'груши',
                                                                     'лепешка', 'молоко', 'курица', 'лаваш',
                                                                     'вафли', 'мандарины'
                                                           )
                                                           THEN price * 10.0 / 110.0
                                                       ELSE price * 20.0 / 120.0
                                                       END,
                                                   2
                                           )
                                   )          AS tax
                            FROM order_products
                            GROUP BY date),
     orders_by_day AS (SELECT creation_time::DATE AS date,
                              COUNT(*)            AS orders_count
                       FROM orders
                       WHERE order_id NOT IN (SELECT order_id
                                              FROM cancelled_orders)
                       GROUP BY creation_time::DATE),
     courier_deliveries_by_day AS (SELECT time::DATE AS date,
                                          COUNT(*)   AS deliveries_count
                                   FROM courier_actions
                                   WHERE action = 'deliver_order'
                                   GROUP BY time::DATE),
     courier_daily_deliveries AS (SELECT time::DATE AS date,
                                         courier_id,
                                         COUNT(*)   AS deliveries_count
                                  FROM courier_actions
                                  WHERE action = 'deliver_order'
                                  GROUP BY time::DATE,
                                           courier_id),
     courier_bonuses_by_day AS (SELECT date,
                                       COUNT(*) FILTER (
                                           WHERE deliveries_count >= 5
                                           ) AS bonus_couriers_count
                                FROM courier_daily_deliveries
                                GROUP BY date),
     dates AS (SELECT creation_time::DATE AS date
               FROM orders
               UNION
               SELECT time::DATE AS date
               FROM courier_actions),
     daily_metrics AS (SELECT d.date,
                              COALESCE(rt.revenue, 0) AS revenue,
                              (
                                  CASE
                                      WHEN d.date < DATE '2022-09-01'
                                          THEN 120000
                                      ELSE 150000
                                      END
                                      +
                                  COALESCE(obd.orders_count, 0)
                                      *
                                  CASE
                                      WHEN d.date < DATE '2022-09-01'
                                          THEN 140
                                      ELSE 115
                                      END
                                      +
                                  COALESCE(cdd.deliveries_count, 0) * 150
                                      +
                                  COALESCE(cbb.bonus_couriers_count, 0)
                                      *
                                  CASE
                                      WHEN d.date < DATE '2022-09-01'
                                          THEN 400
                                      ELSE 500
                                      END
                                  )::DECIMAL          AS costs,
                              COALESCE(rt.tax, 0)     AS tax
                       FROM dates d
                                LEFT JOIN revenue_tax_by_day rt
                                          ON d.date = rt.date
                                LEFT JOIN orders_by_day obd
                                          ON d.date = obd.date
                                LEFT JOIN courier_deliveries_by_day cdd
                                          ON d.date = cdd.date
                                LEFT JOIN courier_bonuses_by_day cbb
                                          ON d.date = cbb.date

                       WHERE d.date BETWEEN DATE '2022-08-01'
                                 AND DATE '2022-09-30'),
     daily_profit AS (SELECT date,
                             revenue,
                             costs,
                             tax,
                             revenue - costs - tax AS gross_profit
                      FROM daily_metrics),
     metrics_with_totals AS (SELECT date,
                                    revenue,
                                    costs,
                                    tax,
                                    gross_profit,
                                    SUM(revenue) OVER (
                                        ORDER BY date
                                        ) AS total_revenue,
                                    SUM(costs) OVER (
                                        ORDER BY date
                                        ) AS total_costs,
                                    SUM(tax) OVER (
                                        ORDER BY date
                                        ) AS total_tax,
                                    SUM(gross_profit) OVER (
                                        ORDER BY date
                                        ) AS total_gross_profit
                             FROM daily_profit)

SELECT date,
       revenue,
       costs,
       tax,
       gross_profit,
       total_revenue,
       total_costs,
       total_tax,
       total_gross_profit,
       ROUND(
               gross_profit::DECIMAL
                   / NULLIF(revenue, 0)
                   * 100,
               2
       ) AS gross_profit_ratio,
       ROUND(
               total_gross_profit::DECIMAL
                   / NULLIF(total_revenue, 0)
                   * 100,
               2
       ) AS total_gross_profit_ratio
FROM metrics_with_totals
ORDER BY date;