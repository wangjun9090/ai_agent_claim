-- Step 1: Identify top 5% high-cost PPO members for 2025
WITH ppo_top5 AS (
  SELECT member_id, claim_amt_2025
  FROM claims
  WHERE plan_type = 'PPO'
    AND YEAR = 2025
    AND claim_amt_2025 IS NOT NULL
  GROUP BY member_id, claim_amt_2025
  HAVING claim_amt_2025 >= (
    SELECT PERCENTILE_APPROX(claim_amt_2025, 0.95)
    FROM claims
    WHERE plan_type = 'PPO'
      AND YEAR = 2025
      AND claim_amt_2025 IS NOT NULL
  )
),

-- Step 2: Flag risk behaviors based on procedure codes and service dates
risk_flags AS (
  SELECT c.member_id,
    -- Flag 1: No blood sugar check (CPT 83036/82947) in last 30 days
    MAX(CASE WHEN (c.procedure_code IN ('83036', '82947') OR c.procedure_description LIKE '%glucose%') THEN c.service_date ELSE NULL END) < CURRENT_DATE - INTERVAL '30' DAY AS skip_glucose_check,
    -- Flag 2: No clinic visit (POS 21/22) in last 60 days
    MAX(CASE WHEN c.place_of_service IN ('21', '22') THEN c.service_date ELSE NULL END) < CURRENT_DATE - INTERVAL '60' DAY AS miss_clinic,
    -- Flag 3: Recent ER visit (REV 045X or POS 23) in last 35 days
    EXISTS (
      SELECT 1
      FROM claims e
      WHERE e.member_id = c.member_id
        AND (e.revenue_code LIKE '045%' OR e.place_of_service = '23')
        AND e.service_date >= CURRENT_DATE - INTERVAL '35' DAY
    ) AS recent_er
  FROM claims c
  INNER JOIN ppo_top5 t ON c.member_id = t.member_id
  WHERE c.plan_type = 'PPO'
    AND c.YEAR = 2025
  GROUP BY c.member_id
),

-- Step 3: Score and select high-risk members (score >= 2) for shift recommendation
final_list AS (
  SELECT member_id,
    (COALESCE(skip_glucose_check::int, 0) + COALESCE(miss_clinic::int, 0) + COALESCE(recent_er::int, 0)) AS risk_score,
    CASE WHEN skip_glucose_check THEN 'Y' ELSE 'N' END AS skip_glucose,
    CASE WHEN miss_clinic THEN 'Y' ELSE 'N' END AS miss_clinic,
    CASE WHEN recent_er THEN 'Y' ELSE 'N' END AS recent_er
  FROM risk_flags
  WHERE (COALESCE(skip_glucose_check::int, 0) + COALESCE(miss_clinic::int, 0) + COALESCE(recent_er::int, 0)) >= 2
)

-- Output: Top 500 high-risk members to recommend for C-SNP shift
SELECT member_id, risk_score, skip_glucose, miss_clinic, recent_er
FROM final_list
ORDER BY risk_score DESC, member_id
LIMIT 500;
