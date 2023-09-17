# 🍕 Case Study #2 - Pizza Runner

## 🧼 Data Cleaning & Transformation

### 🔨 Table: customer_orders

Looking at the customer_orders table, we can see that there are
- In the `exclusions` column, there are missing/ blank spaces ' ' and 'null' values.
- In the `extras` column, there are missing/ blank spaces ' ' and 'null' values.

In this project, we need to perform data analysis or generate reports, it's often beneficial to keep null values intact. Null values can be easily filtered or aggregated, providing more accurate results.
- Create a temporary table with all the columns
- Replace `blank spaces ' ' and 'null'` values in exlusions and extras columns with null values.

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
----   

### 🔨 Table: runner_orders
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
----
