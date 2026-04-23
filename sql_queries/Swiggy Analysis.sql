use SwiggyAnalysis
select * from dim_date;
select * from dim_dish

select * from dim_location

select * from dim_restaurant

select * from fact_orders

--Data Validation
--Null Check

select
SUM(case when state IS NULL then 1 ELSE 0 END)AS null_state,
SUM(case when city is null then 1 else 0 end) as null_city,
SUM(case when location  IS NULL then 1 else 0 end ) as null_location
from dim_location

select
SUM(case when category is null then 1 else 0 end ) as null_category,
SUM(case when dish_name IS NULL then 1 else 0 end ) as null_dish
from dim_dish

select 
SUM(case when price is null then 1 else 0 end) as null_price,
SUM(case when rating is null then 1 else 0 end) as null_rating,
SUM(case when rating_count is null then 1 else 0 end) as rating_count
from fact_orders

select
SUM(case when order_date IS NULL then 1 else 0 end ) as null_order_date
from dim_date

select 
SUM(case when restaurant_name IS NULL then 1 else 0 end ) as null_restaurant
from dim_restaurant

--Blank Or Empty String
select * 
from dim_location
where state='' or city='' or location=''

select *
FROM dim_dish
where category='' or dish_name=''

--Duplicate Detection
select
state, city, location, COUNT(*) as cnt
from dim_location
group by state, city, location
having COUNT(*)>1

select
category, dish_name, COUNT(*) as cnt
from dim_dish
group by category,dish_name
having COUNT(*)>1

select 
price,rating,rating_count, COUNT(*) as  cnt
from fact_orders
group by price,rating,rating_count
having COUNT(*)>1

select 
order_date,COUNT(*) as cnt
from dim_date
group by order_date
having COUNT(*)>1

select 
restaurant_name ,COUNT(*) as cnt
from dim_restaurant
group by restaurant_name
having COUNT(*)>1

--Delete Duplication
with cte AS (
SELECT	 *,row_number() over(
partition by state,city,location
order by (select null)
) as dd
from dim_location
)
delete from cte where dd>1

with cte as(
select * ,ROW_NUMBER() over(
partition by category,dish_name
order by (select null)
) as dd
from dim_dish
)
delete from cte where dd>1


with cte as (
select *, ROW_NUMBER() over(
PARTITION BY price,rating,rating_count
ORDER BY (SELECT NULL)
) AS DD
from fact_orders
)
delete from cte where dd>1


with cte as (
select *, ROW_NUMBER() over(
PARTITION BY order_date
ORDER BY (SELECT NULL)
) AS DD
from dim_date
)
delete from cte where dd>1

with cte as (
select *, ROW_NUMBER() over(
PARTITION BY restaurant_name
ORDER BY (SELECT NULL)
) AS DD
from dim_restaurant
)
delete from cte where dd>1


alter table dim_date 
add year_num int,
month_num int,
month_name varchar(20),
quarter_num int

update dim_date
set 
year_num =	YEAR(order_date),
month_num = MONTH(order_date),
month_name = DATENAME(month, order_date),
quarter_num = DATEPART(quarter,order_date)

select top 10 *
from dim_date

---KPI'S
--Total Orders
select 
COUNT(*) as Total_order from
fact_orders

--Total_Revenue
select 
concat(round(SUM(price)/1000000,2),'M') as Total_Revenue from fact_orders

--Average Dish Price
select
concat(round(AVG(price),2), ' INR') as  Average_Dish_Price
from fact_orders

--Average Rating
select
round(AVG(rating),1) as Average_Rating from fact_orders

---Deep Dive Business Analysis

-- Monthly Order Trend
select 
d.year_num,
d.month_name,
d.month_num,
count(f.order_id) as Total_Orders
from fact_orders f
join dim_date d
on d.date_id=f.date_id
group by 
d.year_num,
d.month_name,
d.month_num
order by 
d.month_num

--Qurterly Trend
select 
d.year_num,
d.quarter_num,
count(f.order_id) as Total_Orders
from fact_orders f
join dim_date d
on d.date_id=f.date_id
group by 
d.year_num,
d.quarter_num
order by 
d.quarter_num

--Orders By Day Of Week (Mon-Sun)
select
 DATENAME(WEEKDAY,d.order_date) as day_name,
 count(f.order_id) as Total_Orders
 from fact_orders f
 left join dim_date d
 on d.date_id=f.date_id
 group by datename(WEEKDAY ,d.order_date), DATEPART(WEEKDAY,d.order_date)
 order by datepart(weekday,d.order_date);

 -- Top 10 cities by Order Volume
 select top 10
l.city,
COUNT(f.order_id) as Total_Orders
from fact_orders f
join dim_location l
on l.location_id=f.location_id
group by l.city
order by Total_Orders desc


-- Revenue Contribution By States
select
l.state,
concat(round(SUM(f.price)/10000,2),'K') as Total_Revenue
from fact_orders f
join dim_location l
on l.location_id=f.location_id
group by l.state
order  by Total_Revenue 

--Top 10 Restaurant By Orders
select top 10
r.restaurant_name,
COUNT(f.order_id) as Total_Orders
from fact_orders f
join dim_restaurant r
on r.restaurant_id=f.restaurant_id
group by r.restaurant_name
order by Total_Orders desc


-- Top Categories By Order Volume
select top 10
ds.category,
COUNT(f.order_id) as Total_Orders
from fact_orders f
join dim_dish ds
on ds.dish_id=f.food_id
group by ds.category
order by Total_Orders desc

-- Most Ordered Dish
select top 10
ds.dish_name,
COUNT(f.order_id)as Total_Orders
from fact_orders f
join dim_dish ds
on ds.dish_id=f.food_id
group by dish_name
order by Total_Orders desc


-- Cuisine Performance (Orders + Avg Rating
select
ds.category,
COUNT(f.order_id)as Total_Orders,
round(AVG(f.rating),1) as Average_Rating
from fact_orders f
join dim_dish ds
on ds.dish_id=f.food_id
group by ds.category
order by Total_Orders desc

-- Total Orders By Price Range
select
	case 
		when CONVERT(float,price) < 100 then 'Under 100'
		when CONVERT(float, price) between 100 and 199 then '100-199'
		when CONVERT (float,price) between 200 and 299 then '200-299'
		when CONVERT (float,price) between 300 and 399 then '300-499'
		else '500+'
     end as price_range,
     count(order_id)as Total_Orders
from fact_orders
group by 
    case 
		when CONVERT(float,price)<100 then 'Under 100'
		when CONVERT(float, price) between 100 and 199 then '100-199'
		when CONVERT (float,price) between 200 and 299 then '200-299'
		when CONVERT (float,price) between 300 and 399 then '300-499'
		else '500+'
	end
order by Total_Orders desc;


--Rating Count Distribution (1-5)
select
 round(rating,2)as rating,
 COUNT(rating_count) as Rating_Count 
 from fact_orders
 group by rating
 order by Rating_Count desc