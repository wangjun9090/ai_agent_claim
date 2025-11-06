# -*- coding: utf-8 -*-
"""
Propensity Score Matching (PSM) + outcome comparison
CSNP vs PPO using January 2023 severity proxy
"""

import pandas as pd
import numpy as np
from causalinference import CausalModel
import matplotlib.pyplot as plt
import seaborn as sns

# -------------------------------------------------
# 1. Load data
# -------------------------------------------------
df = pd.read_csv('baseline_and_claims.csv')

# -------------------------------------------------
# 2. Pre-process
# -------------------------------------------------
# Treatment: 1 = CSNP, 0 = PPO
df['plan'] = df['plan_type'].map({'CSNP': 1, 'PPO': 0})

# Gender: M → 1, F → 0
df['gender'] = df['gender'].map({'M': 1, 'F': 0})

# ZIP: keep first 5 digits only
df['zip'] = df['zip'].astype(str).str[:5].astype(float)

# Ensure numeric types
df['age'] = df['age'].astype(int)
df['severity_jan'] = df['severity_jan'].astype(int)

# Drop rows with missing covariates
df = df.dropna(subset=['age', 'gender', 'zip', 'severity_jan', 'plan'])

# -------------------------------------------------
# 3. Propensity Score Estimation & Matching
# -------------------------------------------------
covariates = ['age', 'gender', 'zip', 'severity_jan']
X = df[covariates].values
y = df['plan'].values
outcome = df['total_claim_36m'].values

# CausalModel performs logistic regression + nearest-neighbor matching
cm = CausalModel(X=X, D=y, Y=outcome)
cm.est_propensity_s()          # Estimate propensity scores
cm.trim_s()                    # Optional: trim extreme scores
cm.est_via_matching(matches=1, caliper=0.05)  # 1:1 nearest, caliper 0.05

# -------------------------------------------------
# 4. Extract matched data
# -------------------------------------------------
# Indices of matched units
matched_idx = np.where(cm.matched)[0]
matched_df = df.iloc[matched_idx].copy()
matched_df['propensity'] = cm.propensity['fitted']

# Add matched pair info (optional)
matched_df['weight'] = cm.summary_stats['weights']

# -------------------------------------------------
# 5. Balance check (Standardized Mean Difference)
# -------------------------------------------------
def smd(group1, group2):
    mean1, mean2 = np.mean(group1), np.mean(group2)
    var1, var2 = np.var(group1), np.var(group2)
    pooled_sd = np.sqrt((var1 + var2) / 2)
    return np.abs(mean1 - mean2) / pooled_sd

balance = {}
for cov in covariates:
    g1 = matched_df[matched_df['plan'] == 1][cov]
    g0 = matched_df[matched_df['plan'] == 0][cov]
    balance[cov] = smd(g1, g0)

print("=== Balance (SMD) after matching ===")
for k, v in balance.items():
    print(f"{k}: {v:.3f}  (target < 0.1)")

# -------------------------------------------------
# 6. Outcome comparison
# -------------------------------------------------
summary = (
    matched_df.groupby('plan_type')['total_claim_36m']
    .agg(['count', 'mean', 'std', 'median'])
    .round(2)
)
print("\n=== 36-month claim summary (matched) ===")
print(summary)

# T-test (Welch)
from scipy.stats import ttest_ind
csnp_claims = matched_df[matched_df['plan'] == 1]['total_claim_36m']
ppo_claims  = matched_df[matched_df['plan'] == 0]['total_claim_36m']
t_stat, p_val = ttest_ind(csnp_claims, ppo_claims, equal_var=False)
print(f"\nWelch t-test: t = {t_stat:.3f}, p = {p_val:.4f}")

# -------------------------------------------------
# 7. Visualization
# -------------------------------------------------
plt.figure(figsize=(8, 5))
sns.boxplot(x='plan_type', y='total_claim_36m', data=matched_df, palette='Set2')
plt.title('36-Month Total Claims: CSNP vs PPO (Matched)')
plt.ylabel('Total Claim Amount ($)')
plt.xlabel('Plan')
plt.grid(True, axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()
plt.show()
