 
-- ============================================================
-- PROJECT: Diabetes Hospital Readmission Analysis
-- DATABASE: healthcare_ds
-- TABLE: diabetes_130_raw
-- REQUIREMENT: MySQL 8.0+
--
-- Skills:
-- Data exploration, data quality, GROUP BY, CASE, subqueries,
-- CTEs, window functions, RANK, DENSE_RANK, ROW_NUMBER,
-- LAG, PARTITION BY, and analytical views.
--
-- Source data is not updated or deleted.
-- ============================================================


-- ============================================================
-- 1. DATABASE AND SCHEMA CHECKS
-- ============================================================

CREATE DATABASE IF NOT EXISTS healthcare_ds;
USE healthcare_ds;

-- Confirm that the source table exists.
SHOW TABLES LIKE 'diabetes_130_raw';

-- Inspect the source table's column names and data types.
DESCRIBE diabetes_130_raw;

-- Inspect the total number of columns.
SELECT
    COUNT(*) AS total_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'diabetes_130_raw';

-- Inspect the table's approximate storage information.
SELECT
    TABLE_NAME,
    TABLE_ROWS AS approximate_row_count,
    ENGINE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'diabetes_130_raw';


-- ============================================================
-- 2. BASIC DATA EXPLORATION
-- ============================================================

-- Preview the data.
SELECT *
FROM diabetes_130_raw
LIMIT 20;

-- Count all encounters.
SELECT COUNT(*) AS total_encounters
FROM diabetes_130_raw;

-- Count unique patients.
SELECT COUNT(DISTINCT patient_nbr) AS unique_patients
FROM diabetes_130_raw;

-- Explore the readmission categories.
SELECT
    readmitted,
    COUNT(*) AS encounters,
    ROUND(
        100.0 * COUNT(*) /
        NULLIF((SELECT COUNT(*) FROM diabetes_130_raw), 0),
        2
    ) AS percentage_of_encounters
FROM diabetes_130_raw
GROUP BY readmitted
ORDER BY encounters DESC;

-- Explore age groups.
SELECT
    age,
    COUNT(*) AS encounters
FROM diabetes_130_raw
GROUP BY age
ORDER BY age;

-- Explore gender.
SELECT
    gender,
    COUNT(*) AS encounters
FROM diabetes_130_raw
GROUP BY gender
ORDER BY encounters DESC;


-- ============================================================
-- 3. DATA QUALITY CHECKS
-- ============================================================

-- Check NULL values in important columns.
SELECT
    SUM(CASE WHEN encounter_id IS NULL THEN 1 ELSE 0 END)
        AS null_encounter_id,
    SUM(CASE WHEN patient_nbr IS NULL THEN 1 ELSE 0 END)
        AS null_patient_nbr,
    SUM(CASE WHEN readmitted IS NULL THEN 1 ELSE 0 END)
        AS null_readmitted,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END)
        AS null_age,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END)
        AS null_gender,
    SUM(CASE WHEN time_in_hospital IS NULL THEN 1 ELSE 0 END)
        AS null_hospital_stay,
    SUM(CASE WHEN num_medications IS NULL THEN 1 ELSE 0 END)
        AS null_num_medications
FROM diabetes_130_raw;

-- Identify duplicate encounter IDs.
SELECT
    encounter_id,
    COUNT(*) AS duplicate_count
FROM diabetes_130_raw
GROUP BY encounter_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Find patients with multiple encounters.
-- Multiple encounters for one patient are not necessarily duplicates.
SELECT
    patient_nbr,
    COUNT(*) AS encounter_count
FROM diabetes_130_raw
GROUP BY patient_nbr
HAVING COUNT(*) > 1
ORDER BY encounter_count DESC
LIMIT 20;

-- Check unexpected readmission categories.
SELECT
    readmitted,
    COUNT(*) AS encounters
FROM diabetes_130_raw
WHERE readmitted IS NULL
   OR readmitted NOT IN ('<30', '>30', 'NO')
GROUP BY readmitted;

-- Check hospital stay ranges.
SELECT
    MIN(time_in_hospital) AS minimum_stay,
    MAX(time_in_hospital) AS maximum_stay,
    ROUND(AVG(time_in_hospital), 2) AS average_stay
FROM diabetes_130_raw;

-- Find missing or invalid hospital stay durations.
SELECT *
FROM diabetes_130_raw
WHERE time_in_hospital IS NULL
   OR time_in_hospital <= 0;

-- Check medication counts.
SELECT
    MIN(num_medications) AS minimum_medications,
    MAX(num_medications) AS maximum_medications,
    ROUND(AVG(num_medications), 2) AS average_medications
FROM diabetes_130_raw;


-- ============================================================
-- 4. OVERALL READMISSION ANALYSIS
-- ============================================================

-- Readmission within 30 days vs. other categories.
SELECT
    COUNT(*) AS total_encounters,
    SUM(
        CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
    ) AS readmitted_within_30_days,
    SUM(
        CASE WHEN readmitted = '>30' THEN 1 ELSE 0 END
    ) AS readmitted_after_30_days,
    SUM(
        CASE WHEN readmitted = 'NO' THEN 1 ELSE 0 END
    ) AS not_readmitted,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_within_30_days_pct
FROM diabetes_130_raw;


-- ============================================================
-- 5. READMISSION BY DEMOGRAPHICS
-- ============================================================

-- Readmission by age.
SELECT
    age,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY age
ORDER BY readmission_rate_pct DESC;

-- Readmission by gender.
SELECT
    gender,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY gender
ORDER BY readmission_rate_pct DESC;

-- Readmission by race.
SELECT
    race,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY race
ORDER BY readmission_rate_pct DESC;

-- Readmission by admission type.
SELECT
    admission_type_id,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY admission_type_id
ORDER BY readmission_rate_pct DESC;

-- Readmission by discharge disposition.
SELECT
    discharge_disposition_id,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY discharge_disposition_id
ORDER BY readmission_rate_pct DESC;


-- ============================================================
-- 6. HOSPITAL STAY ANALYSIS
-- ============================================================

-- Compare length of stay across readmission categories.
SELECT
    readmitted,
    COUNT(*) AS total_encounters,
    ROUND(AVG(time_in_hospital), 2) AS average_stay_days,
    MIN(time_in_hospital) AS minimum_stay_days,
    MAX(time_in_hospital) AS maximum_stay_days
FROM diabetes_130_raw
GROUP BY readmitted
ORDER BY average_stay_days DESC;

-- Categorize length of stay with CASE.
SELECT
    CASE
        WHEN time_in_hospital BETWEEN 1 AND 3
            THEN '1-3 days'
        WHEN time_in_hospital BETWEEN 4 AND 6
            THEN '4-6 days'
        WHEN time_in_hospital BETWEEN 7 AND 9
            THEN '7-9 days'
        ELSE '10+ days'
    END AS stay_group,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
WHERE time_in_hospital IS NOT NULL
  AND time_in_hospital > 0
GROUP BY stay_group
ORDER BY MIN(time_in_hospital);


-- ============================================================
-- 7. PRIOR HOSPITAL UTILIZATION
-- ============================================================

-- Readmission by previous inpatient visits.
SELECT
    CASE
        WHEN number_inpatient = 0 THEN '0 prior visits'
        WHEN number_inpatient = 1 THEN '1 prior visit'
        WHEN number_inpatient BETWEEN 2 AND 3 THEN '2-3 prior visits'
        ELSE '4+ prior visits'
    END AS prior_inpatient_group,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
WHERE number_inpatient IS NOT NULL
GROUP BY prior_inpatient_group
ORDER BY MIN(number_inpatient);

-- Readmission by previous emergency visits.
SELECT
    CASE
        WHEN number_emergency = 0 THEN '0 prior visits'
        WHEN number_emergency = 1 THEN '1 prior visit'
        WHEN number_emergency BETWEEN 2 AND 3 THEN '2-3 prior visits'
        ELSE '4+ prior visits'
    END AS prior_emergency_group,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
WHERE number_emergency IS NOT NULL
GROUP BY prior_emergency_group
ORDER BY MIN(number_emergency);

-- Readmission by previous outpatient visits.
SELECT
    CASE
        WHEN number_outpatient = 0 THEN '0 prior visits'
        WHEN number_outpatient = 1 THEN '1 prior visit'
        WHEN number_outpatient BETWEEN 2 AND 3 THEN '2-3 prior visits'
        ELSE '4+ prior visits'
    END AS prior_outpatient_group,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
WHERE number_outpatient IS NOT NULL
GROUP BY prior_outpatient_group
ORDER BY MIN(number_outpatient);


-- ============================================================
-- 8. MEDICATION ANALYSIS
-- ============================================================

-- Number of medications and readmission.
SELECT
    CASE
        WHEN num_medications BETWEEN 0 AND 5 THEN '0-5'
        WHEN num_medications BETWEEN 6 AND 10 THEN '6-10'
        WHEN num_medications BETWEEN 11 AND 15 THEN '11-15'
        WHEN num_medications BETWEEN 16 AND 20 THEN '16-20'
        ELSE '21+'
    END AS medication_group,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
WHERE num_medications IS NOT NULL
GROUP BY medication_group
ORDER BY MIN(num_medications);

-- Insulin and readmission.
SELECT
    insulin,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY insulin
ORDER BY readmission_rate_pct DESC;

-- Diabetes medication indicator.
SELECT
    diabetesMed,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY diabetesMed
ORDER BY readmission_rate_pct DESC;

-- Medication changes.
SELECT
    `change` AS medication_change,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY `change`
ORDER BY readmission_rate_pct DESC;


-- ============================================================
-- 9. DIAGNOSIS ANALYSIS
-- ============================================================

-- Primary diagnosis.
SELECT
    diag_1,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY diag_1
HAVING COUNT(*) >= 100
ORDER BY readmission_rate_pct DESC
LIMIT 20;

-- Number of diagnoses.
SELECT
    CASE
        WHEN number_diagnoses BETWEEN 1 AND 3 THEN '1-3 diagnoses'
        WHEN number_diagnoses BETWEEN 4 AND 6 THEN '4-6 diagnoses'
        ELSE '7+ diagnoses'
    END AS diagnosis_group,
    COUNT(*) AS total_encounters,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
WHERE number_diagnoses IS NOT NULL
GROUP BY diagnosis_group
ORDER BY MIN(number_diagnoses);


-- ============================================================
-- 10. CTE: READMISSION RATE BY AGE
-- ============================================================

WITH age_readmission AS (
    SELECT
        age,
        COUNT(*) AS total_encounters,
        SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) AS readmitted_within_30_days,
        ROUND(
            100.0 * SUM(
                CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
            ) / NULLIF(COUNT(*), 0),
            2
        ) AS readmission_rate_pct
    FROM diabetes_130_raw
    GROUP BY age
)
SELECT *
FROM age_readmission
ORDER BY readmission_rate_pct DESC;


-- ============================================================
-- 11. WINDOW FUNCTION: RANK AGE GROUPS
-- ============================================================

WITH age_readmission AS (
    SELECT
        age,
        COUNT(*) AS total_encounters,
        ROUND(
            100.0 * SUM(
                CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
            ) / NULLIF(COUNT(*), 0),
            2
        ) AS readmission_rate_pct
    FROM diabetes_130_raw
    GROUP BY age
)
SELECT
    age,
    total_encounters,
    readmission_rate_pct,
    RANK() OVER (
        ORDER BY readmission_rate_pct DESC
    ) AS readmission_rank,
    DENSE_RANK() OVER (
        ORDER BY readmission_rate_pct DESC
    ) AS dense_readmission_rank,
    ROW_NUMBER() OVER (
        ORDER BY readmission_rate_pct DESC, age
    ) AS row_num
FROM age_readmission
ORDER BY readmission_rank;


-- ============================================================
-- 12. WINDOW FUNCTION: PARTITION BY GENDER
-- Rank age groups within each gender.
-- ============================================================

WITH gender_age_readmission AS (
    SELECT
        gender,
        age,
        COUNT(*) AS total_encounters,
        ROUND(
            100.0 * SUM(
                CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
            ) / NULLIF(COUNT(*), 0),
            2
        ) AS readmission_rate_pct
    FROM diabetes_130_raw
    GROUP BY gender, age
)
SELECT
    gender,
    age,
    total_encounters,
    readmission_rate_pct,
    RANK() OVER (
        PARTITION BY gender
        ORDER BY readmission_rate_pct DESC
    ) AS rank_within_gender
FROM gender_age_readmission
ORDER BY gender, rank_within_gender;


-- ============================================================
-- 13. WINDOW FUNCTION: LAG
-- Compare each patient's encounter stay with the previous
-- encounter ordered by encounter_id.
-- NOTE: encounter_id order is not guaranteed to be chronological.
-- ============================================================

WITH patient_encounters AS (
    SELECT
        patient_nbr,
        encounter_id,
        time_in_hospital,
        readmitted,
        LAG(time_in_hospital) OVER (
            PARTITION BY patient_nbr
            ORDER BY encounter_id
        ) AS previous_encounter_stay
    FROM diabetes_130_raw
)
SELECT
    patient_nbr,
    encounter_id,
    time_in_hospital,
    previous_encounter_stay,
    time_in_hospital - previous_encounter_stay
        AS difference_in_stay_days,
    readmitted
FROM patient_encounters
WHERE previous_encounter_stay IS NOT NULL
ORDER BY patient_nbr, encounter_id
LIMIT 100;


-- ============================================================
-- 14. MULTIPLE FACTORS: PRIOR VISITS AND MEDICATIONS
-- ============================================================

WITH utilization_analysis AS (
    SELECT
        CASE
            WHEN number_inpatient = 0 THEN '0 prior visits'
            WHEN number_inpatient = 1 THEN '1 prior visit'
            WHEN number_inpatient BETWEEN 2 AND 3 THEN '2-3 prior visits'
            ELSE '4+ prior visits'
        END AS prior_visit_group,
        CASE
            WHEN num_medications BETWEEN 0 AND 5 THEN '0-5 medications'
            WHEN num_medications BETWEEN 6 AND 10 THEN '6-10 medications'
            WHEN num_medications BETWEEN 11 AND 15 THEN '11-15 medications'
            WHEN num_medications BETWEEN 16 AND 20 THEN '16-20 medications'
            ELSE '21+ medications'
        END AS medication_group,
        COUNT(*) AS total_encounters,
        SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) AS readmitted_within_30_days
    FROM diabetes_130_raw
    WHERE number_inpatient IS NOT NULL
      AND num_medications IS NOT NULL
    GROUP BY prior_visit_group, medication_group
)
SELECT
    prior_visit_group,
    medication_group,
    total_encounters,
    readmitted_within_30_days,
    ROUND(
        100.0 * readmitted_within_30_days /
        NULLIF(total_encounters, 0),
        2
    ) AS readmission_rate_pct
FROM utilization_analysis
WHERE total_encounters >= 30
ORDER BY readmission_rate_pct DESC;


-- ============================================================
-- 15. PATIENT ENCOUNTER SUMMARY
-- ============================================================

SELECT
    patient_nbr,
    COUNT(*) AS total_encounters,
    SUM(
        CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
    ) AS encounters_followed_by_readmission_within_30_days,
    ROUND(AVG(time_in_hospital), 2) AS average_stay_days,
    ROUND(AVG(num_medications), 2) AS average_medications
FROM diabetes_130_raw
WHERE patient_nbr IS NOT NULL
GROUP BY patient_nbr
HAVING COUNT(*) > 1
ORDER BY total_encounters DESC
LIMIT 100;


-- ============================================================
-- 16. EXECUTIVE SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_encounters,
    COUNT(DISTINCT patient_nbr) AS unique_patients,
    ROUND(AVG(time_in_hospital), 2) AS average_stay_days,
    ROUND(AVG(num_medications), 2) AS average_medications,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmitted_within_30_days_pct,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = '>30' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS readmitted_after_30_days_pct,
    ROUND(
        100.0 * SUM(
            CASE WHEN readmitted = 'NO' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS not_readmitted_pct
FROM diabetes_130_raw;


-- ============================================================
-- 17. CREATE ANALYTICAL VIEW
-- ============================================================

CREATE OR REPLACE VIEW vw_diabetes_readmission_summary AS
SELECT
    encounter_id,
    patient_nbr,
    race,
    gender,
    age,
    time_in_hospital,
    num_lab_procedures,
    num_procedures,
    num_medications,
    number_outpatient,
    number_emergency,
    number_inpatient,
    diag_1,
    diag_2,
    diag_3,
    insulin,
    `change` AS medication_change,
    diabetesMed,
    readmitted,
    CASE
        WHEN readmitted = '<30' THEN 1
        ELSE 0
    END AS readmitted_within_30_days
FROM diabetes_130_raw;

-- Test the view.
SELECT *
FROM vw_diabetes_readmission_summary
LIMIT 20;


-- ============================================================
-- 18. FINAL VERIFICATION
-- ============================================================

-- Confirm that the analytical view exists.
SHOW FULL TABLES
FROM healthcare_ds
WHERE Table_type = 'VIEW';

-- Final source row count.
SELECT COUNT(*) AS final_source_row_count
FROM diabetes_130_raw;

-- ============================================================
-- END OF ANALYSIS
-- ============================================================
