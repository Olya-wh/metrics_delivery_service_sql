WITH 
	cte1 as (
		SELECT 
			count(distinct user_id) as paying_users,
	        time::date as date
        FROM user_actions
        WHERE order_id not in (
			SELECT order_id
            FROM user_actions
            WHERE action = 'cancel_order')
        GROUP BY date
        ORDER BY 2
    ),
    
    cte2 as (
		SELECT 
			date,
            count(users) as users
        FROM (
	        SELECT 
		        count(user_id) as users,
                user_id,
                time::date as date
            FROM user_actions
            WHERE action = 'create_order'
                and order_id not in (
	                SELECT order_id
                    FROM   user_actions
                    WHERE  action = 'cancel_order')
		    GROUP BY date, user_id 
		    HAVING count(user_id) = 1
		    ORDER BY 2
		    ) as u
        GROUP BY date
        )
        
SELECT cte1.date,
       round(users::decimal/paying_users*100, 2) as single_order_users_share,
       100-round(users::decimal/paying_users*100, 2) as several_orders_users_share
FROM   cte1 join cte2
        ON cte1.date = cte2.date