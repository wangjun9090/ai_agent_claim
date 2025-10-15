CREATE OR REPLACE TABLE hive_metastore.off_orig.member_claim_amt
USING DELTA
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.tuneFileSizesForRewrites' = 'true',
  'delta.targetFileSize' = '256MB'
)
AS

SELECT
    MembershipNumber,
    COUNT(DISTINCT CASE WHEN YEAR(PROC_DT) = 2025 THEN CLAIM_ID END) AS claim_count_2025,
    SUM(CASE WHEN YEAR(PROC_DT) = 2025 THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS claim_amt_2025,
    COUNT(DISTINCT CASE WHEN YEAR(PROC_DT) = 2024 THEN CLAIM_ID END) AS claim_count_2024,
    SUM(CASE WHEN YEAR(PROC_DT) = 2024 THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS claim_amt_2024,
    COUNT(DISTINCT CASE WHEN YEAR(PROC_DT) = 2023 THEN CLAIM_ID END) AS claim_count_2023,
    SUM(CASE WHEN YEAR(PROC_DT) = 2023 THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS claim_amt_2023,

    -- ER visit counts
    COUNT(DISTINCT CASE 
        WHEN YEAR(PROC_DT) = 2023 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%EMERGENCY%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ER %' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '% ER%' 
              OR UPPER(PROC_DESC) LIKE '%URGENT%' 
              OR UPPER(PROC_DESC) LIKE '%TRAUMA%')
        THEN CLAIM_ID END) AS er_visit_count_2023,
    COUNT(DISTINCT CASE 
        WHEN YEAR(PROC_DT) = 2024 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%EMERGENCY%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ER %' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '% ER%' 
              OR UPPER(PROC_DESC) LIKE '%URGENT%' 
              OR UPPER(PROC_DESC) LIKE '%TRAUMA%')
        THEN CLAIM_ID END) AS er_visit_count_2024,
    COUNT(DISTINCT CASE 
        WHEN YEAR(PROC_DT) = 2025 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%EMERGENCY%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ER %' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '% ER%' 
              OR UPPER(PROC_DESC) LIKE '%URGENT%' 
              OR UPPER(PROC_DESC) LIKE '%TRAUMA%')
        THEN CLAIM_ID END) AS er_visit_count_2025,

    -- ER visit amounts
    SUM(CASE 
        WHEN YEAR(PROC_DT) = 2023 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%EMERGENCY%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ER %' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '% ER%' 
              OR UPPER(PROC_DESC) LIKE '%URGENT%' 
              OR UPPER(PROC_DESC) LIKE '%TRAUMA%')
        THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS er_visit_amt_2023,
    SUM(CASE 
        WHEN YEAR(PROC_DT) = 2024 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%EMERGENCY%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ER %' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '% ER%' 
              OR UPPER(PROC_DESC) LIKE '%URGENT%' 
              OR UPPER(PROC_DESC) LIKE '%TRAUMA%')
        THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS er_visit_amt_2024,
    SUM(CASE 
        WHEN YEAR(PROC_DT) = 2025 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%EMERGENCY%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ER %' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '% ER%' 
              OR UPPER(PROC_DESC) LIKE '%URGENT%' 
              OR UPPER(PROC_DESC) LIKE '%TRAUMA%')
        THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS er_visit_amt_2025,

    -- Preventive visit counts
    COUNT(DISTINCT CASE 
        WHEN YEAR(PROC_DT) = 2023 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%PREVENTIVE%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%SCREENING%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ANNUAL%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%IMMUNIZATION%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%VACCINATION%')
        THEN CLAIM_ID END) AS preventive_visit_count_2023,
    COUNT(DISTINCT CASE 
        WHEN YEAR(PROC_DT) = 2024 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%PREVENTIVE%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%SCREENING%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ANNUAL%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%IMMUNIZATION%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%VACCINATION%')
        THEN CLAIM_ID END) AS preventive_visit_count_2024,
    COUNT(DISTINCT CASE 
        WHEN YEAR(PROC_DT) = 2025 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%PREVENTIVE%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%SCREENING%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ANNUAL%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%IMMUNIZATION%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%VACCINATION%')
        THEN CLAIM_ID END) AS preventive_visit_count_2025,

    -- Preventive visit amounts
    SUM(CASE 
        WHEN YEAR(PROC_DT) = 2023 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%PREVENTIVE%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%SCREENING%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ANNUAL%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%IMMUNIZATION%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%VACCINATION%')
        THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS preventive_visit_amt_2023,
    SUM(CASE 
        WHEN YEAR(PROC_DT) = 2024 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%PREVENTIVE%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%SCREENING%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ANNUAL%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%IMMUNIZATION%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%VACCINATION%')
        THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS preventive_visit_amt_2024,
    SUM(CASE 
        WHEN YEAR(PROC_DT) = 2025 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%PREVENTIVE%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%SCREENING%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ANNUAL%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%IMMUNIZATION%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%VACCINATION%')
        THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS preventive_visit_amt_2025,

    -- Specialist visit counts
    COUNT(DISTINCT CASE 
        WHEN YEAR(PROC_DT) = 2023 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%SPECIALIST%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%CARDIO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%NEURO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ENDOCRINOLOGY%')
        THEN CLAIM_ID END) AS specialist_visit_count_2023,
    COUNT(DISTINCT CASE 
        WHEN YEAR(PROC_DT) = 2024 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%SPECIALIST%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%CARDIO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%NEURO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ENDOCRINOLOGY%')
        THEN CLAIM_ID END) AS specialist_visit_count_2024,
    COUNT(DISTINCT CASE 
        WHEN YEAR(PROC_DT) = 2025 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%SPECIALIST%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%CARDIO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%NEURO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ENDOCRINOLOGY%')
        THEN CLAIM_ID END) AS specialist_visit_count_2025,

    -- Specialist visit amounts
    SUM(CASE 
        WHEN YEAR(PROC_DT) = 2023 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%SPECIALIST%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%CARDIO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%NEURO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ENDOCRINOLOGY%')
        THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS specialist_visit_amt_2023,
    SUM(CASE 
        WHEN YEAR(PROC_DT) = 2024 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%SPECIALIST%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%CARDIO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%NEURO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ENDOCRINOLOGY%')
        THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS specialist_visit_amt_2024,
    SUM(CASE 
        WHEN YEAR(PROC_DT) = 2025 AND 
             (UPPER(COALESCE(PROC_DESC, '')) LIKE '%SPECIALIST%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%CARDIO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%NEURO%' 
              OR UPPER(COALESCE(PROC_DESC, '')) LIKE '%ENDOCRINOLOGY%')
        THEN COALESCE(GL_AMT, 0) ELSE 0 END) AS specialist_visit_amt_2025,

    -- Diabetes flag (fixed - reinstate HBA1C/A1C, expanded codes)
    MAX(CASE
        WHEN EXISTS (
            SELECT 1
            FROM hive_metastore.off_orig.claims_member sub
            WHERE sub.CLAIM_ID = main.CLAIM_ID
            AND sub.PROC_CD IN (
                '83036', '82947', 'J1815', 'J1817', '95251', 'G0245', 'G0246', 'S9465', 'A9274', 'A9275',
                'E0607', 'E0784', 'E0787', 'A4224', 'A4225', 'A4230', 'A4231', 'A4232', 'S5550', 'S5551',
                '95249', '3044F', '3045F', '3046F', '99214'
            )
            AND (
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%DIABETES%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%DIABETIC%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%INSULIN%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%HBA1C%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%A1C%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%DM%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%TYPE 2 DIABETES%'
            )
        )
        THEN 1 ELSE 0 END) AS has_diabetes_proc,

    -- Cardiac flag (fixed - expanded codes, added keywords)
    MAX(CASE
        WHEN EXISTS (
            SELECT 1
            FROM hive_metastore.off_orig.claims_member sub
            WHERE sub.CLAIM_ID = main.CLAIM_ID
            AND sub.PROC_CD IN (
                '83880', '93306', '93350', 'J2785', '93000', '93005', '93010', '93018', '99214'
            )
            AND (
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%HEART FAILURE%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%CONGESTIVE HEART FAILURE%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%CHF%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%CARDIAC FAILURE%'
            )
        )
        THEN 1 ELSE 0 END) AS has_cardiac_proc,

    -- COPD flag (fixed - expanded codes, added keywords)
    MAX(CASE
        WHEN EXISTS (
            SELECT 1
            FROM hive_metastore.off_orig.claims_member sub
            WHERE sub.CLAIM_ID = main.CLAIM_ID
            AND sub.PROC_CD IN (
                '94640', '94668', 'J7620', 'J7615', '94010', '94060', '94664', '99214'
            )
            AND (
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%CHRONIC OBSTRUCTIVE%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%COPD%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%EMPHYSEMA%' OR
                UPPER(COALESCE(sub.PROC_DESC, '')) LIKE '%PULMONARY DISEASE%'
            )
        )
        THEN 1 ELSE 0 END) AS has_copd_proc,

    -- Additional flags & dates
    MIN(PROC_DT) AS first_claim_date,
    MAX(PROC_DT) AS last_claim_date,
    COUNT(DISTINCT YEAR(PROC_DT)) AS claim_years_active,
    COUNT(DISTINCT SRC_SYS_CD) AS claim_source_systems
FROM hive_metastore.off_orig.claims_member main
WHERE GL_AMT IS NOT NULL
GROUP BY MembershipNumber
