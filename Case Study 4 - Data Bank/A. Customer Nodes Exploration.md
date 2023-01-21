## Case Study #4: Data Bank - Customer Nodes Exploration

### Case Study Questions

1. How many unique nodes are there on the Data Bank system?
2. What is the number of nodes per region?
3. How many customers are allocated to each region?
4. How many days on average are customers reallocated to a different node?
5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

----

### 1. How many unique nodes are there on the Data Bank system?
```sql
select count(distinct node_id)
from data_bank.customer_nodes;
```

### 2. What is the number of nodes per region?
```sql
select region_id,
		count(node_id)as number_node
FROM data_bank.customer_nodes
group by 1
order by 1;
```

### 3. How many customers are allocated to each region?
```sql
select region_id,
		count(distinct customer_id)
FROM data_bank.customer_nodes 
group by 1
order by 1;
```

### 4. How many days on average are customers reallocated to a different node?

Firstly, we need to check if there is any duplication or data anomaly 
```sql
select distinct start_date
from data_bank.customer_nodes

select distinct end_date
from data_bank.customer_nodes
```
There is anomali date in end_date column : 9999-12-31. So we can clean data with `WHERE` clause

After clean data, we can find the average number of reallocated days
```sql
select round(avg(end_date - start_date),2)as avg_reallocated
from data_bank.customer_nodes
where end_date != '9999-12-31';
```

### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

reallocation days metric: days taken to reallocate to a different node

1. find median or 50th percwntile for reallocation days
```sql
with reallocation_days_cte AS(
	SELECT *,
			end_date - start_date as reallocation_days
	FROM data_bank.customer_nodes
	join data_bank.regions using (region_id)
	where end_date != '9999-12-31'
),
-- Percentile found by partitioning the dataset by regions and arranging it in ascending order of reallocation_days
-- 50th percentile -> 50% of the values are less than or equal to the current value

percentile AS(
	select *,
			percent_rank() over(partition by region_id order by reallocation_days)*100 as p
	from reallocation_days_cte
)
	select region_id,
			region_name,
			reallocation_days
	from percentile
	where p > 50
	group by 1,2,3
	order by 1,3;
```
2. find 80th percwntile for reallocation days
```sql
with reallocation_days_cte AS(
	SELECT *,
			end_date - start_date as reallocation_days
	FROM data_bank.customer_nodes
	join data_bank.regions using (region_id)
	where end_date != '9999-12-31'
),
-- Percentile found by partitioning the dataset by regions and arranging it in ascending order of reallocation_days
-- 80th percentile -> 80% of the values are less than or equal to the current value

percentile AS(
	select *,
			percent_rank() over(partition by region_id order by reallocation_days)*100 as p
	from reallocation_days_cte
)
	select region_id,
			region_name,
			reallocation_days
	from percentile
	where p > 80
	group by 1,2,3
	order by 1,3;
```
3. find 95th percwntile for reallocation days
```sql
with reallocation_days_cte AS(
	SELECT *,
			end_date - start_date as reallocation_days
	FROM data_bank.customer_nodes
	join data_bank.regions using (region_id)
	where end_date != '9999-12-31'
),
-- Percentile found by partitioning the dataset by regions and arranging it in ascending order of reallocation_days
-- 95th percentile -> 95% of the values are less than or equal to the current value

percentile AS(
	select *,
			percent_rank() over(partition by region_id order by reallocation_days)*100 as p
	from reallocation_days_cte
)
	select region_id,
			region_name,
			reallocation_days
	from percentile
	where p > 95
	group by 1,2,3
	order by 1,3;
```

--
