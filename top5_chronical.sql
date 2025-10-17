WITH all_high_risk AS (
  SELECT DISTINCT c.MembershipNumber AS member_id
  FROM hive_metastore.off_orig.claims_member c
  INNER JOIN hive_metastore.off_orig.enhanced_member_features t
    ON c.MembershipNumber = t.MembershipNumber
  WHERE t.plan_type = 'PPO'
    AND t.claim_amt_2025 >= (
      SELECT PERCENTILE_APPROX(claim_amt_2025, 0.95)
      FROM hive_metastore.off_orig.enhanced_member_features
      WHERE plan_type = 'PPO'
    )
    AND c.PROC_DT BETWEEN '2025-01-01' AND '2025-12-31'
),
risk_score AS (
  SELECT member_id,
    COALESCE(
      (CASE WHEN MAX(CASE WHEN c.PROC_CD IN ('83036', '82947') THEN c.PROC_DT END) < CURRENT_DATE - INTERVAL '60' DAY THEN 2 ELSE 0 END) +
      (CASE WHEN MAX(CASE WHEN c.PROC_CD IN ('93000', '93005') THEN c.PROC_DT END) < CURRENT_DATE - INTERVAL '60' DAY THEN 2 ELSE 0 END) +
      (CASE WHEN MAX(CASE WHEN c.PROC_CD IN ('94010', '94200') THEN c.PROC_DT END) < CURRENT_DATE - INTERVAL '60' DAY THEN 2 ELSE 0 END), 0
    ) AS risk_score
  FROM hive_metastore.off_orig.claims_member c
  INNER JOIN all_high_risk ar ON c.MembershipNumber = ar.member_id
  WHERE c.PROC_DT BETWEEN '2025-01-01' AND '2025-12-31'
  GROUP BY member_id
)
SELECT member_id, risk_score,
  CASE
    WHEN risk_score >= 2 THEN 'High Risk - Shift to C-SNP'
    ELSE 'Monitor'
  END AS action
FROM risk_score
ORDER BY risk_score DESC
LIMIT 2451;
