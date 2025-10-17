-- Step 1: Identify top 5% high-cost PPO members for 2025
WITH ppo_top5 AS (
  SELECT
    Agent_ID,
    MembershipNumber,
    claim_amt_2025
  FROM hive_metastore.off_orig.enhanced_member_features
  WHERE plan_type = 'PPO'
    AND claim_amt_2025 IS NOT NULL
    AND claim_amt_2025 >= (
      SELECT PERCENTILE_APPROX(claim_amt_2025, 0.95)
      FROM hive_metastore.off_orig.enhanced_member_features
      WHERE plan_type = 'PPO'
        AND claim_amt_2025 IS NOT NULL
    )
),

-- Step 2: Flag risk behaviors based on procedure codes and service dates for COPD
risk_flags AS (
  SELECT c.MembershipNumber AS member_id,
    -- Flag 1: No pulmonary function test (e.g., 94010/94200) in last 30 days
    MAX(CASE WHEN (c.PROC_CD IN ('94010', '94200') OR c.PROC_DESC LIKE '%pulmonary%') THEN c.PROC_DT ELSE NULL END) < CURRENT_DATE - INTERVAL '30' DAY AS skip_pulmonary_check,
    -- Flag 2: No clinic visit (POS 21/22) in last 60 days
    MAX(CASE WHEN c.PLSRV_CD IN ('21', '22') THEN c.PROC_DT ELSE NULL END) < CURRENT_DATE - INTERVAL '60' DAY AS miss_clinic,
    -- Flag 3: Recent ER visit (POS 23 or respiratory ER codes) in last 35 days
    EXISTS (
      SELECT 1
      FROM hive_metastore.off_orig.claims_member e
      WHERE e.MembershipNumber = c.MembershipNumber
        AND (e.PROC_CD IN ('99284', '99285', '99292') OR e.PLSRV_CD = '23')
        AND e.PROC_DT >= CURRENT_DATE - INTERVAL '35' DAY
    ) AS recent_er
  FROM hive_metastore.off_orig.claims_member c
  INNER JOIN ppo_top5 t ON c.MembershipNumber = t.MembershipNumber
  WHERE c.PROC_DT BETWEEN '2025-01-01' AND '2025-12-31'
  GROUP BY c.MembershipNumber, c.Agent_ID
),

-- Step 3: Score and select high-risk members (score >= 2) for shift recommendation
final_list AS (
  SELECT member_id,
    (COALESCE(skip_pulmonary_check::int, 0) + COALESCE(miss_clinic::int, 0) + COALESCE(recent_er::int, 0)) AS risk_score,
    CASE WHEN skip_pulmonary_check THEN 'Y' ELSE 'N' END AS skip_pulmonary,
    CASE WHEN miss_clinic THEN 'Y' ELSE 'N' END AS miss_clinic,
    CASE WHEN recent_er THEN 'Y' ELSE 'N' END AS recent_er
  FROM risk_flags
  WHERE (COALESCE(skip_pulmonary_check::int, 0) + COALESCE(miss_clinic::int, 0) + COALESCE(recent_er::int, 0)) >= 2
)

-- Output: Top 500 high-risk COPD members to recommend for C-SNP shift
SELECT member_id, risk_score, skip_pulmonary, miss_clinic, recent_er
FROM final_list
ORDER BY risk_score DESC, member_id
LIMIT 500;
