WITH cancelled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
), not_cancelled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
), n_paying_users AS (
    SELECT
        time::DATE date,
        user_id,
        COUNT(order_id) AS num_orders
    FROM user_actions JOIN not_cancelled_orders USING(order_id)
    GROUP BY time::DATE, user_id
), single_order_users_t AS (
    SELECT
        date,
        COUNT(user_id) single_order_users
    FROM n_paying_users
    WHERE num_orders = 1
    GROUP BY date
), several_orders_users_t AS (
    SELECT
        date,
        COUNT(user_id) several_orders_users
    FROM n_paying_users
    WHERE num_orders > 1
        GROUP BY date
)

SELECT
    date,
    ROUND(single_order_users::DECIMAL  /(single_order_users+several_orders_users)*100,2) single_order_users_share,
    ROUND(several_orders_users::DECIMAL/(single_order_users+several_orders_users)*100,2) several_orders_users_share
FROM
    single_order_users_t
    JOIN several_orders_users_t USING(date)
ORDER BY date