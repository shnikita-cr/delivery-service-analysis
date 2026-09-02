WITH cancelled_orders AS (
  SELECT order_id
  FROM user_actions
  WHERE action = 'cancel_order'
), delivered_orders AS (
    SELECT order_id
    FROM courier_actions
    WHERE action = 'deliver_order'
), paying_clients_t AS (
  SELECT
    date,
    COUNT(user_id) paying_users
  FROM (
      SELECT
        time::DATE date,
        user_id,
        COUNT(order_id) orders_count
      FROM user_actions
      WHERE action = 'create_order'
        AND order_id NOT IN (SELECT * FROM cancelled_orders)
      GROUP BY time::DATE, user_id
  ) q
  WHERE orders_count>=1
  GROUP BY date
), active_couriers_t AS (
  SELECT
    date,
    COUNT(courier_id) active_couriers
  FROM (
      SELECT
        time::DATE date,
        courier_id,
        COUNT(order_id) orders_count
      FROM courier_actions
      WHERE (action = 'accept_order'
        AND order_id IN (SELECT * FROM delivered_orders)) OR action = 'deliver_order'
      GROUP BY time::DATE, courier_id
  ) q
  WHERE orders_count>=1
  GROUP BY date
), courier_action_number AS (
    SELECT
      courier_id,
      time,
      ROW_NUMBER() OVER(PARTITION BY courier_id ORDER BY time) action_number
    FROM
      courier_actions
), daily_new_couriers AS (
    SELECT
        time::DATE date,
        COUNT(courier_id) new_couriers
    FROM courier_action_number
    WHERE action_number = 1
    GROUP BY time::DATE
), user_action_number AS (
    SELECT
      user_id,
      time,
      ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY time) action_number
    FROM
      user_actions
), daily_new_users AS (
    SELECT
        time::DATE date,
        COUNT(user_id) new_users
    FROM user_action_number
    WHERE action_number = 1
    GROUP BY time::DATE
), total_users_couriers AS (
    SELECT
        date,
        SUM(new_users) OVER (ORDER BY date)::INTEGER total_users,
        SUM(new_couriers) OVER (ORDER BY date)::INTEGER total_couriers
    FROM
        daily_new_couriers JOIN daily_new_users USING(date)
)

SELECT
    date,
    paying_users,
    active_couriers,
    ROUND(paying_users*1.0 / total_users*100, 2)paying_users_share,
    ROUND(active_couriers*1.0 / total_couriers*100, 2) active_couriers_share
FROM paying_clients_t
    FULL JOIN active_couriers_t USING(date)
    FULL JOIN total_users_couriers USING(date)
ORDER BY date