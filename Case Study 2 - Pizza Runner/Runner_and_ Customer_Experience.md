## BEFORE ANSWERING THE QUESTIONS, LET'S BEGIN BY FIXING THE TABLES

--PART 1: FIXING THE TABLES
-- First: customer_orders
--- Creating a view ---
```sql
DROP TABLE IF EXISTS customer_orders_cleaned
CREATE TEMP TABLE customer_orders_cleaned AS WITH first_layer AS(
  SELECT order_id,
          customer_id,
          pizza_id,
          CASE
             WHEN exclusions = '' THEN NULL
             WHEN exclusions = 'null' THEN NULL
             ELSE exclusions
          END as exclusions,
          CASE
             WHEN extras = '' THEN NULL
             WHEN extras = 'null' THEN NULL
             ELSE extras
          END as extras,
          order_time
  FROM customer_orders
  )
    SELECT 
          ROW_NUMBER() OVER(ORDER BY order_id, pizza_id) as row_order,
          order_id,
          customer_id,
          pizza_id,
          exclusions,
          extras,
          order_time
    FROM first_layer ;
```    
    
-----------------------------------------------
-- Second: runner_orders:    
```sql
  DROP TABLE IF EXISTS runner_orders_cleaned;
    CREATE TEMP TABLE runner_orders_cleaned AS WITH first_layer AS (
      SELECT
        order_id,
        runner_id,
        CAST(
          CASE
            WHEN pickup_time = 'null' THEN NULL
            ELSE pickup_time
          END AS timestamp
        ) AS pickup_time,
        CASE
          WHEN distance = '' THEN NULL
          WHEN distance = 'null' THEN NULL
          ELSE distance
        END as distance,
        CASE
          WHEN duration = '' THEN NULL
          WHEN duration = 'null' THEN NULL
          ELSE duration
        END as duration,
        CASE
          WHEN cancellation = '' THEN NULL
          WHEN cancellation = 'null' THEN NULL
          ELSE cancellation
        END as cancellation
      FROM
        runner_orders
    )
    SELECT
      order_id,
      runner_id,
      
      -- adding INTERVAL '13 hour' in order_id = 3 because order_time for this id at 23:51:23
      
      CASE WHEN order_id = '3' THEN (pickup_time + INTERVAL '13 hour') ELSE pickup_time END AS pickup_time,
      CAST( regexp_replace(distance, '[a-z]+', '' ) AS DECIMAL(5,2) ) AS distance,
    	CAST( regexp_replace(duration, '[a-z]+', '' ) AS INT ) AS duration,
    	cancellation
    FROM
      first_layer;
```

-----------------------------------------------
-- New temp table for this part
```sql
DROP TABLE IF EXISTS join_table;
    CREATE TEMP TABLE join_table AS
	SELECT co.order_id,
			co.customer_id,
			co.pizza_id,
			rc.runner_id,
			rc.distance,
			rc.duration,
			co.order_time,
			rc.pickup_time
	FROM customer_orders_cleaned co
		LEFT JOIN runner_orders_cleaned rc ON co.order_id = rc.order_id
	WHERE rc.cancellation IS NULL	
	ORDER BY 1;
```	
-----------------------------------------------------------



## B. Runner and Customer Experience

1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
SELECT cast(to_char(registration_date, 'WW')as NUMERIC)as week_period,
		count(runner_id)as number_signup
FROM runners		
GROUP BY 1
ORDER BY 1;
```

2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
SELECT runner_id,
		ROUND(CAST(AVG(
				( DATE_PART('hour', pickup_time - order_time)*60 + DATE_PART('minute', pickup_time - order_time) )*60 +
					DATE_PART('second', pickup_time - order_time)
			)AS NUMERIC
				),2)as average_delivery_time
FROM join_table
GROUP BY 1
ORDER BY 1;
```

3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
SELECT number_pizza,
		ROUND(AVG(average_delivery_time),2)as duration_prepare
FROM(	
	SELECT order_id,
			COUNT(pizza_id)as number_pizza,
			ROUND(CAST(AVG(
					( DATE_PART('hour', pickup_time - order_time)*60 + DATE_PART('minute', pickup_time - order_time) )*60 +
						DATE_PART('second', pickup_time - order_time)
				)AS NUMERIC
					),2)as average_delivery_time
	FROM join_table
	GROUP BY 1
	ORDER BY 1)as average_prepare
GROUP BY 1
ORDER BY 1;
```


4. What was the average distance travelled for each customer?
```sql
SELECT customer_id,
		ROUND(AVG(distance),2)as average_distance_travelled
FROM join_table
GROUP BY 1
ORDER BY 1;
```


5. What was the difference between the longest and shortest delivery times for all orders?
```sql
SELECT max_duration - min_duration as difference
FROM (
SELECT 
		MAX(duration)as max_duration,
		MIN(duration)as min_duration
FROM join_table)as temp_table	
```


6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
SELECT runner_id,
		order_id,
		ROUND(AVG(distance::numeric / (duration::numeric/60)),2)as average_speed
FROM join_table
GROUP BY 1,2
ORDER BY 1,2
```

7. What is the successful delivery percentage for each runner?
```sql
SELECT runner_id,
		round(SUM(successful_order::numeric)*100 / COUNT(successful_order::numeric),2) as percentage
FROM(		
	select runner_id,
			order_id,
			cancellation,
			case when cancellation IS NULL then 1 ELSE 0 END as successful_order
	from join_table
	GROUP BY
        runner_id,
        order_id,
        cancellation
      ORDER BY
        runner_id, order_id)AS a
GROUP BY 1
ORDER BY 1;
```


