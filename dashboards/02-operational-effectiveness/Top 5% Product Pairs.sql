WITH cancelled_orders AS (SELECT order_id
                          FROM user_actions
                          WHERE action = 'cancel_order'),
     tt AS (SELECT order_id, UNNEST(product_ids) product_id
            FROM orders
            WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)),
     t AS (SELECT order_id, product_id, name
           FROM tt
                    JOIN products USING (product_id)),
     pairs AS (SELECT DISTINCT lft.order_id, ARRAY_SORT(ARRAY [lft.name, rght.name]) pair
               FROM t lft
                        JOIN t rght ON lft.order_id = rght.order_id AND lft.product_id != rght.product_id),
     aggregated_pairs AS (SELECT pair,
                                 COUNT(pair) AS count_pair
                          FROM pairs
                          GROUP BY pair),
     ranked_pairs AS (SELECT pair,
                             count_pair,
                             ROW_NUMBER() OVER (ORDER BY count_pair DESC, pair) AS row_num,
                             COUNT(*) OVER ()                                   AS total_rows
                      FROM aggregated_pairs)
SELECT pair, count_pair
FROM ranked_pairs
WHERE row_num <= (total_rows * 0.05)
ORDER BY count_pair DESC, pair;
