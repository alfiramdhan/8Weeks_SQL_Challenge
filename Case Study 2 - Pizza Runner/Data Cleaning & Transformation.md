# 🍕 Case Study #2 - Pizza Runner

## 🧼 Data Cleaning & Transformation

### 🔨 Table: customer_orders

Looking at the customer_orders table, we can see that there are missing/ blank spaces ' ' and 'null' values :
- The `exclusions` column
- The `extras` column

In this project, we need to perform data analysis or generate reports, it's often beneficial to keep null values intact. Null values can be easily filtered or aggregated, providing more accurate results

#### Steps :
- Create a temporary table called customer_orders_cleaned by performing data cleaning and transformation on an existing table called customer_orders
- Selects columns from the customer_orders table and applies transformations to the exclusions and extras columns using `CASE` statements
- Replace `empty strings ('') or the string 'null'` with null values in exlusions and extras columns

```sql
/*
Transforms the data in the customer_orders table by replacing specific values in the exclusions and extras columns with [null] values.
It then creates a temporary table (customer_orders_cleaned) with the cleaned data
*/

DROP TABLE IF EXISTS customer_orders_cleaned;
CREATE TEMP TABLE customer_orders_cleaned AS
SELECT order_id,
		customer_id,
		pizza_id,
		CASE WHEN exclusions = '' THEN NULL
			 WHEN exclusions = 'null' THEN NULL
			 ELSE exclusions
		END as exclusions,
		CASE WHEN extras = '' THEN NULL
			 WHEN extras = 'null' THEN NULL
			 ELSE extras
		END as extras,
		order_time
FROM pizza_runner.customer_orders;
```
----   

### 🔨 Table: runner_orders

### Issue:
- In pickup_time column, replace the string 'null'` with null values
- In distance column, remove "km" and replace the string 'null'` with null values
- In duration column, remove "minutes", "minute" and replace the string 'null'` with null values
- In cancellation column, replace the string 'null'` with null values

```sql
DROP TABLE IF EXISTS runner_orders_cleaned;
CREATE TEMP TABLE runner_orders_cleaned AS WITH CTE AS(
SELECT order_id,
		runner_id,
		CASE WHEN pickup_time = 'null' THEN NULL
			 ELSE pickup_time
		END	as pickup_time,
		CASE WHEN distance = 'null' THEN NULL
			 ELSE distance
		END as distance,
		CASE WHEN duration = 'null' THEN NULL
			 ELSE duration
		END as duration,
		CASE WHEN cancellation = 'null' OR cancellation = '' THEN NULL
			 ELSE cancellation
		END as cancellation
FROM pizza_runner.runner_orders
)	
	SELECT order_id,
			runner_id,
			CAST(pickup_time as TIMESTAMP)as pickup_time,
			CAST((REGEXP_REPLACE(distance, '[a-z]+','')) as DECIMAL(5,2))as distance,
			CAST((REGEXP_REPLACE(duration, '[a-z]+','')) as INT)as duration,
			cancellation
	FROM CTE;
```
----
