WITH 
    cte1 AS (
        SELECT 
            COUNT(DISTINCT user_id) AS users,
            COUNT(DISTINCT user_id) FILTER (
                WHERE order_id NOT IN (
                    SELECT order_id 
                    FROM user_actions 
                    WHERE action = 'cancel_order'
                )
            ) AS paying_users,
            time::date AS date
        FROM user_actions
        GROUP BY date
        ORDER BY 3
    ),
    
    cte2 AS (
        SELECT 
            COUNT(DISTINCT courier_id) AS couriers,
            COUNT(DISTINCT courier_id) FILTER (
                WHERE order_id IN (
                    SELECT order_id 
                    FROM courier_actions 
                    WHERE action = 'deliver_order'
                )
            ) AS active_couriers,
            time::date AS date
        FROM courier_actions
        GROUP BY date
        ORDER BY 2
    ),
    
    cte3 AS (
        SELECT 
            COUNT(user_id) AS new_users,
            date
        FROM (
            SELECT 
                user_id,
                time::date AS date,
                ROW_NUMBER() OVER(
                    PARTITION BY user_id 
                    ORDER BY time
                ) AS row_num
            FROM user_actions
        ) AS ua
        WHERE row_num = 1
        GROUP BY date
    ),
    
    cte4 AS (
        SELECT 
            COUNT(courier_id) AS new_couriers,
            date
        FROM (
            SELECT 
                courier_id,
                time::date AS date,
                ROW_NUMBER() OVER(
                    PARTITION BY courier_id 
                    ORDER BY time
                ) AS row_num
            FROM courier_actions
        ) AS ca
        WHERE row_num = 1
        GROUP BY date
    )

SELECT 
    cte1.date,
    paying_users,
    active_couriers,
    ROUND(paying_users / SUM(new_users) OVER (ORDER BY cte1.date) * 100, 2) AS paying_users_share,
    ROUND(active_couriers / SUM(new_couriers) OVER (ORDER BY cte1.date) * 100, 2) AS active_couriers_share
FROM cte1
JOIN cte2 ON cte1.date = cte2.date
JOIN cte4 ON cte4.date = cte1.date
JOIN cte3 ON cte3.date = cte1.date