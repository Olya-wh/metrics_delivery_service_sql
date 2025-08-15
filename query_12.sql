SELECT 
	ua.date,
    new_users,
    new_couriers,
    sum(new_users) OVER(ORDER BY ua.date)::integer as total_users,
    sum(new_couriers) OVER(ORDER BY ua.date)::integer as total_couriers
FROM (SELECT count(user_id) as new_users,
               date
        FROM   (SELECT user_id,
                       time::date as date,
                       row_number() OVER(PARTITION BY user_id
                                         ORDER BY time) as roww
                FROM   user_actions) as ua
        WHERE  roww = 1
        GROUP BY date) as ua full join (SELECT count(courier_id) as new_couriers,
                                       date
                                FROM   (SELECT courier_id,
                                               time::date as date,
                                               row_number() OVER(PARTITION BY courier_id
                                                                 ORDER BY time) as roww
                                        FROM   courier_actions) as ca
                                WHERE  roww = 1
                                GROUP BY date) as ca
        ON ca.date = ua.date