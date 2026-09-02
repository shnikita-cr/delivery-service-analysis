WITH cancelled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
), orders_sum AS (
    SELECT
        name product_name,
        SUM(price) AS product_sum
    FROM
        (SELECT
            order_id,
            UNNEST(product_ids) product_id
        FROM orders ) q1
        JOIN products USING(product_id)
    WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
    GROUP BY name
), round_sums AS (
    SELECT
        product_name,
        product_sum revenue,
        ROUND((product_sum/SUM(product_sum) OVER ()*100),2) share_in_revenue,
        ROUND((product_sum/SUM(product_sum) OVER ()*100),2) > 0.5 big_product
    FROM orders_sum
)

SELECT
    product_name,
    revenue,
    share_in_revenue
FROM round_sums
WHERE big_product = true

UNION ALL

SELECT
    'ДРУГОЕ',
    SUM(revenue),
    SUM(share_in_revenue)
FROM round_sums
WHERE big_product = false
ORDER BY revenue DESC