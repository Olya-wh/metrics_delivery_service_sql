WITH 
    cte1 AS (
        SELECT 
            date,
            SUM(price) AS revenue
        FROM (
            SELECT 
                UNNEST(product_ids) AS product_id,
                order_id,
                creation_time::date AS date
            FROM orders
        ) AS o 
        JOIN products AS p
            ON o.product_id = p.product_id
        WHERE order_id NOT IN (
            SELECT order_id
            FROM user_actions
            WHERE action = 'cancel_order'
        )
        GROUP BY date
    ), 
    
    cte2 AS (
        SELECT 
            time::date AS date,
            COUNT(order_id) AS sbor_count
        FROM user_actions
        WHERE action = 'create_order'
          AND order_id NOT IN (
              SELECT order_id
              FROM user_actions
              WHERE action = 'cancel_order'
          )
        GROUP BY date
    ), 
    
    cte3 AS (
        SELECT 
            time::date AS date,
            COUNT(order_id) AS order_count
        FROM courier_actions
        WHERE action = 'deliver_order'
        GROUP BY date
    ), 
    
    cte4 AS (
        SELECT 
            date,
            COUNT(order_count) AS five_count
        FROM (
            SELECT 
                time::date AS date,
                courier_id,
                COUNT(order_id) AS order_count
            FROM courier_actions
            WHERE action = 'deliver_order'
            GROUP BY date, courier_id 
            HAVING COUNT(order_id) >= 5
        ) AS ca
        GROUP BY date
    ), 
    
    cte5 AS (
        SELECT 
            cte1.date,
            revenue,
            CASE 
                WHEN date_part('month', cte1.date) = 8 THEN 
                    120000 + 140 * sbor_count + 150 * order_count + 400 * (COALESCE(five_count, 0))
                ELSE 
                    150000 + 115 * sbor_count + 150 * order_count + 500 * (COALESCE(five_count, 0))
            END AS costs
        FROM cte1
        LEFT JOIN cte2
            ON cte1.date = cte2.date
        LEFT JOIN cte3
            ON cte3.date = cte1.date
        LEFT JOIN cte4
            ON cte4.date = cte1.date
        ORDER BY 1
    ), 
    
    cte6 AS (
        SELECT 
            date,
            SUM(price_tax) AS tax
        FROM (
            SELECT 
                creation_time::date AS date,
                UNNEST(product_ids) AS product_id
            FROM orders
            WHERE order_id NOT IN (
                SELECT order_id
                FROM user_actions
                WHERE action = 'cancel_order'
            )
        ) AS o
        LEFT JOIN (
            SELECT 
                CASE 
                    WHEN name IN ('сахар', 'сухарики', 'сушки', 'семечки', 'масло льняное', 'виноград', 'масло оливковое', 'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 'овсянка', 'макароны', 'баранина', 'апельсины', 'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины') 
                    THEN ROUND(price * 0.1 / 1.1, 2)
                    ELSE ROUND(price * 0.2 / 1.2, 2) 
                END AS price_tax,
                product_id,
                price,
                name
            FROM products
        ) AS p
            ON p.product_id = o.product_id
        GROUP BY date
        ORDER BY 1
    )

SELECT 
    cte6.date,
    revenue,
    costs::decimal,
    tax,
    revenue - tax - costs AS gross_profit,
    SUM(revenue) OVER(ORDER BY cte6.date) AS total_revenue,
    SUM(costs) OVER(ORDER BY cte6.date) AS total_costs,
    SUM(tax) OVER(ORDER BY cte6.date) AS total_tax,
    SUM(revenue - tax - costs) OVER(ORDER BY cte6.date) AS total_gross_profit,
    ROUND((revenue - tax - costs) / revenue * 100, 2) AS gross_profit_ratio,
    ROUND(
        SUM(revenue - tax - costs) OVER(ORDER BY cte6.date) / 
        SUM(revenue) OVER(ORDER BY cte6.date) * 100,
        2
    ) AS total_gross_profit_ratio
FROM cte6 
JOIN cte5
    ON cte5.date = cte6.date