
-- ============================================================
-- PROJECT: Diabetes Hospital Readmission Analysis
-- DATABASE: healthcare_ds
-- TABLE:    diabetes_130_raw
-- DIALECT:  MySQL 8.0+
-- ============================================================

-- 1. DATABASE SETUP
CREATE DATABASE IF NOT EXISTS healthcare_ds;
USE healthcare_ds;

-- ============================================================
-- 2. DATA EXPLORATION
-- ============================================================

-- Preview records
SELECT *
FROM diabetes_130_raw
LIMIT 20;

-- Total number of records
SELECT COUNT(*) AS total_records
FROM diabetes_130_raw;

-- Number of columns
SELECT COUNT(*) AS total_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'healthcare_ds'
  AND TABLE_NAME = 'diabetes_130_raw';

-- Inspect column names and data types
DESCRIBE diabetes_130_raw;

-- Check the distribution of readmission categories
SELECT
    readmitted,
    COUNT(*) AS patient_count,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM diabetes_130_raw),
        2
    ) AS percentage
FROM diabetes_130_raw
GROUP BY readmitted
ORDER BY patient_count DESC;

-- ============================================================
-- 3. DATA QUALITY CHECKS
-- ============================================================

-- Check NULL values in important columns
SELECT
    SUM(patient_nbr IS NULL) AS null_patient_nbr,
    SUM(encounter_id IS NULL) AS null_encounter_id,
    SUM(readmitted IS NULL) AS null_readmitted,
    SUM(age IS NULL) AS null_age,
    SUM(gender IS NULL) AS null_gender,
    SUM(time_in_hospital IS NULL) AS null_time_in_hospital,
    SUM(num_medications IS NULL) AS null_num_medications
FROM diabetes_130_raw;

-- Check duplicate encounter IDs
SELECT
    encounter_id,
    COUNT(*) AS duplicate_count
FROM diabetes_130_raw
GROUP BY encounter_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Check duplicate patient identifiers
-- A patient may legitimately have multiple encounters.
SELECT
    patient_nbr,
    COUNT(*) AS encounter_count
FROM diabetes_130_raw
GROUP BY patient_nbr
HAVING COUNT(*) > 1
ORDER BY encounter_count DESC
LIMIT 20;

-- Check missing or unknown gender values
SELECT
    gender,
    COUNT(*) AS patient_count
FROM diabetes_130_raw
GROUP BY gender
ORDER BY patient_count DESC;

-- Check age categories
SELECT
    age,
    COUNT(*) AS patient_count
FROM diabetes_130_raw
GROUP BY age
ORDER BY age;

-- Check invalid or unusual hospital stay durations
SELECT
    MIN(time_in_hospital) AS minimum_days,
    MAX(time_in_hospital) AS maximum_days,
    AVG(time_in_hospital) AS average_days
FROM diabetes_130_raw;

SELECT *
FROM diabetes_130_raw
WHERE time_in_hospital <= 0
   OR time_in_hospital IS NULL;

-- ============================================================
-- 4. OVERALL READMISSION ANALYSIS
-- ============================================================

-- Readmission rate by category
-- Dataset values commonly include:
-- '<30' = readmitted within 30 days
-- '>30' = readmitted after 30 days
-- 'NO'  = not readmitted

SELECT
    readmitted,
    COUNT(*) AS encounters,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM diabetes_130_raw),
        2
    ) AS percentage_of_encounters
FROM diabetes_130_raw
GROUP BY readmitted
ORDER BY encounters DESC;

-- Readmitted within 30 days vs. all other encounters
SELECT
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    SUM(readmitted = '>30') AS readmitted_after_30_days,
    SUM(readmitted = 'NO') AS not_readmitted,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_within_30_days_pct
FROM diabetes_130_raw;

-- ============================================================
-- 5. READMISSION BY DEMOGRAPHICS
-- ============================================================

-- Readmission by age group
SELECT
    age,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY age
ORDER BY readmission_rate_pct DESC;

-- Readmission by gender
SELECT
    gender,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY gender
ORDER BY readmission_rate_pct DESC;

-- Readmission by race
SELECT
    race,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY race
ORDER BY readmission_rate_pct DESC;

-- Readmission by admission type
SELECT
    admission_type_id,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY admission_type_id
ORDER BY readmission_rate_pct DESC;

-- Readmission by discharge disposition
SELECT
    discharge_disposition_id,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY discharge_disposition_id
ORDER BY readmission_rate_pct DESC;

-- ============================================================
-- 6. HOSPITAL STAY ANALYSIS
-- ============================================================

-- Average length of stay by readmission category
SELECT
    readmitted,
    COUNT(*) AS total_encounters,
    ROUND(AVG(time_in_hospital), 2) AS average_stay_days,
    MIN(time_in_hospital) AS minimum_stay_days,
    MAX(time_in_hospital) AS maximum_stay_days
FROM diabetes_130_raw
GROUP BY readmitted
ORDER BY average_stay_days DESC;

-- Readmission by length-of-stay group
SELECT
    CASE
        WHEN time_in_hospital BETWEEN 1 AND 3 THEN '1-3 days'
        WHEN time_in_hospital BETWEEN 4 AND 6 THEN '4-6 days'
        WHEN time_in_hospital BETWEEN 7 AND 9 THEN '7-9 days'
        ELSE '10+ days'
    END AS stay_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY stay_group
ORDER BY MIN(time_in_hospital);

-- ============================================================
-- 7. PRIOR UTILIZATION ANALYSIS
-- ============================================================

-- Readmission by prior inpatient visits
SELECT
    CASE
        WHEN number_inpatient = 0 THEN '0 prior inpatient visits'
        WHEN number_inpatient = 1 THEN '1 prior inpatient visit'
        WHEN number_inpatient BETWEEN 2 AND 3 THEN '2-3 prior visits'
        ELSE '4+ prior visits'
    END AS prior_inpatient_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY prior_inpatient_group
ORDER BY MIN(number_inpatient);

-- Readmission by prior emergency visits
SELECT
    CASE
        WHEN number_emergency = 0 THEN '0 prior emergency visits'
        WHEN number_emergency = 1 THEN '1 prior emergency visit'
        WHEN number_emergency BETWEEN 2 AND 3 THEN '2-3 prior visits'
        ELSE '4+ prior visits'
    END AS prior_emergency_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY prior_emergency_group
ORDER BY MIN(number_emergency);

-- Readmission by prior outpatient visits
SELECT
    CASE
        WHEN number_outpatient = 0 THEN '0 prior outpatient visits'
        WHEN number_outpatient = 1 THEN '1 prior outpatient visit'
        WHEN number_outpatient BETWEEN 2 AND 3 THEN '2-3 prior visits'
        ELSE '4+ prior visits'
    END AS prior_outpatient_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY prior_outpatient_group
ORDER BY MIN(number_outpatient);

-- ============================================================
-- 8. MEDICATION ANALYSIS
-- ============================================================

-- Number of medications vs. readmission
SELECT
    CASE
        WHEN num_medications BETWEEN 0 AND 5 THEN '0-5 medications'
        WHEN num_medications BETWEEN 6 AND 10 THEN '6-10 medications'
        WHEN num_medications BETWEEN 11 AND 15 THEN '11-15 medications'
        WHEN num_medications BETWEEN 16 AND 20 THEN '16-20 medications'
        ELSE '21+ medications'
    END AS medication_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY medication_group
ORDER BY MIN(num_medications);

-- Insulin usage and readmission
SELECT
    insulin,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY insulin
ORDER BY readmission_rate_pct DESC;

-- Diabetes medication indicator and readmission
SELECT
    diabetesMed,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY diabetesMed
ORDER BY readmission_rate_pct DESC;

-- Medication changes and readmission
SELECT
    change,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY change
ORDER BY readmission_rate_pct DESC;

-- ============================================================
-- 9. DIAGNOSIS ANALYSIS
-- ============================================================

-- Readmission by primary diagnosis
SELECT
    diag_1,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY diag_1
HAVING COUNT(*) >= 100
ORDER BY readmission_rate_pct DESC
LIMIT 20;

-- Readmission by secondary diagnosis
SELECT
    diag_2,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY diag_2
HAVING COUNT(*) >= 100
ORDER BY readmission_rate_pct DESC
LIMIT 20;

-- Readmission by number of diagnoses
SELECT
    CASE
        WHEN number_diagnoses BETWEEN 1 AND 3 THEN '1-3 diagnoses'
        WHEN number_diagnoses BETWEEN 4 AND 6 THEN '4-6 diagnoses'
        ELSE '7+ diagnoses'
    END AS diagnosis_count_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY diagnosis_count_group
ORDER BY MIN(number_diagnoses);

-- ============================================================
-- 10. PATIENT RISK PROFILE
-- ============================================================

-- Explore patients with repeated hospital utilization.
-- Results are encounter-level, not unique-patient risk estimates.
SELECT
    patient_nbr,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmissions_within_30_days,
    SUM(number_inpatient) AS total_prior_inpatient_visits,
    AVG(time_in_hospital) AS average_stay_days,
    AVG(num_medications) AS average_medications
FROM diabetes_130_raw
GROUP BY patient_nbr
HAVING COUNT(*) > 1
ORDER BY readmissions_within_30_days DESC,
         total_encounters DESC
LIMIT 100;

-- ============================================================
-- 11. READMISSION RATE BY MULTIPLE FACTORS
-- ============================================================

-- Age and hospital stay
SELECT
    age,
    CASE
        WHEN time_in_hospital BETWEEN 1 AND 3 THEN '1-3 days'
        WHEN time_in_hospital BETWEEN 4 AND 6 THEN '4-6 days'
        WHEN time_in_hospital BETWEEN 7 AND 9 THEN '7-9 days'
        ELSE '10+ days'
    END AS stay_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY age, stay_group
HAVING COUNT(*) >= 30
ORDER BY readmission_rate_pct DESC;

-- Prior inpatient visits and medication count
SELECT
    CASE
        WHEN number_inpatient = 0 THEN '0 prior visits'
        WHEN number_inpatient = 1 THEN '1 prior visit'
        WHEN number_inpatient BETWEEN 2 AND 3 THEN '2-3 prior visits'
        ELSE '4+ prior visits'
    END AS prior_visit_group,
    CASE
        WHEN num_medications <= 5 THEN '0-5 medications'
        WHEN num_medications <= 10 THEN '6-10 medications'
        WHEN num_medications <= 15 THEN '11-15 medications'
        WHEN num_medications <= 20 THEN '16-20 medications'
        ELSE '21+ medications'
    END AS medication_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_rate_pct
FROM diabetes_130_raw
GROUP BY prior_visit_group, medication_group
HAVING COUNT(*) >= 30
ORDER BY readmission_rate_pct DESC;

-- ============================================================
-- 12. EXECUTIVE SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_encounters,
    COUNT(DISTINCT patient_nbr) AS unique_patients,
    ROUND(AVG(time_in_hospital), 2) AS average_hospital_stay_days,
    ROUND(AVG(num_medications), 2) AS average_medications,
    ROUND(
        100.0 * SUM(readmitted = '<30') / COUNT(*),
        2
    ) AS readmission_within_30_days_pct,
    ROUND(
        100.0 * SUM(readmitted = '>30') / COUNT(*),
        2
    ) AS readmission_after_30_days_pct,
    ROUND(
        100.0 * SUM(readmitted = 'NO') / COUNT(*),
        2
    ) AS not_readmitted_pct
FROM diabetes_130_raw;

-- ============================================================
-- 13. OPTIONAL: CREATE AN ANALYSIS VIEW
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
    change,
    diabetesMed,
    readmitted,
    CASE
        WHEN readmitted = '<30' THEN 1
        ELSE 0
    END AS readmitted_within_30_days
FROM diabetes_130_raw;

-- Preview the analysis view
SELECT *
FROM vw_diabetes_readmission_summary
LIMIT 20;

-- ============================================================
-- END OF PROJECT
-- ============================================================
