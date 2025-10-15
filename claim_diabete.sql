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

    -- Diabetes flag (no DIAG_CD)
    MAX(CASE
        WHEN EXISTS (
            SELECT 1
            FROM hive_metastore.off_orig.claims_member sub
            WHERE sub.CLAIM_ID = main.CLAIM_ID
            AND sub.PROC_CD IN (
                '82948', 'D0412', 'J1814', 'S9140', 'S9460', '3E013VG', 'G9887', 'A9274', 'S9455', 'S9214',
                '3051F', 'J1815', '83525', 'A4772', 'G9147', '82947', 'A4224', '86337', '82950', '3754F',
                'S5551', '0447T', '3E033VG', 'S9141', 'D0411', 'S5561', '3E053VG', 'A9552', 'A4225', 'G9886',
                'M1371', '84206', 'S8490', 'E0787', 'S9145', '82945', 'M1211', '82952', '0407U', '3044F',
                '83037', 'E0784', 'E0607', '0740T', 'A9275', 'S5570', '74249', '3046F', 'A4230', 'J1812',
                '0403T', 'S5553', 'J2910', '0488T', '82951', 'S3000', '0446T', '82946', 'G0247', 'A9609',
                'M1372', 'A4232', '0468U', 'G2089', 'A4231', 'S5550', 'A4255', '83036', '3052F', 'M1212',
                'G0246', 'M1373', '80424', 'S9465', '95251', 'G0245', '3045F', 'S5552', '80422', 'S5571',
                '82949', '83527', 'J1817', '3E043VG', 'J1811'
            )
            AND EXISTS (
                SELECT 1
                FROM hive_metastore.off_orig.claims_member sub2
                WHERE sub2.CLAIM_ID = sub.CLAIM_ID
                AND (
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%DIABETES%' OR
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%DIABETIC%' OR
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%INSULIN%' OR
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%HBA1C%' OR
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%A1C%'
                )
            )
        )
        THEN 1 ELSE 0 END) AS has_diabetes_proc,

    -- Cardiac (no DIAG_CD)
    MAX(CASE
        WHEN EXISTS (
            SELECT 1
            FROM hive_metastore.off_orig.claims_member sub
            WHERE sub.CLAIM_ID = main.CLAIM_ID
            AND sub.PROC_CD IN (
                '99211', '99212', '99213', '99214', '99215', '93005', '93010', '93018', '83880', 
                '93306', '93350', 'J2785', '4040F', '98925', '93000', '99406', '80061', '82565'
            )
            AND EXISTS (
                SELECT 1
                FROM hive_metastore.off_orig.claims_member sub2
                WHERE sub2.CLAIM_ID = sub.CLAIM_ID
                AND (
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%HEART FAILURE%' OR
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%CONGESTIVE HEART FAILURE%' OR
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%CHF%' OR
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%CARDIAC DECOMPENSATION%'
                )
            )
        )
        THEN 1 ELSE 0 END) AS has_cardiac_proc,

    -- COPD (no DIAG_CD)
    MAX(CASE
        WHEN EXISTS (
            SELECT 1
            FROM hive_metastore.off_orig.claims_member sub
            WHERE sub.CLAIM_ID = main.CLAIM_ID
            AND sub.PROC_CD IN (
                '99213', '94640', '94668', 'J7620', 'J7615', '83020', '94010', '94060', '94664', '94729'
            )
            AND EXISTS (
                SELECT 1
                FROM hive_metastore.off_orig.claims_member sub2
                WHERE sub2.CLAIM_ID = sub.CLAIM_ID
                AND (
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%CHRONIC OBSTRUCTIVE%' OR
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%COPD%' OR
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%EMPHYSEMA%' OR
                    UPPER(COALESCE(sub2.PROC_DESC, '')) LIKE '%CHRONIC BRONCHITIS%'
                )
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
