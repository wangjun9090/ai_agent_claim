-- =====================================================
-- 1. Pull 1,000 CSNP and 1,000 PPO members separately
-- =====================================================
WITH csnp_raw AS (
  SELECT 
    'CSNP' AS plan_type,
    MemDOB,
    MemGender,
    MemZip,
    MembershipNumber,
    SubProduct,
    MonthsOnPlan,
    MonthsWithUHC
  FROM hive_metastore.off_orig.members_data
  WHERE MonthsOnPlan IN (36,35,34,33,32)
    AND MonthsWithUHC < 36
    AND SubProduct LIKE '%Chronic%'
  LIMIT 1000
),

ppo_raw AS (
  SELECT 
    'PPO' AS plan_type,
    MemDOB,
    MemGender,
    MemZip,
    MembershipNumber,
    SubProduct,
    MonthsOnPlan,
    MonthsWithUHC
  FROM hive_metastore.off_orig.members_data
  WHERE MonthsOnPlan IN (36,35,34,33,32)
    AND MonthsWithUHC < 36 
    AND MonthsWithUHC > 30
    AND (SubProduct LIKE '%Regional PPO%' OR SubProduct LIKE '%Local PPO%')
  LIMIT 1000
),

-- Union them
all_members AS (
  SELECT * FROM csnp_raw
  UNION ALL
  SELECT * FROM ppo_raw
),

-- =====================================================
-- 2. Compute age on 2023-01-01
-- =====================================================
members_with_age AS (
  SELECT 
    *,
    FLOOR(DATEDIFF(CAST('2023-01-01' AS DATE), MemDOB) / 365.25) AS age
  FROM all_members
),

-- =====================================================
-- 3. January 2023 severity proxy (inpatient=3, ER=2)
-- =====================================================
baseline_jan AS (
  SELECT 
    c.MembershipNumber,
    MAX(
      CASE 
        WHEN c.PLSRV_CD = '21' THEN 3   -- Inpatient
        WHEN c.PLSRV_CD = '23' THEN 2   -- Emergency Room
        ELSE 0 
      END
    ) AS severity_jan
  FROM hive_metastore.off_orig.claims_member c
  INNER JOIN members_with_age m 
    ON m.MembershipNumber = c.MembershipNumber
  WHERE c.PROC_DT BETWEEN '2023-01-01' AND '2023-01-31'
  GROUP BY c.MembershipNumber
),

-- =====================================================
-- 4. Total claims over 36 months
-- =====================================================
claims_36m AS (
  SELECT 
    c.MembershipNumber,
    SUM(c.gl_amt) AS total_claim_36m
  FROM hive_metastore.off_orig.claims_member c
  INNER JOIN members_with_age m 
    ON m.MembershipNumber = c.MembershipNumber
  WHERE c.PROC_DT >= '2023-01-01'
    AND c.PROC_DT < DATE_ADD('2023-01-01', 1095)
    AND c.gl_amt IS NOT NULL
  GROUP BY c.MembershipNumber
)

-- =====================================================
-- 5. Final output: 1 row per member
-- =====================================================
SELECT 
  m.plan_type,
  m.MembershipNumber,
  m.age,
  m.MemGender AS gender,
  m.MemZip AS zip,
  COALESCE(b.severity_jan, 0) AS severity_jan,
  COALESCE(c.total_claim_36m, 0) AS total_claim_36m
FROM members_with_age m
LEFT JOIN baseline_jan b 
  ON m.MembershipNumber = b.MembershipNumber
LEFT JOIN claims_36m c 
  ON m.MembershipNumber = c.MembershipNumber
ORDER BY m.plan_type, m.MembershipNumber;
