
# SQL Portfolio Project: Diabetes Hospital Readmission Analysis

**Project Type:** Healthcare Data Analytics  
**Difficulty:** Beginner to Intermediate  
**Database:** `healthcare_ds`  
**Table:** `diabetes_130_raw`  
**SQL Dialect:** MySQL  
**Primary Focus:** Data exploration, data cleaning, aggregation, joins, CTEs, subqueries, window functions, and healthcare outcome analysis.

---

## 1. Project Description

### Background

Hospital readmissions are an important healthcare quality measure. Understanding the patterns associated with readmission can help healthcare organizations identify populations that may benefit from additional follow-up care.

In this project, we analyzed a diabetes hospital encounter dataset using SQL. We explored patient demographics, hospital stays, admission types, diabetes medication use, and readmission outcomes.

We used SQL to clean and summarize data, calculate readmission rates, compare patient groups, and identify patterns that warrant further investigation.

### Problem Statement

The healthcare organization wanted to understand the characteristics of hospital encounters associated with readmission among patients with diabetes.

The goal was to use SQL to answer business questions about readmission outcomes and produce a summary that can support further healthcare quality analysis.

### Project Objectives

1. Understand the structure and quality of the dataset.
2. Explore patient demographics, including age, race, and gender.
3. Analyze hospital encounters and length of stay.
4. Calculate readmission rates within 30 days and after 30 days.
5. Compare readmission outcomes across patient and encounter categories.
6. Identify groups with readmission rates above the overall average.
7. Apply intermediate SQL techniques to produce a final analytical report.

### Dataset Overview

The `diabetes_130_raw` dataset is commonly associated with the Diabetes 130-US Hospitals dataset. It contains hospital encounter information for patients with diabetes.

Potentially useful columns include:

| Column | Description |
|---|---|
| `encounter_id` | Identifier for a hospital encounter |
| `patient_nbr` | Patient identifier |
| `race` | Recorded race category |
| `gender` | Recorded gender |
| `age` | Age category |
| `admission_type_id` | Coded admission type |
| `time_in_hospital` | Number of days spent in the hospital |
| `num_lab_procedures` | Number of laboratory procedures |
| `num_procedures` | Number of non-laboratory procedures |
| `num_medications` | Number of medications |
| `diabetesMed` | Whether diabetes medication was prescribed or administered as recorded |
| `readmitted` | Readmission outcome category |

Confirm the actual column names and definitions in your table before running the analysis.

### Important Definitions

- **Hospital encounter:** A hospital visit or admission recorded in the dataset.
- **Readmission within 30 days:** An encounter with `readmitted = '<30'`.
- **Readmission after 30 days:** An encounter with `readmitted = '>30'`.
- **No recorded readmission:** An encounter with `readmitted = 'NO'`.
- **Readmission rate within 30 days:** The number of encounters categorized as readmitted within 30 days divided by the total number of encounters in the group, multiplied by 100.

For this project, we will calculate the 30-day readmission rate separately from the rate for all recorded readmissions.

---

# Part 1: Database Setup and Data Exploration

## Query 1: Select the Database

**Objective:** Select the database that contains the healthcare dataset.

```sql
USE healthcare_ds;
```

**Explanation:** The `USE` statement sets the database context for subsequent queries.

## Query 2: Retrieve the Dataset

**Objective:** Inspect the dataset and understand how the records are structured.

```sql
SELECT *
FROM diabetes_130_raw
LIMIT 10;
```

**Explanation:**
- `SELECT *` retrieves all columns.
- `FROM` specifies the source table.
- `LIMIT 10` displays only ten records.

Inspect the values, column names, and general structure before beginning the analysis.

## Query 3: Count Total Hospital Encounters

**Business Question:** How many hospital encounters are recorded in the dataset?

```sql
SELECT COUNT(*) AS total_encounters
FROM diabetes_130_raw;
```

**Explanation:** `COUNT(*)` counts all rows in the table.

**SQL Concepts:** `SELECT`, `COUNT()`, `AS`.

## Query 4: List All Columns and Data Types

**Objective:** Identify the columns available for analysis.

```sql
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'healthcare_ds'
  AND TABLE_NAME = 'diabetes_130_raw'
ORDER BY ORDINAL_POSITION;
```

**Explanation:** `INFORMATION_SCHEMA.COLUMNS` contains metadata about database columns. `ORDINAL_POSITION` preserves the columns' original order.

**SQL Concepts:** Metadata queries, filtering, sorting.

## Query 5: Explore Unique Race Categories

**Business Question:** What race categories are present in the dataset?

```sql
SELECT DISTINCT race
FROM diabetes_130_raw
ORDER BY race;
```

**Explanation:** `DISTINCT` returns unique values. This helps identify categories and potential inconsistencies.

**SQL Concepts:** `DISTINCT`, `ORDER BY`.

## Query 6: Examine Readmission Categories

**Business Question:** How many encounters fall into each readmission category?

```sql
SELECT
    readmitted,
    COUNT(*) AS total_encounters
FROM diabetes_130_raw
GROUP BY readmitted
ORDER BY total_encounters DESC;
```

**Explanation:** `GROUP BY` creates a group for each readmission category, while `COUNT(*)` counts encounters in each group.

**SQL Concepts:** `GROUP BY`, aggregation, `ORDER BY`.

---

# Part 2: Data Quality and Cleaning

## Query 7: Check Missing Values

**Objective:** Identify missing values in important analytical columns.

```sql
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN race IS NULL
        THEN 1 ELSE 0 END) AS missing_race,
    SUM(CASE WHEN age IS NULL
        THEN 1 ELSE 0 END) AS missing_age,
    SUM(CASE WHEN gender IS NULL
        THEN 1 ELSE 0 END) AS missing_gender,
    SUM(CASE WHEN readmitted IS NULL
        THEN 1 ELSE 0 END) AS missing_readmitted
FROM diabetes_130_raw;
```

**Explanation:** Each `CASE WHEN` expression assigns 1 to missing values and 0 to nonmissing values. `SUM()` calculates the total number of missing values for each column.

**SQL Concepts:** `CASE WHEN`, `SUM()`, conditional aggregation.

**Important:** Some datasets represent missing categorical values using strings such as `'?'`. Check for those separately, for example:

```sql
SELECT COUNT(*) AS unknown_race
FROM diabetes_130_raw
WHERE race = '?';
```

Do not assume that a value is missing simply because it belongs to an `Other` category.

## Query 8: Check Duplicate Encounter Identifiers

**Objective:** Determine whether any encounter identifiers occur more than once.

```sql
SELECT
    encounter_id,
    COUNT(*) AS record_count
FROM diabetes_130_raw
GROUP BY encounter_id
HAVING COUNT(*) > 1;
```

**Explanation:** The query groups records by encounter identifier and returns identifiers appearing more than once.

**SQL Concepts:** `GROUP BY`, `HAVING`, `COUNT()`.

Repeated encounters for the same patient are not necessarily duplicates. The `patient_nbr` column may legitimately appear multiple times because a patient can have multiple hospital encounters.

---

# Part 3: Patient Demographics

## Query 9: Count Encounters by Age Category

**Business Question:** Which age categories account for the most encounters?

```sql
SELECT
    age,
    COUNT(*) AS total_encounters
FROM diabetes_130_raw
GROUP BY age
ORDER BY total_encounters DESC;
```

**Explanation:** This query counts hospital encounters within each age category and sorts the categories from most frequent to least frequent.

**SQL Concepts:** `GROUP BY`, `COUNT()`, `ORDER BY`.

## Query 10: Count Encounters by Race

**Business Question:** How are hospital encounters distributed across recorded race categories?

```sql
SELECT
    race,
    COUNT(*) AS total_encounters
FROM diabetes_130_raw
GROUP BY race
ORDER BY total_encounters DESC;
```

**Explanation:** This query summarizes encounters by race. It provides a demographic overview but does not establish differences in healthcare quality or individual risk.

## Query 11: Find Race Categories with More Than 1,000 Encounters

**Objective:** Practice filtering aggregated groups.

```sql
SELECT
    race,
    COUNT(*) AS total_encounters
FROM diabetes_130_raw
GROUP BY race
HAVING COUNT(*) > 1000
ORDER BY total_encounters DESC;
```

**Explanation:**
- `GROUP BY race` groups the records by race.
- `HAVING COUNT(*) > 1000` keeps only groups with more than 1,000 encounters.
- `ORDER BY` sorts the remaining groups.

**SQL Concepts:** `GROUP BY`, `HAVING`, aggregation.

**Key distinction:** `WHERE` filters individual rows before grouping, while `HAVING` filters groups after aggregation.

---

# Part 4: Hospital Stay Analysis

## Query 12: Calculate Average, Minimum, and Maximum Hospital Stay

**Business Question:** How long do patients typically stay in the hospital?

```sql
SELECT
    AVG(time_in_hospital) AS average_stay,
    MIN(time_in_hospital) AS minimum_stay,
    MAX(time_in_hospital) AS maximum_stay
FROM diabetes_130_raw;
```

**Explanation:**
- `AVG()` calculates the mean hospital stay.
- `MIN()` identifies the minimum recorded stay.
- `MAX()` identifies the maximum recorded stay.

These functions ignore `NULL` values in the specified column.

**SQL Concepts:** Aggregate functions.

## Query 13: Categorize Hospital Stays

**Objective:** Divide encounters into short, medium, and long stays.

For this project, define:
- Short stay: 1–3 days.
- Medium stay: 4–7 days.
- Long stay: 8 or more days.

```sql
SELECT
    CASE
        WHEN time_in_hospital BETWEEN 1 AND 3
            THEN 'Short'
        WHEN time_in_hospital BETWEEN 4 AND 7
            THEN 'Medium'
        WHEN time_in_hospital >= 8
            THEN 'Long'
        ELSE 'Unknown'
    END AS stay_category,
    COUNT(*) AS total_encounters,
    AVG(time_in_hospital) AS average_stay
FROM diabetes_130_raw
GROUP BY
    CASE
        WHEN time_in_hospital BETWEEN 1 AND 3
            THEN 'Short'
        WHEN time_in_hospital BETWEEN 4 AND 7
            THEN 'Medium'
        WHEN time_in_hospital >= 8
            THEN 'Long'
        ELSE 'Unknown'
    END
ORDER BY average_stay;
```

**Explanation:** `CASE WHEN` creates a new categorical variable based on hospital stay length. The query then summarizes each category.

**SQL Concepts:** `CASE WHEN`, `GROUP BY`, `AVG()`.

---

# Part 5: Readmission Analysis

## Query 14: Count Each Readmission Outcome

**Business Question:** How many encounters resulted in readmission within 30 days, after 30 days, or no recorded readmission?

```sql
SELECT
    readmitted,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM diabetes_130_raw),
        2
    ) AS percentage_of_encounters
FROM diabetes_130_raw
GROUP BY readmitted
ORDER BY total_encounters DESC;
```

**Explanation:** The subquery calculates the total number of encounters. The outer query calculates the percentage belonging to each readmission category.

**SQL Concepts:** Subqueries, `GROUP BY`, `ROUND()`, percentage calculations.

## Query 15: Calculate the Overall 30-Day Readmission Rate

**Business Question:** What percentage of encounters are categorized as readmitted within 30 days?

```sql
SELECT
    COUNT(*) AS total_encounters,
    SUM(CASE
        WHEN readmitted = '<30' THEN 1
        ELSE 0
    END) AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS readmission_rate_30_day_pct
FROM diabetes_130_raw;
```

**Explanation:** The conditional `SUM()` counts only encounters with `readmitted = '<30'`. Dividing this count by all encounters produces the overall 30-day readmission percentage.

**SQL Concepts:** Conditional aggregation, `CASE WHEN`, `SUM()`, `ROUND()`.

## Query 16: Compare 30-Day Readmission Rates by Age

**Business Question:** Which age categories have the highest recorded 30-day readmission rates?

```sql
SELECT
    age,
    COUNT(*) AS total_encounters,
    SUM(CASE
        WHEN readmitted = '<30' THEN 1
        ELSE 0
    END) AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS readmission_rate_30_day_pct
FROM diabetes_130_raw
GROUP BY age
ORDER BY readmission_rate_30_day_pct DESC;
```

**Explanation:** The query calculates a separate 30-day readmission rate for each age category and sorts the categories by rate.

**SQL Concepts:** Conditional aggregation, `GROUP BY`, sorting.

**Interpretation:** Compare both the readmission rate and the number of encounters in each group. A high rate calculated from a small number of encounters may be less stable.

## Query 17: Compare Readmission Rates by Race

**Business Question:** Do recorded 30-day readmission rates differ across race categories?

```sql
SELECT
    race,
    COUNT(*) AS total_encounters,
    SUM(CASE
        WHEN readmitted = '<30' THEN 1
        ELSE 0
    END) AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS readmission_rate_30_day_pct
FROM diabetes_130_raw
GROUP BY race
ORDER BY readmission_rate_30_day_pct DESC;
```

**Explanation:** This query compares readmission outcomes across demographic categories. The results should be interpreted cautiously because demographic differences can reflect many underlying factors, including health status, access to care, and differences in encounter composition.

## Query 18: Compare Readmission Rates by Hospital Stay Category

**Business Question:** Are short, medium, and long hospital stays associated with different 30-day readmission rates?

```sql
WITH stay_stats AS (
    SELECT
        CASE
            WHEN time_in_hospital BETWEEN 1 AND 3
                THEN 'Short'
            WHEN time_in_hospital BETWEEN 4 AND 7
                THEN 'Medium'
            WHEN time_in_hospital >= 8
                THEN 'Long'
            ELSE 'Unknown'
        END AS stay_category,
        COUNT(*) AS total_encounters,
        SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) AS readmitted_30_days
    FROM diabetes_130_raw
    GROUP BY
        CASE
            WHEN time_in_hospital BETWEEN 1 AND 3
                THEN 'Short'
            WHEN time_in_hospital BETWEEN 4 AND 7
                THEN 'Medium'
            WHEN time_in_hospital >= 8
                THEN 'Long'
            ELSE 'Unknown'
        END
)
SELECT
    stay_category,
    total_encounters,
    readmitted_30_days,
    ROUND(
        100.0 * readmitted_30_days / total_encounters,
        2
    ) AS readmission_rate_30_day_pct
FROM stay_stats
ORDER BY readmission_rate_30_day_pct DESC;
```

**Explanation:** The CTE calculates summary statistics by stay category. The outer query calculates and sorts the resulting readmission rates.

**SQL Concepts:** CTEs, `CASE WHEN`, conditional aggregation.

---

# Part 6: Subqueries and CTEs

## Query 19: Find Age Categories Above the Overall Readmission Rate

**Business Question:** Which age categories have 30-day readmission rates higher than the overall rate?

```sql
WITH age_stats AS (
    SELECT
        age,
        COUNT(*) AS total_encounters,
        SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) AS readmitted_30_days
    FROM diabetes_130_raw
    GROUP BY age
),
overall_stats AS (
    SELECT
        100.0 * SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) / COUNT(*) AS overall_rate
    FROM diabetes_130_raw
)
SELECT
    a.age,
    a.total_encounters,
    ROUND(
        100.0 * a.readmitted_30_days /
        a.total_encounters,
        2
    ) AS age_readmission_rate_pct,
    ROUND(o.overall_rate, 2) AS overall_rate_pct
FROM age_stats a
CROSS JOIN overall_stats o
WHERE
    100.0 * a.readmitted_30_days /
    a.total_encounters > o.overall_rate
ORDER BY age_readmission_rate_pct DESC;
```

**Explanation:**
1. `age_stats` calculates encounters and readmissions by age.
2. `overall_stats` calculates the overall 30-day readmission rate.
3. `CROSS JOIN` makes the single overall-rate result available to every age group.
4. `WHERE` filters the groups to those above the benchmark.

**SQL Concepts:** Multiple CTEs, `CROSS JOIN`, calculated metrics, filtering.

## Query 20: Find Admission Types Above the Overall Readmission Rate

**Business Question:** Which admission types have 30-day readmission rates above the overall rate?

```sql
SELECT
    admission_type_id,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY admission_type_id
HAVING
    SUM(CASE
        WHEN readmitted = '<30' THEN 1
        ELSE 0
    END) * 1.0 / COUNT(*)
    >
    (
        SELECT
            SUM(CASE
                WHEN readmitted = '<30' THEN 1
                ELSE 0
            END) * 1.0 / COUNT(*)
        FROM diabetes_130_raw
    )
ORDER BY readmission_rate_pct DESC;
```

**Explanation:** The subquery calculates the overall readmission proportion. `HAVING` retains only admission types with a greater proportion.

**SQL Concepts:** Subqueries, `HAVING`, conditional aggregation.

**Important:** Admission type IDs are coded categories. Consult the dataset's codebook before assigning descriptive labels to the IDs.

---

# Part 7: Window Functions

## Query 21: Rank Race Categories by Readmission Rate

**Business Question:** How do race categories rank according to their recorded 30-day readmission rates?

```sql
WITH race_stats AS (
    SELECT
        race,
        COUNT(*) AS total_encounters,
        SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) AS readmitted_30_days
    FROM diabetes_130_raw
    GROUP BY race
)
SELECT
    race,
    total_encounters,
    ROUND(
        100.0 * readmitted_30_days /
        total_encounters,
        2
    ) AS readmission_rate_pct,
    RANK() OVER (
        ORDER BY
            readmitted_30_days * 1.0 /
            total_encounters DESC
    ) AS readmission_rank
FROM race_stats
ORDER BY readmission_rank;
```

**Explanation:** `RANK()` assigns the same rank to categories with tied rates and skips the subsequent rank where ties occur.

**SQL Concepts:** CTEs, `RANK()`, window functions.

## Query 22: Compare Readmission Rates with the Previous Age Category

**Business Question:** How does each age category's readmission rate compare with the previous category in the sorted sequence?

```sql
WITH age_stats AS (
    SELECT
        age,
        COUNT(*) AS total_encounters,
        SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) * 1.0 / COUNT(*) AS readmission_rate
    FROM diabetes_130_raw
    GROUP BY age
)
SELECT
    age,
    total_encounters,
    ROUND(readmission_rate * 100, 2)
        AS readmission_rate_pct,
    ROUND(
        LAG(readmission_rate * 100)
        OVER (ORDER BY age),
        2
    ) AS previous_category_rate_pct
FROM age_stats
ORDER BY age;
```

**Explanation:** `LAG()` retrieves the rate from the previous row. The first row has no previous value and therefore returns `NULL`.

**SQL Concepts:** CTEs, `LAG()`, `OVER()`, window functions.

**Caution:** Age is a categorical variable in this dataset. The previous row refers to the previous age label in alphabetical order, not necessarily the next youngest age category. For meaningful age comparisons, define an explicit age-category ordering.

---

# Part 8: JOINs

## Query 23: Compare Each Encounter with Its Age Category's Readmission Rate

**Business Question:** What is the readmission rate for the age category associated with each encounter?

```sql
WITH age_stats AS (
    SELECT
        age,
        COUNT(*) AS age_total_encounters,
        SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) * 1.0 / COUNT(*) AS age_readmission_rate
    FROM diabetes_130_raw
    GROUP BY age
)
SELECT
    d.encounter_id,
    d.age,
    d.readmitted,
    s.age_total_encounters,
    ROUND(
        s.age_readmission_rate * 100,
        2
    ) AS age_readmission_rate_pct
FROM diabetes_130_raw d
INNER JOIN age_stats s
    ON d.age = s.age
LIMIT 100;
```

**Explanation:**
- `d` represents the original encounter table.
- `s` represents the age-level summary.
- `INNER JOIN` matches each encounter to its age-level statistics.

**SQL Concepts:** `INNER JOIN`, aliases, CTEs.

**Important:** This is an illustrative join within one dataset. A separate patient or hospital reference table would provide an opportunity to practice joins between independent tables.

---

# Part 9: Medication Use and Readmission

## Query 24: Compare Readmission Outcomes by Diabetes Medication Use

**Business Question:** Do encounters for which diabetes medication was recorded as used have different readmission rates from encounters for which it was not used?

```sql
SELECT
    diabetesMed,
    COUNT(*) AS total_encounters,
    SUM(CASE
        WHEN readmitted = '<30' THEN 1
        ELSE 0
    END) AS readmitted_30_days,
    ROUND(
        100.0 * SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS readmission_rate_30_day_pct
FROM diabetes_130_raw
GROUP BY diabetesMed
ORDER BY readmission_rate_30_day_pct DESC;
```

**Explanation:** The query groups encounters by the diabetes medication indicator and calculates the 30-day readmission rate for each group.

**SQL Concepts:** `GROUP BY`, conditional aggregation, percentages.

**Interpretation:** Medication status may be associated with disease severity, treatment decisions, and other factors. This analysis cannot establish whether medication use causes higher or lower readmission rates.

---

# Part 10: Final Analytical Summary

## Query 25: Create a Readmission Summary by Age and Gender

**Business Question:** What are the encounter counts, readmission outcomes, and average hospital stays for each age and gender group?

```sql
SELECT
    age,
    gender,
    COUNT(*) AS total_encounters,

    SUM(CASE
        WHEN readmitted = '<30' THEN 1
        ELSE 0
    END) AS readmitted_within_30_days,

    SUM(CASE
        WHEN readmitted = '>30' THEN 1
        ELSE 0
    END) AS readmitted_after_30_days,

    SUM(CASE
        WHEN readmitted = 'NO' THEN 1
        ELSE 0
    END) AS no_recorded_readmission,

    ROUND(
        100.0 * SUM(CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS readmission_rate_30_day_pct,

    ROUND(
        AVG(time_in_hospital),
        2
    ) AS average_hospital_stay

FROM diabetes_130_raw
GROUP BY age, gender
ORDER BY readmission_rate_30_day_pct DESC;
```

**Explanation:** This query combines grouping, conditional aggregation, percentages, and averages into a final summary table. The result can be exported to a spreadsheet or connected to a dashboard.

---

# Part 11: Expected Project Deliverables

After running the queries, prepare the following deliverables.

### Deliverable 1: SQL Script

Save all queries in one `.sql` file, organized into sections for:
- Data exploration
- Data quality
- Demographics
- Hospital stays
- Readmission analysis
- CTEs and subqueries
- Window functions
- Joins
- Final summary

### Deliverable 2: Findings Report

Write three to five findings supported by your actual query results. For example:

- Which age category accounts for the most encounters?
- Which category has the highest 30-day readmission rate?
- How do readmission rates vary by length of stay?
- Which admission types exceed the overall rate?
- Are medication-use categories associated with different outcomes?

Do not write findings until you have executed the queries and verified the results.

### Deliverable 3: Summary Dashboard

Create a table or dashboard displaying:
- Total encounters
- Overall 30-day readmission rate
- Readmission rate by age category
- Readmission rate by race category
- Readmission rate by length of stay
- Readmission rate by admission type
- Average hospital stay

### Deliverable 4: Limitations

Document the following limitations:

1. Multiple encounters may belong to the same patient.
2. Missing or unknown values may affect the analysis.
3. Demographic and treatment comparisons are observational.
4. Some groups may have small sample sizes.
5. A high group-level readmission rate is not an individual risk prediction.
6. The dataset's encounter and readmission definitions should be checked against its codebook.

---

# Part 12: SQL Skills Practiced

| SQL topic | Where you practiced it |
|---|---|
| `SELECT`, `FROM`, `LIMIT` | Queries 1–3 |
| `DISTINCT` | Query 5 |
| `GROUP BY` | Queries 6–25 |
| `HAVING` | Queries 8, 11, 20 |
| `ORDER BY` | Throughout the project |
| Aggregate functions | Queries 3, 6, 9, 12 |
| `CASE WHEN` | Queries 7, 13–25 |
| `IS NULL` | Query 7 |
| Subqueries | Queries 14, 19, 20 |
| CTEs | Queries 18, 19, 21–23 |
| `CROSS JOIN` | Query 19 |
| `INNER JOIN` | Query 23 |
| Window functions | Queries 21–22 |
| `RANK()` | Query 21 |
| `LAG()` | Query 22 |
| Conditional aggregation | Queries 7, 15–25 |
| Calculated metrics | Queries 14–25 |

---

## Final Conclusion

This project demonstrates how intermediate SQL can be used to explore healthcare data, evaluate readmission patterns, and build an analytical summary.

The most important skills to master are `GROUP BY`, `HAVING`, conditional aggregation, CTEs, subqueries, joins, and window functions. These skills are transferable to many data analyst and data scientist roles beyond healthcare.


