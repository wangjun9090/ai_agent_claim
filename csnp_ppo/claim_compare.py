# --------------------------------------------------------------
# 1. Load the CSV produced by the SQL (member_id, plan_type, ...)
# --------------------------------------------------------------
import pandas as pd
import numpy as np
from psmpy import PsmPy
from psmpy.plotting import *
import matplotlib.pyplot as plt
import seaborn as sns

df = pd.read_csv('matched_input.csv')          # <-- your SQL output
df = df.rename(columns={'total_claim_36m': 'claim_36m'})

# ----------------------------------------------------------------
# 2. Quick sanity checks (optional but recommended)
# ----------------------------------------------------------------
print(df[['plan_type','age','gender','zip','severity_2023','claim_36m']].describe(include='all'))

# ----------------------------------------------------------------
# 3. Prepare variables for PSM
# ----------------------------------------------------------------
#   - treatment : 1 = C-SNP, 0 = PPO
df['treatment'] = (df['plan_type'] == 'C-SNP').astype(int)

#   - gender : map to 0/1
df['gender'] = df['gender'].map({'M':0, 'F':1, 'Male':0, 'Female':1})

#   - zip : one-hot (too many levels → use the first 3 digits for coarsening)
df['zip3'] = df['zip'].astype(str).str[:3]
zip_dummies = pd.get_dummies(df['zip3'], prefix='zip', drop_first=True)
df = pd.concat([df, zip_dummies], axis=1)

#   - list of covariates for the logit model
covariates = ['age', 'gender', 'severity_2023'] + list(zip_dummies.columns)

# ----------------------------------------------------------------
# 4. Run Propensity-Score Matching (psmpy)
# ----------------------------------------------------------------
psm = PsmPy(
    df,
    treatment='treatment',
    indx='member_id',
    exclude=['plan_type','claim_36m','zip','zip3']   # keep only covariates
)

# Logistic PS model
psm.logistic_ps(balance=True, factors=covariates)

# 1:1 nearest-neighbor WITHOUT replacement, tight caliper
psm.knn_matched(
    matcher='propensity_logit',
    replacement=False,
    caliper=0.05                     # 0.05 ≈ 5 % of the SD of the logit PS
)

# ----------------------------------------------------------------
# 5. Inspect balance (standardized mean differences)
# ----------------------------------------------------------------
psm.effect_size_plot(title='Balance after Matching (severity_2023 included)')

# ----------------------------------------------------------------
# 6. Merge matched pairs back with claim amounts
# ----------------------------------------------------------------
matched = psm.matched_data.copy()
matched = matched.merge(
    df[['member_id','claim_36m']],
    on='member_id',
    how='left'
)

# ----------------------------------------------------------------
# 7. Outcome analysis (t-test + medians)
# ----------------------------------------------------------------
c_snp = matched[matched['treatment']==1]['claim_36m']
ppo   = matched[matched['treatment']==0]['claim_36m']

from scipy.stats import ttest_ind, mannwhitneyu

t_stat, t_p = ttest_ind(c_snp, ppo, equal_var=False)
mw_stat, mw_p = mannwhitneyu(c_snp, ppo, alternative='two-sided')

print(f"\nMatched N = {len(c_snp)} per arm")
print(f"Mean  C-SNP: ${c_snp.mean():,.0f} | PPO: ${ppo.mean():,.0f}")
print(f"Median C-SNP: ${c_snp.median():,.0f} | PPO: ${ppo.median():,.0f}")
print(f"t-test  p = {t_p:.6f}")
print(f"Wilcoxon p = {mw_p:.6f}")

# ----------------------------------------------------------------
# 8. Simple business-impact bar chart (total savings)
# ----------------------------------------------------------------
total_c_snp = c_snp.sum()
total_ppo   = ppo.sum()
savings     = total_ppo - total_c_snp      # positive = C-SNP cheaper

fig, ax = plt.subplots(figsize=(8,5))
bars = ax.bar(
    ['C-SNP', 'PPO'],
    [total_c_snp, total_ppo],
    color=['#2ca02c', '#7f7f7f'],
    edgecolor='black'
)
ax.set_ylabel('Total 36-Month Claims ($)')
ax.set_title('Matched Cohort (N={:,} per arm)'.format(len(c_snp)))
ax.yaxis.get_major_formatter().set_scientific(False)

# annotate totals
for bar in bars:
    h = bar.get_height()
    ax.text(bar.get_x() + bar.get_width()/2, h + max(total_c_snp,total_ppo)*0.01,
            f'${h:,.0f}', ha='center', fontsize=11, fontweight='bold')

# savings arrow
if savings != 0:
    ax.annotate(
        f'${abs(savings):,.0f} {"saved" if savings>0 else "extra"}',
        xy=('C-SNP', total_c_snp), xycoords='data',
        xytext=('PPO', total_ppo), textcoords='data',
        arrowprops=dict(arrowstyle='->', lw=2, color='red'),
        fontsize=12, color='red', ha='center'
    )

plt.tight_layout()
plt.savefig('csnp_vs_ppo_matched_savings.png', dpi=300)
plt.show()
