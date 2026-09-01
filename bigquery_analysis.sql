-- 1. Portfolio Overview - Loan Status

SELECT
  loan_status
  , COUNT(*) AS loan_count
  , SUM(funded_amount) AS total_funded_amount
  , ROUND(
      SAFE_DIVIDE(
        SUM(funded_amount)
        , SUM(SUM(funded_amount)) OVER ()
      ) * 100
      , 2
    ) AS funded_amount_pct
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
GROUP BY 1
ORDER BY total_funded_amount DESC;

-- Finding: current loans dominate the portfolio, contributing 97.44% of total funded amount.



-- 2. Portfolio Outstanding Amount (OS)

SELECT
  COUNT(DISTINCT customer_id) AS portfolio_customers
  , COUNT(*) AS portfolio_loans
  , SUM(funded_amount) AS outstanding_amount
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
);

-- Finding: the portfolio holds $242.89M outstanding across 15,926 active loans.



-- 3. Earning Net Receivable (ENR)

SELECT
  SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Default' THEN funded_amount
        ELSE 0
      END
    ) AS default_os
  , SUM(funded_amount)
    - SUM(
        CASE
          WHEN loan_status = 'Default' THEN funded_amount
          ELSE 0
        END
      ) AS enr
  , ROUND(
      SAFE_DIVIDE(
        SUM(funded_amount)
        - SUM(
            CASE
              WHEN loan_status = 'Default' THEN funded_amount
              ELSE 0
            END
          )
        , SUM(funded_amount)
      ) * 100
      , 2
    ) AS enr_ratio
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
);

-- Finding: ENR reaches $242.85M, representing 99.98% of portfolio OS.



-- 4. TKB30

SELECT
  SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Late (31-120 days)'
        THEN funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
                THEN funded_amount
                ELSE 0
              END
            )
            , SUM(funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
);

-- Assumption: Late (31-120 days) is used as a proxy
-- for DPD >30 days because actual DPD is not available.
-- TKB30 stands at 98.69%, with 1.31% of portfolio OS represented by loans in the Late (31–120 days) category used as a proxy for DPD >30 days.



-- 5. Cohort Analysis - OS, ENR & TKB30

SELECT
  issue_year
  , COUNT(*) AS portfolio_loans
  , SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Default'
        THEN funded_amount
        ELSE 0
      END
    ) AS default_os
  , SUM(funded_amount)
    - SUM(
        CASE
          WHEN loan_status = 'Default'
          THEN funded_amount
          ELSE 0
        END
      ) AS enr
  , SUM(
      CASE
        WHEN loan_status = 'Late (31-120 days)'
        THEN funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
                THEN funded_amount
                ELSE 0
              END
            )
            , SUM(funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
GROUP BY 1
ORDER BY 1;

-- Finding: 2013 cohort has the lowest TKB30 at 96.49%, with $641.15K OS over 30 days.



-- 6. Cohort 2013 - Home Ownership

SELECT
  c.home_ownership
  , COUNT(*) AS loan_count
  , SUM(l.funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN l.loan_status = 'Late (31-120 days)'
        THEN l.funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN l.loan_status = 'Late (31-120 days)'
                THEN l.funded_amount
                ELSE 0
              END
            )
            , SUM(l.funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
FROM fip-finance-analysis.fip_finance.loan_clean AS l
INNER JOIN fip-finance-analysis.fip_finance.customer_clean AS c
  ON l.customer_id = c.customer_id
WHERE l.loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND l.issue_year = 2013
GROUP BY 1
ORDER BY tkb30;



-- 6a. Validate Customer Coverage - Cohort 2013

SELECT
  COUNT(*) AS portfolio_loans
  , COUNTIF(c.customer_id IS NOT NULL) AS matched_loans
  , COUNTIF(c.customer_id IS NULL) AS unmatched_loans
  , ROUND(
      SAFE_DIVIDE(
        COUNTIF(c.customer_id IS NOT NULL)
        , COUNT(*)
      ) * 100
      , 2
    ) AS match_rate
FROM fip-finance-analysis.fip_finance.loan_clean AS l
LEFT JOIN fip-finance-analysis.fip_finance.customer_clean AS c
  ON l.customer_id = c.customer_id
WHERE l.loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND l.issue_year = 2013;

-- Finding: Only 1 of 892 cohort-2013 loans matched to customer data (0.11%).


-- Compare Customer ID Format (data_validation 12)

SELECT
  'customer' AS table_name
  , COUNT(*) AS total_rows
  , COUNT(DISTINCT customer_id) AS distinct_customer_id
  , AVG(LENGTH(customer_id)) AS avg_id_length
  , MIN(LENGTH(customer_id)) AS min_id_length
  , MAX(LENGTH(customer_id)) AS max_id_length
FROM fip-finance-analysis.fip_finance.customer_clean

UNION ALL
SELECT
  'loan' AS table_name
  , COUNT(*) AS total_rows
  , COUNT(DISTINCT customer_id) AS distinct_customer_id
  , AVG(LENGTH(customer_id)) AS avg_id_length
  , MIN(LENGTH(customer_id)) AS min_id_length
  , MAX(LENGTH(customer_id)) AS max_id_length
FROM fip-finance-analysis.fip_finance.loan_clean;

-- Compare Matched and Unmatched Customer ID (data_validation 13)

SELECT
  CASE
    WHEN c.customer_id IS NOT NULL THEN 'Matched'
    ELSE 'Unmatched'
  END AS match_status
  , l.customer_id
  , LENGTH(l.customer_id) AS id_length
  , COUNT(*) AS loan_count
FROM fip-finance-analysis.fip_finance.loan_clean AS l
LEFT JOIN fip-finance-analysis.fip_finance.customer_clean AS c
  ON l.customer_id = c.customer_id
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC
LIMIT 20;

-- Check Duplicate Customer ID in Loan (data_validation 14)

SELECT
  customer_id
  , COUNT(*) AS loan_count
FROM fip-finance-analysis.fip_finance.loan_clean
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY 2 DESC;

-- Customer Match Rate by Cohort (data_validation 15)

SELECT
  l.issue_year
  , COUNT(*) AS portfolio_loans
  , COUNTIF(c.customer_id IS NOT NULL) AS matched_loans
  , COUNTIF(c.customer_id IS NULL) AS unmatched_loans
  , ROUND(
      SAFE_DIVIDE(
        COUNTIF(c.customer_id IS NOT NULL)
        , COUNT(*)
      ) * 100
      , 2
    ) AS match_rate
FROM fip-finance-analysis.fip_finance.loan_clean AS l
LEFT JOIN fip-finance-analysis.fip_finance.customer_clean AS c
  ON l.customer_id = c.customer_id
WHERE l.loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
GROUP BY 1
ORDER BY 1;

-- Potential hypothesis: The low customer-loan match rate in earlier cohorts may indicate a historical data coverage or source-system limitation.

-- Customer Linkage Coverage by Cohort (data_validation 16)

SELECT
  l.issue_year
  , COUNT(*) AS portfolio_loans
  , COUNTIF(c.customer_id IS NOT NULL) AS matched_loans
  , ROUND(
      SAFE_DIVIDE(
        COUNTIF(c.customer_id IS NOT NULL)
        , COUNT(*)
      ) * 100
      , 2
    ) AS match_rate
  , COUNTIF(
      c.customer_id IS NOT NULL
      AND c.home_ownership IS NOT NULL
    ) AS matched_with_customer_attributes
FROM fip-finance-analysis.fip_finance.loan_clean AS l
LEFT JOIN fip-finance-analysis.fip_finance.customer_clean AS c
  ON l.customer_id = c.customer_id
WHERE l.loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
GROUP BY 1
ORDER BY 1;

-- Finding: Customer linkage is very limited in early cohorts,especially 2013 with only 0.11% matched loans.



-- 7. Cohort 2013 - Loan Purpose

SELECT
  purpose
  , COUNT(*) AS loan_count
  , SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Late (31-120 days)'
        THEN funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
                THEN funded_amount
                ELSE 0
              END
            )
            , SUM(funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND issue_year = 2013
GROUP BY 1
ORDER BY tkb30;

-- Finding: House shows the lowest TKB30 at 77.53%, but only across 6 loans. Debt consolidation has the largest >30-day exposure at $433.35K across 597 loans.



-- 8. Cohort 2013 - Interest Rate

SELECT
  CASE
    WHEN int_rate < 0.10 THEN '<10%'
    WHEN int_rate < 0.15 THEN '10-15%'
    WHEN int_rate < 0.20 THEN '15-20%'
    WHEN int_rate < 0.25 THEN '20-25%'
    ELSE '>=25%'
  END AS interest_rate_band
  , COUNT(*) AS loan_count
  , SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Late (31-120 days)'
        THEN funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
                THEN funded_amount
                ELSE 0
              END
            )
            , SUM(funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND issue_year = 2013
GROUP BY 1
ORDER BY
  CASE
    WHEN interest_rate_band = '<10%' THEN 1
    WHEN interest_rate_band = '10-15%' THEN 2
    WHEN interest_rate_band = '15-20%' THEN 3
    WHEN interest_rate_band = '20-25%' THEN 4
    ELSE 5
  END;

-- Finding: All cohort-2013 loans have interest rates below 10%, interest rate does not differentiate portfolio quality within this cohort.



-- 8a. Validate Interest Rate Range - Cohort 2013

SELECT
  MIN(int_rate) AS min_int_rate
  , MAX(int_rate) AS max_int_rate
  , ROUND(AVG(int_rate), 2) AS avg_int_rate
  , COUNTIF(int_rate IS NULL) AS null_int_rate
  , COUNT(*) AS total_loans
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND issue_year = 2013;

-- Finding: The 20-25% interest-rate band has the lowest meaningful TKB30, at 93.78%, with $308.13K OS over 30 days across 223 loans.



-- 9. Cohort 2013 - Grade

SELECT
  grade
  , COUNT(*) AS loan_count
  , SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Late (31-120 days)'
        THEN funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
              THEN funded_amount
              ELSE 0
              END
            )
            , SUM(funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND issue_year = 2013
GROUP BY 1
ORDER BY tkb30;

-- Finding: Lower loan grades show weaker TKB30; grade E has meaningful exposure with TKB30 of 93.65%; and $190.5K OS over 30 days.



-- 10. Interest Rate x Grade - Cohort 2013

SELECT
  grade
  , CASE
      WHEN int_rate < 0.10 THEN '<10%'
      WHEN int_rate < 0.15 THEN '10-15%'
      WHEN int_rate < 0.20 THEN '15-20%'
      WHEN int_rate < 0.25 THEN '20-25%'
      ELSE '>=25%'
    END AS interest_rate_band
  , COUNT(*) AS loan_count
  , SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Late (31-120 days)'
        THEN funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
                THEN funded_amount
                ELSE 0
              END
            )
            , SUM(funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND issue_year = 2013
GROUP BY 1, 2
ORDER BY grade, interest_rate_band;

-- Finding: The 20-25% interest-rate band is concentrated in Grade D-G; with Grade E as the largest segment (130 loans) and TKB30 of 93.65%.



-- 11. Cohort 2013 - Loan Term

SELECT
  term
  , COUNT(*) AS loan_count
  , SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Late (31-120 days)'
        THEN funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
                THEN funded_amount
                ELSE 0
              END
            )
            , SUM(funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND issue_year = 2013
GROUP BY 1
ORDER BY tkb30;

-- Finding: Loan term does not differentiate portfolio quality in the 2013 cohort because all loans have the same 60-month term.



-- 12. Cohort 2013 - Loan Amount

SELECT
  CASE
    WHEN funded_amount < 10000 THEN '<$10K'
    WHEN funded_amount < 20000 THEN '$10K-$20K'
    WHEN funded_amount < 30000 THEN '$20K-$30K'
    WHEN funded_amount < 40000 THEN '$30K-$40K'
    ELSE '>=$40K'
  END AS loan_amount_band
  , COUNT(*) AS loan_count
  , SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Late (31-120 days)'
        THEN funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
                THEN funded_amount
                ELSE 0
              END
            )
            , SUM(funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND issue_year = 2013
GROUP BY 1
ORDER BY
  CASE
    WHEN loan_amount_band = '<$10K' THEN 1
    WHEN loan_amount_band = '$10K-$20K' THEN 2
    WHEN loan_amount_band = '$20K-$30K' THEN 3
    WHEN loan_amount_band = '$30K-$40K' THEN 4
    ELSE 5
  END;

-- Finding: Loan amount does not show a material differentiation in portfolio quality, with TKB30 remaining around 96.17%–96.61% across the meaningful segments.



-- 13. Cohort 2013 - Loan Type

SELECT
  type
  , COUNT(*) AS loan_count
  , SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Late (31-120 days)'
        THEN funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
                THEN funded_amount
                ELSE 0
              END
            )
            , SUM(funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND issue_year = 2013
GROUP BY 1
ORDER BY tkb30;

-- Finding: Loan type does not differentiate portfolio quality in the 2013 cohort, as all 892 loans are classified as Individual.



-- 14. Validate Risk Segment Contribution - Cohort 2013

SELECT
  COUNT(*) AS loan_count
  , SUM(funded_amount) AS portfolio_os
  , SUM(
      CASE
        WHEN loan_status = 'Late (31-120 days)'
        THEN funded_amount
        ELSE 0
      END
    ) AS os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
                THEN funded_amount
                ELSE 0
              END
            )
            , SUM(funded_amount)
          )
      ) * 100
      , 2
    ) AS tkb30
  , ROUND(
      SAFE_DIVIDE(
        SUM(
          CASE
            WHEN loan_status = 'Late (31-120 days)'
            THEN funded_amount
            ELSE 0
          END
        )
        , (
          SELECT
            SUM(
              CASE
                WHEN loan_status = 'Late (31-120 days)'
                THEN funded_amount
                ELSE 0
              END
            )
          FROM fip-finance-analysis.fip_finance.loan_clean
          WHERE loan_status IN (
            'Current'
            , 'In Grace Period'
            , 'Late (16-30 days)'
            , 'Late (31-120 days)'
            , 'Default'
          )
          AND issue_year = 2013
        )
      ) * 100
      , 2
    ) AS pct_of_cohort_os_over_30_days
FROM fip-finance-analysis.fip_finance.loan_clean
WHERE loan_status IN (
  'Current'
  , 'In Grace Period'
  , 'Late (16-30 days)'
  , 'Late (31-120 days)'
  , 'Default'
)
AND issue_year = 2013
AND grade IN ('D', 'E', 'F', 'G')
AND int_rate >= 0.20
AND int_rate < 0.25;

-- Finding: Segmen Grade D–G dengan interest rate 20–25% terdiri dari 223 loans (25% dari cohort 2013), dengan portfolio OS $4.96M dan TKB30 93.78%. Segmen ini menyumbang $308.13K atau 48.06% dari total OS >30 hari cohort 2013.



-- 15. Risk Segment Contribution by Grade

WITH cohort_2013 AS (
  SELECT
    grade
    , funded_amount
    , loan_status
  FROM fip-finance-analysis.fip_finance.loan_clean
  WHERE loan_status IN (
    'Current'
    , 'In Grace Period'
    , 'Late (16-30 days)'
    , 'Late (31-120 days)'
    , 'Default'
  )
  AND issue_year = 2013
  AND grade IN ('D', 'E', 'F', 'G')
  AND int_rate >= 0.20
  AND int_rate < 0.25
),

grade_summary AS (
  SELECT
    grade
    , COUNT(*) AS loan_count
    , SUM(funded_amount) AS portfolio_os
    , SUM(
        CASE
          WHEN loan_status = 'Late (31-120 days)'
          THEN funded_amount
          ELSE 0
        END
      ) AS os_over_30_days
  FROM cohort_2013
  GROUP BY grade
)

SELECT
  grade
  , loan_count
  , portfolio_os
  , os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            os_over_30_days
            , portfolio_os
          )
      ) * 100
      , 2
    ) AS tkb30
  , ROUND(
      SAFE_DIVIDE(
        os_over_30_days
        , SUM(os_over_30_days) OVER ()
      ) * 100
      , 2
    ) AS pct_of_segment_os_over_30_days
  , RANK() OVER (
      ORDER BY os_over_30_days DESC
    ) AS risk_rank
FROM grade_summary
ORDER BY risk_rank;

-- Finding: Within the 20–25% interest-rate risk segment, Grade E is the largest contributor to OS >30 days, accounting for 61.83% of the segment's delinquent exposure, with TKB30 of 93.65%.



-- 16. Root Cause Synthesis
-- The weaker TKB30 performance of the 2013 cohort is primarily associated with the concentration of loans in the 20–25% interest-rate segment, particularly Grade E, which contributes 61.83% of OS over 30 days within the identified risk segment and 48.06% of the cohort's total OS over 30 days.



-- 16a. Risk Segment TKB30 Across Cohorts

WITH risk_segment AS (
  SELECT
    issue_year
    , grade
    , funded_amount
    , loan_status
  FROM fip-finance-analysis.fip_finance.loan_clean
  WHERE loan_status IN (
    'Current'
    , 'In Grace Period'
    , 'Late (16-30 days)'
    , 'Late (31-120 days)'
    , 'Default'
  )
  AND grade = 'E'
  AND int_rate >= 0.20
  AND int_rate < 0.25
),

cohort_summary AS (
  SELECT
    issue_year
    , COUNT(*) AS loan_count
    , SUM(funded_amount) AS portfolio_os
    , SUM(
        CASE
          WHEN loan_status = 'Late (31-120 days)'
          THEN funded_amount
          ELSE 0
        END
      ) AS os_over_30_days
  FROM risk_segment
  GROUP BY issue_year
)

SELECT
  issue_year
  , loan_count
  , portfolio_os
  , os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            os_over_30_days
            , portfolio_os
          )
      ) * 100
      , 2
    ) AS tkb30
  , ROUND(
      SAFE_DIVIDE(
        os_over_30_days
        , SUM(os_over_30_days) OVER ()
      ) * 100
      , 2
    ) AS pct_of_total_segment_os_over_30_days
  , RANK() OVER (
      ORDER BY
        (
          1
          - SAFE_DIVIDE(
              os_over_30_days
              , portfolio_os
            )
        ) ASC
    ) AS risk_rank
FROM cohort_summary
ORDER BY issue_year;

-- Finding: The Grade E + 20–25% interest-rate segment is not unique to the 2013 cohort. Although the segment contributes materially to 2013's delinquent exposure, its TKB30 is higher than the same segment in 2014, 2016, and 2017. Therefore, this segment alone cannot be considered a specific root cause of the 2013 cohort's weaker TKB30.



-- 16b. Grade Composition Across Cohorts

WITH cohort_grade AS (
  SELECT
    issue_year
    , grade
    , COUNT(*) AS loan_count
    , SUM(funded_amount) AS portfolio_os
    , SUM(
        CASE
          WHEN loan_status = 'Late (31-120 days)'
          THEN funded_amount
          ELSE 0
        END
      ) AS os_over_30_days
  FROM fip-finance-analysis.fip_finance.loan_clean
  WHERE loan_status IN (
    'Current'
    , 'In Grace Period'
    , 'Late (16-30 days)'
    , 'Late (31-120 days)'
    , 'Default'
  )
  GROUP BY issue_year , grade
),

grade_composition AS (
  SELECT
    issue_year
    , grade
    , loan_count
    , portfolio_os
    , os_over_30_days
    , ROUND(
        SAFE_DIVIDE(
          loan_count
          , SUM(loan_count) OVER (
              PARTITION BY issue_year
            )
        ) * 100
        , 2
      ) AS pct_of_cohort_loans
  FROM cohort_grade
)

SELECT
  issue_year
  , grade
  , loan_count
  , pct_of_cohort_loans
  , portfolio_os
  , os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            os_over_30_days
            , portfolio_os
          )
      ) * 100
      , 2
    ) AS tkb30
FROM grade_composition
ORDER BY issue_year, grade;

-- Finding: The 2013 cohort has a relatively high share of lower-grade loans (D–G = 42.38%), but grade composition alone does not explain its weaker TKB30, as the 2012 cohort had an even higher D–G share (57.48%) while maintaining a higher TKB30 of 97.35%.



-- 17. Loan Status Composition Across Cohorts

WITH cohort_status AS (
  SELECT
    issue_year
    , loan_status
    , COUNT(*) AS loan_count
    , SUM(funded_amount) AS portfolio_os
  FROM fip-finance-analysis.fip_finance.loan_clean
  WHERE loan_status IN (
    'Current'
    , 'In Grace Period'
    , 'Late (16-30 days)'
    , 'Late (31-120 days)'
    , 'Default'
  )
  GROUP BY issue_year, loan_status
)

SELECT
  issue_year
  , loan_status
  , loan_count
  , portfolio_os
  , ROUND(
      SAFE_DIVIDE(
        loan_count
        , SUM(loan_count) OVER (
            PARTITION BY issue_year
          )
      ) * 100
      , 2
    ) AS pct_of_cohort_loans
  , ROUND(
      SAFE_DIVIDE(
        portfolio_os
        , SUM(portfolio_os) OVER (
            PARTITION BY issue_year
          )
      ) * 100
      , 2
    ) AS pct_of_cohort_os
FROM cohort_status
ORDER BY issue_year, loan_status;

-- Finding: The weaker TKB30 in 2013 may be related not only to the number of delinquent loans, but also to the relatively larger exposure attached to those delinquent loans.



-- 18. Average Loan Size by Loan Status Across Cohorts

WITH status_summary AS (
  SELECT
    issue_year
    , loan_status
    , COUNT(*) AS loan_count
    , SUM(funded_amount) AS portfolio_os
    , ROUND(
        AVG(funded_amount)
        , 2
      ) AS avg_loan_amount
    , MIN(funded_amount) AS min_loan_amount
    , MAX(funded_amount) AS max_loan_amount
  FROM fip-finance-analysis.fip_finance.loan_clean
  WHERE loan_status IN (
    'Current'
    , 'Late (31-120 days)'
  )
  GROUP BY issue_year, loan_status
)

SELECT
  issue_year
  , loan_status
  , loan_count
  , portfolio_os
  , avg_loan_amount
  , min_loan_amount
  , max_loan_amount
  , RANK() OVER (
      PARTITION BY loan_status
      ORDER BY avg_loan_amount DESC
    ) AS avg_loan_size_rank
FROM status_summary
ORDER BY issue_year, loan_status;

-- Finding: Cohort 2013 had the highest average loan amount among loans delinquent for 31–120 days, at $20.68K. However, this was only 1.4% higher than the cohort's average Current loan size, suggesting that loan size alone is unlikely to fully explain the weaker TKB30.



-- 19. Grade × Loan Amount Interaction - Cohort 2013

WITH loan_segment AS (
  SELECT
    grade
    , funded_amount
    , loan_status
    , CASE
        WHEN funded_amount < 10000 THEN '<$10K'
        WHEN funded_amount < 20000 THEN '$10K-$20K'
        WHEN funded_amount < 30000 THEN '$20K-$30K'
        WHEN funded_amount < 40000 THEN '$30K-$40K'
        ELSE '>=$40K'
      END AS loan_amount_band
  FROM fip-finance-analysis.fip_finance.loan_clean
  WHERE issue_year = 2013
  AND loan_status IN (
    'Current'
    , 'In Grace Period'
    , 'Late (16-30 days)'
    , 'Late (31-120 days)'
    , 'Default'
  )
  AND grade IN ('D', 'E', 'F', 'G')
),

segment_summary AS (
  SELECT
    grade
    , loan_amount_band
    , COUNT(*) AS loan_count
    , SUM(funded_amount) AS portfolio_os
    , SUM(
        CASE
          WHEN loan_status = 'Late (31-120 days)'
          THEN funded_amount
          ELSE 0
        END
      ) AS os_over_30_days
  FROM loan_segment
  GROUP BY grade, loan_amount_band
)

SELECT
  grade
  , loan_amount_band
  , loan_count
  , portfolio_os
  , os_over_30_days
  , ROUND(
      (
        1
        - SAFE_DIVIDE(
            os_over_30_days
            , portfolio_os
          )
      ) * 100
      , 2
    ) AS tkb30
  , ROUND(
      SAFE_DIVIDE(
        loan_count
        , SUM(loan_count) OVER (
            PARTITION BY grade
          )
      ) * 100
      , 2
    ) AS pct_of_grade_loans
FROM segment_summary
ORDER BY grade,loan_amount_band;

-- Finding: Within the 2013 cohort, larger loan amounts are associated with weaker TKB30 among Grade E and F loans. Grade E shows a clear decline in TKB30 from 95.77% for $10–20K loans to 92.19% for $30–40K loans, while OS >30 days increases from $30.8K to $90K.



-- 20. Root Cause & Key Findings Synthesis

-- 3 Key Insights:

-- Insight 01 — 2013 is a weaker performing cohort
-- TKB30 96.49% with $641.15K OS >30 days, indicating relatively weaker repayment quality.

-- Insight 02 — Risk exposure is concentrated in lower-grade, larger loans
-- Within Grade E and F, larger loan amounts show weaker TKB30 and higher delinquent exposure.
-- Grade E $30–40K:
-- TKB30 92.19% | OS >30d $90K

-- Insight 03 — Customer-level risk profiling is constrained by data linkage
-- Only 0.11% of 2013 loans could be linked to customer records, preventing reliable demographic-level risk analysis.



-- Recommendation:

-- Recommendation 1 — Strengthen risk-based underwriting
-- Evidence:
-- Grade E/F + larger loan amount show weaker TKB30.
-- Action:
-- Apply stricter underwriting thresholds for lower-grade borrowers requesting larger loan amounts, including additional affordability and repayment-capacity checks.

-- Recommendation 2 — Introduce exposure-based risk monitoring

-- Recommendation 3 — Improve customer-loan data integration

-- The analysis identifies concentration of repayment risk in larger exposures within lower-grade segments, while customer-level profiling remains constrained by incomplete customer-loan linkage.



-- Final Findings:
-- Finding 1 — Cohort 2013 recorded a relatively weaker funding quality, with TKB30 of 96.49% and $641.15K in OS over 30 days.
-- Finding 2 — The 20–25% interest-rate segment among Grade D–G loans accounts for 48.06% of cohort 2013's OS over 30 days, making it a material risk concentration.
-- Finding 3 — Within the identified 20–25% interest-rate risk segment, Grade E contributes the largest share of OS over 30 days at 61.83%.
-- Finding 4 — Within Grade E and F, larger loan amounts are associated with weaker TKB30 and higher delinquent exposure, with Grade E loans of $30–40K showing TKB30 of 92.19% and $90K in OS over 30 days.

-- Data Limitation:
-- Customer-level risk profiling is constrained by extremely low customer-loan linkage, with only 0.11% of cohort 2013 loans successfully matched to customer records.

-- Final Recommendation:
-- Recommendation 1 — Strengthen risk-based underwriting
-- Recommendation 2 — Prioritize exposure-based monitoring
-- Recommendation 3 — Early intervention for delinquency
-- Recommendation 4 — Improve customer-loan data integration
