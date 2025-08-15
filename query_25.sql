WITH cte AS (
    SELECT
        date,
        SUM(price) AS revenue,
        order_id
    FROM
        (
            (
                SELECT
                    UNNEST(product_ids) AS product_id,
                    order_id,
                    creation_time::DATE AS date
                FROM orders
            ) AS o
            JOIN products AS p ON o.product_id = p.product_id
        ) AS po
    WHERE
        order_id NOT IN (
            SELECT order_id
            FROM user_actions
            WHERE action = 'cancel_order'
        )
    GROUP BY
        date,
        order_id
),
cte1 AS (
    SELECT
        date,
        order_id
    FROM
        (
            SELECT
                time::DATE AS date,
                action,
                user_id,
                order_id,
                DENSE_RANK() OVER (PARTITION BY user_id ORDER BY time::DATE) AS rank_order
            FROM
                user_actions
        ) AS ua
    WHERE
        rank_order = 1
        AND order_id NOT IN (
            SELECT order_id
            FROM user_actions
            WHERE action = 'cancel_order'
        )
        AND action = 'create_order'
)

SELECT
    cte.date,
    SUM(revenue) AS revenue,
    SUM(revenue) FILTER (WHERE cte1.order_id IS NOT NULL) AS new_users_revenue,
    ROUND(
        SUM(revenue) FILTER (WHERE cte1.order_id IS NOT NULL) / SUM(revenue) * 100,
        2
    ) AS new_users_revenue_share,
    100 - ROUND(
        SUM(revenue) FILTER (WHERE cte1.order_id IS NOT NULL) / SUM(revenue) * 100,
        2
    ) AS old_users_revenue_share
FROM
    cte LEFT JOIN
    cte1 ON cte.order_id = cte1.order_id
GROUP BY cte.date
ORDER BY 1