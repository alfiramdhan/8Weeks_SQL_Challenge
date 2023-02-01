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
![image](https://github.com/alfiramdhan/8Weeks_SQL_Challenge/blob/main/Case%20Study%204%20-%20Data%20Bank/regions.png)

### 2. What is the average total historical deposit counts and amounts for all customers?



### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?



### 4. What is the closing balance for each customer at the end of the month?




### 5. What is the percentage of customers who increase their closing balance by more than 5%?
