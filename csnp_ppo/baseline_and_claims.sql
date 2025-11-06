-- ==============================================================
-- 1. Raw member pools (C-SNP & PPO)
-- ==============================================================
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

-- ==============================================================
-- 2. Age as of 2023-01-01 + 5-digit zip
-- ==============================================================
members_with_age AS (
    SELECT
        member_id,
        plan_type,
        FLOOR(DATEDIFF('2023-01-01', MemDOB) / 365.25) AS age,
        gender,
        LEFT(zip, 5) AS zip
    FROM all_members
    WHERE MemDOB IS NOT NULL
      AND FLOOR(DATEDIFF('2023-01-01', MemDOB) / 365.25) >= 65
),

-- ==============================================================
-- 3. 2023 baseline severity (inpatient, ER, surgery, drugs)
-- ==============================================================
inpatient_er AS (
    SELECT
        c.MembershipNumber AS member_id,
        MAX(CASE WHEN c.PLSRV_CD = '21' THEN 3 ELSE 0 END) AS hosp_flag,
        MAX(CASE WHEN c.PLSRV_CD = '23' THEN 2 ELSE 0 END) AS er_flag
    FROM hive_metastore.off_orig.claims_member c
    WHERE c.PROC_DT >= '2023-01-01' AND c.PROC_DT < '2024-01-01'
    GROUP BY c.MembershipNumber
),
surgery_flag AS (
    SELECT DISTINCT MembershipNumber AS member_id
    FROM hive_metastore.off_orig.claims_member
    WHERE PROC_DT >= '2023-01-01' AND PROC_DT < '2024-01-01'
      AND (
          PROC_CD LIKE '6698%' OR PROC_CD LIKE '2744%' OR PROC_CD LIKE '909%' OR PROC_CD LIKE '0%'
      )
),
drug_flag AS (
    SELECT DISTINCT MembershipNumber AS member_id
    FROM hive_metastore.off_orig.claims_member
    WHERE PROC_DT >= '2023-01-01' AND PROC_DT < '2024-01-01'
      AND (PROC_CD LIKE 'J%' OR PROC_CD LIKE 'A42%' OR PROC_CD LIKE 'C%')
),
severity_calc AS (
    SELECT
        m.member_id,
        m.plan_type,
        m.age,
        m.gender,
        m.zip,
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

-- ==============================================================
-- 4. Claims by 12-month periods
-- ==============================================================
yearly_claims AS (
    SELECT
        c.MembershipNumber AS member_id,
        SUM(CASE 
            WHEN c.PROC_DT >= '2023-01-01' AND c.PROC_DT < '2024-01-01' THEN c.gl_amt 
            ELSE 0 
        END) AS claim_y1,
        SUM(CASE 
            WHEN c.PROC_DT >= '2024-01-01' AND c.PROC_DT < '2025-01-01' THEN c.gl_amt 
            ELSE 0 
        END) AS claim_y2,
        SUM(CASE 
            WHEN c.PROC_DT >= '2025-01-01' AND c.PROC_DT < '2026-01-01' THEN c.gl_amt 
            ELSE 0 
        END) AS claim_y3,
        SUM(c.gl_amt) AS total_claim_36m
    FROM hive_metastore.off_orig.claims_member c
    WHERE c.PROC_DT >= '2023-01-01' AND c.PROC_DT < '2026-01-01'
    GROUP BY c.MembershipNumber
)

-- ==============================================================
-- 5. Final output: one row per member
-- ==============================================================
SELECT
    sc.plan_type,
    sc.member_id,
    sc.age,
    sc.gender,
    sc.zip,
    sc.severity_2023,
    COALESCE(yc.claim_y1, 0) AS claim_y1,
    COALESCE(yc.claim_y2, 0) AS claim_y2,
    COALESCE(yc.claim_y3, 0) AS claim_y3,
    COALESCE(yc.total_claim_36m, 0) AS total_claim_36m
FROM severity_calc sc
LEFT JOIN yearly_claims yc ON yc.member_id = sc.member_id
ORDER BY sc.plan_type, sc.severity_2023 DESC, sc.member_id;
