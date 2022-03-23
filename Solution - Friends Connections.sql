### FRIENDS_CONNECTIONS ###

SELECT * FROM friends_connections;

-- Facebook’s analytics team wants to understand how users stay connected among friends on their platform. 
-- The team believes that understanding patterns could help improve an algorithm that matches potential friends. 

#1. ​Return a list of users who blocked another user after connecting for at least 90 days. Show the user_id and receiver_id.
-- Create two temp tables, one for connected and other for blocked
-- Join the tables on user_id, receiver_id, where d2 - d1 >= 90

with connected as (
select * from friends_connections where action = 'Connected'
),
blocked as (
select * from friends_connections where action = 'Blocked'
)
select t1.user_id
from connected t1
join blocked t2 on t1.user_id = t2.user_id and t1.receiver_id = t2.receiver_id
where datediff(t2.dates, t1.dates) >= 90;


#2. ​For each user, what is the proportion of each action? 
#   Note that the receiver_id can appear in multiple actions per user, only regard the latest status when calculating the distribution. 

-- Create columns 'Connected', 'Sent' and 'Blocked' columns,
-- Create a column counting the interaction among users (consider just the last),
-- Query from that first table calculating the proportion of each activity, and filtering to get only the last action. (iteraction_num = 1)

with activity_table as (
select
	*,
    case when action = 'Sent' then 1 else 0 end as sent,
    case when action = 'Connected' then 1 else 0 end as connected,
    case when action = 'Blocked' then 1 else 0 end as blocked,
    row_number() over(partition by user_id, receiver_id order by dates desc) iteraction_num
from friends_connections
)
select 
	user_id, 
	sum(sent)/(sum(sent)+sum(connected)+sum(blocked)) prop_sent,
    sum(connected)/(sum(sent)+sum(connected)+sum(blocked)) prop_connected,
    sum(blocked)/(sum(sent)+sum(connected)+sum(blocked)) prop_block
from activity_table 
where iteraction_num = 1
group by user_id;





## Allternative Solution
-- Facebook’s analytics team wants to understand how users stay connected among friends on their platform. 
-- The team believes that understanding patterns could help improve an algorithm that matches potential friends. 

#1. ​Return a list of users who blocked another user after connecting for at least 90 days. Show the user_id and receiver_id.

-- Self join table, joining conection and block tables on the condition that datediff(block, connect) >= 90

select t1.user_id, t2.receiver_id, datediff(t2.dates, t1.dates)
from friends_connections t1
inner join friends_connections t2 on t2.user_id = t1.user_id and t2.receiver_id = t1.receiver_id
where t1.action = 'sent' and t2.action = 'blocked' and datediff(t2.dates, t1.dates) >= 90;


#2. ​For each user, what is the proportion of each action? 
#   Note that the receiver_id can appear in multiple actions per user, only regard the latest status when calculating the distribution. 

-- group by user_id and action, counting the number of each action

select user_id, action, n_action, tot_action, n_action/tot_action prop
from
(select user_id, action, count(action) n_action, sum(count(action)) over(partition by user_id) tot_action
from friends_connections
group by 1,2) t;

-- To consider only the latest status we can create a temporary table using row_number, and filter by the row

with friendship_status as ( select *, row_number() over(partition by user_id, receiver_id order by dates desc) as event_order
							from friends_connections)

select user_id, action, n_action, tot_action, n_action/tot_action prop
from
(select user_id, action, count(action) n_action, sum(count(action)) over(partition by user_id) tot_action
from friendship_status
where event_order = 1
group by 1,2) t;

-- To create the table pivotes, we can create a sequence of temporary tables:
-- 1. Table using row_number() to order the events
-- 2. Table using filtering by row_number() in the first table to select only the latest event
-- 3. Pivoted table that will create columns using CASE WHEN THEN logic to count the number of 'sent', 'connected' and 'blocked'.
-- 4. Distribution table that will divide the sum of each event, divide by the total events, and group by the user
 
WITH friendship_status AS (
	SELECT *,  
		   ROW_NUMBER() OVER(PARTITION BY user_id, receiver_id ORDER BY dates DESC) AS event_order
	FROM friends_connections 
),  
-- Filter on the latest event per user_id and receiver_id pair
latest_friendship_status AS (
	SELECT *
	FROM friendship_status
	WHERE event_order = 1
),
-- Create a dummy variable column per action type
status_dummy_variables AS (
	SELECT *,
		   CASE WHEN action = 'Sent' THEN 1 ELSE 0 END AS sent,
		   CASE WHEN action = 'Received' THEN 1 ELSE 0 END AS received,
		   CASE WHEN action = 'Connected' THEN 1 ELSE 0 END AS connected,
		   CASE WHEN action = 'Blocked' THEN 1 ELSE 0 END AS blocked
	FROM latest_friendship_status
),
-- For each action column, divide by event order to get proportion of action types per user.
distribution AS (
	SELECT user_id,
		 	SUM(sent) / SUM(event_order) AS sent,
		 	SUM(received) / SUM(event_order) AS received,
		 	SUM(connected) / SUM(event_order) AS connected,
		 	SUM(blocked) / SUM(event_order) AS blocked
	FROM status_dummy_variables
	GROUP BY user_id
)
SELECT * FROM distribution;













