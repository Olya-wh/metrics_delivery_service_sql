SELECT 
	date_trunc('month', start_date)::date as start_month,
    start_date,
    date - start_date as day_number,
    round(
	    users::decimal / max(users) OVER (PARTITION BY start_date),
	    2) as retention
FROM (
	SELECT 
		start_date,
        time::date as date,
        count(distinct user_id) as users
        FROM (
	        SELECT 
		        user_id,
                time::date,
                min(time::date) OVER (PARTITION BY user_id) as start_date
            FROM   user_actions) t1
GROUP BY start_date, time::date) t2