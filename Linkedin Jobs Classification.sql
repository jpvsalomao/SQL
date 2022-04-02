-- Problem:

select * from linkedin_job_postings;

-- On LinkedIn, companies companies can advertise job openings. The data team wants to categorize job posts 
-- as either ​active, expired, ​or​ repeats​.

-- > A post is active if it was published the past 30 days before 09/11/19 (current date). 
-- > A post is expired if it was published 30 days before 09/11/19.
-- > A post is a repeat if it was expired then active again.

-- Aaddress the following question: 

-- #1. Count the number of active and expired posts. Do not count repeats in the active-only or expired buckets.
-- Create a temp table with expired and active posts

with clas_table as (
select distinct
	*,
    case when datediff('2019-09-11',timestamp) > 30 then 1 else 0 end as expired,
    case when datediff('2019-09-11',timestamp) <= 30 then 1 else 0 end as act,
    datediff('2019-09-11', timestamp) dif
from linkedin_job_postings
),
repeat_table as (
select 
	post_id, advertiser_id,
    sum(expired) exp_tot, sum(act) act_tot
from clas_table
group by 1,2
)
select 
	*,
    case
    when exp_tot > 0 and act_tot = 0 then 'expired'
    when exp_tot = 0 and act_tot > 0 then 'active'
    else 'repeat' end as stats
from repeat_table;



## Alternative SOlution
-- #1. Count the number of active and expired posts. Do not count repeats in the active-only or expired buckets.

-- Create a temp table with expired and active posts



with tt as
(select
	*,
    case
    when datediff('2019-09-11', timestamp) > 30 then 1 else 0
    end as t_expired,
    case
    when datediff('2019-09-11', timestamp) <= 30 then 1 else 0
    end as t_active
from linkedin_job_postings),
-- Classify posts as active, expired or repeat following the logic:
-- if post is just active, active. If the post is just expired, expired. If the post is active and expired, repeat
post_status as
(select
	post_id, advertiser_id,
    case
    when tot_exp = 0 and tot_act = 1 then 'active'
    when tot_exp > 0 and tot_act = 0 then 'expired'
    else 'Repeat' end as clas
from 
		-- For each post, count the number of snapshots that were active
		-- and expired. This will determine whether the post is active-only,
		-- expired or repeat.
(select 
	post_id, advertiser_id,
	sum(t_expired) tot_exp, sum(t_active) tot_act
from tt
group by post_id, advertiser_id) t)
select * from post_status;
select clas, count(*) from post_status group by 1;



WITH post_snapshot AS (
-- For each post snapshot, tag whether the snapshot is active or expired
-- This label is required to remove repeats.
SELECT post_id, advertiser_id, timestamp,
	   CASE WHEN ('2019-09-11' - timestamp) <= 30 THEN 1
	        ELSE 0
	   END AS snapshot_active,
	   CASE WHEN ('2019-09-11' - timestamp) > 30 THEN 1
	        ELSE 0
	   END AS snapshot_expired
FROM linkedin_job_postings
),
	post_status AS (
	-- Tag a post as active, expired, repeat given the logic: If the post
	-- contains 1 snapshot that's active and no snapshot expired, then it's
	-- active-only. If it contains no active and multiple expired snapshots,
	-- then it's expired. All other post instances are repeats. 
	SELECT post_id, advertiser_id,
		   CASE WHEN current_active = 1 AND number_of_expired = 0 THEN 'Active'
		        WHEN current_active = 0 AND number_of_expired > 0 THEN 'Expired'
		        ELSE 'Repeat'
		    END AS status
	FROM (
		-- For each post, count the number of snapshots that were active
		-- and expired. This will determine whether the post is active-only,
		-- expired or repeat.
		SELECT post_id, advertiser_id,
			   SUM(snapshot_active) AS current_active,
			   SUM(snapshot_expired) AS number_of_expired
		FROM post_snapshot
		GROUP BY 1, 2
	) t
)
-- Using post_status, count the number of instances.
select * from post_status;


