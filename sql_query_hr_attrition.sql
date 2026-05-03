-- ================================================
-- HR ATTRITION ANALYSIS — SQL PROJECT
-- Author: Tanya Singh Rajput
-- Dataset: IBM HR Analytics (1,470 employees)
-- Tool: MySQL Workbench
-- 
-- SECTIONS IN THIS FILE:
-- 1. Database Setup & Table Creation
-- 2. Data Cleaning & Quality Checks
-- 3. Basic Analysis (Q1–Q10)
-- 4. Advanced Queries — CTEs, Window Functions,
--    Risk Scoring Model (Q11–Q20)
-- ================================================

-- ================================================
-- SECTION 1: DATABASE SETUP
-- ================================================

CREATE DATABASE IF NOT EXISTS hr_analytics;

USE hr_analytics;

SELECT COUNT(*) AS total_rows FROM hr_attrition;

SELECT * FROM hr_attrition 
LIMIT 5;

-- ================================================
-- SECTION 2: DATA CLEANING
-- ================================================

-- Checks for missing (NULL) values across all columns

SELECT
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END)           AS missing_age,
    SUM(CASE WHEN Attrition IS NULL THEN 1 ELSE 0 END)     AS missing_attrition,
    SUM(CASE WHEN Department IS NULL THEN 1 ELSE 0 END)    AS missing_department,
    SUM(CASE WHEN MonthlyIncome IS NULL THEN 1 ELSE 0 END) AS missing_income,
    SUM(CASE WHEN OverTime IS NULL THEN 1 ELSE 0 END)      AS missing_overtime,
    SUM(CASE WHEN JobSatisfaction IS NULL THEN 1 ELSE 0 END) AS missing_job_sat,
    SUM(CASE WHEN YearsAtCompany IS NULL THEN 1 ELSE 0 END) AS missing_tenure
FROM hr_attrition;

-- Checks for typos in text columns using DISTINCT

SELECT DISTINCT Attrition FROM hr_attrition;

SELECT DISTINCT Department FROM hr_attrition;

SELECT DISTINCT OverTime FROM hr_attrition;

SELECT DISTINCT Gender FROM hr_attrition;

SELECT DISTINCT JobSatisfaction FROM hr_attrition ORDER BY JobSatisfaction;

-- Checks for duplicate employee records

SELECT
    EmployeeNumber,
    COUNT(*) AS times_appearing
FROM hr_attrition
GROUP BY EmployeeNumber
HAVING COUNT(*) > 1;

SELECT
    MIN(Age)           AS youngest,
    MAX(Age)           AS oldest,
    MIN(MonthlyIncome) AS lowest_salary,
    MAX(MonthlyIncome) AS highest_salary,
    MIN(YearsAtCompany) AS shortest_tenure,
    MAX(YearsAtCompany) AS longest_tenure
FROM hr_attrition;

-- Adds AttritionFlag column (1=Left, 0=Stayed) for easier math

ALTER TABLE hr_attrition
ADD COLUMN AttritionFlag INT DEFAULT 0;

UPDATE hr_attrition
SET AttritionFlag = CASE
    WHEN Attrition = "Yes" THEN 1
    ELSE 0
END;

SELECT
    Attrition,
    AttritionFlag,
    COUNT(*) AS employee_count
FROM hr_attrition
GROUP BY Attrition, AttritionFlag;

-- ================================================
-- SECTION 3: BASIC ANALYSIS
-- ================================================

-- Overall attrition rate — what % of employees left?

SELECT
    COUNT(*) AS total_employees,
    SUM(AttritionFlag) AS employees_who_left,
    COUNT(*) - SUM(AttritionFlag) AS employees_who_stayed,
    ROUND(
        SUM(AttritionFlag) * 100.0 / COUNT(*)
    , 2) AS attrition_rate_pct
FROM hr_attrition;


-- Attrition rate by department — which dept loses most people?

SELECT
    Department,
    COUNT(*) AS total_employees,
    SUM(AttritionFlag) AS employees_left,
    ROUND(AVG(AttritionFlag) * 100, 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY Department
ORDER BY attrition_rate_pct DESC;

-- Does overtime cause more attrition?

SELECT 
	OverTime AS overtime_status,
    COUNT(*) AS total_employees,
    SUM(AttritionFlag)  AS employees_left,
    ROUND(AVG(AttritionFlag) * 100, 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY OverTime
ORDER BY attrition_rate_pct DESC;
 
-- Salary bands vs attrition — do low paid employees leave more?

SELECT
    CASE
        WHEN MonthlyIncome < 3000 THEN "1. Low (below $3k)"
        WHEN MonthlyIncome BETWEEN 3000 AND 5999 THEN "2. Mid ($3k-$6k)"
        WHEN MonthlyIncome BETWEEN 6000 AND 9999 THEN "3. Upper ($6k-$10k)"
        ELSE "4. High (above $10k)"
    END AS salary_band,
    COUNT(*) AS total_employees,
    SUM(AttritionFlag) AS employees_left,
    ROUND(AVG(AttritionFlag) * 100, 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY salary_band
ORDER BY salary_band;

-- Top 5 job roles with highest attrition
SELECT
    JobRole,
    COUNT(*) AS total_in_role,
    SUM(AttritionFlag) AS employees_left,
    ROUND(AVG(AttritionFlag) * 100, 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY JobRole
ORDER BY attrition_rate_pct DESC
LIMIT 5;


-- Job satisfaction score vs attrition rate

SELECT
    JobSatisfaction,
    CASE JobSatisfaction
        WHEN 1 THEN "Low"
        WHEN 2 THEN "Medium"
        WHEN 3 THEN "High"
        WHEN 4 THEN "Very High"
    END AS satisfaction_label,
    COUNT(*) AS total_employees,
    ROUND(AVG(AttritionFlag) * 100, 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY JobSatisfaction
ORDER BY JobSatisfaction;

-- Attrition trend by years at company — when do people leav

SELECT
    YearsAtCompany,
    COUNT(*) AS total_employees,
    SUM(AttritionFlag) AS employees_left,
    ROUND(AVG(AttritionFlag) * 100, 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY YearsAtCompany
ORDER BY YearsAtCompany
LIMIT 10;  


-- Work-life balance vs attrition

SELECT
    WorkLifeBalance,
    CASE WorkLifeBalance
        WHEN 1 THEN "Bad"
        WHEN 2 THEN "Good"
        WHEN 3 THEN "Better"
        WHEN 4 THEN "Best"
    END AS wlb_label,
    COUNT(*) AS total_employees,
    ROUND(AVG(AttritionFlag) * 100, 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY WorkLifeBalance
ORDER BY WorkLifeBalance;

-- Does training reduce attrition?

SELECT
    TrainingTimesLastYear AS trainings_attended,
    COUNT(*) AS employees,
    ROUND(AVG(AttritionFlag) * 100, 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY TrainingTimesLastYear
ORDER BY TrainingTimesLastYear;

-- Profile comaprision - whi leaves us who stays?

SELECT
    Attrition AS left_company,
    ROUND(AVG(Age), 1) AS avg_age,
    ROUND(AVG(MonthlyIncome), 0) AS avg_monthly_income,
    ROUND(AVG(YearsAtCompany), 1) AS avg_tenure_years,
    ROUND(AVG(JobSatisfaction), 1) AS avg_job_satisfaction,
    ROUND(AVG(WorkLifeBalance), 1) AS avg_work_life_balance,
    ROUND(AVG(DistanceFromHome), 1) AS avg_distance_from_home
FROM hr_attrition
GROUP BY Attrition;

-- ================================================
-- SECTION 4: ADVANCED QUERIES
-- ================================================

-- CTE — defines high-risk employee profile (4 danger signals)
--  and measures actual attrition within that group


WITH high_risk_employees AS (
    SELECT *
    FROM hr_attrition
    WHERE
        OverTime = "Yes"           -- Working overtime
        AND JobSatisfaction <= 2   -- Low or medium satisfaction
        AND MonthlyIncome < 4000   -- Below-average salary
        AND YearsAtCompany <= 3    -- Still early in career
)

SELECT
    Department,
    COUNT(*) AS high_risk_employees,
    SUM(AttritionFlag) AS actually_left,
    ROUND(AVG(AttritionFlag) * 100, 1) AS attrition_rate_pct
FROM high_risk_employees
GROUP BY Department
ORDER BY attrition_rate_pct DESC;

-- Window function RANK() — ranks job roles within each
--       department by attrition rate independently

SELECT
    Department,
    JobRole,
    COUNT(*) AS employees,
    ROUND(AVG(AttritionFlag) * 100, 1) AS attrition_pct,
    RANK() OVER (
        PARTITION BY Department            -- Rank within each dept separately
        ORDER BY AVG(AttritionFlag) DESC   -- Highest attrition = Rank 1
    ) AS rank_in_dept
FROM hr_attrition
GROUP BY Department, JobRole
ORDER BY Department, rank_in_dept;

-- Running total — cumulative attritions by tenure year
--       using SUM() OVER window function

SELECT
    YearsAtCompany AS tenure_year,
    SUM(AttritionFlag) AS left_this_year,
    SUM(SUM(AttritionFlag)) OVER (
        ORDER BY YearsAtCompany
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_total
FROM hr_attrition
GROUP BY YearsAtCompany
ORDER BY YearsAtCompany
LIMIT 15;

-- Correlated subquery — finds employees earning below
--       their own department average who left

SELECT
    h.EmployeeNumber,
    h.Department,
    h.JobRole,
    h.MonthlyIncome AS their_salary,
    ROUND((
        SELECT AVG(MonthlyIncome)
        FROM hr_attrition
        WHERE Department = h.Department 
    ), 0) AS dept_avg_salary,
    h.Attrition
FROM hr_attrition h
WHERE
    h.MonthlyIncome < (
        SELECT AVG(MonthlyIncome)
        FROM hr_attrition
        WHERE Department = h.Department    -- ← same link again
    )
    AND h.Attrition = "Yes"
ORDER BY h.Department, h.MonthlyIncome
LIMIT 20;

-- Pivot table — overtime vs no overtime attrition
--       side by side per department using CASE WHEN

SELECT
    Department,
    COUNT(*) AS total_employees,
    ROUND(AVG(
        CASE WHEN OverTime = "Yes" THEN AttritionFlag ELSE NULL END
    ) * 100, 1) AS attrition_pct_with_overtime,
    ROUND(AVG(
        CASE WHEN OverTime = "No" THEN AttritionFlag ELSE NULL END
    ) * 100, 1) AS attrition_pct_without_overtime

FROM hr_attrition
GROUP BY Department
ORDER BY Department;

-- ROW_NUMBER() + risk scoring model — assigns weighted
--       scores to identify top 5 at-risk employees per dept

WITH risk_scored AS (
    SELECT
        EmployeeNumber,
        Department,
        JobRole,
        MonthlyIncome,

        (
          CASE WHEN OverTime = "Yes" THEN 3 ELSE 0 END
        + CASE WHEN JobSatisfaction <= 2 THEN 2 ELSE 0 END
        + CASE WHEN WorkLifeBalance <= 2 THEN 2 ELSE 0 END
        + CASE WHEN MonthlyIncome < 3000 THEN 2 ELSE 0 END
        + CASE WHEN YearsAtCompany <= 2 THEN 1 ELSE 0 END
        + CASE WHEN YearsSinceLastPromotion >= 4 THEN 1 ELSE 0 END
        ) AS risk_score,

        ROW_NUMBER() OVER (
            PARTITION BY Department
            ORDER BY (
              CASE WHEN OverTime = "Yes" THEN 3 ELSE 0 END
            + CASE WHEN JobSatisfaction <= 2 THEN 2 ELSE 0 END
            + CASE WHEN WorkLifeBalance <= 2 THEN 2 ELSE 0 END
            + CASE WHEN MonthlyIncome < 3000 THEN 2 ELSE 0 END
            + CASE WHEN YearsAtCompany <= 2 THEN 1 ELSE 0 END
            + CASE WHEN YearsSinceLastPromotion >= 4 THEN 1 ELSE 0 END
            ) DESC
        ) AS rank_in_dept

    FROM hr_attrition
    WHERE Attrition = "No"  
)
SELECT *
FROM risk_scored
WHERE rank_in_dept <= 5
ORDER BY Department, rank_in_dept;

-- Age group buckets vs attrition rate

SELECT
    CASE
        WHEN Age BETWEEN 18 AND 25 THEN "18-25 (Early career)"
        WHEN Age BETWEEN 26 AND 35 THEN "26-35 (Building career)"
        WHEN Age BETWEEN 36 AND 45 THEN "36-45 (Mid career)"
        WHEN Age BETWEEN 46 AND 55 THEN "46-55 (Senior)"
        ELSE "56+ (Near retirement)"
    END AS age_group,
    COUNT(*) AS employees,
    ROUND(AVG(AttritionFlag) * 100, 1)  AS attrition_pct,
    ROUND(AVG(MonthlyIncome), 0) AS avg_salary
FROM hr_attrition
GROUP BY age_group
ORDER BY attrition_pct DESC;

-- Multi-column GROUP BY — department x marital status

SELECT
    Department,
    MaritalStatus,
    COUNT(*) AS employees,
    ROUND(AVG(AttritionFlag) * 100, 1)  AS attrition_pct
FROM hr_attrition
GROUP BY Department, MaritalStatus
ORDER BY Department, attrition_pct DESC;

-- Distance from home vs attrition

SELECT
    CASE
        WHEN DistanceFromHome <= 5 THEN "1. Very Close (0-5 km)"
        WHEN DistanceFromHome BETWEEN 6 AND 15 THEN "2. Near (6-15 km)"
        WHEN DistanceFromHome BETWEEN 16 AND 25 THEN "3. Far (16-25 km)"
        ELSE "4. Very Far (25+ km)"
    END AS distance_band,
    COUNT(*) AS employees,
    ROUND(AVG(AttritionFlag) * 100, 1)  AS attrition_pct
FROM hr_attrition
GROUP BY distance_band
ORDER BY distance_band;

-- Executive summary — all key findings in one query

SELECT "Overall Attrition Rate"   AS metric,
    CONCAT(ROUND(AVG(AttritionFlag)*100,1),"%") AS value
FROM hr_attrition

UNION ALL

SELECT "Overtime Attrition Rate",
    CONCAT(ROUND(AVG(AttritionFlag)*100,1),"%")
FROM hr_attrition WHERE OverTime="Yes"

UNION ALL

SELECT "Non-Overtime Attrition Rate",
    CONCAT(ROUND(AVG(AttritionFlag)*100,1),"%")
FROM hr_attrition WHERE OverTime="No"

UNION ALL

SELECT "Highest Attrition Dept",
    (SELECT Department FROM hr_attrition
     GROUP BY Department
     ORDER BY AVG(AttritionFlag) DESC LIMIT 1)

UNION ALL

SELECT "Year 1 Attrition Rate",
    CONCAT(ROUND(AVG(AttritionFlag)*100,1),"%")
FROM hr_attrition WHERE YearsAtCompany=1;






