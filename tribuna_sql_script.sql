-- Створення ключів/зв'язків
-- Creating primary and foreign key relationships.

ALTER TABLE users
ADD PRIMARY KEY (user_id);


ALTER TABLE events
ADD CONSTRAINT fk_events_users
FOREIGN KEY (user_id)
REFERENCES users(user_id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_users
FOREIGN KEY (user_id)
REFERENCES users(user_id);

-- Увесь набір даних
-- The complete dataset.

SELECT *
FROM tribuna.users u
INNER JOIN tribuna.orders o ON u.user_id = o.user_id
INNER JOIN tribuna.events e ON u.user_id = e.user_id;

--  ТОП-10 країн за кількістю зареєстрованих користувачів/гравців у 2024 році.
-- Top 10 countries by the number of users/players registered in 2024

SELECT COUNT(Distinct u.user_id) AS CustomerCount,
		u.country
FROM tribuna.users u
WHERE YEAR(u.registration_date) = 2024
GROUP BY u.country
ORDER BY CustomerCount DESC
LIMIT 10;

--  Кконверсія з реєстрації в перше замовлення (%) по місяцях.
-- Monthly conversion rate from registration to first order (%).

CREATE TEMPORARY TABLE t_reg_conversion1
AS
SELECT 	COUNT(DISTINCT u.user_id) AS FirstMonthOrderCount,
		MONTH(MIN(u.registration_date)) AS OrderMonth,
        MONTH(u.registration_date) AS Months
FROM tribuna.users u
LEFT JOIN tribuna.orders o ON u.user_id = o.user_id
GROUP BY Months;

CREATE TEMPORARY TABLE t_reg_conversion2
AS
SELECT 	COUNT(DISTINCT u.user_id) AS FirstMonthOrderCount,
		MONTH(MIN(u.registration_date)) AS OrderMonth,
        MONTH(u.registration_date) AS Months
FROM tribuna.users u
LEFT JOIN tribuna.orders o ON u.user_id = o.user_id
WHERE MONTH(u.registration_date) = MONTH(o.order_date)
GROUP BY Months;

SELECT 	t1.Months,
		ROUND(t2.FirstMonthOrderCount / t1.FirstMonthOrderCount * 100,1) AS FirstMonthConversionPercent
FROM t_reg_conversion1 t1
LEFT JOIN t_reg_conversion2 t2 ON t1.Months = t2.Months
GROUP BY t1.Months, FirstMonthConversionPercent;

DROP TEMPORARY TABLE t_reg_conversion1;
DROP TEMPORARY TABLE t_reg_conversion2;


--  Користувачі, які зробили більше 3 транзакцій, але жодна з них не була успішною (status ≠ 'completed').
-- Users who made more than three transactions, but none of them were successful (status ≠ 'completed').


SELECT u.user_id,
    COUNT(o.order_id) AS total_orders
FROM tribuna.users u
INNER JOIN tribuna.orders o ON u.user_id = o.user_id
GROUP BY u.user_id
HAVING
    COUNT(o.order_id) > 3 AND SUM(CASE WHEN o.status = 'completed' THEN 1 ELSE 0 END) = 0;


-- Когортний аналіз: Retention Day 1, Day 7, Day 30 для когорт по місяцю реєстрації.
-- Cohort analysis: Day 1, Day 7, and Day 30 retention by registration month cohort.

WITH cte_cohorts AS (
  SELECT
    user_id,
    DATE_FORMAT(registration_date, '%Y-%m') AS cohort_month,
    registration_date
  FROM tribuna.users
),
cte_orders_diff AS (
  SELECT
    c.user_id,
    c.cohort_month,
    DATEDIFF(o.order_date, c.registration_date) AS days_after_registration
  FROM cte_cohorts
  JOIN tribuna.orders o ON c.user_id = o.user_id
)
SELECT
  cohort_month,
  COUNT(DISTINCT user_id) AS cohort_size,
  COUNT(DISTINCT CASE WHEN days_after_registration = 1 THEN user_id END) / COUNT(DISTINCT user_id) AS day_1_retention,
  COUNT(DISTINCT CASE WHEN days_after_registration = 7 THEN user_id END) / COUNT(DISTINCT user_id) AS day_7_retention,
  COUNT(DISTINCT CASE WHEN days_after_registration = 30 THEN user_id END) / COUNT(DISTINCT user_id) AS day_30_retention
FROM cte_orders_diff
GROUP BY cohort_month
ORDER BY cohort_month;


--  Запит, який покаже динаміку середнього чека (AOV) по тижнях з відсотком зміни до попереднього тижня.
-- The query that shows the weekly trend of the Average Order Value (AOV), including the percentage change compared to the previous week.

WITH cte_AOV AS (
  SELECT
    YEAR(o.order_date) AS year,
    WEEK(o.order_date, 1) AS week,
    ROUND(AVG(o.amount),1) AS avg_order
  FROM tribuna.orders o
  GROUP BY year, week
),
cte_AOV_prev AS (
  SELECT
    year,
    week,
    avg_order,
    LAG(avg_order) OVER (ORDER BY year, week) AS prev_avg_order
  FROM cte_AOV
)
SELECT
  year,
  week,
  avg_order,
  ROUND(
    CASE
      WHEN prev_avg_order IS NULL THEN NULL
      ELSE ((avg_order - prev_avg_order) / prev_avg_order) * 100
    END, 1
  ) AS change_vs_prev_week
FROM cte_AOV_prev
ORDER BY year, week;