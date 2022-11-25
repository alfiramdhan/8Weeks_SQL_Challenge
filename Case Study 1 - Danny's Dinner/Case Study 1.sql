CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
select customer_id,
		sum(price)as total_spent
from sales s
join menu m on s.product_id = m.product_id
group by customer_id
order by customer_id;


-- 2. How many days has each customer visited the restaurant?
select customer_id,
		count(order_date)
from sales	
group by 1
order by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
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
order by 1	;

-- or
with index_rank as(
	select customer_id,
			order_date,
			product_id,
			row_number() over(partition by customer_id order by order_date)as ranking
	from sales	)
	
select customer_id,
		order_date,
		product_name
from index_rank id, menu mn
where id.product_id = mn.product_id
	and ranking = 1
order by 1	

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name,
		count(s.product_id)as total_purchase,
		ROW_NUMBER() OVER(ORDER BY count(s.product_id) DESC)as row_total_items,
		RANK() OVER(ORDER BY count(s.product_id) DESC)as rank_total_items
FROM menu m, sales s
WHERE m.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC


-- 5. Which item was the most popular for each customer?
SELECT customer_id,
		product_name,
		count(s.product_id)as total_purchase,
		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY count(s.product_id) DESC)as row_popular
FROM sales s, menu m
WHERE s.product_id = m.product_id
GROUP BY 1,2
ORDER BY 4, 3 DESC


-- 6. Which item was purchased first by the customer after they became a member?
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
order by 1	;

-- or
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
order by 1	



-- 7. Which item was purchased just before the customer became a member?
	select s.customer_id,
			s.order_date as date_before_member,
			mn.product_id,
			mn.product_name
	from sales s, members ms, menu mn
	where s.customer_id = ms.customer_id
		and s.product_id = mn.product_id
		and s.order_date < ms.join_date
	order by 1,2


-- 8. What is the total items and amount spent for each member before they became a member?
	select s.customer_id,
			order_date as date_before_member,
			count(s.product_id)as total_items,
			sum(price)as total_spent
	from sales s, members ms, menu mn
	where s.customer_id = ms.customer_id
		and s.product_id = mn.product_id
		and s.order_date < ms.join_date
	group by 1,2
	order by 1,2



-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier
--		- how many points would each customer have?
with total_points as(
	select customer_id,
			product_name,
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


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
--		- how many points do customer A and B have at the end of January? 		
with total_points as(	
	select mm.customer_id,
			order_date,
			join_date,
			case when order_date>=join_date then 20 end as points,
			sum(price)as total_spent
	from members mm
	left join sales ss ON mm.customer_id = ss.customer_id
	join menu mn ON ss.product_id = mn.product_id
	group by 1,2,3
	order by 1
	)
		select customer_id,
				sum(total_spent*points)as customer_points
		from total_points		
		group by 1
		order by 1;
	
