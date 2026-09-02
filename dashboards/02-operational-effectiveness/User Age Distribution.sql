SELECT CASE
           WHEN date_part('year', age(birth_date)) :: integer BETWEEN 18
               AND 24 THEN '18-24'
           WHEN date_part('year', age(birth_date)) :: integer BETWEEN 25
               AND 29 THEN '25-29'
           WHEN date_part('year', age(birth_date)) :: integer BETWEEN 30
               AND 35 THEN '30-35'
           WHEN date_part('year', age(birth_date)) :: integer >= 36 THEN '36+'
           END        AS group_age,
       count(user_id) as users_count
FROM users
WHERE birth_date IS NOT NULL
GROUP BY group_age
ORDER BY group_age