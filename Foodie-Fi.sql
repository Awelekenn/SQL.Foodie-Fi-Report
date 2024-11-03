select *
FROM subscriptions;

SELECT *
FROM plans;

  -- QUESTIONS
-- Query to join subscriptions with plan names for easier description of customer journeys
SELECT * FROM plans;
SELECT * FROM subscriptions;
-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM subscriptions;

/* 2. What is the monthly distribution of trial plan start_date values for our dataset
 use the start of the month as the group by value */
SELECT customer_id,plan_id, monthname(start_date) AS start_month
FROM subscriptions
WHERE plan_id = 0
ORDER BY monthname(start_date) ASC;

SELECT COUNT(customer_id) AS num_of_customers, monthname(start_date) AS start_month
FROM subscriptions
WHERE plan_id = 0
GROUP BY start_month
ORDER BY start_month;

/* 3. What plan start_date values occur after the year 2020 for our dataset? 
Show the breakdown by count of events for each plan_name */

SELECT p.plan_name, COUNT(*) AS count_of_events
FROM subscriptions as S
JOIN plans as P
ON p.plan_id = s.plan_id
WHERE year(start_date) > '2020-12-31'
GROUP BY p.plan_name
ORDER BY count_of_events DESC;


/* 4. What is the customer count and percentage of customers who have churned 
rounded to 1 decimal place? */
SELECT COUNT(CASE WHEN p.plan_name = 'Churn' THEN 1 END) AS no_of_churned_customers, ROUND((COUNT(CASE WHEN p.plan_name = 'Churn' THEN 1 END)/COUNT(DISTINCT customer_id)*100),1) AS churn_percentage
FROM Subscriptions as s
JOIN plans as p
ON p.plan_id = s.plan_id;


/* 5. How many customers have churned straight after their initial free trial 
- what percentage is this rounded to the nearest whole number? */

WITH TotalCustomers as (
SELECT COUNT(distinct customer_id) as TotalCustomers
FROM subscriptions
),
ChurnedAfterTrial as 
(SELECT COUNT(DISTINCT s2.customer_id) AS no_of_immediate_churned_customers
FROM subscriptions as s1
JOIN subscriptions as s2
ON s1.customer_id = s2.customer_id
WHERE S1.plan_id = 0 AND s2.plan_id = 4 AND s2.start_date > s1.start_date)
SELECT c.no_of_immediate_churned_customers as churned_customers, ROUND((c.no_of_immediate_churned_customers)/(t.TotalCustomers)*100) AS churned_percentage
FROM ChurnedAfterTrial c, TotalCustomers t;

-- 6. What is the number and percentage of customer plans after their initial free trial?

WITH CTE AS (
SELECT customer_id, plan_name,
row_number () OVER(PARTITION BY customer_id ORDER BY start_date ASC) AS rn 
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id
)
SELECT plan_name, COUNT(customer_id) AS customer_count,
ROUND(COUNT(customer_id)/(SELECT COUNT(distinct customer_id) FROM CTE)*100,1) as customer_percent
FROM CTE
WHERE rn = 2
GROUP BY plan_name
ORDER BY customer_count DESC;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH CTE AS(
SELECT *,
row_number() OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS rn
FROM subscriptions
WHERE start_date <= '2020-12-31' -- These are customer plans they were at the end of the year
)
SELECT plan_name,COUNT(*) AS customer_count, ROUND(COUNT(*)/(SELECT COUNT(distinct customer_id) FROM CTE)*100,1) AS customer_percentage
FROM CTE AS ct
JOIN plans AS p
ON ct.plan_id = p.plan_id
WHERE rn = 1
GROUP BY plan_name
ORDER BY customer_count DESC;

-- 8. How many customers have upgraded to an annual plan in 2020?

SELECT COUNT(s2.customer_id) as customer_count, p.plan_name
FROM Subscriptions as s1
JOIN Subscriptions as s2
ON s1.customer_id = s2.customer_id
JOIN plans as p
ON p.plan_id = s2.plan_id
WHERE s1.plan_id = 0 AND s2.plan_id = 3 AND s2.start_date <= '2020-12-31'
GROUP BY p.plan_name;

/* 9. How many days on average does it take for a customer to upgrade to an annual plan from 
the day they join Foodie-Fi? */
SELECT ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) AS avg_days_from_trial_to_annual_plan
FROM Subscriptions as s1
JOIN Subscriptions as s2
ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 0 AND s2.plan_id = 3;


/* 10. Can you further breakdown this average value into 30 day periods 
(i.e. 0-30 days, 31-60 days etc) */

WITH CTE AS(
SELECT s2.customer_id, ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) as avg_days_from_trial_to_annual, CASE
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 0 AND 30 THEN '0-30 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 31 AND 60 THEN '31-60 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 51 AND 80 THEN '51-80 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 71 AND 100 THEN '71-100 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 101 AND 130 THEN '101-130 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 131 AND 160 THEN '131-160 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 161 AND 190 THEN '161-190 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 191 AND 220 THEN '191-220 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 221 AND 250 THEN '221-250 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 251 AND 280 THEN '251-280 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 281 AND 310 THEN '281-310 '
WHEN ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) BETWEEN 281 AND 310 THEN '311-340 '
ELSE '340+'
END AS Avg_day_range
FROM Subscriptions as s1
JOIN Subscriptions as s2
ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 0 AND s2.plan_id = 3
GROUP BY s2.customer_id
ORDER BY avg_days_from_trial_to_annual
)
SELECT COUNT(distinct customer_id) AS customer_count, Avg_day_range
FROM CTE
GROUP BY Avg_day_range
ORDER BY customer_count DESC;

-- 2nd option

WITH CTE AS( 

SELECT s2.customer_id, (datediff(s2.start_date,s1.start_date)) as days_from_trial_to_annual, CASE
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 0 AND 30 THEN '0-30'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 31 AND 60 THEN '31-60'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 61 AND 80 THEN '61-80'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 81 AND 100 THEN '81-100'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 101 AND 130 THEN '101-130'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 131 AND 160 THEN '131-160'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 161 AND 190 THEN '161-190'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 191 AND 220 THEN '191-220'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 221 AND 250 THEN '221-250'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 251 AND 280 THEN '251-280'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 281 AND 310 THEN '281-310'
               WHEN datediff(s2.start_date, s1.start_date) BETWEEN 311 AND 340 THEN '311-340'
               ELSE '340+'
END AS Avg_day_range
FROM Subscriptions as s1
JOIN Subscriptions as s2
ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 0 AND s2.plan_id = 3
ORDER BY days_from_trial_to_annual
)
SELECT COUNT(distinct customer_id) AS customer_count, Avg_day_range
FROM CTE
GROUP BY Avg_day_range
ORDER BY customer_count DESC;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT *
FROM Subscriptions as s1
JOIN Subscriptions as s2
ON s1.customer_id = s2.customer_id
JOIN plans as p
ON p.plan_id = s2.plan_id
WHERE s2.plan_id = 1 AND s1.plan_id = 2 AND s2.start_date <= '2020-12-31' AND s1.start_date <= '2020-12-31'AND s2.start_date > s1.start_date;
