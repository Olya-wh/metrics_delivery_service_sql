WITH cte AS (
    SELECT
        weekday,
        weekday_number,
        SUM(price) AS revenue
    FROM
        (
            (
                SELECT
                    UNNEST(product_ids) AS product_id,
                    order_id,
                    DATE_PART('isodow', creation_time) AS weekday_number,
                    TO_CHAR(creation_time, 'Day') AS weekday
                FROM
                    orders
                WHERE
                    creation_time BETWEEN '2022-08-26' AND '2022-09-09'
            ) AS o
            JOIN products AS p ON o.product_id = p.product_id
        ) AS po
    WHERE
        order_id NOT IN (
            SELECT
                order_id
            FROM
                user_actions
            WHERE
                action = 'cancel_order'
        )
    GROUP BY
        weekday,
        weekday_number
),
cte2 AS (
    SELECT
        DATE_PART('isodow', time) AS weekday_number,
        TO_CHAR(time, 'Day') AS weekday,
        COUNT(DISTINCT order_id) AS count_order
    FROM
        user_actions
    WHERE
        order_id NOT IN (
            SELECT
                order_id
            FROM
                user_actions
            WHERE
                action = 'cancel_order'
        )
        AND time BETWEEN '2022-08-26' AND '2022-09-09'
    GROUP BY
        weekday,
        weekday_number
),
cte1 AS (
    SELECT
        COUNT(DISTINCT user_id) AS new_users,
        COUNT(DISTINCT user_id) FILTER (
            WHERE
                order_id NOT IN (
                    SELECT
                        order_id
                    FROM
                        user_actions
                    WHERE
                        action = 'cancel_order'
                )
        ) AS paying_users,
        DATE_PART('isodow', time) AS weekday_number,
        TO_CHAR(time, 'Day') AS weekday
    FROM
        user_actions
    WHERE
        time BETWEEN '2022-08-26' AND '2022-09-09'
    GROUP BY
        weekday,
        weekday_number
    ORDER BY
        3
)
SELECT 
	cte.weekday, 
	cte.weekday_number, 
	round(revenue/new_users, 2) as arpu, 
	round(revenue/paying_users, 2) as arppu, 
	round(revenue/count_order, 2) as aov 
FROM 
	cte LEFT JOIN cte2 ON cte.weekday_number = cte2.weekday_number 
	LEFT JOIN cte1 ON cte.weekday_number = cte1.weekday_number 
ORDER BY 2