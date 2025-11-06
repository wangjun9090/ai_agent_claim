-- Final SQL Script: Extract matched C-SNP vs PPO members with robust 2023 baseline severity
-- Output: member_id, plan_type, age, gender, zip, severity_2023, total_claim_36m

WITH csnp_raw AS (
    SELECT 
        'C-SNP' AS plan_type,
        MembershipNumber AS member_id,
        MemDOB,
        MemGender AS gender,
        MemZip AS zip,
        SubProduct
    FROM hive_metastore.off_orig.members_data
    WHERE MonthsOnPlan >= 36
      AND SubProduct LIKE '%Chronic%'
      AND MonthsWithUHC < 36
    LIMIT 5000
),
ppo_raw AS (
    SELECT 
        'PPO' AS plan_type,
        MembershipNumber AS member_id,
        MemDOB,
        MemGender AS gender,
        MemZip AS zip,
        SubProduct
    FROM hive_metastore.off_orig.members_data
    WHERE MonthsOnPlan >= 36
      AND (SubProduct LIKE '%Regional PPO%' OR SubProduct LIKE '%Local PPO%')
      AND MonthsWithUHC BETWEEN 31 AND 35
    LIMIT 5000
),
all_members AS (
    SELECT * FROM csnp_raw
    UNION ALL
    SELECT * FROM ppo_raw
),
-- Calculate age as of 2023-01-01
members_with_age AS (
    SELECT 
        member_id,
        plan_type,
        FLOOR(DATEDIFF('2023-01-01', MemDOB) / 365.25) AS age,
        gender,
        LEFT(zip, 5) AS zip5
    FROM all_members
    WHERE MemDOB IS NOT NULL
      AND FLOOR(DATEDIFF('2023-01-01', MemDOB) / 365.25) >= 65
),
-- 1. Inpatient (21) & ER (23) flags in 2023
inpatient_er AS (
    SELECT 
        c.MembershipNumber AS member_id,
        MAX(CASE WHEN c.PLSRV_CD = '21' THEN 3 ELSE 0 END) AS hosp_flag,
        MAX(CASE WHEN c.PLSRV_CD = '23' THEN 2 ELSE 0 END) AS er_flag
    FROM hive_metastore.off_orig.claims_member c
    WHERE c.PROC_DT >= '2023-01-01'
      AND c.PROC_DT < '2024-01-01'
    GROUP BY c.MembershipNumber
),
-- 2. Major surgery proxy (CPT examples: cataract, joint, dialysis)
surgery_flag AS (
    SELECT DISTINCT MembershipNumber AS member_id
    FROM hive_metastore.off_orig.claims_member
    WHERE PROC_DT >= '2023-01-01'
      AND PROC_DT < '2024-01-01'
      AND (
          PROC_CD LIKE '6698%'    -- Cataract
          OR PROC_CD LIKE '2744%' -- Knee replacement
          OR PROC_CD LIKE '909%'  -- Dialysis
          OR PROC_CD LIKE '0%'    -- ICD-10-PCS surgery
      )
),
-- 3. Chronic drug proxy (J-codes, insulin, etc.)
drug_flag AS (
    SELECT DISTINCT MembershipNumber AS member_id
    FROM hive_metastore.off_orig.claims_member
    WHERE PROC_DT >= '2023-01-01'
      AND PROC_DT < '2024-01-01'
      AND (
          PROC_CD LIKE 'J%'       -- Injected drugs
          OR PROC_CD LIKE 'A42%'  -- Insulin
          OR PROC_CD LIKE 'C%'    -- Cardiac
      )
),
-- Combine all to compute severity score (0–10+)
severity_calc AS (
    SELECT 
        m.member_id,
        m.plan_type,
        m.age,
        m.gender,
        m.zip5 AS zip,
        (
            COALESCE(h.hosp_flag, 0) +
            COALESCE(h.er_flag, 0) +
            CASE WHEN s.member_id IS NOT NULL THEN 3 ELSE 0 END +
            CASE WHEN d.member_id IS NOT NULL THEN 2 ELSE 0 END
        ) AS severity_2023
    FROM members_with_age m
    LEFT JOIN inpatient_er h ON h.member_id = m.member_id
    LEFT JOIN surgery_flag s ON s.member_id = m.member_id
    LEFT JOIN drug_flag d ON d.member_id = m.member_id
),
-- 36-month total claims (2023-01-01 to 2025-12-31)
claims_36m AS (
    SELECT 
        c.MembershipNumber AS member_id,
        SUM(c.gl_amt) AS total_claim_36m
    FROM hive_metastore.off_orig.claims_member c
    WHERE c.PROC_DT >= '2023-01-01'
      AND c.PROC_DT < '2026-01-01'
    GROUP BY c.MembershipNumber
)
-- Final output for matching & analysis
SELECT 
    sc.plan_type,
    sc.member_id,
    sc.age,
    sc.gender,
    sc.zip,
    sc.severity_2023,
    COALESCE(c.total_claim_36m, 0) AS total_claim_36m
FROM severity_calc sc
LEFT JOIN claims_36m c ON c.member_id = sc.member_id
ORDER BY sc.plan_type, sc.severity_2023 DESC, sc.member_id;
