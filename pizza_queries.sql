/*1. In each category, how many types of pizza's are available?*/
select category, count(*) as types_of_pizzas
from pizza_db.pizza_types
group by category;

/*2. Find total revenue generated annually.*/
select round(sum(total_amount),2) as annual_revenue
from sales_details;

/*3. Find total revenue generated daily.*/
select round(sum(total_amount)/365,2) as daily_revenue
from sales_details;

/*4. Find total revenue per order.*/
select round(sum(total_amount)/count(distinct order_id),2) as revenue_per_order
from sales_details;

/*5. Find the total pizzas sold in a year.*/
select sum(quantity) as total_quantity
from order_details;

/*3. Find total pizzas sold daily.*/
select round(sum(quantity)/365,2) as daily_sold
from order_details;

/*4. How many pizzas were ordered by each individual order.*/
select round(sum(quantity)/count(distinct order_id),2) as pizzas_sold_per_order
from order_details;

/*5. List the highest and lowest percentage of pizzas sold of their kind.*/
with max_min as (with cte as (select p.pizza_type_id, od.order_id, od.pizza_id, od.quantity
from order_details od
inner join pizzas p using(pizza_id))

select c.pizza_type_id, pt.name, round((sum(c.quantity)/(select sum(quantity) from order_details))*100,2) as sold_prcnt
from cte c
inner join pizza_types pt using(pizza_type_id)
group by c.pizza_type_id, pt.name)

select *
from max_min
where sold_prcnt in ((select max(sold_prcnt) from max_min),(select min(sold_prcnt) from max_min));

/*6. List the highest and lowest revenue producing pizzas.*/
with max_min as (with cte as (select p.pizza_type_id, sd.order_id, sd.pizza_id, sd.total_amount
from sales_details sd
inner join pizzas p using(pizza_id))

select c.pizza_type_id, pt.name, round(sum(c.total_amount/1000),2) as revenue_in_thsnd
from cte c
inner join pizza_types pt using(pizza_type_id)
group by c.pizza_type_id, pt.name)

select *
from max_min
where revenue_in_thsnd in ((select max(revenue_in_thsnd) from max_min),(select min(revenue_in_thsnd) from max_min));

/*7. Make a list of running customers and table counts in a pizza resturants.*/
with cte as (select order_id, date, time, total_customers, tables_required,
       @running_total := @running_total + total_customers as running_customers,
       @running_total2 := @running_total2 + tables_required as running_tables
from turnout_details, (select @running_total := 0) as rt, (select @running_total2 := 0) as rt2
order by date, time)

select count(*)
from cte;

/*8. How many times the tables are exceeded with more than 15 even if the chairs are not fully occupied.*/
with times as (with table_status as (select order_id, date, time, total_customers, tables_required,
       @running_total := @running_total + total_customers as running_customers,
       @running_total2 := @running_total2 + tables_required as running_tables
from turnout_details, (select @running_total := 0) as rt, (select @running_total2 := 0) as rt2
order by date, time)

select *, if(running_tables > 15, "Exceed", "Ok") as status
from table_status)

select status, concat(count(*), " times") as cnt
from times
group by status;

/*9. How many customers have ordered atleast four pizzas?*/
with avg_prcnt as (with pizza_status as (select order_id, sum(quantity) as total_quantity
from order_details
group by order_id)

select *, if(total_quantity in (1,2,3), "3 Pizzas", "Atleast 4 Pizzas") as status
from pizza_status)

select status, concat(round(count(*)*100/(select count(*) from avg_prcnt),2), "%") as prcnt
from avg_prcnt
group by status;

/*10. How many average pizzas were sold on each weekday?*/
with cte as (with t1 as (select order_id, sum(quantity) as total_qty
from order_details
group by order_id),
t2 as (
select order_id, date, dayname(date) as name_of_week
from orders)

select *
from t1 
inner join t2 using(order_id))

select name_of_week, round(sum(total_qty)/52) as avg_pizzas_sold
from cte
group by name_of_week
order by 2;

/*11. What is the total average sales of pizza in each weekday?*/
with cte as (with t1 as (select order_id, sum(total_amount) as order_amt
from sales_details
group by order_id),
t2 as (
select order_id, date, dayname(date) as name_of_week
from orders)

select *
from t1 
inner join t2 using(order_id))

select name_of_week, concat("$ ",round(sum(order_amt)/52,2)) as avg_sales
from cte
group by name_of_week
order by 2;

/*12. Which size of pizzas ordered the most?*/
select size, count(*) as ordered
from pizzas p
inner join order_details od using(pizza_id)
group by size
order by ordered desc;

/*13. What kind of pizza of large size is sold the most?*/
with pizza_name as (select pizza_type_id, count(*) as large_size_ordered
from pizzas p
inner join order_details od using(pizza_id)
where size = "L"
group by pizza_type_id
order by 2 desc)

select pizza_type_id, name, large_size_ordered
from pizza_types pt
inner join pizza_name pn using(pizza_type_id);

/*14. At what hours the pizzas sold the most in Friday and Sunday?*/
with hourwise_rank as(select dayname(date) as name_of_day, hour(time) as hours, count(*) as order_cnt 
from pizza_db.orders 
group by name_of_day, hours with rollup
having hours is not null
order by 1,2)

select *, rank() over(partition by name_of_day order by order_cnt desc) as rnk
from hourwise_rank
where name_of_day in ("Friday", "Sunday");

/*15. Which time has the highest number of orders we get?*/
with fall_count as (with day_category as (select *, hour(time) as hours
from orders)

select *, case
			when hours between 9 and 11 then "Morning"
            when hours between 12 and 18 then "Afternoon"
            else "Evening"
		  end as day_fall
from day_category)

select day_fall, count(*) as order_count
from fall_count
group by day_fall;