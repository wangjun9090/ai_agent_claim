WITH chronic_highcost_2023 AS (
  SELECT
    SubProduct,
    MembershipNumber,
    claim_amt_2023,
    NTILE(20) OVER (
      PARTITION BY SubProduct
      ORDER BY claim_amt_2023 DESC
    ) AS ntile_20_2023
  FROM hive_metastore.off_orig.enhanced_member_features
  WHERE (has_cardiac_proc = 1 OR has_diabetes_proc = 1 OR has_copd_proc = 1)
    AND claim_amt_2023 IS NOT NULL
),
-- Total high-cost population summary
total_summary_2023 AS (
  SELECT
    SubProduct,
    COUNT(*) AS total_count_2023,
    COUNT(DISTINCT MembershipNumber) AS unique_members_2023,
    SUM(claim_amt_2023) AS total_claim_amt_2023,
    AVG(claim_amt_2023) AS avg_claim_amt_2023,
    MIN(claim_amt_2023) AS min_claim_2023,
    MAX(claim_amt_2023) AS max_claim_2023,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY claim_amt_2023) AS median_claim_2023,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY claim_amt_2023) AS p75_claim_2023,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY claim_amt_2023) AS p90_claim_2023
  FROM chronic_highcost_2023
  GROUP BY SubProduct
),
-- Top 5% of high-cost claims summary
top5_summary_2023 AS (
  SELECT
    SubProduct,
    COUNT(*) AS top5_count_2023,
    COUNT(DISTINCT MembershipNumber) AS top5_unique_members_2023,
    SUM(claim_amt_2023) AS top5_total_amt_2023,
    AVG(claim_amt_2023) AS top5_avg_amt_2023,
    MIN(claim_amt_2023) AS top5_min_amt_2023,
    MAX(claim_amt_2023) AS top5_max_amt_2023,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY claim_amt_2023) AS top5_median_amt_2023
  FROM chronic_highcost_2023
  WHERE ntile_20_2023 = 1
  GROUP BY SubProduct
)
SELECT
  ts23.SubProduct,
  
  -- TOTAL HIGH-COST POPULATION (Claims > $15K)
  ts23.total_count_2023,
  ts23.unique_members_2023,
  ts23.total_claim_amt_2023,
  ts23.avg_claim_amt_2023,
  ts23.median_claim_2023,
  ts23.min_claim_2023,
  ts23.max_claim_2023,
  ts23.p75_claim_2023,
  ts23.p90_claim_2023,
  
  -- TOP 5% OF HIGH-COST CLAIMS
  t5_23.top5_count_2023,
  t5_23.top5_unique_members_2023,
  t5_23.top5_total_amt_2023,
  t5_23.top5_avg_amt_2023,
  t5_23.top5_median_amt_2023,
  t5_23.top5_min_amt_2023,
  t5_23.top5_max_amt_2023,
  
  -- COMPARISONS: Top 5% vs Total
  ROUND(t5_23.top5_total_amt_2023 * 100.0 / NULLIF(ts23.total_claim_amt_2023, 0), 2) AS top5_pct_of_total_amt,
  ROUND(t5_23.top5_count_2023 * 100.0 / NULLIF(ts23.total_count_2023, 0), 2) AS top5_pct_of_total_count,
  ROUND(t5_23.top5_avg_amt_2023 / NULLIF(ts23.avg_claim_amt_2023, 0), 2) AS top5_avg_vs_overall_avg_ratio

FROM total_summary_2023 ts23
LEFT JOIN top5_summary_2023 t5_23
  ON ts23.SubProduct = t5_23.SubProduct
ORDER BY t5_23.top5_total_amt_2023 DESC;
