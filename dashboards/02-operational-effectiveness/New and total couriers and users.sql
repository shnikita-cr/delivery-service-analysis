WITH courier_action_number AS (
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
)

SELECT
    date,
    new_users,
    new_couriers,
    SUM(new_users) OVER (ORDER BY date)::INTEGER total_users,
    SUM(new_couriers) OVER (ORDER BY date)::INTEGER total_couriers
FROM
    daily_new_couriers JOIN daily_new_users USING(date)
ORDER BY date

