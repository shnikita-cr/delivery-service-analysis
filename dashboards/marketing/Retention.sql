SELECT
    DATE_TRUNC('month', start_date)::DATE start_month,
    start_date,
    (date - start_date)::INTEGER day_number,
    ROUND(COUNT(DISTINCT user_id)::DECIMAL / MAX(COUNT(DISTINCT user_id)) OVER (PARTITION BY start_date),2) retention
FROM (
    SELECT
        time::DATE date,
        user_id,
        MIN(time::DATE) OVER (PARTITION BY user_id) start_date
    FROM user_actions
) q1
GROUP BY date, start_date
ORDER BY start_date, day_number