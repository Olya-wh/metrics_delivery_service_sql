SELECT 
	product_name,
    sum(revenue) as revenue,
    sum(share_in_revenue) as share_in_revenue
FROM 
	(
		SELECT 
			case when round(
				sum(price)/(sum(sum(price)) OVER())*100,
                1) >= 0.5 then name
                    else 'ДРУГОЕ' end as product_name,
               sum(price) as revenue,
               round(sum(price)/(sum(sum(price)) OVER())*100, 2) as share_in_revenue
        FROM   (SELECT unnest(product_ids) as product_id,
                       order_id,
                       creation_time::date as date
                FROM   orders) as o join products as p
                ON o.product_id = p.product_id
        WHERE  order_id not in (SELECT order_id
                                FROM   user_actions
                                WHERE  action = 'cancel_order')
        GROUP BY name
        ORDER BY 2 desc) as o
GROUP BY product_name
ORDER BY 2 desc