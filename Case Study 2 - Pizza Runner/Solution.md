## Introduction

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

Before you start writing your SQL queries however - you might want to investigate the data, you may want to do something with some of those null values and data types in the customer_orders and runner_orders tables!

Full description: [Case Study #2 - Pizza Runner ](https://8weeksqlchallenge.com/case-study-2/)


## Case Study Questions

This case study has LOTS of questions - they are broken up by area of focus including:

- Pizza Metrics
- Runner and Customer Experience
- Ingredient Optimisation
- Pricing and Ratings
- Bonus DML Challenges (DML = Data Manipulation Language)


## BEFORE ANSWERING THE QUESTIONS, LET'S BEGIN BY FIXING THE TABLES
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
      CASE WHEN order_id = '3' THEN (pickup_time + INTERVAL '13 hour') ELSE pickup_time END AS pickup_time,
      CAST( regexp_replace(distance, '[a-z]+', '' ) AS DECIMAL(5,2) ) AS distance,
    	CAST( regexp_replace(duration, '[a-z]+', '' ) AS INT ) AS duration,
    	cancellation
    FROM
      first_layer;
```



## A. Pizza Metrics

1. How many pizzas were ordered?
```sql
SELECT COUNT(pizza_id)as total_pizza
FROM customer_orders;
```
There were 14 of pizza ordered


2. How many unique customer orders were made?
```sql
SELECT COUNT(DISTINCT order_id)as total_customer_order
FROM customer_orders;
```
There were 10 orders made


3. How many successful orders were delivered by each runner?

As the runner_orders table is not neat so it needs to be corrected first, then we can use the Temp runner_orders_cleaned to find the answer

```sql
SELECT runner_id,
	COUNT(order_id)as total_successful_orders
FROM runner_orders_cleaned
WHERE cancellation IS null
GROUP BY 1;
```
The first runner successfully delivered 4 orders

The second runner successfully delivered 3 orders

And the third runner successfully delivered 1 order


4. How many of each type of pizza was delivered?

As the customer_orders table is not neat so it needs to be corrected first, then we can use the Temp runner_orders_cleaned to find the answer

```sql
SELECT pizza_id,
		COUNT(pizza_id)as total_pizza
FROM customer_orders_cleaned cc, runner_orders_cleaned rc
WHERE cc.order_id = rc.order_id
	AND cancellation IS NULL
GROUP BY 1	
ORDER BY 1;
```
Pizza type 1 successfully sent 9

pizza type 2 successfully delivered 3


5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
SELECT customer_id,
		sum(case when cc.pizza_id = 1 THEN 1 ELSE 0 END)as Meatlovers,
		sum(case when cc.pizza_id = 2 THEN 1 ELSE 0 END)as Vegetarian
FROM customer_orders_cleaned cc, pizza_names pn
WHERE cc.pizza_id = pn.pizza_id
GROUP BY 1	
ORDER BY 1;
```
The most popular pizza for customer 101 was Meatlovers, they purchased it 2 times then Vegetarian once

The most popular item for customer 102 was Meatlovers, they purchased it 2 times then Vegetarian once

The most popular item for customer 103 was Meatlovers, they purchased it 3 times then Vegetarian once

The most popular item for customer 104 was Meatlovers, they purchased it 3 times

The most popular item for customer 105 was Vegetarian once


6. What was the maximum number of pizzas delivered in a single order?
```sql
SELECT order_id,
		COUNT(pizza_id)as total_pizza
FROM customer_orders_cleaned
GROUP BY 1
ORDER BY total_pizza DESC;
```
The maximum number of pizzas delivered in a single order was 3


7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
SELECT customer_id,
		sum(case when (exclusions IS NOT NULL or extras IS NOT NULL) THEN 1 ELSE 0 END)as perform_change,
		sum(case when (exclusions IS NULL and extras IS NULL) THEN 1 ELSE 0 END)as no_change
FROM customer_orders_cleaned
GROUP BY 1
ORDER BY 1;
```
For customer 101, has a total of 3 pizza deliveries that didn't change

For customer 102, has a total of 3 pizza deliveries that didn't change

For customer 103, has a total of 4 pizza deliveries that performed change

For customer 104, has a total of 1 pizza deliveries that didn't change and 2 pizza deliveries that performed change

For customer 105, has a total of 1 pizza deliveries that performed change


8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT sum(case when (exclusions IS NOT NULL and extras IS NOT NULL) THEN 1 ELSE 0 END)as perform_change
FROM customer_orders_cleaned;
```
There were a total of 2 pizza deliveries that had both exclusions and extras


9. What was the total volume of pizzas ordered for each hour of the day?
```sql
select extract(hour from order_time)as pizza_hour,
		count(extract(hour from order_time))as number_pizza_ordered,
		ROUND(count(extract(hour from order_time))*100/sum(count(*)) OVER(),2)as total_volume
from customer_orders_cleaned
group by 1
order by 1
```

10. What was the volume of orders for each day of the week?
```sql

