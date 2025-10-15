SELECT
    YEAR(PROC_DT) AS year,
    SUM(has_diabetes_proc) / COUNT(DISTINCT MembershipNumber) AS diabetes_prevalence,
    SUM(has_cardiac_proc) / COUNT(DISTINCT MembershipNumber) AS cardiac_prevalence,
    SUM(has_copd_proc) / COUNT(DISTINCT MembershipNumber) AS copd_prevalence
FROM hive_metastore.off_orig.member_claim_amt
GROUP BY YEAR(PROC_DT)
