WITH cte AS (
    SELECT
        date,
        SUM(price) AS revenue
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
    GROUP BY date
)
SELECT
    date,
    revenue,
    SUM(revenue) OVER (ORDER BY date) AS total_revenue,
    ROUND(
        ((revenue - LAG(revenue, 1) OVER (ORDER BY date)) / LAG(revenue, 1) OVER (ORDER BY date)) * 100,
        1
    ) AS revenue_change
FROM cte