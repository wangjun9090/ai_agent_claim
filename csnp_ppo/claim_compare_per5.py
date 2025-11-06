# --------------------------------------------------------------
# Top 5 Outlier Comparison: C-SNP vs PPO (Matched + Trimmed)
# --------------------------------------------------------------
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load matched + trimmed data (from previous script)
matched = pd.read_csv('matched_trimmed_final.csv')  # <-- ensure this has claim_y1, y2, y3

# Filter matched only
matched = matched[matched['is_matched'] == True]

# Function to get top 5 highest claims in a period
def get_top5(df, period_col, plan):
    return (df[df['plan_type'] == plan]
            .nlargest(5, period_col)
            [['member_id', 'age', 'gender', 'severity_2023', period_col]]
            .copy())

# Extract top 5 for each year and plan
top5_data = []
for year, col in [('Year 1', 'claim_y1'), ('Year 2', 'claim_y2'), ('Year 3', 'claim_y3')]:
    c_snp_top = get_top5(matched, col, 'C-SNP')
    ppo_top   = get_top5(matched, col, 'PPO')
    
    c_snp_top['Plan'] = 'C-SNP'
    ppo_top['Plan'] = 'PPO'
    c_snp_top['Period'] = year
    ppo_top['Period'] = year
    
    top5_data.append(c_snp_top)
    top5_data.append(ppo_top)

top5_df = pd.concat(top5_data, ignore_index=True)
top5_df = top5_df.rename(columns={col: 'Claim Amount ($)' for col in ['claim_y1','claim_y2','claim_y3'] 
                                 if col in top5_df.columns})

# --------------------------------------------------------------
# Plot: Side-by-side bar chart of Top 5 per year
# --------------------------------------------------------------
plt.figure(figsize=(14, 8))
sns.barplot(
    data=top5_df,
    x='Period',
    y='Claim Amount ($)',
    hue='Plan',
    palette=['#2ca02c', '#d62728'],
    ci=None
)
plt.title('Top 5 Highest Claims per Year: C-SNP vs PPO (Matched Cohort)\n'
          'Outliers After 5% Trim', fontsize=16, fontweight='bold')
plt.ylabel('Claim Amount ($)')
plt.xlabel('')
plt.legend(title='Plan')
plt.grid(True, axis='y', alpha=0.3)

# Annotate values on bars
for container in plt.gca().containers:
    plt.gca().bar_label(container, fmt='$%,.0f', fontsize=9)

plt.tight_layout()
plt.savefig('top5_outliers_comparison.png', dpi=300)
plt.show()

# --------------------------------------------------------------
# Print detailed table
# --------------------------------------------------------------
print("\n=== Top 5 Outliers per Year (C-SNP vs PPO) ===")
for period in ['Year 1', 'Year 2', 'Year 3']:
    print(f"\n--- {period} ---")
    subset = top5_df[top5_df['Period'] == period].sort_values(['Plan', 'Claim Amount ($)'], ascending=[True, False])
    print(subset[['Plan', 'member_id', 'age', 'gender', 'severity_2023', 'Claim Amount ($)']].to_string(index=False))
