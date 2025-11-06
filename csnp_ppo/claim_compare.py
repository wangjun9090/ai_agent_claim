# --------------------------------------------------------------
# 1. Load data
# --------------------------------------------------------------
import pandas as pd
import numpy as np
from psmpy import PsmPy
from psmpy.plotting import *
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import ttest_ind, mannwhitneyu

df = pd.read_csv('matched_input.csv')
df = df.rename(columns={'total_claim_36m': 'claim_36m'})

# --------------------------------------------------------------
# 2. Sanity check
# --------------------------------------------------------------
print("=== Raw data summary ===")
print(df[['plan_type','age','gender','zip','severity_2023','claim_36m']].describe(include='all'))

# --------------------------------------------------------------
# 3. Prepare variables
# --------------------------------------------------------------
df['treatment'] = (df['plan_type'] == 'C-SNP').astype(int)
df['gender'] = df['gender'].map({'M':0, 'F':1, 'Male':0, 'Female':1}).fillna(-1)

# Coarsen zip to first 3 digits
df['zip3'] = df['zip'].astype(str).str.zfill(5).str[:3]
zip_dummies = pd.get_dummies(df['zip3'], prefix='zip', drop_first=True)
df = pd.concat([df, zip_dummies], axis=1)

covariates = ['age', 'gender', 'severity_2023'] + list(zip_dummies.columns)

# --------------------------------------------------------------
# 4. Propensity Score Matching
# --------------------------------------------------------------
psm = PsmPy(
    df,
    treatment='treatment',
    indx='member_id',
    exclude=['plan_type','claim_36m','zip','zip3']
)

psm.logistic_ps(balance=True, factors=covariates)

# Tight caliper + keep all samples (including unmatched)
psm.knn_matched(
    matcher='propensity_logit',
    replacement=False,
    caliper=0.02,
    drop_unmatched=False          # Keep unmatched for outlier analysis
)

# --------------------------------------------------------------
# 5. Balance diagnostics
# --------------------------------------------------------------
print("\n=== Balance Table (Matched) ===")
print(psm.effect_size)

psm.effect_size_plot(title='Covariate Balance After Matching (caliper=0.02)')

# --------------------------------------------------------------
# 6. Merge claim amounts
# --------------------------------------------------------------
matched = psm.matched_data.copy()
matched = matched.merge(
    df[['member_id','claim_36m']],
    on='member_id',
    how='left'
)
matched['is_matched'] = matched['matched']

# --------------------------------------------------------------
# 7. Outcome analysis (matched pairs only)
# --------------------------------------------------------------
c_snp = matched.query("treatment==1 and is_matched")['claim_36m']
ppo   = matched.query("treatment==0 and is_matched")['claim_36m']

n_matched = len(c_snp)
print(f"\n=== Matched N = {n_matched} per arm ===")
print(f"Mean   C-SNP: ${c_snp.mean():,.0f} | PPO: ${ppo.mean():,.0f}")
print(f"Median C-SNP: ${c_snp.median():,.0f} | PPO: ${ppo.median():,.0f}")

t_stat, t_p = ttest_ind(c_snp, ppo, equal_var=False)
mw_stat, mw_p = mannwhitneyu(c_snp, ppo, alternative='two-sided')
print(f"t-test p = {t_p:.6f}")
print(f"Wilcoxon p = {mw_p:.6f}")

# --------------------------------------------------------------
# 8. Year-by-Year Trend: C-SNP should show higher Year 1, then drop below PPO
# --------------------------------------------------------------
# Assume your SQL already includes year-specific claims:
# claim_y1, claim_y2, claim_y3 (or derive from PROC_DT)
# If not, add to SQL: SUM(CASE WHEN YEAR(PROC_DT)=2023 THEN gl_amt ELSE 0 END) AS claim_y1, etc.

if all(col in df.columns for col in ['claim_y1','claim_y2','claim_y3']):
    # Merge year columns into matched
    matched = matched.merge(df[['member_id','claim_y1','claim_y2','claim_y3']], on='member_id', how='left')
    
    # Aggregate by plan & year
    yearly = matched.query("is_matched").melt(
        id_vars=['plan_type','member_id'],
        value_vars=['claim_y1','claim_y2','claim_y3'],
        var_name='year',
        value_name='claim'
    )
    yearly['year'] = yearly['year'].map({'claim_y1':'Year 1','claim_y2':'Year 2','claim_y3':'Year 3'})
    
    # Mean per year
    yearly_mean = yearly.groupby(['plan_type','year'])['claim'].mean().reset_index()
    
    plt.figure(figsize=(9,5))
    sns.lineplot(data=yearly_mean, x='year', y='claim', hue='plan_type',
                 marker='o', linewidth=2.5, palette=['#2ca02c','#d62728'])
    plt.title('Expected Trend: C-SNP Higher in Year 1, Then Drops Below PPO\n'
              '(Matched Cohort, N={:,} per arm)'.format(n_matched))
    plt.ylabel('Average Annual Claim ($)')
    plt.xlabel('')
    plt.grid(True, alpha=0.3)
    plt.legend(title='Plan')
    plt.tight_layout()
    plt.savefig('csnp_trend_expected.png', dpi=300)
    plt.show()
    
    # Print year-by-year comparison
    print("\n=== Year-by-Year Mean Claims (Matched) ===")
    print(yearly_mean.pivot(index='year', columns='plan_type', values='claim').round(0))
else:
    print("\nWarning: Year-specific claim columns (claim_y1/y2/y3) not found. "
          "Add to SQL to show expected trend.")

# --------------------------------------------------------------
# 9. Final CDF + Median/Mean Bar (business summary)
# --------------------------------------------------------------
plt.figure(figsize=(9,6))
sns.ecdfplot(data=matched.query("is_matched"), x='claim_36m', hue='plan_type',
             palette=['#2ca02c', '#d62728'], linewidth=2.5)
plt.xlim(0, 50000)
plt.title('Cumulative Distribution: \n'
          'C-SNP: Higher Year 1 → Expected Drop in Years 2–3', fontsize=14)
plt.xlabel('36-Month Claim ($)')
plt.ylabel('Proportion ≤ X')
plt.axvline(c_snp.median(), color='#2ca02c', linestyle='--')
plt.axvline(ppo.median(), color='#d62728', linestyle='--')
plt.legend(title='Plan')
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('cdf_with_trend_expectation.png', dpi=300)
plt.show()

# --------------------------------------------------------------
# 10. Outlier inspection (unmatched high-cost members)
# --------------------------------------------------------------
unmatched_high = matched.query("not is_matched and claim_36m > 100000")
print(f"\n=== High-Cost Unmatched Members ({len(unmatched_high)}) ===")
print(unmatched_high[['plan_type','claim_36m','severity_2023']].head())
