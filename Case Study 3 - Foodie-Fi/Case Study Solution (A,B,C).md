## A. Customer Journey

Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

````sql
SELECT customer_id,
	plan_name,
	start_date
FROM foodie_fi.subscriptions t1
JOIN foodie_fi.plans t2 ON t1.plan_id = t2.plan_id;
````
  

## B. Data Analysis Solutions

1. How many customers has Foodie-Fi ever had?
````sql
SELECT COUNT(DISTINCT customer_id)as total_customers
FROM foodie_fi.subscriptions
````
Foodie-Fi has 1000 subscribers

2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```sql
SELECT EXTRACT(month from start_date)as months,
	COUNT(plan_id)as monthly_distribution
FROM foodie_fi.subscriptions
WHERE plan_id = 0
GROUP BY 1
ORDER BY 1;
```
The distribution of the number of subscribers from trial plan reached its highest figure in March

3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
```sql
SELECT plan_name,
	COUNT(t1.plan_id)as count_event
FROM foodie_fi.subscriptions t1
LEFT JOIN foodie_fi.plans t2
	ON t1.plan_id = t2.plan_id
WHERE EXTRACT(year from start_date) > 2020
GROUP BY 1
ORDER BY 2 DESC;
```
The number of subscribers who churned the plan was the biggest one after the year 2020, with 71 subscribers.

4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

To find the percentage we can calculate the number of rows multiplied by 100 divided by the total number of customers.
```sql
SELECT COUNT(*)as num_churn,
		CAST(COUNT(*)*100::FLOAT / (SELECT COUNT(DISTINCT customer_id)as total_customer
							   FROM foodie_fi.subscriptions)::FLOAT AS NUMERIC)as pct_churn
FROM foodie_fi.subscriptions
WHERE plan_id = 4;
```
There are 307 customers who have churned, which 30.7% of customers who have churned the plans.

5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

We can use CTE to create a temporary result that can be referred later on. LEAD clause is used to look forward a number of rows and access data of that row from the current row.

Then we named the result from LEAD clause as lead_plan so we can recall it outside the CTE set. Filter the plan_id = 0 and next_plan = 4 because we want to find the percentage who have churned after trial.

```sql
WITH lead_plan AS(
SELECT *,
	LEAD(plan_id,1) OVER(PARTITION BY customer_id ORDER BY start_date)as next_plan
FROM foodie_fi.subscriptions
)
	SELECT COUNT(*)AS num_churn,
		CAST(COUNT(*)*100::FLOAT / (SELECT COUNT(DISTINCT customer_id)as total_customer
						 FROM foodie_fi.subscriptions)::FLOAT AS NUMERIC)as pct_churn
	FROM lead_plan
	WHERE plan_id = 0 and next_plan = 4;
```
There are 92 customers who have churned straight after their initial free trial, which 9% of the customer base.

6. What is the number and percentage of customer plans after their initial free trial?

We can use CTE to create a temporary result that can be referred later on. LEAD clause is used to look forward a number of rows and access data of that row from the current row.

Then we named the result from LEAD clause as lead_plan so we can recall it outside the CTE set. Filter the plan_id = 0 and next_plan IS NOT NULL because we want to find the percentage after trial plan.
```sql
WITH lead_plan AS(
SELECT *,
	LEAD(plan_id,1) OVER(PARTITION BY customer_id ORDER BY start_date)as next_plan
FROM foodie_fi.subscriptions
)
	SELECT next_plan,
		COUNT(*)AS num_churn,
		CAST(COUNT(*)*100::FLOAT / (SELECT COUNT(DISTINCT customer_id)as total_customer
						FROM foodie_fi.subscriptions)::FLOAT AS NUMERIC)as pct_churn
	FROM lead_plan
	WHERE plan_id = 0 and next_plan IS NOT NULL
	GROUP BY 1
	ORDER BY 1;
```
- 54.5% of customers choose basic monthly after their initial trial.
- 32.5% of customers choose pro monthly after their initial trial.
- 3.7% of customers choose pro annual after their initial trial.
- 9.2% of customers choose churn after their initial trial.

7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

#1 STEP : Create CTE for dates after 2020-12-31 for each customer. then named it as ‘table next date’.

#2 Create other CTE to count number of customers for each plan,, then filter start_date after their trial period and before the end of 2020-12-31 of each customer

#3 Last, outside the CTE we call the plan id, number of customers of each plans, and the percentage of each plans
```sql
WITH date_plan AS(
SELECT *,
	LEAD(start_date,1) OVER(PARTITION BY customer_id ORDER BY start_date)as next_date
FROM foodie_fi.subscriptions
),

num_customer AS(
	SELECT plan_id,
		COUNT(DISTINCT customer_id)AS number_customer
	FROM date_plan
	WHERE (next_date IS NOT NULL AND ('2020-12-31'::DATE > start_date AND '2020-12-31'::DATE < next_date))
        	OR (next_date IS NULL AND '2020-12-31'::DATE > start_date)
	GROUP BY 1
)

	SELECT plan_id,
		number_customer,
		ROUND(CAST(number_customer *100 / (SELECT COUNT(DISTINCT customer_id)as total_customer
							FROM foodie_fi.subscriptions) AS NUMERIC),2)as pct_each_plan
	FROM num_customer;
```
Plan_id 2 or Pro Monthly plan has the highest percentage of subscribers until 31-12-2020.

8. How many customers have upgraded to an annual plan in 2020?
```sql
WITH lead_plan AS(
SELECT *,
	LEAD(plan_id,1) OVER(PARTITION BY customer_id ORDER BY start_date)as next_plan
FROM foodie_fi.subscriptions
)
	SELECT COUNT(*)AS num_annual
	FROM lead_plan
	WHERE next_plan = 3
		and EXTRACT(year from start_date) = '2020';
```
There are 253 customers who have upgraded to annual in 2020.

9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
WITH join_date AS(
	SELECT customer_id,
		start_date AS trial_date
	FROM foodie_fi.subscriptions
	WHERE plan_id = 0
),

annual_date AS(
	SELECT customer_id,
		start_date as pro_annual_date
	FROM foodie_fi.subscriptions
	WHERE plan_id = 3
)
	SELECT ROUND(AVG(pro_annual_date - trial_date),2)as avg_days
	FROM join_date, annual_date
		WHERE join_date.customer_id = annual_date.customer_id;
```
On average, it takes 105 days for a customer take an annual plan from the day they joined Foodie-Fi.

10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

We're gonna using `WIDTH_BUCKET()`function. So we need to do some steps :

#1 step find out min and max days 
```sql
WITH join_date AS(
	SELECT customer_id,
		start_date AS trial_date
	FROM foodie_fi.subscriptions
	WHERE plan_id = 0
),

annual_date AS(
	SELECT customer_id,
		start_date as pro_annual_date
	FROM foodie_fi.subscriptions
	WHERE plan_id = 3
)
	SELECT Min(pro_annual_date - trial_date)as min_days,
		Max(pro_annual_date - trial_date)as max_days
	FROM join_date, annual_date
		WHERE join_date.customer_id = annual_date.customer_id;
```
Then we got Min 7 days and Max 346 for a customer to annual plan from the day they join Foodie-Fi

Next, we can create range 0-360 which,
- 0 = low value (The minimum bound (inclusive) of all buckets)
- 360 = high value (The maximum bound (exclusive) of all buckets)
- 12 = count/rows (The number of buckets.)
```sql
WITH join_date AS(
	SELECT customer_id,
		start_date AS trial_date
	FROM foodie_fi.subscriptions
	WHERE plan_id = 0
),

annual_date AS(
	SELECT customer_id,
		start_date as pro_annual_date
	FROM foodie_fi.subscriptions
	WHERE plan_id = 3
),

bins AS(
	SELECT WIDTH_BUCKET(pro_annual_date - trial_date, 0, 360, 12) AS avg_days_to_upgrade
	FROM join_date t1
	JOIN annual_date t2
       	 ON t1.customer_id = t2.customer_id
)

	SELECT ((avg_days_to_upgrade - 1)*30 || '-' || (avg_days_to_upgrade)*30) AS "30-day-range",
		COUNT(*) as total
	FROM bins
	GROUP BY avg_days_to_upgrade
	ORDER BY avg_days_to_upgrade;
```

11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
WITH lead_plan AS(	
	SELECT *,
		LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date)as next_plan
	FROM foodie_fi.subscriptions
)
	SELECT COUNT(DISTINCT customer_id)as number_customer
	FROM lead_plan
	WHERE plan_id = 2
		AND next_plan = 1
			AND EXTRACT(year from start_date) = '2020';
```
---

## C. Challenge Payment Question
We need to create  a new payments table for the year 2020 that includes : customer_id, plan_id, plan_name, payment_date, amount, payment_order

First Step, make sure first plan for each customer was plan_id = 0 or trial plan

```SQL
with index_rank as(	
	select customer_id,
			start_date,
			plan_id,
			row_number() over(partition by customer_id order by start_date)as rn
	from foodie_fi.subscriptions)
	
	select customer_id,
			start_date,
			plan_id
	from index_rank
	where rn = 1
		and plan_id != 0
```
Then create cte USING lag() function to get new column
```
with lag_table AS(
	select customer_id,
			lag(t1.plan_id,1) over(partition by customer_id order by start_date)as last_plan,
			t1.plan_id as new_plan,
			plan_name,
			lag(start_date,1) over(partition by customer_id order by start_date)as start_date,
			start_date as payment_date,
			lag(numeric,1) over(partition by customer_id order by start_date)as last_amount,
			numeric as amount
	from foodie_fi.subscriptions t1
	join foodie_fi.plans t2 ON t1.plan_id = t2.plan_id
	where extract(year from start_date) = 2020
)

	select customer_id,
			new_plan as plan_id,
			plan_name,
			payment_date,
			case when last_plan = 1 and new_plan = 2 then amount - last_amount
				when last_plan = 1 and new_plan = 3 then amount - last_amount 
				else amount end as total_amount,
			row_number() over(partition by customer_id order by payment_date)as payment_order	
	from lag_table
	where last_plan is not null
		and new_plan != 4
	order by customer_id;
```

--
