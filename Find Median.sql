
select t1.*, " ", t2.* from med_users t1, med_transactions t2;


-- Problem:
-- There are two tables users and transactions. The median_users table contains the user_id 
-- and user_creation_date. The median_transactions table contains the user_id, transaction_date,
-- and transaction_amount. A user can purchase as a visitor even before creating an account, 
-- and they user_id remains the same. 

-- #1. Among transactions that occurred on or after the date of sign-up, find the median and average
-- per user.

-- SOLUTION 
-- Create a temp table filtered by the dates after the account creation

with tt as (
select
	t1.user_id, t2.account_created_date, t1.transaction_date, t1.transaction_amount,
    row_number() over(partition by t1.user_id order by t1.transaction_amount) n_row_asc,
    row_number() over(partition by t1.user_id order by t1.transaction_amount desc) n_row_desc
from med_transactions t1
left join med_users t2 on t2.user_id = t1.user_id
where transaction_date >= account_created_date
)
select 
	user_id,
    avg(transaction_amount) average_user,
    avg(case
			when n_row_asc between n_row_desc -1 and n_row_desc + 1 
            then transaction_amount 
            else null end) median
from tt
group by 1;


-- Alternative Solution
-- Problem:
-- There are two tables users and transactions. The median_users table contains the user_id 
-- and user_creation_date. The median_transactions table contains the user_id, transaction_date,
-- and transaction_amount. A user can purchase as a visitor even before creating an account, 
-- and they user_id remains the same. 

-- #1. Among transactions that occurred on or after the date of sign-up, find the median and average
-- per user.

-- Create table with user ID, transaction_date, transaction_amount, account_created_date, and filtering by dates after creating account
-- From this table get the median and average per user, grouping by user

with transactions as (
	-- Join users and transactions table and filter on transactions that came
	-- after the sign-up
	select 
		t1.user_id, 
		t1.transaction_date, 
		t1.transaction_amount, 
		t2.account_created_date
	from med_transactions t1
	join med_users t2
	on t1.user_id = t2.user_id
	where t2.account_created_date <= t1.transaction_date
),
r_number as (
	-- Create row_numbers in ascending and descending orders which will be useful for 
	-- calculating the median. 
    select 
		user_id,
		transaction_amount,
		row_number() over(partition by user_id order by transaction_amount asc) as ascending,
		row_number() over(partition by user_id order by transaction_amount desc) as descending
	from transactions
)
-- Calculating the average is straightforward as you can use the AVG() function. The median,
-- however, can be somewhat tricky. The descending column serves as a reference point for the 
-- ascending column. When values in the ascending column are within the bounds of descending - 1
-- and ascending + 1, preserve the values. Otherwise null. Averaging this column returns the median.
select 
	user_id,
    avg(transaction_amount) as average,
    avg(case
			when ascending between descending - 1 and descending + 1
            then transaction_amount else null
            end) as median
from r_number
group by user_id;



