# Finance Portfolio & Risk Analysis

## Project Overview

This project analyzes a lending portfolio to assess portfolio health, identify risk concentrations, and understand loan characteristics associated with weaker repayment performance.

The analysis focuses on cohort performance, delinquent exposure, and loan-level risk characteristics to support data-driven lending and risk management decisions.

---

## Business Problem

How can RevoFin identify portfolio risk patterns and understand the loan characteristics associated with weaker repayment performance?

---

## Objectives

- Assess overall loan portfolio health and repayment quality.
- Identify cohorts with relatively weaker performance.
- Detect risk segments contributing disproportionately to delinquent exposure.
- Analyze how loan grade, interest rate, and loan amount relate to repayment performance.
- Translate findings into actionable lending and risk management recommendations.

---

## Data & Scope

The analysis uses six datasets providing complementary views of customers, loans, loan purposes, and regions:

- `customer.csv` — Customer profile
- `loan.csv` — Core loan and risk analysis
- `loan_count_by_year.csv` — Temporal trend analysis
- `loan_purposes.csv` — Loan purpose analysis
- `loan_with_region.csv` — Regional analysis
- `state_regions.csv` — Regional reference

The `loan` dataset serves as the primary source for portfolio and risk analysis.

---

## Methodology

The analysis follows a structured approach:

**Data Understanding → Data Cleaning → Portfolio Analysis → Cohort Analysis → Risk Concentration Analysis → Loan Characteristic Analysis → Recommendations**

### 1. Data Preparation
- Standardized customer IDs across datasets.
- Validated table relationships and data quality.
- Identified limitations in customer–loan data linkage.

### 2. Portfolio Analysis
- Assessed portfolio outstanding exposure (OS).
- Evaluated loan status composition.
- Calculated TKB30 as a key portfolio quality indicator.

### 3. Cohort Analysis
- Compared TKB30 across loan cohorts.
- Identified relatively weaker-performing cohorts.
- Evaluated delinquent exposure across cohorts.

### 4. Risk Deep Dive
- Analyzed delinquent exposure across interest-rate segments.
- Examined risk concentration by loan grade.
- Evaluated the relationship between loan amount and TKB30.

### 5. Business Recommendations
- Developed risk-based monitoring strategies.
- Identified opportunities for early intervention.
- Proposed improvements to customer–loan data integration.

---

## Key Findings

### 1. 2013 Cohort Shows Relatively Weaker Performance

The 2013 cohort recorded the lowest TKB30 at **96.49%**, with **$641.15K in OS over 30 days** across **892 loans**.

This indicates a relatively weaker funding quality and meaningful delinquent exposure requiring deeper risk analysis.

### 2. Risk Exposure Is Concentrated in a Specific Segment

Loans with **20–25% interest rates and Grade D–G** accounted for **48.06% of cohort 2013's OS over 30 days**, making this a material risk concentration.

### 3. Grade E Has the Largest Delinquent Exposure

Within the identified 20–25% interest-rate segment, **Grade E contributed 61.83% of OS over 30 days**, making it the largest contributor to delinquent exposure.

### 4. Larger Loans Show Weaker Performance in Lower Grades

Within Grade E and F, TKB30 declined as loan amounts increased. The weakest performance was observed in the **$30K–$40K loan amount band**, particularly for Grade E and F.

---

## Business Recommendations

- Strengthen affordability and repayment-capacity assessment for higher-risk segments.
- Prioritize risk monitoring based on **Grade × Interest Rate × Loan Amount × Loan Status**.
- Introduce early intervention before loans migrate into more severe delinquency stages.
- Improve customer–loan data integration to enable more reliable customer-level risk profiling.

---

## Key Metrics

| Metric | 2013 Cohort |
|---|---:|
| Total Loans | 892 |
| Portfolio OS | $18.25M |
| OS >30 Days | $641.15K |
| TKB30 | 96.49% |
| Customer Match Rate | 0.11% |

---

## Dashboard

The interactive dashboard focuses on portfolio health and risk concentration, including:

- TKB30 by cohort
- Loan status composition
- OS over 30 days by cohort
- Delinquent exposure by interest-rate band
- Grade contribution within the identified risk segment
- TKB30 by grade and loan amount

![Finance Portfolio & Risk Dashboard](./dashboard/dashboard.png)
---

## Data Limitation

Customer–loan linkage was extremely limited, with only **0.11% of loans in the 2013 cohort successfully matched to customer records**.

Therefore, customer-level risk profiling was considered unreliable, and the final analysis prioritized **loan-level risk characteristics** such as grade, interest rate, loan amount, and loan status.

---

## Project Files

| File | Description |
|---|---|
| `analysis/` | SQL queries and analytical outputs |
| `dashboard/` | Tableau dashboard and preview |
| `presentation/` | Analytical report and presentation |

---

## Disclaimer

This project was developed for educational and portfolio purposes using a provided finance case study dataset. The analysis and recommendations are intended to demonstrate analytical thinking and should not be interpreted as actual financial or lending advice.
