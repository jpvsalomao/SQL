## DUPLICATE VALUES

select * from duplicate_transactions;

## Solution 2

## 1. How many duplicate records are there? 
-- To get the number of duplicate records, we can select id, timestamp, price, department, count(*), and group by all the fields
-- From that number we need to subtract 1, so that it does not count unique records as duplicates
-- Lastly we sum the column num_duplicates and get the total number of dups.

with dup_table as (
select transaction_id, timestamp, price, department, count(*)-1 as n_dups
from duplicate_transactions
group by 1,2,3,4
)
select sum(n_dups) 
from dup_table 
where n_dups > 0;

## 2. How many unique records have duplications?
-- To get the number of unique records with duplications, we can edit the last query and use count, instead of sum.

with dup_table as (
select transaction_id, timestamp, price, department, count(*)-1 as n_dups
from duplicate_transactions
group by 1,2,3,4
)
select count(n_dups) 
from dup_table 
where n_dups > 0;

## 3. Remove duplicate records, only preserving the unique records.
-- To remove duplicate we can apply DISTINCT directly
select distinct * from duplicate_transactions;

## 4. Which department has the highest duplicate records? 
## Return the department name and count of duplicate records. 
## Assume the possibility that multiple departments could have the same highest count.
-- 1st. Create a table counting the number of duplicate transactions
-- 2nd. Use the first table to compute the total number of duplicates per department 
-- 3rd. Use the second table to dense_rank the departments ordered by the total number of duplicates desc
-- 4th. use the third table and return the department and total number of duplicates where the rank = 1.

with dup_table as (
select transaction_id, timestamp, price, department, count(*)-1 as n_dups
from duplicate_transactions
group by 1,2,3,4
),
dept_dup_table as (
select 
	department, 
    sum(n_dups) total_dups
from dup_table
group by 1
),
dept_rank_table as (
select
	department, total_dups,
    dense_rank() over(order by total_dups desc) dup_rank
from dept_dup_table
)
select department, total_dups from dept_rank_table where dup_rank = 1;





## Solution 1

## 1. How many duplicate records are there? 
-- For instance, if Row 1, and Row 2 and Row 3 contain the same values, then there are two duplicate records.

SELECT sum(n_duplicated)
from
(SELECT transaction_id, timestamp, price, department, count(*)-1 as n_duplicated
from duplicate_transactions
group by 1,2,3,4
order by 5 desc) t;

-- To get the number of duplicate records we can select all the columns plus a 'count(*)-1'. 
-- That way, if a record has 1 duplicate, the count will innitially be 2, the -1 will return to the correct value of duplicates
-- To get the total number of duplicates, we just sum the entire 'n_duplicated' column.

## 2. How many unique records have duplications?

SELECT count(*)
from
(SELECT transaction_id, timestamp, price, department, count(*)-1 as n_duplicated
from duplicate_transactions
group by 1,2,3,4
order by 5 desc) t
where n_duplicated > 0;

-- We can use 'where n_duplicated > 0' to filter our dataset to include just records with duplication, and count the remaining values.

## 3. Remove duplicate records, only preserving the unique records.

SELECT DISTINCT * FROM duplicate_transactions;

-- Directly apply 'DISTINCT *' to remove duplicate records.

## 4. Which department has the highest duplicate records? 
## Return the department name and count of duplicate records. 
## Assume the possibility that multiple departments could have the same highest count.

select *
from
(select 
	distinct t2.*,
    dense_rank() over(order by sum_dup desc) dup_rank
from
(select
	department,
    sum(n_duplicated) over(partition by department) sum_dup
from
(SELECT transaction_id, timestamp, price, department, count(*)-1 as n_duplicated
from duplicate_transactions
group by 1,2,3,4
order by 5 desc) t) t2) t3
where dup_rank = 1;

-- 1st - Create a table counting the number of duplicated records per record
-- 2nd - From that table, query distinct rows, and use the window function SUM, to sum the number of duplicates per department 
-- 3rd - From the 2 nested tables, use dense_rank to rank the departments according to the number of duplicates
-- 4th - From the 3 nested tables, query the required fields, including a WHERE clause where rank = 1.