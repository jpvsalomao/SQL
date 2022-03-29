
select * from revenue_analytics;

-- Problem:
-- Given the company revenue data below, address two questions:

-- #1​. For each year, return the names of companies with the top 10th percentile revenue. Also return years and revenues.

with rank_table as (
select
	*,
    row_number() over(partition by year order by revenue desc) as position_rank,
    percent_rank() over(partition by year order by revenue desc) as per_rank
from revenue_analytics
)
select * from rank_table
where per_rank <= 0.10;


-- #2 Return the names of companies that grew their YoY revenue by at least 5%, consecutively every year.

with lag_table as (
	-- Include the value of previous year in the table to make possible the yoy calculation
select 
	*,
    lag(revenue, 1) over(partition by company order by year) as 'last_year'
from revenue_analytics
),
yoy_table as (
	-- Calculate YoY growth for each company by dividing the revenue of current year by last year. 
select 
	*,
    revenue/last_year as yoy_rev
from lag_table
),
cons_growth as (
	-- Get the number of consecutive grows of 5% per company, and the number o years per company
select
	company,
    sum(if(yoy_rev > 1.05,1,0)) as cons_grow,
    count(*) as num_years
from yoy_table
group by 1
)
-- Return the list of companies that grew 5% for all possible years.
select * from cons_growth where cons_grow = num_years -1;



-- Alternative Solution
-- Given the company revenue data below, address two questions:

-- #1​. For each year, return the names of companies with the top 10th percentile revenue. Also return years and revenues.

select
	company,
    year,
    revenue,
    per_rank,
    rev_rank,
    num_companies,
    rev_rank/num_companies as percent_2
from
(select 
	*, 
    row_number() over(partition by year order by revenue desc) as 'rev_rank',
    percent_rank() over(partition by year order by revenue desc)*100 as 'per_rank',
    count(*) over(partition by year) as 'num_companies'
from revenue_analytics) t
where per_rank <= 10;


-- #2 Return the names of companies that grew their YoY revenue by at least 5%, consecutively every year.
select company, year, sum(revenue) from revenue_analytics group by company, year;

select * 
from revenue_analytics t1
join revenue_analytics t2 on t1.company = t2.company and t1.year = t2.year-1
join revenue_analytics t3 on t3.company = t2.company and t3.year = t2.year+1
where t3.revenue > t2.revenue*1.05 and t2.revenue > t1.revenue*1.05;



WITH yoy_growth AS (
	-- Calculate YoY growth for each company by dividing the revenue of
	-- current year by last year. 
	SELECT company, year,
		   revenue * 1.0 / revenue_last_year yoy
	FROM (
		-- Shift the last year's revenue to the current year snapshot
		SELECT company, revenue, year,
			   LAG(revenue, 1) OVER(PARTITION BY company ORDER BY year) AS revenue_last_year
		FROM revenue_analytics
	) t
), 
growth_companies AS (
	-- For each company, count the number of consecutive years that achieved 5% growths and
	-- the number of years that the company existed. If the number_of_years - 1 == consecutive
	-- growths, then the company matches the criteria
	SELECT company,
		   SUM(CASE WHEN yoy >= 1.05 THEN 1 ELSE 0 END) AS consecutive_growths,
		   COUNT(*) AS number_of_years
	FROM yoy_growth
	GROUP BY 1
)
-- Return the list of companies that always achieved 5% growths in revenue.
SELECT company
FROM growth_companies
WHERE consecutive_growths = number_of_years - 1;


