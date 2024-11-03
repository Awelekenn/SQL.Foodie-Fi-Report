# SQL.Foodie-Fi-Report
PowerBi Visualisations &amp; SQL Queries - Data Exploration, Joins, Filtering, CTE, Temp Table

**Description**:

**Foodie-Fi** is a subscription-based streaming service launched in 2020 by Danny and his team, focusing solely on food-related content, such as cooking shows and culinary tutorials. The business model includes both monthly and annual subscription plans, offering customers unlimited access to a curated collection of exclusive food videos.

As the company was built with a data-driven mindset, all decisions around product development, customer acquisition, and feature updates are informed by detailed analysis of subscription data. This project leverages SQL and Power BI to analyse user subscription behaviours, churn rates, and identify areas for growth and optimisation.

---

## Objective

The main goal of this analysis was to address critical business questions related to customer subscriptions, trial plan conversions, churn rates, and plan upgrades. By analysing the subscription data, the Foodie-Fi team can make data-driven decisions about customer retention strategies and future investments.

In order to carry out the proposed analysis, **the following questions are defined** to be resolved throughout the analysis:

1. **How many customers has Foodie-Fi ever had?**
2. **What is the monthly distribution of trial plan start dates?**
3. **What plan start dates occur after 2020, and what is the breakdown by plan?**
4. **Customer count and percentage of customers who churned (rounded to 1 decimal place)**:
5. **What is the number and percentage of customer plans after the initial free trial?**
6. **Customer count and percentage breakdown of all 5 plan types as of 2020-12-31**:
7. **How many customers upgraded to an annual plan in 2020?**
8. **How long does it take for a customer to upgrade to an annual plan (on average)?**
9. **Breakdown of the average upgrade period into 30-day intervals**:
10. **How many customers downgraded from Pro Monthly to Basic Monthly in 2020?**

---

## Dataset

**Source**:

The data used in this project was sourced from [8 Week SQL Challenge: Case Study #3](https://8weeksqlchallenge.com/case-study-3/), which provided two key tables:

- **Subscriptions Table**: Tracks customer subscription events, such as start dates, plan types, and churn events.
- **Plan Table**: Contains customer details like plan id, plan name and price.

Tools:

- SQL **for Data Extraction**:
SQL queries were used to extract subscription start dates, churn events, and upgrade timelines from the `foodie_fi` database. Key queries were used to address the business questions, including calculating churn percentages and identifying plan upgrades.
- PowerBi **for Visualisation**:
After data extraction, Power BI was used to visualise key trends, such as customer plan distribution, churn rates, and upgrade patterns

---

## Data Analysis Process

- Counted the unique customers from the dataset

```sql
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM subscriptions;
```

- Extracted the customer id, plan id & number of customers that joined the trial plan per month in the dataset

```sql
SELECT customer_id,plan_id, monthname(start_date) AS start_month
FROM subscriptions
WHERE plan_id = 0
ORDER BY monthname(start_date) ASC;
```

- Extracted the number of plan start dates as well as the corresponding plan name there were after the year 2020

```sql
SELECT p.plan_name, COUNT(*) AS count_of_events
FROM subscriptions as S
JOIN plans as P
ON p.plan_id = s.plan_id
WHERE year(start_date) > '2020-12-31'
GROUP BY p.plan_name
ORDER BY count_of_events DESC;
```

- Extracted the number of customers who have churned as well as calculated the percentage of customers that have churned by using this number divided by the overall number of unique customers in the dataset

```sql
SELECT COUNT(CASE WHEN p.plan_name = 'Churn' THEN 1 END) AS no_of_churned_customers, 
ROUND((COUNT(CASE WHEN p.plan_name = 'Churn' THEN 1 END)/COUNT(DISTINCT customer_id)*100),1) AS churn_percentage
FROM Subscriptions as s
JOIN plans as p
ON p.plan_id = s.plan_id;
```

- Created a temporary table for the total number of customers in order to calculate the number of customers that churned after trial. Extracted the count and percentage of unique customers who churned once their trial plan was over.

```sql
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
SELECT c.no_of_immediate_churned_customers AS churned_customers, 
ROUND((c.no_of_immediate_churned_customers)/(t.TotalCustomers)*100) AS churned_percentage
FROM ChurnedAfterTrial c, TotalCustomers t;
```

- Created a temporary table to number the row of each customer and the plans they’ve been on. Using the temporary table, I extracted the number of customers and the percentage of customers that moved on to another plan after the free trial.

```sql
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
```

- Created a temporary table to show the row number for the plan each customer was on before end of 2020. Extracted number & percentage of customers that were on each plan as of the end of the year

```sql
WITH CTE AS(
SELECT *,
row_number() OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS rn
FROM subscriptions
WHERE start_date <= '2020-12-31' -- These are customer plans that were at the end of the year
)
SELECT plan_name,COUNT(*) AS customer_count, ROUND(COUNT(*)/(SELECT COUNT(distinct customer_id) FROM CTE)*100,1) AS customer_percentage
FROM CTE AS ct
JOIN plans AS p
ON ct.plan_id = p.plan_id
WHERE rn = 1
GROUP BY plan_name
ORDER BY customer_count DESC;
```

- Extracted the number of customers that upgraded to the annual plan in 2020

```sql
SELECT COUNT(s2.customer_id) as customer_count, p.plan_name
FROM Subscriptions as s1
JOIN Subscriptions as s2
ON s1.customer_id = s2.customer_id
JOIN plans as p
ON p.plan_id = s2.plan_id
WHERE s1.plan_id = 0 AND s2.plan_id = 3 AND s2.start_date <= '2020-12-31'
GROUP BY p.plan_name;
```

- Extracted the average number of time (in days) to it took for customers to switch from trial to an annual plan

```sql
SELECT ROUND(AVG(datediff(s2.start_date,s1.start_date)),1) AS avg_days_from_trial_to_annual_plan
FROM Subscriptions as s1
JOIN Subscriptions as s2
ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 0 AND s2.plan_id = 3;
```

- Extracted the number of customers that switched from trial plan to annual in 30 day periods so we’re able to see what time period has the most number of customers.

```sql
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
```

```sql
SELECT *
FROM Subscriptions as s1
JOIN Subscriptions as s2
ON s1.customer_id = s2.customer_id
JOIN plans as p
ON p.plan_id = s2.plan_id
WHERE s2.plan_id = 1 AND s1.plan_id = 2 
AND s2.start_date <= '2020-12-31' 
AND s1.start_date <= '2020-12-31'
AND s2.start_date > s1.start_date;
```

---

## Key Analysis & Insights

**Customer Plan Distribution**

- **Basic monthly** plans are the most popular plans customers upgrade to after free trial, at **54.6%**, which they’d have to downgrade to. We have **32.5%** of customers **upgrade to the Pro Monthly** plans which they automatically transition to after the trial. **3.7%** of customers **upgrade to the Pro Annual plan.**
- **March** had the **highest number of customers, 94,** starting trial plans while **February** saw the lowest number at **68 customers**. The number over the period of January 2020 to April 2021
- As at the **end of 2020**, **32.6% of customers were on the Pro Monthly plan**, **22.4% were on the Basic Monthly**, **19.5% were on the Pro Annual plan** and lastly, **1.9% were on the trial plan**

**Churn Analysis**

- Foodie-Fi has had **1000** customers in total and **30.7%** of these customer have unsubscribed
- in 2021,  **71 customers unsubscribed**, which was the highest number, compared to the number of customers that started other plans on Foodie-Fi. More people unsubscribed that started any paid plans with us, which is a sign of a churn issue.
- **9.2%** of customers **unsubscribe immediately after their free trial** so this suggests that they’re either price sensitive or they aren’t finding what they’re looking for
- At the end of 2020, **23.6%** of customers had **cancelled their plans.**

**Upgrade/Downgrade Analysis** 

- **195 customers** upgraded to the **Annual plan** in 2020
- On average, it takes customers **105 days to upgrade to the annual plan after joining**, this includes customers that might have gone on a few other plans before upgrading to annual.
- Following a further breakdown of the amount of time it takes for customers to upgrade to the annual plan, we found that **most of the customers, 49**, who have upgraded, did so **within 30 days after joining** while **3 customers took about 281 to 347 days** to upgrade to the annual plan.

---

## Visualisations

Provide a brief overview of the visualisations included in the project.

For example:

- **KPI Card**: Total Customer Foodie-Fi has ever had

![Screenshot 2024-10-27 at 10 13 45](https://github.com/user-attachments/assets/e5f5a049-2ec5-4783-9395-35f03b237fca)

- **KPI Card**: Amount of customers who have churned

![Screenshot 2024-10-27 at 10 13 45](https://github.com/user-attachments/assets/dd8d6383-9d59-4b2e-9316-16db1a460c22)

- **Bar Chart:**  The number of plans that started each month

![Screenshot 2024-10-27 at 10 14 34](https://github.com/user-attachments/assets/03dadd23-41ab-4904-b0ef-0b46cc50479e)

- **Bar Chart**: The number of events for each subscription plan starting after 2020
  
![Screenshot 2024-10-27 at 10 14 46](https://github.com/user-attachments/assets/6f5d4dc0-b000-4986-b81f-d1c9abc9acd3)

- **Pie Chart**: The plan distribution directly after their free trial and the percentage of customers across each plan

![Screenshot 2024-10-27 at 10 14 55](https://github.com/user-attachments/assets/3129bd4a-5fda-4ff5-ace4-2982a4d231e6)

- A breakdown of  all customer plans (Basic Monthly, Pro Monthly, Pro Annual, Free Trial, and Churned) as of the end of 2020
  
![Screenshot 2024-10-27 at 10 15 02](https://github.com/user-attachments/assets/8fcf9aa8-83a2-4868-94f6-40dba6f6ce1c)

- **KPI Card**: The number of customers who upgraded to annual plans during 2020

![Screenshot 2024-10-27 at 10 15 11](https://github.com/user-attachments/assets/31cbcef8-1a0b-49f3-b241-d226b18200ff)

- **KPI Card**: The average number of days for customers to upgrade to an annual plan
  
![Screenshot 2024-10-27 at 10 15 22](https://github.com/user-attachments/assets/92dc55c1-4eef-441c-a7a9-b5309220c438)


- **KPI Card**:  Customers who downgraded from Pro monthly to basic monthly

![Screenshot 2024-10-27 at 10 15 42](https://github.com/user-attachments/assets/f6c584d2-1f01-44c2-84db-8dfba0cb4df8)

- Bar Chart: The upgrade timeline was further analysed, segmenting customers into 30-day buckets

![Foodie-Fi bar chart](https://github.com/user-attachments/assets/5166af46-8bf4-4a97-aa39-1a4347829ea2)

---

---

## Recommendations

- Customers generally seem to downgrade down to the basic monthly plan once their trial plan is over, this could suggest that the trial plan period may be a little short to determine if the price of a pro monthly plan will be worth it or they’re unaware of the full potential of a pro monthly plan vs a basic monthly plan. Incentivise customer by offering discounts or extended trial plan periods
- Based on the analysis, the churn rate is quite high and there needs to be more focus on engagement and retention strategies. Launch a re-engagement strategy to win back churned customers by offering lower price points for these customers
- Foodie-fi had no customers downgrade from the pro monthly plan to the basic monthly plan. Based on this insight, i’d say that customers are generally happy with the value of the pro monthly plan compared to the basic monthly, once they do get on it.
- Since most customers tend to upgrade within 30 days of joining then maybe around the 30 day mark, prompt customers to upgrade annual plan once they reach 30 days in Foodie-Fi
