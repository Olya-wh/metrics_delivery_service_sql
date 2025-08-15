SELECT
    date,
    new_users,
    new_couriers,
    total_users,
    total_couriers,
    ROUND(
        100 * (new_users - LAG(new_users, 1) OVER (ORDER BY date)) / LAG(new_users, 1) OVER (ORDER BY date)::DECIMAL,
        2
    ) AS new_users_change,
    ROUND(
        100 * (new_couriers - LAG(new_couriers, 1) OVER (ORDER BY date)) / LAG(new_couriers, 1) OVER (ORDER BY date)::DECIMAL,
        3
    ) AS new_couriers_change,
    ROUND(
        100 * new_users::DECIMAL / LAG(total_users, 1) OVER (ORDER BY date),
        4
    ) AS total_users_growth,
    ROUND(
        100 * new_couriers::DECIMAL / LAG(total_couriers, 1) OVER (ORDER BY date),
        5
    ) AS total_couriers_growth
FROM
    (
        SELECT
            start_date AS date,
            new_users,
            new_couriers,
            (SUM(new_users) OVER (ORDER BY start_date))::INT AS total_users,
            (SUM(new_couriers) OVER (ORDER BY start_date))::INT AS total_couriers
        FROM
            (
                SELECT
                    start_date,
                    COUNT(courier_id) AS new_couriers
                FROM
                    (
                        SELECT
                            courier_id,
                            MIN(time::DATE) AS start_date
                        FROM
                            courier_actions
                        GROUP BY
                            courier_id
                    ) t1
                GROUP BY
                    start_date
            ) t2
        LEFT JOIN
            (
                SELECT
                    start_date,
                    COUNT(user_id) AS new_users
                FROM
                    (
                        SELECT
                            user_id,
                            MIN(time::DATE) AS start_date
                        FROM
                            user_actions
                        GROUP BY
                            user_id
                    ) t3
                GROUP BY
                    start_date
            ) t4 USING (start_date)
    ) t5;