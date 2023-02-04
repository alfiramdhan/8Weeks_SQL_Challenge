## Case Study #4: Data Bank - Customer Transactions

### Case Study Questions
1. What is the unique count and total amount for each transaction type?
2. What is the average total historical deposit counts and amounts for all customers?
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
4. What is the closing balance for each customer at the end of the month?
5. What is the percentage of customers who increase their closing balance by more than 5%?

--------------------------

### 1. What is the unique count and total amount for each transaction type?
```SQL
SELECT txn_type,	
		COUNT(*),
		sum(txn_amount)as total_amount
FROM data_bank.customer_transactions
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/alfiramdhan/8Weeks_SQL_Challenge/blob/main/Case%20Study%204%20-%20Data%20Bank/4.2%20IMAGE%201.png)

### 2. What is the average total historical deposit counts and amounts for all customers?
```SQL
WITH historical_deposit AS (
	SELECT 
		customer_id,
		COUNT(txn_type) AS deposit_count,
		SUM(txn_amount) AS deposit_amount
	FROM data_bank.customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id
)
SELECT 
	floor(AVG(deposit_count)) AS avg_deposit_count,
	round(AVG(deposit_amount),2) AS avg_deposit_amount
FROM historical_deposit;
```
![image](https://github.com/alfiramdhan/8Weeks_SQL_Challenge/blob/main/Case%20Study%204%20-%20Data%20Bank/4.2%20IMAGE%202.png)


### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```SQL
with cte_txn_type as(
	SELECT extract(month from txn_date)as months,
			TO_CHAR(txn_date, 'Month') AS month,
			customer_id,
			sum(case when txn_type = 'deposit' then 1 else 0 end)as number_deposit,
			sum(case when txn_type = 'purchase' then 1 else 0 end)as number_purchase,
			sum(case when txn_type = 'withdrawal' then 1 else 0 end)as number_withdraw
	FROM data_bank.customer_transactions
	GROUP BY 1,2,3
	order by 1,2,3
)
	select month,
			count(customer_id)as number_customer
	from cte_txn_type
	where number_deposit > 1 and (number_purchase = 1 or number_withdraw = 1)
	group by months, month
	order by months;
```
![image](https://github.com/alfiramdhan/8Weeks_SQL_Challenge/blob/main/Case%20Study%204%20-%20Data%20Bank/4.2%20IMAGE%203.png)

### 4. What is the closing balance (saldo penutupan) or running total for each customer at the end of the month?

Closing bank balance is the nominal amount of debit or credit in bank account at the end of the period

When we want to get CLOSING BALANCE, it means we need to calculate RUNNING TOTAL or total_amount per day. Once get the total_amount, we can use ROWS clause to get the running total. Since creating the closing balance requires different criteria so we have to do it step by step :

```SQL
-- CTE 1 : To identify transaction amount as an inflow (+) or outflow (-)
-- - Then generate last day or end of the month date_trunc() then add interval 1 month minus day to get last day at end of the month
WITH monthly_balances AS(
	SELECT customer_id,
		(date_trunc('month', txn_date) + INTERVAL '1 MONTH - 1 DAY')AS closing_month,
		txn_type,
		txn_amount,
		SUM(CASE WHEN txn_type = 'purchase' or txn_type = 'withdrawal' THEN (-txn_amount)
			 ELSE txn_amount
			END)as transaction_balance
	FROM data_bank.customer_transactions
	GROUP BY customer_id, txn_date, txn_type, txn_amount
	ORDER BY 1,2
),
-- CTE 2 : To generate txn_date as a series of last day of month for each customer, start from '2020-01-31'

last_day AS(
	SELECT DISTINCT customer_id,
		('2020-01-31'::DATE + GENERATE_SERIES(0,3) * INTERVAL '1 MONTH')AS ending_month
	FROM data_bank.customer_transactions
	ORDER BY 1,2
),
-- CTE 3 - Create closing balance (RUNNING TOTAL) for each DAY using Window function SUM() to add changes during the month
-- we need to assume that if the transaction_balance is null, it is zero. Then we can use the COALESCE function

closing_balance AS(
	SELECT ld.customer_id,
		ending_month,
		COALESCE(transaction_balance, 0)as monthly_change,
		SUM(transaction_balance) OVER(PARTITION BY ld.customer_id ORDER BY ending_month
						ROWS UNBOUNDED PRECEDING)as closing_balance
	FROM last_day ld
	LEFT JOIN monthly_balances mb ON ld.customer_id = mb.customer_id
		and ld.ending_month = mb.closing_month
),
-- CTE 4 - Use Window function ROW_NUMBER() to rank transactions within each month
-- ## This step is optional, if we skip this step we can jump to LEAD function and get final closing balance

transaction_rank AS(
	SELECT customer_id,
		ending_month,
		monthly_change,
		closing_balance,
		ROW_NUMBER() OVER(PARTITION BY customer_id, ending_month ORDER BY ending_month)as ranking
	FROM closing_balance		
),
-- CTE 5 - Use Window function LEAD() to query value in next row and retrieve NULL for last row

lead_rn AS(
	SELECT customer_id,
		ending_month,
		monthly_change,
		closing_balance,
		ranking,
		LEAD(ranking) OVER(PARTITION BY customer_id, ending_month ORDER BY ending_month)as lead_rank
	FROM transaction_rank		
)
-- STEP 4-5 are useful for sorting the value of the ending balance per day so if there are several values in 1 day it can be summarized

	SELECT customer_id, ending_month, 
		monthly_change, closing_balance,
		CASE WHEN lead_rank is null then ranking end as Criteria
	FROM lead_rn
	WHERE lead_rank IS NULL;
```
![image](https://github.com/alfiramdhan/8Weeks_SQL_Challenge/blob/main/Case%20Study%204%20-%20Data%20Bank/4.2%20IMAGE%204.png)


### 5. What is the percentage of customers who increase their closing balance by more than 5%?
