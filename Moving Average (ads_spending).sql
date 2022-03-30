#### GOOGLE ADS SPENDING ####
SELECT * FROM ADS_SPENDING;

-- Problem:
-- A social network platform allows businesses to publish advertisements. The platform tracks 
-- daily advertisment spendings across business accounts. Currently, the platform
-- doesn’t have a backend system to alert unsual spendings. Address the SQL questions below:

-- Address these two questions:

## 1​.​ Compute the 30-day moving average of advertisement spending per business.

-- Use self-join filtering by the row related to the moving average

select 
	*,
	(select
		avg(t2.spending)
	from ads_spending t2
    where datediff(t1.date, t2.date) <= 30
    and datediff(t1.date, t2.date) >= 0
    and t1.business = t2.business) mov_avg
from ads_spending t1;


## 2​.​ Compute the 30-day moving standard deviation of advertisement spending per business.

select 
	*,
	(select
		std(t2.spending)
	from ads_spending t2
    where datediff(t1.date, t2.date) <= 30
    and datediff(t1.date, t2.date) >= 0
    and t1.business = t2.business) mov_std
from (
		select 
			*,
            (select avg(t3.spending) from ads_spending t3
				where datediff(t2.date, t3.date) <= 30
				and datediff(t2.date, t3.date) >= 0
				and t2.business = t3.business) mov_avg
		from ads_spending t2) t1;
				
# 3 - The platform wants to track anomalous spendings. Create a new column called “outlier” 
-- which flags any spending that is above or below the two standard deviation from the mean. 
-- Use the moving average and standard deviation computed in previous steps.


select
	*,
    case when spending > mov_avg + (2*mov_std) or spending  < mov_avg - (2*mov_std) then 'outlier' else 'normal' end as 'outlier'
from
(select 
	*,
	(select
		std(t2.spending)
	from ads_spending t2
    where datediff(t1.date, t2.date) <= 30
    and datediff(t1.date, t2.date) >= 0
    and t1.business = t2.business) mov_std
from (
		select 
			*,
            (select avg(t3.spending) from ads_spending t3
				where datediff(t2.date, t3.date) <= 30
				and datediff(t2.date, t3.date) >= 0
				and t2.business = t3.business) mov_avg
		from ads_spending t2) t1) t4;


## Alternative Solution

-- Problem:
-- A social network platform allows businesses to publish advertisements. The platform tracks 
-- daily advertisment spendings across business accounts. Currently, the platform
-- doesn’t have a backend system to alert unsual spendings. Address the SQL questions below:

-- Address these two questions:

## 1​.​ Compute the 30-day moving average of advertisement spending per business.


select *,
	(select 
		avg(t2.spending)
        from ads_spending t2
        where datediff(t1.date, t2.date) <= 30
        and datediff(t1.date, t2.date) >= 0
        and t1.business = t2.business) as mov_avg
from ads_spending t1;


select *,
	(select avg(t2.spending)
     from ads_spending t2
     where datediff(t1.date, t2.date) <= 30 
     and t1.business = t2.business 
     and datediff(t1.date, t2.date) >= 0) as mov_avg
from ads_spending t1;     

## 2​.​ Compute the 30-day moving standard deviation of advertisement spending per business.

select *,
	(select std(t3.spending)
    from ads_spending t3
    where t3.business = t1.business 
    and datediff(t3.date, t1.date) <= 30
    and datediff(t3.date, t1.date) >= 0) as mov_std
from 
(select *,
	(select avg(t2.spending)
     from ads_spending t2
     where datediff(t1.date, t2.date) <= 30 
     and t1.business = t2.business 
     and datediff(t1.date, t2.date) >= 0) as mov_avg
from ads_spending t1) t1;
    
    
# 3 - The platform wants to track anomalous spendings. Create a new column called “outlier” 
-- which flags any spending that is above or below the two standard deviation from the mean. 
-- Use the moving average and standard deviation computed in previous steps.

select 
	*,
    case
    when t4.spending > mov_avg + (2*mov_std) then 'outlier'
    when t4.spending < mov_avg - (2*mov_std) then 'outlier'
    else 'no outlier'
    end
from
(select *,
	(select std(t3.spending)
    from ads_spending t3
    where t3.business = t1.business 
    and (t3.date - t1.date) <= 30
    and (t3.date - t1.date) >= 0) as mov_std
from 
(select *,
	(select avg(t2.spending)
     from ads_spending t2
     where (t1.date - t2.date) <= 30 
     and t1.business = t2.business 
     and (t1.date - t2.date) >= 0) as mov_avg
from ads_spending t1) t1) t4;


SELECT *,
       -- Append a new column called ‘outlier’ that flags outlier spendings
	   (CASE WHEN spending > moving_avg + 2 * moving_std THEN 1
	   		 WHEN spending < moving_avg - 2 * moving_std THEN 1
	   		 else 0
	   	END) AS outlier
FROM (	   		 
	SELECT *,
           -- Compute the moving std of spending
		   (SELECT POWER(AVG(POWER(s3.spending - t1.moving_avg, 2)), 0.5) FROM ads_spending s3
		   	WHERE (t1.date - s3.date) <= 30 AND
		   		  (t1.date - s3.date) >= 0 AND
		   		   t1.business = s3.business) AS moving_std
	FROM (	   		   
		SELECT *,
         	   -- Compute the moving average of spending
			   (SELECT AVG(s2.spending) FROM ads_spending s2 
			   	WHERE (s1.date - s2.date) <= 30 AND
					  (s1.date - s2.date) >= 0 AND
			   		   s1.business = s2.business) AS moving_avg
		FROM ads_spending s1
	) t1
) t2;