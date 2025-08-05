-- Count total number of unique customers
Select distinct count(*) from customers;

-- Count number of customers who made only one transaction
Select count(*) from (
    select cust_id, count(transaction_id) 
    from transactions
    group by 1 
    having count(transaction_id) = 1
) sub;

-- Calculate repeat customer percentage
With r_customers as ( 
    select cust_id, count(transaction_id) as r_transactions
    from transactions
    group by cust_id 
    having count(transaction_id) > 1
),
t_customers as ( 
    select cust_id, count(transaction_id) as t_transactions
    from transactions 
    group by cust_id
)
select 
    count(r.cust_id) * 100.0 / count(t.cust_id) as repeat_customer_percentage
from 
    t_customers t
left join 
    r_customers r on t.cust_id = r.cust_id;

-- Count total return transactions
Select count(*) from transactions
where transaction_type = 'Return';

-- Calculate return rate as a percentage of all transactions
Select 
    count(*) * 100.0 / (select count(*) from transactions) as return_rate_percentage
from transactions
where transaction_type = 'Return';

-- Calculate return percentage by gender
Select 
    count(*) * 100.0 / (select count(*) from transactions) as purchase_bygender
from 
    transactions as t
join 
    customers as c on t.cust_id = c.cust_id
where 
    c.gender = 'F'
    and t.transaction_type = 'Return';

-- Count returns by product category
Select p.prod_cat, count(*) as ret
from transactions as t 
join product_category as p 
on t.prod_cat_code = p.prod_cat_code
group by 1
order by 2 desc;

-- Analyze repeat purchase behavior by gender and age group
With customer_order_counts as (
    select 
        cust_id,
        count(distinct tran_date) as purchase_days
    from transactions
    where transaction_type = 'Sale'
    group by cust_id
),
repeat_flags as (
    select 
        cust_id,
        case 
            when purchase_days > 1 then 'Repeat'
            else 'One-Time'
        end as purchase_type
    from customer_order_counts
),
customer_segments as (
    select 
        c.cust_id,
        c.gender,
        timestampdiff(year, c.dob, curdate()) as age,
        case 
            when timestampdiff(year, c.dob, curdate()) <= 25 then 'Under 25'
            when timestampdiff(year, c.dob, curdate()) between 26 and 40 then '26-40'
            when timestampdiff(year, c.dob, curdate()) between 41 and 60 then '41-60'
            else '60+'
        end as age_group,
        rf.purchase_type
    from customers c
    join repeat_flags rf on c.cust_id = rf.cust_id
)
select 
    gender,
    age_group,
    count(case when purchase_type = 'Repeat' then 1 end) * 100.0 / count(*) as repeat_rate_percentage,
    count(*) as total_customers
from customer_segments
group by gender, age_group
order by repeat_rate_percentage asc;

-- Total revenue by store type
Select store_type, sum(total_amt)
from transactions
group by 1;

-- Total revenue by gender
Select c.gender, sum(t.total_amt)
from transactions as t 
join customers as c on c.cust_id = t.cust_id
group by 1
order by sum(total_amt) desc;

-- Revenue by customer age group
With cte as ( 
    select c.cust_id, timestampdiff(year, dob, curdate()) as age, sum(total_amt) as revenue
    from customers as c 
    join transactions as t on c.cust_id = t.cust_id
    group by 1,2
    order by 3 desc 
) 
select case 
            when age <= 25 then 'Under 25'
            when age between 26 and 40 then '26-40'
            when age between 41 and 60 then '41-60'
            else '60+'
        end as age_group, revenue
from cte;

-- Return rate percentage by store type
Select 
    store_type,
    count(case when transaction_type = 'Return' then 1 end) as returned_orders,
    count(*) as total_transactions,
    round(
        100.0 * count(case when transaction_type = 'Return' then 1 end) / count(*),
        2
    ) as return_rate_percentage
from 
    transactions
group by 
    store_type;

-- Find subcategory with highest number of returns
Select 
    pc.prod_subcat as subcategory_name,
    count(*) as total_returns
from 
    transactions t
join 
    product_category pc on t.prod_subcat_code = pc.prod_sub_cat_code
where 
    t.transaction_type = 'Return'
group by 
    pc.prod_subcat
order by 
    total_returns desc
limit 1;

-- Revenue by product subcategory
Select 
    pc.prod_subcat as subcategory,
    round(sum(t.total_amt), 2) as revenue
from 
    transactions t
join 
    product_category pc on t.prod_subcat_code = pc.prod_sub_cat_code
where 
    t.transaction_type = 'Sale'
group by 
    pc.prod_subcat
order by 
    revenue desc;

-- Top 5 cities by total sales revenue
Select 
    c.city_code,
    round(sum(t.total_amt), 2) as total_revenue
from 
    transactions t
join 
    customers c on t.cust_id = c.cust_id
where 
    t.transaction_type = 'Sale'
group by 
    c.city_code
order by 
    total_revenue desc
limit 5;

-- Top 10 customers by total purchase revenue
Select 
    t.cust_id,
    round(sum(t.total_amt), 2) as total_revenue
from 
    transactions t
where 
    t.transaction_type = 'Sale'
group by 
    t.cust_id
order by 
    total_revenue desc
limit 10;

-- Calculate average order value (AOV)
Select 
    round(sum(total_amt) / count(distinct transaction_id), 2) as avg_order_value
from 
    transactions
where 
    transaction_type = 'Sale';

-- Monthly revenue trend over time
Select 
    year(tran_date) as year,
    month(tran_date) as month,
    round(sum(total_amt), 2) as monthly_revenue
from 
    transactions
where 
    transaction_type = 'Sale'
group by 
    year(tran_date), month(tran_date)
order by 
    year, month;
