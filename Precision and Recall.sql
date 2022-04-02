select * from precision_recall;

-- The precision_recall table contains transaction_id, probability, labels and department.
-- The probability column contains the probabilty score from a classification model, which 
-- is in the range of [0.0, 1.0]. The labels contains an integer value of 0, indicating no fraud,
-- and 1, indicating fraud. Assume no duplication or missingness in the table. 

# SOLUTION 
## 1. Given that a transaction with probability greater than 0.70 is predicted as fraud, calculate the precision and recall.
-- Precision: TruePositives/(TruePositives+FalsePositives)
-- Recall: TruePositives/(TruePositives + False Negatives)

-- 1. Create a table with the classification Fraud/no fraud
-- 2. Create a second table with the number of true predictions

with clas_table as (
select
	*,
    case when probability > 0.7 then 1 else 0 end as 'fraud'
from precision_recall
),
true_table as (
select
	*,
    case when fraud = 1 and labels = 1 then 1 else 0 end as 'true_positive',
    case when fraud = 1 and labels = 0 then 1 else 0 end as 'false_positive',
    case when fraud = 0 and labels = 0 then 1 else 0 end as 'true_negative',
    case when fraud = 0 and labels = 1 then 1 else 0 end as 'false_negative'
from clas_table
)
select 
	sum(true_positive)/(sum(true_positive)+sum(false_positive)) as 'precision',
    sum(true_positive)/(sum(true_positive)+sum(false_negative)) as 'recall'
from true_table;

-- #2. Given that a transaction with probability greater than 0.70 is predicted as fraud, 
-- 	calculate the precision and recall per department. Then, sort it by precision in a
-- 	descending order.

with clas_table as (
select
	*,
    case when probability > 0.7 then 1 else 0 end as 'fraud'
from precision_recall
),
true_table as (
select
	*,
    case when fraud = 1 and labels = 1 then 1 else 0 end as 'true_positive',
    case when fraud = 1 and labels = 0 then 1 else 0 end as 'false_positive',
    case when fraud = 0 and labels = 0 then 1 else 0 end as 'true_negative',
    case when fraud = 0 and labels = 1 then 1 else 0 end as 'false_negative'
from clas_table
)
select 
	department,
	sum(true_positive)/(sum(true_positive)+sum(false_positive)) as 'precision',
    sum(true_positive)/(sum(true_positive)+sum(false_negative)) as 'recall'
from true_table
group by 1
order by 2 desc;


## Alternative Solution

## 1. Given that a transaction with probability greater than 0.70 is predicted as fraud, calculate the precision and recall.
-- Precision: TruePositives/(TruePositives+FalsePositives)
-- Recall: TruePositives/(TruePositives + False Negatives)

-- Create a column for true positives, false positives and false negatives
-- select * from precision_recall;

-- H0 = not fraud 
-- H1 = fraud

select
	sum(TruePositive)/(sum(TruePositive)+sum(FalsePositive)) as 'Precision',
    sum(TruePositive)/(sum(TruePositive)+sum(FalseNegative)) as 'Recall'
from
(select
	*,
    case when probability > 0.7 and labels = 1 then 1 else 0 end as 'TruePositive',
    case when probability > 0.7 and labels = 0 then 1 else 0 end as 'FalsePositive',
    case when probability < 0.7 and labels = 1 then 1 else 0 end as 'FalseNegative',
    case when probability < 0.7 and labels = 0 then 1 else 0 end as 'TrueNegative'
from precision_recall) t;


-- #2. Given that a transaction with probability greater than 0.70 is predicted as fraud, 
-- 	calculate the precision and recall per department. Then, sort it by precision in a
-- 	descending order.

select
	department,
	sum(TruePositive)/(sum(TruePositive)+sum(FalsePositive)) as 'Precision',
    sum(TruePositive)/(sum(TruePositive)+sum(FalseNegative)) as 'Recall'
from
(select
	*,
    case when probability > 0.7 and labels = 1 then 1 else 0 end as 'TruePositive',
    case when probability > 0.7 and labels = 0 then 1 else 0 end as 'FalsePositive',
    case when probability < 0.7 and labels = 1 then 1 else 0 end as 'FalseNegative',
    case when probability < 0.7 and labels = 0 then 1 else 0 end as 'TrueNegative'
from precision_recall) t
group by 1 order by 2 desc;




-- Solution #2
WITH Prediction AS (
	-- Using the CASE clause, create an indicator where probability score 
	-- is greater than 0.70 is marked fraud. Else, no fraud. 
	SELECT
		department,
		CASE WHEN probability > 0.7 THEN 1 ELSE 0 END AS prediction,
		labels
	FROM precision_recall
),
CorrectPrediction AS (
	-- Mark cases where the prediction and labels are the same.
	SELECT
		department,
		prediction,
		labels,
		CASE WHEN prediction = 1 AND labels = 1 THEN 1 ELSE 0 END AS correct_prediction
	FROM Prediction
),
CalcPrecisionRecall AS (
	-- Calculate the precision and recall per department.
	SELECT
		department,
		SUM(correct_prediction) * 1.0 / SUM(prediction) AS 'precision',
		SUM(correct_prediction) * 1.0 / SUM(labels) AS recall
	FROM CorrectPrediction
	GROUP BY department
)
-- Return the final result in the descending order of precision.
SELECT * FROM CalcPrecisionRecall
ORDER BY 2 DESC;