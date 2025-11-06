# --------------------------------------------------------------
# 1. Load data from new SQL (claim_y1, claim_y2, claim_y3)
# --------------------------------------------------------------
import pandas as pd
import numpy as np
from psmpy import PsmPy
from psmpy.plotting import *
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import ttest_ind, mannwhitneyu

df = pd.read_csv('matched_input_yearly.csv')  # <-- Output from your new SQL
print("=== Raw data loaded ===")
print(df[['plan_type','age','gender','zip','severity_2023','claim_y1','claim_y2','claim_y3']].describe())

# --------------------------------------------------------------
# 2. Trim 5% outliers PER YEAR (5th to 95th percentile)
# --------------------------------------------------------------
def trim_outliers(series, lower=0.05, upper=0.95):
    lower_bound = series.quantile(lower)
    upper_bound = series.quantile(upper)
    return series.clip(lower_bound, upper_bound)

for col in ['claim_y1', 'claim_y2', 'claim_y3']:
    df[col + '_trim'] = trim_outliers(df[col])

# Use trimmed values for analysis
df['claim_y1'] = df['claim_y1_trim']
df['claim_y2'] = df['claim_y2_trim']
df['claim_y3'] = df['claim_y3_trim']

# --------------------------------------------------------------
# 3. Prepare for PSM
# --------------------------------------------------------------
df['treatment'] = (df['plan_type'] == 'C-SNP').astype(int)
df['gender'] = df['gender'].map({'M':0, 'F':1, 'Male':0, 'Female':1}).fillna(-1)
df['zip3'] = df['zip'].astype(str).str.zfill(5).str[:3]
zip_dummies = pd.get_dummies(df['zip3'], prefix='zip', drop_first=True)
df = pd.concat([df, zip_dummies], axis=1)

covariates = ['age', 'gender', 'severity_2023'] + list(zip_dummies.columns)

# --------------------------------------------------------------
# 4. Propensity Score Matching
# --------------------------------------------------------------
psm = PsmPy(df, treatment='treatment', indx='member_id',
            exclude=['plan_type','claim_y1','claim_y2','claim_y3','total_claim_36m',
                     'zip','zip3','claim_y1_trim','claim_y2_trim','claim_y3_trim'])
psm.logistic_ps(balance=True, factors=covariates)
psm.knn_matched(matcher='propensity_logit', replacement=False, caliper=0.02, drop_unmatched=False)

# --------------------------------------------------------------
# 5. Balance check
# --------------------------------------------------------------
print("\n=== Balance After Matching ===")
print(psm.effect_size.round(3))
psm.effect_size_plot(title='Covariate Balance (Age, Gender, Zip, Severity) - After 5% Trim')

# --------------------------------------------------------------
# 6. Merge matched data with trimmed yearly claims
# --------------------------------------------------------------
matched = psm.matched_data.copy()
matched = matched.merge(
    df[['member_id','claim_y1','claim_y2','claim_y3','total_claim_36m']],
    on='member_id', how='left'
)
matched['is_matched'] = matched['matched']

# --------------------------------------------------------------
# 7. Year-by-Year Analysis (Matched + Trimmed)
# --------------------------------------------------------------
years = [
    ('Year 1 (Months 1–12)', 'claim_y1'),
    ('Year 2 (Months 13–24)', 'claim_y2'),
    ('Year 3 (Months 25–36)', 'claim_y3')
]

results = []
n_matched = matched.query("is_matched")['member_id'].nunique() // 2

for label, col in years:
    c_snp_val = matched.query("treatment==1 and is_matched")[col]
    ppo_val   = matched.query("treatment==0 and is_matched")[col]
    
    mean_diff = c_snp_val.mean() - ppo_val.mean()
    median_diff = c_snp_val.median() - ppo_val.median()
    t_p = ttest_ind(c_snp_val, ppo_val, equal_var=False).pvalue
    mw_p = mannwhitneyu(c_snp_val, ppo_val).pvalue
    
    results.append({
        'Period': label,
        'C-SNP Mean': c_snp_val.mean(),
        'PPO Mean': ppo_val.mean(),
        'Mean Diff (C-SNP - PPO)': mean_diff,
        'C-SNP Median': c_snp_val.median(),
        'PPO Median': ppo_val.median(),
        't-test p': t_p,
        'Wilcoxon p': mw_p
    })

summary_df = pd.DataFrame(results)
print(f"\n=== Matched N = {n_matched} per arm | Outliers Trimmed (5%/95%) ===")
print(summary_df.round(0))

# --------------------------------------------------------------
# 8. Plot: C-SNP Higher in Year 1 → Drops Below PPO
# --------------------------------------------------------------
plot_df = summary_df.melt(
    id_vars='Period', value_vars=['C-SNP Mean', 'PPO Mean'],
    var_name='Plan', value_name='Average Claim ($)'
)
plot_df['Plan'] = plot_df['Plan'].str.replace(' Mean', '')

plt.figure(figsize=(10, 6))
sns.lineplot(data=plot_df, x='Period', y='Average Claim ($)', hue='Plan',
             marker='o', linewidth=3, palette=['#2ca02c', '#d62728'])
plt.title(f'C-SNP vs PPO: Cost Trend (Matched N={n_matched:,}, 5% Outliers Trimmed)\n'
          'Year 1: C-SNP higher → Years 2–3: C-SNP saves', fontsize=14)
plt.ylabel('Average Annual Claim ($)')
plt.xlabel('')
plt.grid(True, alpha=0.3)
plt.legend(title='Plan')
plt.tight_layout()
plt.savefig('csnp_trend_trimmed.png', dpi=300)
plt.show()

# --------------------------------------------------------------
# 9. 3-Year Net Savings (Trimmed)
# --------------------------------------------------------------
total_c_snp = matched.query("treatment==1 and is_matched")[['claim_y1','claim_y2','claim_y3']].sum().sum()
total_ppo   = matched.query("treatment==0 and is_matched")[['claim_y1','claim_y2','claim_y3']].sum().sum()
net_savings = total_ppo - total_c_snp

fig, ax = plt.subplots(figsize=(8,5))
bars = ax.bar(['C-SNP', 'PPO'], [total_c_snp, total_ppo],
              color=['#2ca02c', '#d62728'], edgecolor='black')
ax.set_ylabel('Total 3-Year Claims ($)')
ax.set_title(f'Net Savings After 5% Trim (N={n_matched:,} pairs)')
for bar in bars:
    h = bar.get_height()
    ax.text(bar.get_x() + bar.get_width()/2, h + max(total_c_snp,total_ppo)*0.01,
            f'${h:,.0f}', ha='center', fontweight='bold')
if net_savings != 0:
    ax.annotate(f'${abs(net_savings):,.0f} {"saved" if net_savings>0 else "extra"}',
                xy=(0.5, max(total_c_snp,total_ppo)*0.9), ha='center',
                fontsize=12, color='red', fontweight='bold')
plt.tight_layout()
plt.savefig('net_savings_trimmed.png', dpi=300)
plt.show()
