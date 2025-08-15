SELECT
    date,
    ROUND(revenue::DECIMAL / users, 2) AS arpu,
    ROUND(revenue::DECIMAL / paying_users, 2) AS arppu,
    ROUND(revenue::DECIMAL / orders, 2) AS aov
FROM
    (
        SELECT
            creation_time::DATE AS date,
            COUNT(DISTINCT order_id) AS orders,
            SUM(price) AS revenue
        FROM
            (
                SELECT
                    order_id,
                    creation_time,
                    UNNEST(product_ids) AS product_id
                FROM orders
                WHERE
                    order_id NOT IN (
                        SELECT  order_id
                        FROM user_actions
                        WHERE action = 'cancel_order'
                    )
            ) t1
        LEFT JOIN products USING (product_id)
        GROUP BY date
    ) t2
LEFT JOIN
    (
        SELECT
            time::DATE AS date,
            COUNT(DISTINCT user_id) AS users
        FROM user_actions
        GROUP BY date
    ) t3 USING (date)
LEFT JOIN
    (
        SELECT
            time::DATE AS date,
            COUNT(DISTINCT user_id) AS paying_users
        FROM user_actions
        WHERE
            order_id NOT IN (
                SELECT order_id
                FROM user_actions
                WHERE action = 'cancel_order'
            )
        GROUP BY date
    ) t4 USING (date)
ORDER BY date