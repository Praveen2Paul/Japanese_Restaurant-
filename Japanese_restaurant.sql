Create Database japanese_restaurant;
use japanese_restaurant;

CREATE TABLE sales (customer_id VARCHAR(1),  order_date DATE,  product_id INTEGER);
INSERT INTO sales
  (customer_id, order_date, product_id)
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
  
CREATE TABLE menu (  product_id INTEGER,  product_name VARCHAR(5),  price INTEGER);
INSERT INTO menu (product_id, product_name, price)
VALUES ('1', 'sushi', '10'), ('2', 'curry', '15'),  ('3', 'ramen', '12');

CREATE TABLE members ( customer_id VARCHAR(1),  join_date DATE);
INSERT INTO members  (customer_id, join_date)
VALUES  ('A', '2021-01-07'), ('B', '2021-01-09');

# What is the total amount each customer spent at the restaurant?
select customer_id,sum(price) as total_sales from sales inner join menu on sales.product_id = menu.product_id group by customer_id;

# How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as no_of_days from sales group by customer_id;

# What was the first item from the menu purchased by each customer?
with ordered_items_cte as (select customer_id, order_date, product_name,
dense_rank() over(partition by customer_id order by order_date) as rnk 
from sales inner join menu on sales.product_id = menu.product_id)
select customer_id, product_name from ordered_items_cte where rnk = 1 group by customer_id,product_name;

# What is the most purchased item on the menu and how many times was it purchased by all customers?
select menu.product_name, count(menu.product_id) most_purchased from sales 
inner join menu on sales.product_id = menu.product_id 
group by menu.product_id, menu.product_name order by most_purchased desc limit 1;

# Which item was the most popular one for each customer?
with fav_item as (select a.customer_id,b.product_name,count(b.product_id) as order_cnt,
dense_rank() over(partition by customer_id order by count(b.product_id) desc) as rnk 
from sales a inner join menu b on a.product_id=b.product_id group by customer_id,product_name)
select customer_id,product_name,order_cnt from fav_item where rnk = 1;

# Which item was purchased first by the customer after they became a member?
with member_sales as (select a.customer_id,b.join_date,a.order_date,a.product_id, 
dense_rank() over(partition by a.product_id order by order_date) as rnk 
from sales a left join members b on a.customer_id = b.customer_id where a.order_date = b.join_date)
select c.customer_id, c.order_date, d.product_name from member_sales c inner join menu d on c.product_id = d.product_id;

# Which item was purchased right before the customer became a member?
with prior_member_sales as (select a.customer_id,b.join_date,a.order_date,a.product_id,
dense_rank() over(partition by customer_id order by order_date desc) as rnk  
from sales a join members b on a.customer_id = b.customer_id where a.order_date < b.join_date)
select c.customer_id,c.order_date,d.product_name from prior_member_sales c 
inner join menu d on c.product_id = d.product_id where rnk = 1;

# What is the total number of items and amount spent for each member before they became a member?
select a.customer_id,count(distinct a.product_id) as no_of_item,sum(c.price) as amount_spent
from sales a join members b on a.customer_id = b.customer_id join menu c on a.product_id = c.product_id where a.order_date < b.join_date 
group by customer_id;

# If each customers $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
with price_points as (select *,case when product_id=1 then price*20
		else price*10 end as points from menu)
select customer_id,sum(a.points) as total_points 
from price_points a inner join sales b on a.product_id = b.product_id 
group by b.customer_id order by b.customer_id;