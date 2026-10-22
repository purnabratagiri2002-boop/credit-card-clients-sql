/*
PROJECT: Credit Card Clients — SQL Analysis
DATABASE: credit_card_db

HOW TO USE
1. Run this script in MySQL Workbench with the source table imported.
2. Read section headings and run/query results section by section.
3. The script uses the existing source table `credit_card_clients` and the
   existing `credit_card_clean` table if it has already been created.

IMPORTANT NOTES
- X1–X23 are kept as supplied by the imported dataset; verify their mapping
  against the original dataset documentation before reporting conclusions.
- Thresholds and risk scores in this project are exploratory, not a validated
  credit-risk prediction model.
- CREATE TABLE IF NOT EXISTS does not refresh an existing clean table. If the
  source data changes, rebuild/update the clean table deliberately.
- This is an organization pass: analytical queries are retained; repeated
  audit queries may remain where they serve as separate checks.
*/


------------------------------------------------------------------------------
-- 01. DATABASE SETUP AND INITIAL DATA AUDIT
------------------------------------------------------------------------------

USE credit_card_db;

-- 1. Check tables
SHOW TABLES;

-- 2. Total records
SELECT COUNT(*) AS total_rows
FROM credit_card_clients;

-- 3. Column information
DESCRIBE credit_card_clients;

-- 4. Preview data
SELECT *
FROM credit_card_clients
LIMIT 10;

-- 5. Check target variable
SELECT Y, COUNT(*) AS frequency
FROM credit_card_clients
GROUP BY Y
ORDER BY frequency DESC;


-- 6. Valid client count
SELECT COUNT(*) AS total_clients
FROM credit_card_clients
WHERE Y IN ('0', '1');

-- 7. Default and non-default count
SELECT
    SUM(Y = '1') AS default_clients,
    SUM(Y = '0') AS non_default_clients
FROM credit_card_clients
WHERE Y IN ('0', '1');

-- 8. Overall default rate
SELECT
    ROUND(
        100.0 * SUM(Y = '1') /
        NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct
FROM credit_card_clients
WHERE Y IN ('0', '1');



------------------------------------------------------------------------------
-- 02. CREDIT LIMIT EXPLORATION
------------------------------------------------------------------------------

-- 9. Credit limit summary
SELECT
    COUNT(*) AS total_records,
    AVG(CAST(X1 AS DECIMAL(12,2))) AS avg_limit,
    MIN(CAST(X1 AS DECIMAL(12,2))) AS min_limit,
    MAX(CAST(X1 AS DECIMAL(12,2))) AS max_limit
FROM credit_card_clients
WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$';

-- 10. Most common credit limits
SELECT
    X1 AS credit_limit,
    COUNT(*) AS client_count
FROM credit_card_clients
WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
GROUP BY X1
ORDER BY client_count DESC
LIMIT 10;

-- 11. Credit limit categories
SELECT
    CASE
        WHEN CAST(X1 AS DECIMAL(12,2)) < 50000
            THEN 'Low'
        WHEN CAST(X1 AS DECIMAL(12,2)) < 200000
            THEN 'Medium'
        ELSE 'High'
    END AS credit_segment,
    COUNT(*) AS total_clients
FROM credit_card_clients
WHERE Y IN ('0', '1')
  AND X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
GROUP BY credit_segment;



------------------------------------------------------------------------------
-- 03. CREDIT LIMIT SEGMENTS AND DEFAULT RATE
------------------------------------------------------------------------------

-- 12. CTE: Default summary
WITH default_summary AS (
    SELECT
        Y AS default_status,
        COUNT(*) AS total_clients
    FROM credit_card_clients
    WHERE Y IN ('0', '1')
    GROUP BY Y
)
SELECT
    default_status,
    total_clients,
    ROUND(
        100.0 * total_clients /
        SUM(total_clients) OVER (),
        2
    ) AS percentage,
    DENSE_RANK() OVER (
        ORDER BY total_clients DESC
    ) AS population_rank
FROM default_summary;

-- 13. Rank credit limit frequency
WITH credit_frequency AS (
    SELECT
        X1 AS credit_limit,
        COUNT(*) AS total_clients
    FROM credit_card_clients
    WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
    GROUP BY X1
)
SELECT
    credit_limit,
    total_clients,
    DENSE_RANK() OVER (
        ORDER BY total_clients DESC
    ) AS frequency_rank
FROM credit_frequency
ORDER BY frequency_rank
LIMIT 20;


-- 14. Default rate by credit segment
WITH client_data AS (
    SELECT
        CAST(X1 AS DECIMAL(12,2)) AS credit_limit,
        CAST(Y AS UNSIGNED) AS default_status
    FROM credit_card_clients
    WHERE Y IN ('0', '1')
      AND X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
),
segmented_data AS (
    SELECT
        CASE
            WHEN credit_limit < 50000 THEN 'Low'
            WHEN credit_limit < 200000 THEN 'Medium'
            ELSE 'High'
        END AS credit_segment,
        default_status
    FROM client_data
)
SELECT
    credit_segment,
    COUNT(*) AS total_clients,
    SUM(default_status = 1) AS default_clients,
    ROUND(AVG(default_status) * 100, 2)
        AS default_rate_pct
FROM segmented_data
GROUP BY credit_segment
ORDER BY default_rate_pct DESC;




------------------------------------------------------------------------------
-- 04. DATA QUALITY AND TARGET VALIDATION
------------------------------------------------------------------------------

-- 15. NULL values in selected columns
SELECT
    SUM(X1 IS NULL) AS null_X1,
    SUM(X2 IS NULL) AS null_X2,
    SUM(X3 IS NULL) AS null_X3,
    SUM(Y IS NULL) AS null_Y
FROM credit_card_clients;

-- 16. Find invalid target values
SELECT
    Y,
    COUNT(*) AS frequency
FROM credit_card_clients
WHERE Y NOT IN ('0', '1')
   OR Y IS NULL
GROUP BY Y;

-- 17. Check possible header row
SELECT *
FROM credit_card_clients
WHERE Y = 'default payment next month';



-- 1. Check available tables
SHOW TABLES;

-- 2. Count total rows
SELECT COUNT(*) AS total_rows
FROM credit_card_clients;

-- 3. Check column names and data types
DESCRIBE credit_card_clients;

-- 4. Preview first 5 rows
SELECT *
FROM credit_card_clients
LIMIT 5;

-- 5. Check target column values
SELECT
    Y,
    COUNT(*) AS client_count
FROM credit_card_clients
GROUP BY Y
ORDER BY client_count DESC;






-- Step 2A: Check whether the header was imported as a row
SELECT *
FROM credit_card_clients
WHERE Y = 'default payment next month';

-- Step 2B: Check missing or blank values
SELECT
    SUM(Y IS NULL) AS null_target,
    SUM(TRIM(Y) = '') AS blank_target
FROM credit_card_clients;

-- Step 2C: Check total row count
SELECT COUNT(*) AS total_rows
FROM credit_card_clients;



------------------------------------------------------------------------------
-- 05. CUSTOMER SEGMENTATION: AGE AND CREDIT LIMIT
------------------------------------------------------------------------------


SELECT *
FROM credit_card_clients
WHERE Y = 'default payment next month';


SELECT
    Y,
    COUNT(*) AS row_count
FROM credit_card_clients
GROUP BY Y
ORDER BY row_count DESC;


SELECT *
FROM credit_card_clients
LIMIT 5;





SELECT
    CASE
        WHEN CAST(X5 AS UNSIGNED) < 25 THEN 'Under 25'
        WHEN CAST(X5 AS UNSIGNED) < 40 THEN '25-39'
        WHEN CAST(X5 AS UNSIGNED) < 60 THEN '40-59'
        ELSE '60+'
    END AS age_group,

    CASE
        WHEN CAST(X1 AS DECIMAL(12,2)) < 50000
            THEN 'Low Credit Limit'
        WHEN CAST(X1 AS DECIMAL(12,2)) < 150000
            THEN 'Medium Credit Limit'
        ELSE 'High Credit Limit'
    END AS credit_limit_group,

    COUNT(*) AS total_customers,

    SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END)
        AS defaulted_customers,

    ROUND(
        100.0 * SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct

FROM credit_card_clients

WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
  AND X5 REGEXP '^[0-9]+$'
  AND Y IN ('0', '1')

GROUP BY age_group, credit_limit_group
ORDER BY default_rate_pct DESC;







------------------------------------------------------------------------------
-- 06. RISK SCORING AND CUSTOMER RANKING
------------------------------------------------------------------------------


SELECT
    MyUnknownColumn AS customer_id,

    CAST(X1 AS DECIMAL(12,2)) AS credit_limit,

    NTILE(4) OVER (
        ORDER BY CAST(X1 AS DECIMAL(12,2))
    ) AS credit_limit_quartile

FROM credit_card_clients

WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
  AND MyUnknownColumn REGEXP '^[0-9]+$';
  
  
  
  

SELECT
    CASE
        WHEN CAST(X6 AS SIGNED) <= 0
            THEN 'No Current Delay'
        WHEN CAST(X6 AS SIGNED) BETWEEN 1 AND 2
            THEN 'Moderate Delay'
        WHEN CAST(X6 AS SIGNED) BETWEEN 3 AND 5
            THEN 'High Delay'
        ELSE 'Very High Delay'
    END AS repayment_group,

    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN Y = '1' THEN 1
            ELSE 0
        END
    ) AS defaulted_customers,

    ROUND(
        100.0 * AVG(
            CASE
                WHEN Y = '1' THEN 1.0
                ELSE 0.0
            END
        ),
        2
    ) AS default_rate_pct

FROM credit_card_clients

WHERE X6 REGEXP '^-?[0-9]+$'
  AND Y IN ('0', '1')

GROUP BY repayment_group

ORDER BY default_rate_pct DESC;






------------------------------------------------------------------------------
-- 07. AGE-GROUP ANALYSIS
------------------------------------------------------------------------------


WITH risk_scoring AS (
    SELECT
        MyUnknownColumn AS customer_id,
        CAST(X1 AS DECIMAL(12,2)) AS credit_limit,
        CAST(X6 AS SIGNED) AS repayment_status,
        CAST(Y AS UNSIGNED) AS default_flag,

        (
            CASE
                WHEN CAST(X6 AS SIGNED) >= 3 THEN 4
                WHEN CAST(X6 AS SIGNED) BETWEEN 1 AND 2 THEN 2
                WHEN CAST(X6 AS SIGNED) = 0 THEN 1
                ELSE 0
            END
        ) AS risk_score

    FROM credit_card_clients

    WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
      AND X6 REGEXP '^-?[0-9]+$'
      AND Y IN ('0', '1')
      AND MyUnknownColumn REGEXP '^[0-9]+$'
)

SELECT
    customer_id,
    credit_limit,
    repayment_status,
    default_flag,
    risk_score,

    DENSE_RANK() OVER (
        ORDER BY risk_score DESC
    ) AS risk_rank

FROM risk_scoring
ORDER BY risk_rank, customer_id;







WITH customer_segments AS (
    SELECT
        CASE
            WHEN CAST(X5 AS UNSIGNED) < 25 THEN 'Under 25'
            WHEN CAST(X5 AS UNSIGNED) < 40 THEN '25-39'
            WHEN CAST(X5 AS UNSIGNED) < 60 THEN '40-59'
            ELSE '60+'
        END AS age_group,

        CAST(X1 AS DECIMAL(12,2)) AS credit_limit,
        CAST(Y AS UNSIGNED) AS default_flag

    FROM credit_card_clients

    WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
      AND X5 REGEXP '^[0-9]+$'
      AND Y IN ('0', '1')
),

segment_summary AS (
    SELECT
        age_group,
        COUNT(*) AS total_customers,
        SUM(default_flag) AS defaulted_customers,

        ROUND(
            100.0 * AVG(default_flag),
            2
        ) AS default_rate_pct,

        ROUND(
            AVG(credit_limit),
            2
        ) AS avg_credit_limit

    FROM customer_segments
    GROUP BY age_group
)

SELECT
    age_group,
    total_customers,
    defaulted_customers,
    default_rate_pct,
    avg_credit_limit,

    DENSE_RANK() OVER (
        ORDER BY default_rate_pct DESC
    ) AS default_risk_rank

FROM segment_summary
ORDER BY default_risk_rank;







------------------------------------------------------------------------------
-- 08. CUSTOMER RISK REPORT VIEW
------------------------------------------------------------------------------


CREATE OR REPLACE VIEW customer_risk_report AS
SELECT
    CASE
        WHEN CAST(X5 AS UNSIGNED) < 25 THEN 'Under 25'
        WHEN CAST(X5 AS UNSIGNED) < 40 THEN '25-39'
        WHEN CAST(X5 AS UNSIGNED) < 60 THEN '40-59'
        ELSE '60+'
    END AS age_group,

    CASE
        WHEN CAST(X1 AS DECIMAL(12,2)) < 50000
            THEN 'Low Credit Limit'
        WHEN CAST(X1 AS DECIMAL(12,2)) < 150000
            THEN 'Medium Credit Limit'
        ELSE 'High Credit Limit'
    END AS credit_limit_group,

    COUNT(*) AS total_customers,

    SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END)
        AS defaulted_customers,

    ROUND(
        100.0 * AVG(CASE WHEN Y = '1' THEN 1.0 ELSE 0.0 END),
        2
    ) AS default_rate_pct

FROM credit_card_clients

WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
  AND X5 REGEXP '^[0-9]+$'
  AND Y IN ('0', '1')

GROUP BY age_group, credit_limit_group;

SELECT *
FROM customer_risk_report
ORDER BY default_rate_pct DESC;

SELECT *
FROM customer_risk_report
WHERE default_rate_pct >= 25
ORDER BY default_rate_pct DESC;






------------------------------------------------------------------------------
-- 09. SEGMENT SUMMARY AND RISK REPORTING
------------------------------------------------------------------------------


SELECT
    age_group,
    credit_limit_group,
    total_customers,
    defaulted_customers,
    default_rate_pct,

    CASE
        WHEN default_rate_pct >= 30 THEN 'High Risk'
        WHEN default_rate_pct >= 20 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category

FROM customer_risk_report

ORDER BY
    default_rate_pct DESC,
    total_customers DESC;
    
    
    
    
    

SELECT
    COUNT(*) AS total_segments,

    SUM(total_customers) AS total_customers,

    SUM(defaulted_customers) AS total_defaulted_customers,

    ROUND(
        100.0 * SUM(defaulted_customers)
        / NULLIF(SUM(total_customers), 0),
        2
    ) AS overall_default_rate_pct

FROM customer_risk_report;





WITH segment_summary AS (
    SELECT
        age_group,
        credit_limit_group,
        total_customers,
        defaulted_customers,
        default_rate_pct
    FROM customer_risk_report
)

SELECT
    age_group,
    credit_limit_group,
    total_customers,
    defaulted_customers,
    default_rate_pct,

    DENSE_RANK() OVER (
        ORDER BY default_rate_pct DESC
    ) AS risk_rank,

    RANK() OVER (
        ORDER BY default_rate_pct DESC
    ) AS risk_position

FROM segment_summary
ORDER BY risk_rank, total_customers DESC;







------------------------------------------------------------------------------
-- 10. STORED PROCEDURE: RISK BY AGE GROUP
------------------------------------------------------------------------------


DROP PROCEDURE IF EXISTS GetCustomerRiskByAge;

DELIMITER //

CREATE PROCEDURE GetCustomerRiskByAge(
    IN p_age_group VARCHAR(20)
)
BEGIN
    SELECT
        age_group,
        credit_limit_group,
        total_customers,
        defaulted_customers,
        default_rate_pct,

        CASE
            WHEN default_rate_pct >= 30 THEN 'High Risk'
            WHEN default_rate_pct >= 20 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS risk_category

    FROM customer_risk_report

    WHERE age_group = p_age_group

    ORDER BY default_rate_pct DESC;
END //

DELIMITER ;
CALL GetCustomerRiskByAge('25-39');
CALL GetCustomerRiskByAge('Under 25');

CALL GetCustomerRiskByAge('40-59');

CALL GetCustomerRiskByAge('60+');









------------------------------------------------------------------------------
-- 11. DATA QUALITY: DUPLICATES, AGE AND MISSING VALUES
------------------------------------------------------------------------------


SELECT
    MyUnknownColumn AS customer_id,
    COUNT(*) AS duplicate_count
FROM credit_card_clients
WHERE MyUnknownColumn REGEXP '^[0-9]+$'
GROUP BY MyUnknownColumn
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
SELECT
    X5 AS age,
    COUNT(*) AS record_count
FROM credit_card_clients
WHERE X5 REGEXP '^[0-9]+$'
  AND (
      CAST(X5 AS UNSIGNED) < 18
      OR CAST(X5 AS UNSIGNED) > 100
  )
GROUP BY X5
ORDER BY record_count DESC;




SELECT
    SUM(X1 IS NULL OR TRIM(X1) = '') AS missing_credit_limit,
    SUM(X5 IS NULL OR TRIM(X5) = '') AS missing_age,
    SUM(Y IS NULL OR TRIM(Y) = '') AS missing_default_flag
FROM credit_card_clients;





SELECT
    Y AS default_flag,
    COUNT(*) AS record_count
FROM credit_card_clients
WHERE Y NOT IN ('0', '1')
   OR Y IS NULL
GROUP BY Y;




------------------------------------------------------------------------------
-- 12. REPAYMENT STATUS ANALYSIS
------------------------------------------------------------------------------


WITH repayment_analysis AS (
    SELECT
        CAST(X6 AS SIGNED) AS repayment_status,
        CAST(Y AS UNSIGNED) AS default_flag
    FROM credit_card_clients
    WHERE X6 REGEXP '^-?[0-9]+$'
      AND Y IN ('0', '1')
),

status_summary AS (
    SELECT
        repayment_status,
        COUNT(*) AS total_customers,
        SUM(default_flag) AS defaulted_customers,
        ROUND(100.0 * AVG(default_flag), 2)
            AS default_rate_pct
    FROM repayment_analysis
    GROUP BY repayment_status
)

SELECT
    repayment_status,
    total_customers,
    defaulted_customers,
    default_rate_pct,

    DENSE_RANK() OVER (
        ORDER BY default_rate_pct DESC
    ) AS risk_rank

FROM status_summary
ORDER BY risk_rank;


SELECT *
FROM credit_card_clients
WHERE Y = 'default payment next month';






------------------------------------------------------------------------------
-- 13. STORED PROCEDURE: CREDIT-LIMIT RISK
------------------------------------------------------------------------------


DROP PROCEDURE IF EXISTS GetCreditLimitRisk;

DELIMITER //

CREATE PROCEDURE GetCreditLimitRisk()
BEGIN

    SELECT
        CASE
            WHEN CAST(X1 AS DECIMAL(12,2)) < 50000
                THEN 'Low Credit Limit'
            WHEN CAST(X1 AS DECIMAL(12,2)) < 150000
                THEN 'Medium Credit Limit'
            ELSE 'High Credit Limit'
        END AS credit_limit_group,

        COUNT(*) AS total_customers,

        SUM(
            CASE WHEN Y = '1' THEN 1 ELSE 0 END
        ) AS defaulted_customers,

        ROUND(
            100.0 * AVG(
                CASE WHEN Y = '1' THEN 1.0 ELSE 0.0 END
            ),
            2
        ) AS default_rate_pct

    FROM credit_card_clients

    WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
      AND Y IN ('0', '1')

    GROUP BY credit_limit_group
    ORDER BY default_rate_pct DESC;

END //

DELIMITER ;



CALL GetCreditLimitRisk();





------------------------------------------------------------------------------
-- 14. BILLING, PAYMENTS AND PAYMENT-TO-BILL ANALYSIS
------------------------------------------------------------------------------


SELECT
    COUNT(*) AS valid_clients,

    ROUND(AVG(CAST(X12 AS DECIMAL(14,2))), 2)
        AS avg_bill_1,

    ROUND(AVG(CAST(X13 AS DECIMAL(14,2))), 2)
        AS avg_bill_2,

    ROUND(AVG(CAST(X14 AS DECIMAL(14,2))), 2)
        AS avg_bill_3,

    ROUND(AVG(CAST(X18 AS DECIMAL(14,2))), 2)
        AS avg_payment_1,

    ROUND(AVG(CAST(X19 AS DECIMAL(14,2))), 2)
        AS avg_payment_2,

    ROUND(AVG(CAST(X20 AS DECIMAL(14,2))), 2)
        AS avg_payment_3

FROM credit_card_clients

WHERE Y IN ('0', '1')
  AND X12 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
  AND X13 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
  AND X14 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
  AND X18 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
  AND X19 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
  AND X20 REGEXP '^-?[0-9]+(\\.[0-9]+)?$';
  
  
  

WITH payment_analysis AS (
    SELECT
        CAST(X12 AS DECIMAL(14,2)) AS bill_amount,
        CAST(X18 AS DECIMAL(14,2)) AS payment_amount,
        CAST(Y AS UNSIGNED) AS default_flag
    FROM credit_card_clients
    WHERE X12 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND X18 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND Y IN ('0', '1')
)

SELECT
    CASE
        WHEN bill_amount <= 0 THEN 'Zero/Negative Bill'
        WHEN payment_amount / bill_amount < 0.25 THEN 'Below 25%'
        WHEN payment_amount / bill_amount < 0.50 THEN '25%-49%'
        WHEN payment_amount / bill_amount < 1.00 THEN '50%-99%'
        ELSE '100% or More'
    END AS payment_ratio_group,

    COUNT(*) AS total_customers,

    SUM(default_flag) AS defaulted_customers,

    ROUND(
        100.0 * AVG(default_flag),
        2
    ) AS default_rate_pct

FROM payment_analysis
GROUP BY payment_ratio_group
ORDER BY default_rate_pct DESC;







------------------------------------------------------------------------------
-- 15. SIX-PERIOD BILLING TRENDS
------------------------------------------------------------------------------


WITH monthly_data AS (

    SELECT
        1 AS billing_period,
        CAST(X12 AS DECIMAL(14,2)) AS bill_amount,
        CAST(X18 AS DECIMAL(14,2)) AS payment_amount
    FROM credit_card_clients
    WHERE X12 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND X18 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND Y IN ('0', '1')

    UNION ALL

    SELECT
        2,
        CAST(X13 AS DECIMAL(14,2)),
        CAST(X19 AS DECIMAL(14,2))
    FROM credit_card_clients
    WHERE X13 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND X19 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND Y IN ('0', '1')

    UNION ALL

    SELECT
        3,
        CAST(X14 AS DECIMAL(14,2)),
        CAST(X20 AS DECIMAL(14,2))
    FROM credit_card_clients
    WHERE X14 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND X20 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND Y IN ('0', '1')

    UNION ALL

    SELECT
        4,
        CAST(X15 AS DECIMAL(14,2)),
        CAST(X21 AS DECIMAL(14,2))
    FROM credit_card_clients
    WHERE X15 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND X21 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND Y IN ('0', '1')

    UNION ALL

    SELECT
        5,
        CAST(X16 AS DECIMAL(14,2)),
        CAST(X22 AS DECIMAL(14,2))
    FROM credit_card_clients
    WHERE X16 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND X22 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND Y IN ('0', '1')

    UNION ALL

    SELECT
        6,
        CAST(X17 AS DECIMAL(14,2)),
        CAST(X23 AS DECIMAL(14,2))
    FROM credit_card_clients
    WHERE X17 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND X23 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
      AND Y IN ('0', '1')
)

SELECT
    billing_period,
    COUNT(*) AS client_count,
    ROUND(AVG(bill_amount), 2) AS avg_bill_amount,
    ROUND(AVG(payment_amount), 2) AS avg_payment_amount,
    ROUND(AVG(bill_amount - payment_amount), 2)
        AS avg_bill_payment_difference

FROM monthly_data
GROUP BY billing_period
ORDER BY billing_period;






------------------------------------------------------------------------------
-- 16. DEMOGRAPHIC ANALYSIS: EDUCATION
------------------------------------------------------------------------------


WITH demographic_data AS (
    SELECT
        CAST(X3 AS UNSIGNED) AS education,
        CAST(Y AS UNSIGNED) AS default_flag
    FROM credit_card_clients
    WHERE X3 REGEXP '^[0-9]+$'
      AND Y IN ('0', '1')
),

education_summary AS (
    SELECT
        CASE
            WHEN education = 1 THEN 'Graduate School'
            WHEN education = 2 THEN 'University'
            WHEN education = 3 THEN 'High School'
            WHEN education = 4 THEN 'Other'
            ELSE 'Unknown / Other Code'
        END AS education_group,

        COUNT(*) AS total_customers,
        SUM(default_flag) AS defaulted_customers,
        ROUND(100.0 * AVG(default_flag), 2) AS default_rate_pct

    FROM demographic_data
    GROUP BY education_group
)

SELECT
    education_group,
    total_customers,
    defaulted_customers,
    default_rate_pct,

    DENSE_RANK() OVER (
        ORDER BY default_rate_pct DESC
    ) AS risk_rank

FROM education_summary
ORDER BY risk_rank;





------------------------------------------------------------------------------
-- 17. DEMOGRAPHIC ANALYSIS: MARRIAGE
------------------------------------------------------------------------------


WITH marriage_data AS (
    SELECT
        CAST(X4 AS UNSIGNED) AS marriage_status,
        CAST(Y AS UNSIGNED) AS default_flag
    FROM credit_card_clients
    WHERE X4 REGEXP '^[0-9]+$'
      AND Y IN ('0', '1')
)

SELECT
    CASE
        WHEN marriage_status = 1 THEN 'Married'
        WHEN marriage_status = 2 THEN 'Single'
        WHEN marriage_status = 3 THEN 'Other'
        ELSE 'Unknown / Other Code'
    END AS marriage_group,

    COUNT(*) AS total_customers,
    SUM(default_flag) AS defaulted_customers,

    ROUND(
        100.0 * AVG(default_flag),
        2
    ) AS default_rate_pct

FROM marriage_data
GROUP BY marriage_group
ORDER BY default_rate_pct DESC;






------------------------------------------------------------------------------
-- 18. DEMOGRAPHIC ANALYSIS: AGE
------------------------------------------------------------------------------


WITH age_data AS (
    SELECT
        CASE
            WHEN CAST(X5 AS UNSIGNED) < 25 THEN 'Under 25'
            WHEN CAST(X5 AS UNSIGNED) < 40 THEN '25-39'
            WHEN CAST(X5 AS UNSIGNED) < 60 THEN '40-59'
            ELSE '60+'
        END AS age_group,

        CAST(Y AS UNSIGNED) AS default_flag

    FROM credit_card_clients
    WHERE X5 REGEXP '^[0-9]+$'
      AND Y IN ('0', '1')
)

SELECT
    age_group,
    COUNT(*) AS total_customers,
    SUM(default_flag) AS defaulted_customers,

    ROUND(
        100.0 * AVG(default_flag),
        2
    ) AS default_rate_pct

FROM age_data
GROUP BY age_group
ORDER BY default_rate_pct DESC;





------------------------------------------------------------------------------
-- 19. ETL VALIDATION AND CLEAN TABLE
------------------------------------------------------------------------------


SELECT
    COUNT(*) AS total_rows,

    SUM(
        CASE WHEN Y IN ('0', '1')
             THEN 1 ELSE 0 END
    ) AS valid_target_rows,

    SUM(
        CASE WHEN Y = 'default payment next month'
             THEN 1 ELSE 0 END
    ) AS possible_header_rows,

    SUM(
        CASE WHEN Y IS NULL OR TRIM(Y) = ''
             THEN 1 ELSE 0 END
    ) AS missing_target_rows

FROM credit_card_clients;




-- If this table already exists, this statement will NOT refresh its data.

CREATE TABLE IF NOT EXISTS credit_card_clean AS
SELECT *
FROM credit_card_clients
WHERE Y IN ('0', '1');


SELECT
    COUNT(*) AS clean_rows,
    SUM(Y = '1') AS default_clients,
    SUM(Y = '0') AS non_default_clients
FROM credit_card_clean;




DESCRIBE credit_card_clean;


------------------------------------------------------------------------------
-- 20. FINAL KPI AND RISK SUMMARIES
------------------------------------------------------------------------------

SHOW TABLES;


SELECT
    COUNT(*) AS total_rows,
    SUM(Y = '1') AS default_clients,
    SUM(Y = '0') AS non_default_clients
FROM credit_card_clean;

DESCRIBE credit_card_clean;







SELECT
    COUNT(*) AS total_customers,

    SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END)
        AS defaulted_customers,

    SUM(CASE WHEN Y = '0' THEN 1 ELSE 0 END)
        AS non_defaulted_customers,

    ROUND(
        100.0 * SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct

FROM credit_card_clean
WHERE Y IN ('0', '1');







------------------------------------------------------------------------------
-- 21. ADDITIONAL CUSTOMER RISK QUERIES
------------------------------------------------------------------------------


SELECT
    CASE
        WHEN CAST(X1 AS DECIMAL(12,2)) < 50000
            THEN 'Low Credit Limit'
        WHEN CAST(X1 AS DECIMAL(12,2)) < 150000
            THEN 'Medium Credit Limit'
        ELSE 'High Credit Limit'
    END AS credit_limit_group,

    COUNT(*) AS total_customers,

    SUM(
        CASE WHEN Y = '1' THEN 1 ELSE 0 END
    ) AS defaulted_customers,

    ROUND(
        100.0 * AVG(
            CASE WHEN Y = '1' THEN 1.0 ELSE 0.0 END
        ),
        2
    ) AS default_rate_pct

FROM credit_card_clean

WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
  AND Y IN ('0', '1')

GROUP BY credit_limit_group
ORDER BY default_rate_pct DESC;





------------------------------------------------------------------------------
-- 22. REPAYMENT AND SEGMENT COMPARISONS
------------------------------------------------------------------------------


SELECT
    age_group,
    credit_limit_group,
    total_customers,
    defaulted_customers,
    default_rate_pct
FROM customer_risk_report
ORDER BY default_rate_pct DESC
LIMIT 5;





SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Y = '0' THEN 1 ELSE 0 END) AS non_default_customers,
    SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END) AS default_customers,
    SUM(CASE WHEN Y NOT IN ('0', '1')
              OR Y IS NULL THEN 1 ELSE 0 END) AS invalid_target_rows
FROM credit_card_clean;






SELECT
    COUNT(*) AS total_customers,

    SUM(CASE
        WHEN Y = '0' THEN 1
        ELSE 0
    END) AS non_default_customers,

    SUM(CASE
        WHEN Y = '1' THEN 1
        ELSE 0
    END) AS default_customers,

    ROUND(
        100.0 * SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct

FROM credit_card_clean
WHERE Y IN ('0', '1');




SELECT
    CASE
        WHEN CAST(X1 AS DECIMAL(12,2)) < 50000
            THEN 'Low Credit Limit'
        WHEN CAST(X1 AS DECIMAL(12,2)) < 150000
            THEN 'Medium Credit Limit'
        ELSE 'High Credit Limit'
    END AS credit_limit_group,

    COUNT(*) AS total_customers,

    SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END)
        AS default_customers,

    ROUND(
        100.0 * AVG(CASE WHEN Y = '1' THEN 1.0 ELSE 0.0 END),
        2
    ) AS default_rate_pct

FROM credit_card_clean
WHERE X1 REGEXP '^[0-9]+(\\.[0-9]+)?$'
  AND Y IN ('0', '1')
GROUP BY credit_limit_group
ORDER BY default_rate_pct DESC;






SELECT
    X6 AS repayment_status,
    COUNT(*) AS total_customers,

    SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END)
        AS default_customers,

    ROUND(
        100.0 * AVG(CASE WHEN Y = '1' THEN 1.0 ELSE 0.0 END),
        2
    ) AS default_rate_pct

FROM credit_card_clean
WHERE X6 REGEXP '^-?[0-9]+$'
  AND Y IN ('0', '1')
GROUP BY X6
ORDER BY default_rate_pct DESC;









------------------------------------------------------------------------------
-- 23. FINAL SUMMARY QUERIES
------------------------------------------------------------------------------


SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Y = '0' THEN 1 ELSE 0 END)
        AS non_default_customers,
    SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END)
        AS default_customers,
    ROUND(
        100.0 * SUM(CASE WHEN Y = '1' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct
FROM credit_card_clean
WHERE Y IN ('0', '1');





SELECT
    'Period 1' AS billing_period,
    ROUND(AVG(CAST(X12 AS DECIMAL(12,2))), 2) AS avg_bill,
    ROUND(AVG(CAST(X18 AS DECIMAL(12,2))), 2) AS avg_payment
FROM credit_card_clean
WHERE X12 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
  AND X18 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'

UNION ALL

SELECT
    'Period 2',
    ROUND(AVG(CAST(X13 AS DECIMAL(12,2))), 2),
    ROUND(AVG(CAST(X19 AS DECIMAL(12,2))), 2)
FROM credit_card_clean
WHERE X13 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
  AND X19 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'

UNION ALL

SELECT
    'Period 3',
    ROUND(AVG(CAST(X14 AS DECIMAL(12,2))), 2),
    ROUND(AVG(CAST(X20 AS DECIMAL(12,2))), 2)
FROM credit_card_clean
WHERE X14 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
  AND X20 REGEXP '^-?[0-9]+(\\.[0-9]+)?$';
  
  
  
  SELECT
    CASE
        WHEN CAST(X12 AS DECIMAL(12,2)) <= 0
            THEN 'No Positive Bill'
        WHEN CAST(X18 AS DECIMAL(12,2))
             / NULLIF(CAST(X12 AS DECIMAL(12,2)), 0) < 0.25
            THEN 'Below 25%'
        WHEN CAST(X18 AS DECIMAL(12,2))
             / NULLIF(CAST(X12 AS DECIMAL(12,2)), 0) < 0.75
            THEN '25%-74%'
        ELSE '75% or Above'
    END AS payment_ratio_group,

    COUNT(*) AS total_customers,
    SUM(Y = '1') AS default_customers,

    ROUND(
        100.0 * AVG(CASE WHEN Y = '1' THEN 1.0 ELSE 0.0 END),
        2
    ) AS default_rate_pct

FROM credit_card_clean
WHERE X12 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
  AND X18 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
  AND Y IN ('0', '1')
GROUP BY payment_ratio_group
ORDER BY default_rate_pct DESC;



------------------------------------------------------------------------------
-- 24. BILLING AMOUNT BY PERIOD: FINAL CHECK
------------------------------------------------------------------------------

SELECT 'Period 1' AS period_name,
       ROUND(AVG(CAST(X12 AS DECIMAL(12,2))), 2) AS avg_bill
FROM credit_card_clean
WHERE X12 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'

UNION ALL
SELECT 'Period 2', ROUND(AVG(CAST(X13 AS DECIMAL(12,2))), 2)
FROM credit_card_clean
WHERE X13 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'

UNION ALL
SELECT 'Period 3', ROUND(AVG(CAST(X14 AS DECIMAL(12,2))), 2)
FROM credit_card_clean
WHERE X14 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'

UNION ALL
SELECT 'Period 4', ROUND(AVG(CAST(X15 AS DECIMAL(12,2))), 2)
FROM credit_card_clean
WHERE X15 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'

UNION ALL
SELECT 'Period 5', ROUND(AVG(CAST(X16 AS DECIMAL(12,2))), 2)
FROM credit_card_clean
WHERE X16 REGEXP '^-?[0-9]+(\\.[0-9]+)?$'

UNION ALL
SELECT 'Period 6', ROUND(AVG(CAST(X17 AS DECIMAL(12,2))), 2)
FROM credit_card_clean
WHERE X17 REGEXP '^-?[0-9]+(\\.[0-9]+)?$';






SELECT *
FROM customer_risk_report
ORDER BY default_rate_pct DESC;
