SELECT DATE_TRUNC('week', time) week,
       COUNT(DISTINCT user_id)  WAU
FROM user_actions
GROUP BY week;