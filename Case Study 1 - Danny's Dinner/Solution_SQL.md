# Case Study 1 - Danny's Diner :rice:

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
#### Steps :
- Use `JOIN` to merge sales and menu table as customer_id and price columns are from both table
- Use `SUM()` and `GROUP BY` to find out the total amount for each customers

#### Answer :
- Total amount spent for customer A is $76
- Total amount spent for customer B is $74
- Total amount spent for customer C is $36
----

#### 2. How many days has each customer visited the restaurant?

````sql
select customer_id,
	count(order_date)as number_days_visit
from dannys_dinner.sales	
group by 1
order by customer_id;
````

#### Steps :
- Use `COUNT()` and `DISTINCT` to find out total visit for each customers
- If we do not use DISTINCT, the number of days may be repeated

#### Answer :
- Customer A visited 4 times
- Customer B visited 6 times
- Customer C visited 2 times
----

#### 3. What was the first item from the menu purchased by each customer?

#### Option 1
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

#### Steps :
- Use `JOIN` and `MIN()` in subquery to get the first item purchased for each customer
- Use the `WHERE` clause to filter on the `order_date = first_date` condition

#### Option 2
````sql
with index_rank as(
	select customer_id,
		order_date,
		product_id,
		dense_rank() over(partition by customer_id order by order_date)as rnk
	from dannys_dinner.sales
)	
select customer_id,
	order_date,
	product_name
from index_rank id
join dannys_dinner.menu mn on id.product_id = mn.product_id
where rnk = 1
order by 1;		
````

#### Steps :
- Use `CTE` to create temporary table
- Use window function `dense_rank()` to rank the items ordered by each customer in a temporary table
- After we have those ranks, we can use `WHERE` clause to select the rows with the rank = 1.

#### Answer :
- Customer A's first purchases were sushi and curry
- Customer B's first purchases was curry
- Customer C's first purchases was ramen
----

#### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

````sql
SELECT t1.product_id,
	product_name,
	COUNT(t1.product_id)as total_items
FROM dannys_dinner.sales t1
LEFT JOIN dannys_dinner.menu t2 ON t1.product_id = t2.product_id
GROUP BY 1,2
ORDER BY 3 DESC;
````

#### Steps :
- Use `COUNT()` and `GROUP BY` to find out number of order for each menu
- Use `ORDER BY` and `DESCENDING` to get the most purchase item by all customers

#### Answer :
- The most purchased item on the menu was ramen, it was purchased 8 times in total
----

#### 5. Which item was the most popular for each customer?

````sql
WITH rank_order AS (
	SELECT t1.customer_id,
		product_name,
		COUNT(t1.product_id)as total_items,
		DENSE_RANK () OVER(PARTITION BY t1.customer_id ORDER BY COUNT(t1.product_id) desc )as rn
	FROM dannys_dinner.sales t1
	JOIN dannys_dinner.menu t2 ON t1.product_id = t2.product_id
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
#### Steps :
- Create a `CTE` and use `DENSE_RANK()` to rank number of order for each menu for each customer
- Use the `WHERE` clause to filter table by rank = 1 to show 1st item purchased by each customer

#### Answer :
- The most popular item for customer A and C was ramen, they purchased it 3 times
- Meanwhile, Customer B enjoys all items on the menu.
----

#### 6. Which item was purchased first by the customer after they became a member?

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
#### Steps :
- Create a `CTE` and use `DENSE_RANK()` to rank purchased items by partitioning `customer_id` and ordering in ascending `order_date`
- Use the `WHERE` clause to filter purchases after a customer becomes a member
- Use the `WHERE` clause to filter table by rank = 1 to show 1st item purchased by each customer

#### Answer :
- Customer A's first order as member is curry
- Customer B's first order as member is sushi
----

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
#### Steps :
- Create a `CTE` and use `DENSE_RANK()` to rank purchased items by partitioning `customer_id` and ordering in descending `order_date`
- Use the `WHERE` clause to filter purchases before a customer becomes a member
- Use the `WHERE` clause to filter table by rank = 1 to show 1st item purchased by each customer

#### Answer :
- Customer A's last order before becoming a member was sushi and curry
- Meanwhile, Customer B's last order before becoming a member was sushi
----

#### 8. What is the total items and amount spent for each member before they became a member?

Let's consider that if the purchase date matches the membership date, then the purchase made on this date, was the first customer's purchase as a member. It means that we need to exclude this date in the `WHERE` statement.

````sql
WITH total AS(	
	SELECT mm.customer_id,
		order_date,
		COUNT(mn.product_id)as total_items,
		SUM(price)as total_amount
	FROM dannys_dinner.members mm
	JOIN dannys_dinner.sales s on mm.customer_id = s.customer_id
	JOIN dannys_dinner.menu mn on s.product_id = mn.product_id
	WHERE order_date < join_date
	GROUP BY 1,2
	ORDER BY 1,2
)
	SELECT customer_id,
		SUM(total_items)as total_items,
		SUM(total_amount)as total_amount
	FROM total
	GROUP BY 1;
````
#### Steps :
- Create a `CTE` and use `COUNT(), SUM()` to calculate total items and total amount
- Use the `JOIN` clause to merge members, sales and menu table as customer_id , product_id and price columns are from those table
- Use the `WHERE` clause to filter purchases before a customer becomes a member

#### Answer :
Before becoming members,
- Customer A spent $ 25 on 2 items.
- Customer B spent $ 40 on 3 items.
----

#### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

````sql
WITH total AS(
	SELECT *,
		CASE WHEN product_id = 1 THEN price * 20
			else price * 10
		END as point
	FROM dannys_dinner.menu
)	
	SELECT s.customer_id,
		SUM(point)as total_point
	FROM total t
	JOIN dannys_dinner.sales s on t.product_id = s.product_id
	GROUP BY 1
	ORDER BY 1;
````
#### Steps :
Let’s breakdown the question.
- Each $1 spent = 10 points.
- But, sushi (product_id = 1) gets 2x points, meaning each $1 spent = 20 points So, we use `CASE WHEN` to create conditional statements
- If product_id = 1, then every $1 price multiply by 20 points
- All other product_id that is not 1, multiply $1 by 10 points
- Using `total`, SUM the point

#### Answer :
- Total points for Customer A is 860
- Total points for Customer B is 940
- Total points for Customer C is 360
----

#### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

#### 1st Step :
- Create `CTE` then find out customer's first week after join the program (which is 6 days after `join_date`) and `end_month' of Jan 2021 (which is ‘2021–01–31’)

````sql
WITH dates_cte AS 
(
   SELECT *, 
      date(join_date + integer '6') first_week, 
      date('2021-01-31') end_month
   FROM dannys_dinner.members mm
),
````
#### 2nd Step :
Our assumptions are:
- On Day -X to Day 1 (customer becomes member on Day 1 join_date), each $1 spent is 10 points and each $1 spent is 20 points for sushi.
- On Day 1 join_date to Day 7 valid_date, each $1 spent for all items is 20 points.
- On Day 8 to end_month of Jan 2021, each $1 spent is 10 points and sushi is 20 points.

````sql
point AS(
SELECT d.customer_id, s.order_date, d.join_date, d.first_week, d.end_month, m.product_name, m.price,
   SUM(CASE
      WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
      WHEN s.order_date BETWEEN d.join_date AND d.first_week THEN 2 * 10 * m.price
      ELSE 10 * m.price
      END) points
FROM dates_cte d
JOIN dannys_dinner.sales s ON d.customer_id = s.customer_id
JOIN dannys_dinner.menu m ON s.product_id = m.product_id
WHERE s.order_date < d.end_month
GROUP BY 1,2,3,4,5,6,7
)
	SELECT customer_id,
		SUM(points)as total_point
	FROM point		
	GROUP BY 1;	
````
#### Answer :
- Total points for Customer A is 1,370
- Total points for Customer B is 820
----

## Bonus Question

#### 11. Join all the things

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
----
#### 12. Rank all the things

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
----
