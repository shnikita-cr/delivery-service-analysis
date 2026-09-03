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
), new_users_couriers AS (
    SELECT
        date,
        new_users,
        new_couriers,
        SUM(new_users) OVER (ORDER BY date)::INTEGER total_users,
        SUM(new_couriers) OVER (ORDER BY date)::INTEGER total_couriers
    FROM
        daily_new_couriers JOIN daily_new_users USING(date)
    ORDER BY date
)

SELECT
    date, new_users, new_couriers, total_users, total_couriers,
    ROUND((new_users-LAG(new_users) OVER (ORDER BY date))*1.0/LAG(new_users) OVER (ORDER BY date)*100,2) new_users_change,
    ROUND((new_couriers-LAG(new_couriers) OVER (ORDER BY date))*1.0/LAG(new_couriers) OVER (ORDER BY date)*100,2) new_couriers_change,
    ROUND((total_users-LAG(total_users) OVER (ORDER BY date))*1.0/LAG(total_users) OVER (ORDER BY date)*100,2) total_users_growth,
    ROUND((total_couriers-LAG(total_couriers) OVER (ORDER BY date))*1.0/LAG(total_couriers) OVER (ORDER BY date)*100,2) total_couriers_growth
FROM new_users_couriers