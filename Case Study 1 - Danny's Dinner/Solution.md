# Case Study 1 - Danny's Diner :rice:

## Problem Statement

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers. 

Full description: [Case Study #1 - Danny's Diner](https://8weeksqlchallenge.com/case-study-1/)

## Entity Relationaship Diagram
![изображение](https://user-images.githubusercontent.com/98699089/156034410-8775d5d2-eda5-4453-9e33-54bfef253084.png)


## Case Study Questions

#### 1. What is the total amount each customer spent at the restaurant?

````sql
select s.customer_id,
		sum(m.price)as total_spent
from sales s
join menu m on s.product_id = m.product_id
group by customer_id 
order by customer_id;
````

#### 2. How many days has each customer visited the restaurant?

````sql
select customer_id,
	count(order_date)as number_days_visit
from sales	
group by 1
order by customer_id;
````

#### 3. What was the first item from the menu purchased by each customer?

To get the first item purchased, we can find the 'first_date' ordered by each customer in subquery `JOIN`
After we have 'first_date', we can select product_name to find first item purchased by each customer

````sql
select s1.customer_id, s2.first_date, s1.product_id, m.product_name
from sales s1
join (
	select ss.customer_id,
			min(ss.order_date)as first_date
	from sales ss
	group by 1
)s2 on s1.customer_id = s2.customer_id
join menu m on s1.product_id = m.product_id	
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
	from sales)
	
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
SELECT product_name,
	count(s.product_id)as total_purchase,
	ROW_NUMBER() OVER(ORDER BY count(s.product_id) DESC)as row_total_items,
	RANK() OVER(ORDER BY count(s.product_id) DESC)as rank_total_items
FROM menu m, sales s
WHERE m.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;
````
The most purchased item on the menu was ramen, it was purchased 8 times in total


#### 5. Which item was the most popular for each customer?

````sql
SELECT customer_id,
		product_name,
		count(s.product_id)as total_purchase,
		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY count(s.product_id) DESC)as row_popular
FROM sales s, menu m
WHERE s.product_id = m.product_id
GROUP BY 1,2
ORDER BY 1, 3 DESC;
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
	from members mm
	join sales ss on mm.customer_id = ss.customer_id
	where ss.order_date > mm.join_date
	group by 1
)s1
left join sales s2	on s1.customer_id = s2.customer_id
join menu m on s2.product_id = m.product_id	
WHERE s2.order_date = s1.first_date	
order by 1;
````

Another way to he first item purchased, we can use window function `rank()` to rank the items ordered by each customer in a temporary table using WITH statement.
After we have those ranks, we can select the rows with the rank = 1.

````sql
with index_rank as(
	select mm.customer_id,
			order_date,
			s.product_id,
			row_number() over(partition by mm.customer_id order by order_date)as ranking
	from sales s, members mm
	where s.customer_id = mm.customer_id
		and s.order_date>mm.join_date)
	
select customer_id,
		order_date,
		product_name
from index_rank id, menu mn
where id.product_id = mn.product_id
	and ranking = 1
order by 1;
````

#### 7. Which item was purchased just before the customer became a member?

Customer A purchased their membership on January, 7 - and they placed an order that day. We do not have time and therefore can not say exactly if this purchase was made before of after they became a member. Let's consider that if the purchase date matches the membership date, then the purchase made on this date, was the first customer's purchase as a member. It means that we need to exclude this date in the `WHERE` statement.

````sql
select s.customer_id,
	s.order_date as date_before_member,
	mn.product_id,
	mn.product_name
from sales s, members ms, menu mn
where s.customer_id = ms.customer_id
	and s.product_id = mn.product_id
	and s.order_date < ms.join_date
order by 1,2;
````

#### 8. What is the total items and amount spent for each member before they became a member?

Let's consider that if the purchase date matches the membership date, then the purchase made on this date, was the first customer's purchase as a member. It means that we need to exclude this date in the `WHERE` statement.

````sql
select s.customer_id,
	order_date as date_before_member,
	count(s.product_id)as total_items,
	sum(price)as total_spent
from sales s, members ms, menu mn
where s.customer_id = ms.customer_id
	and s.product_id = mn.product_id
	and s.order_date < ms.join_date
group by 1,2
order by 1,2;
````

#### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

````sql
with total_points as(
	select customer_id,
		product_id,
		sum(price)as total_spent,
		case when m.product_name = 'sushi' THEN 20
		else 10 end as points
	from sales s, menu m
	where s.product_id = m.product_id
	group by 1,2
	order by 1
)
		select customer_id,
			sum(total_spent*points)as customer_points
		from total_points		
		group by 1
		order by 1;
````

#### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


