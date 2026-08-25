SELECT time::DATE              date,
       COUNT(DISTINCT user_id) DAU
FROM user_actions
GROUP BY time::DATE;
