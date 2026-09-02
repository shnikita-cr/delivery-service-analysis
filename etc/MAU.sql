SELECT DATE_TRUNC('month', time) AS month,
       COUNT(DISTINCT user_id)      MAU
FROM user_actions
GROUP BY month;