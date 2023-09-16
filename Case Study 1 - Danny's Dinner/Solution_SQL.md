# Case Study 1 - Danny's Diner :rice:

## Problem Statement

Danny wants to use the data to answer a few simple questions about :

1. How is customer visiting pattern ?
2. How much money customers have spent and also which menu items are their
Favourite ?
3. Expansion of existing customer loyalty program
4. Join all tables and about the ranking of customer products so Danny and his
team can quickly derive insights

Full description: [Case Study #1 - Danny's Diner](https://8weeksqlchallenge.com/case-study-1/)

## Entity Relationaship Diagram
![изображение](https://user-images.githubusercontent.com/98699089/156034410-8775d5d2-eda5-4453-9e33-54bfef253084.png)


## Case Study Questions

#### 1. What is the total amount each customer spent at the restaurant?

````sql
select s.customer_id,
		sum(m.price)as total_spent
from dannys_dinner.sales s
join dannys_dinner.menu m on s.product_id = m.product_id
group by customer_id 
order by customer_id;
````

#### 2. How many days has each customer visited the restaurant?

````sql
select customer_id,
	count(order_date)as number_days_visit
from dannys_dinner.sales	
group by 1
order by customer_id;
````

#### 3. What was the first item from the menu purchased by each customer?

To get the first item purchased, we can find the 'first_date' ordered by each customer in subquery `JOIN`
After we have 'first_date', we can select product_name to find first item purchased by each customer

````sql
select s1.customer_id, s2.first_date, s1.product_id, m.product_name
from dannys_dinner.sales s1
join (
	select ss.customer_id,
			min(ss.order_date)as first_date
	from dannys_dinner.sales ss
	group by 1
)s2 on s1.customer_id = s2.customer_id
join dannys_dinner.menu m on s1.product_id = m.product_id	
WHERE s1.order_date = s2.first_date	
order by 1;
````

Another way to he first item purchased, we can use window function `rank()` to rank the items ordered by each customer in a temporary table using WITH statement.
After we have those ranks, we can select the rows with the rank = 1.

````sql
with index_rank as(
	select customer_id,
		order_date,
		product_id,
		row_number() over(partition by customer_id order by order_date)as rnk
	from dannys_dinner.sales)
	
select customer_id,
	order_date,
	product_name
from index_rank id, menu mn
where id.product_id = mn.product_id
  and rnk = 1
order by 1;		
````

The first purchase for customer A was sushi

The first purchase for customer B was curry

The first (and the only) purchase for customer C was ramen


#### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

````sql
SELECT t1.product_id,
	product_name,
	COUNT(t1.product_id)as total_items
FROM dannys_dinner.sales t1
LEFT JOIN dannys_dinner.menu t2 ON t1.product_id = t2.product_id
GROUP BY 1,2
ORDER BY 3 desc
````
The most purchased item on the menu was ramen, it was purchased 8 times in total


#### 5. Which item was the most popular for each customer?

````sql
WITH rank_order AS (
	SELECT t1.customer_id,
		product_name,
		COUNT(t1.product_id)as total_items,
		ROW_NUMBER () OVER(PARTITION BY t1.customer_id ORDER BY COUNT(t1.product_id) desc )as rn
	FROM dannys_dinner.sales t1
	LEFT JOIN menu t2 ON t1.product_id = t2.product_id
	GROUP BY 1,2
	ORDER BY 3 DESC
)
	
SELECT customer_id,
	product_name,
	total_items,
	rn
FROM rank_order
WHERE rn=1
ORDER BY 1;
````
The most popular item for customer A was ramen, they purchased it 3 times

The most popular item for customer B was curry, ramen and sushi, they purchased each dish 2 times

The most popular item for customer C was ramen, they purchased it 3 times


#### 6. Which item was purchased first by the customer after they became a member?

Let's consider that if the purchase date matches the membership date, then the purchase made on this date, was the first customer's purchase as a member. It means that we need to include this date in the `WHERE` statement.

````sql
select s1.customer_id, s1.first_date, s2.product_id, m.product_name
from (
	select ss.customer_id,
			min(ss.order_date)as first_date
	from dannys_dinner.members mm
	join dannys_dinner.sales ss on mm.customer_id = ss.customer_id
	where ss.order_date > mm.join_date
	group by 1
)s1
left join dannys_dinner.sales s2 on s1.customer_id = s2.customer_id
join dannys_dinner.menu m on s2.product_id = m.product_id	
WHERE s2.order_date = s1.first_date	
order by 1;
````

Another way to he first item purchased, we can use window function `dense_rank()` to rank the items ordered by each customer in a temporary table using WITH statement.
After we have those ranks, we can select the rows with the rank = 1.

````sql
with ranking AS(
	SELECT mm.customer_id,
		order_date,
		product_name,
		DENSE_RANK() OVER(PARTITION BY mm.customer_id ORDER BY order_date)as rnk
	FROM dannys_dinner.members mm
	JOIN dannys_dinner.sales s on mm.customer_id = s.customer_id
	JOIN dannys_dinner.menu mn on s.product_id = mn.product_id
	WHERE order_date >= join_date
)
	SELECT customer_id,
		order_date,
		product_name
	FROM ranking
	WHERE rnk = 1;
````
So, We find that Curry was purchased first by A after they become a member. Then, Sushi was purchased first by B after they become a member


#### 7. Which item was purchased just before the customer became a member?

Customer A purchased their membership on January, 7 - and they placed an order that day. We do not have time and therefore can not say exactly if this purchase was made before of after they became a member. Let's consider that if the purchase date matches the membership date, then the purchase made on this date, was the first customer's purchase as a member. It means that we need to exclude this date in the `WHERE` statement.

````sql
SELECT mm.customer_id,
	order_date,
	product_name,
	DENSE_RANK() OVER(PARTITION BY mm.customer_id ORDER BY order_date DESC)as rnk
FROM dannys_dinner.members mm
JOIN dannys_dinner.sales s on mm.customer_id = s.customer_id
JOIN dannys_dinner.menu mn on s.product_id = mn.product_id
WHERE order_date < join_date;
````
So, We find that Sushi was purchased by A & B just before they become a member


#### 8. What is the total items and amount spent for each member before they became a member?

Let's consider that if the purchase date matches the membership date, then the purchase made on this date, was the first customer's purchase as a member. It means that we need to exclude this date in the `WHERE` statement.

````sql
WITH ranking AS(	
	SELECT mm.customer_id,
		order_date,
		COUNT(mn.product_id)as total_items,
		SUM(price)as total_amount,
		DENSE_RANK() OVER(PARTITION BY mm.customer_id ORDER BY order_date DESC)as rnk
	FROM dannys_dinner.members mm
	JOIN dannys_dinner.sales s on mm.customer_id = s.customer_id
	JOIN dannys_dinner.menu mn on s.product_id = mn.product_id
	WHERE order_date < join_date
	GROUP BY 1,2
)
	SELECT customer_id,
		order_date,
		total_items,
		total_amount
	FROM ranking
	WHERE rnk = 1;
````
For A, the total items and amount spent before they become a member were 2 and 25

While B, the total items and amount spent before they become a member were 1 and 10


#### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

Since points value only for members so we need to specify for each customer after became a member

````sql
SELECT t1.customer_id,
	SUM(point)as total_point
FROM dannys_dinner.sales t1
JOIN (
	SELECT product_id,
		product_name,
		CASE WHEN product_name = 'sushi' THEN price * 20
			ELSE price * 10
		END as point
	FROM dannys_dinner.menu) t2 ON t1.product_id = t2.product_id
JOIN dannys_dinner.members t3 ON t1.customer_id = t3.customer_id
WHERE order_date >= join_date	
GROUP BY 1
ORDER BY 1;
````

Or we can use CTE :
````sql
WITH total AS(
	SELECT mm.customer_id,
		CASE WHEN product_name = 'sushi' THEN sum(price*20)
			else sum(price*10)
		END as point
	FROM dannys_dinner.sales s
	JOIN dannys_dinner.members mm on s.customer_id = mm.customer_id
	JOIN dannys_dinner.menu mn on s.product_id = mn.product_id
	WHERE order_date >= join_date
	GROUP BY mm.customer_id, product_name
)	
	SELECT customer_id,
		SUM(point)as total_point
	FROM total
	GROUP BY 1
	ORDER BY 1;
````
For A, the total points are 510. Then for B, the total points are 440

#### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

First Step : calculate the total points for each customer as in number 9

````sql
WITH total AS(
	SELECT s.customer_id,
		order_date,
		CASE WHEN product_name = 'sushi' THEN sum(price*20)
			else sum(price*10)
		END as point
	FROM dannys_dinner.sales s
	JOIN dannys_dinner.menu mn on s.product_id = mn.product_id
	GROUP BY s.customer_id, order_date,product_name
),
total_point AS
	SELECT customer_id,
		order_date,
		SUM(point)as total_point
	FROM total
	GROUP BY 1,2
	ORDER BY 1,2
)
````
Once we get total_point, then we can get total points for each customer after they become a member
- txn from 07/01 to 14/01 (7days) for A
- txn from 09/01 to 16/01 (7days)for B. So we use interval 2 days
Since the hint is end of January so we can use CASE WHEN function and Interval function to retrieve data

````
	SELECT mm.customer_id,
		SUM(CASE WHEN order_date >= join_date 
				AND order_date < join_date + (7*INTERVAL '2 day')
				THEN total_point *2
			else total_point
		END)as total_new_point
	FROM total_point t
	JOIN dannys_dinner.members mm ON t.customer_id = mm.customer_id
	WHERE DATE_PART('month',order_date) = 1
	GROUP BY 1
	ORDER BY 1;
````

-- Bonus Question

11. Join all the things

````sql
SELECT t1.customer_id, order_date,
product_name,
price,
CASE WHEN order_date >= join_date THEN 'Y'
ELSE 'N' END as members
FROM dannys_dinner.sales t1
LEFT JOIN dannys_dinner.menu t2 ON t1.product_id = t2.product_id
LEFT JOIN dannys_dinner.members t3 ON t1.customer_id = t3.customer_id;
````

12. Rank all the things

````sql
WITH index_rn AS (
SELECT t1.customer_id,
order_date, product_name, price,
CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END as members
FROM dannys_dinner.sales t1
LEFT JOIN dannys_dinner.menu t2 ON t1.product_id = t2.product_id
LEFT JOIN dannys_dinner.members t3 ON t1.customer_id = t3.customer_id ORDER BY 1
)
SELECT customer_id,
order_date, product_name, price, members,
CASE WHEN members = 'N' THEN null
ELSE RANK () OVER (PARTITION BY customer_id,members ORDER BY order_date)
END as ranking FROM index_rn ;
````

--
