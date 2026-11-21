## Who Leaves and Can We Tell in Advance
# A Customer Churn Study of Spotify Users

## 1. Brief description

An end-to-end analysis of which Spotify users churn and why. SQL Server prepares the data, Python explores it and builds prediction models, and Tableau presents the results for decision-makers.

**Business question:** which users are most likely to churn, and where should retention effort go first?

**Objectives**
- Measure the overall churn rate.
- Compare churn across demographics, subscription plans and devices.
- Test whether listening behavior (usage, skips, ads, offline listening) predicts churn.
- Identify which features raise or lower churn risk, and in which direction.
- Find where the largest number of subscribers is lost.
- Build a model that scores each user's churn risk and check whether it is good enough to guide retention.

**Headline result:** about 26% of 8,000 users churned, and churn is spread evenly across plans, devices, countries and listening behavior. A random forest scored a ROC-AUC of 0.514 (0.5 is random guessing), so the available features carry almost no predictive signal.

**Workflow:** SQL (clean and prepare) → Python (explore, model) → Tableau (communicate)

**Tools:** SQL Server (SSMS), Python 3.12 (pandas, NumPy, matplotlib, seaborn, SciPy, scikit-learn, SQLAlchemy, pyodbc), Jupyter Notebook in VS Code, Tableau.

## 2. Installation

**Requirements:** Python 3.12, Conda (Anaconda or Miniconda), and, only if loading from SQL Server, the Microsoft ODBC Driver 17 or 18 for SQL Server.

1. Create the environment and install the libraries:
   ```
   conda create -n churn-env python=3.12 -y
   conda activate churn-env
   pip install -r requirements.txt
   ```
2. Open `churn.ipynb` in VS Code or Jupyter and select the `churn-env` kernel.
3. In the data-loading cell, use **one** of these:
   - **CSV (simplest):** `df = pd.read_csv("Dataset/<file_name>.csv")`
   - **SQL Server:** set your own server and database names in the connection string.
4. Run all cells. Exports are written to `output/`.

## 3. Data sources

Source: [add the dataset source and link]

8,000 users and 12 columns, with no missing values. [confirm duplicate check result]

| Column | Type | Description |
|---|---|---|
| `user_id` | integer | Unique user identifier |
| `gender` | text | Male, Female or Other |
| `age` | integer | User age in years |
| `country` | text | Country code (AU, CA, DE, FR, IN, PK, UK, US) |
| `subscription_type` | text | Free, Family, Premium or Student |
| `listening_time` | integer | Total listening time [add unit] |
| `songs_played_per_day` | integer | Average songs played per day |
| `skip_rate` | decimal | Share of songs skipped (0 to 0.6) |
| `device_type` | text | Desktop, Mobile or Web |
| `ads_listened_per_week` | integer | Ads heard per week (0 for paid plans) |
| `offline_listening` | integer | 1 if the user listens offline, otherwise 0 |
| `is_churned` | integer | **Target:** 1 if the user churned, otherwise 0 |

**Pre-processing**
- **SQL:** [list the cleaning steps applied in `Spotify churn.sql`, e.g. handling nulls, fixing data types, removing duplicates]. The cleaned table was loaded into Python through SQLAlchemy and pyodbc. [or: exported to CSV, delete whichever does not apply]
- **Python:** created `age_group` (under 25, 25-34, 35-44, 45+), `ads_level` (no ads, some ads, heavy ads) and `skip_level` (low, medium, high skip rate, in equal thirds). For modeling, numeric features were standardized and categories one-hot encoded.

## 4. Code structure

```
├── churn.ipynb          # Main analysis notebook
├── Spotify churn.sql    # SQL cleaning queries
├── Dataset/             # Input data
├── output/              # CSVs exported for Tableau
├── requirements.txt     # Python libraries
├── .gitignore
└── README.md
```

- **`Spotify churn.sql`:** cleans and prepares the raw data in SQL Server.
- **`churn.ipynb`:** loads the cleaned data, then works through segment analysis, behavior analysis, the logistic regression and the random forest, and exports results.
- **`output/`:** summary tables and the risk list that feed the Tableau dashboard.

## 5. Results and evaluation

### Evaluation approach
- **Segment analysis:** compared churn rates by subscription type, device, country, gender and age group, and built a "where is the money" table (churn rate, users, churned users and share of all churn for every segment). Heatmaps compared subscription type with skip rate and with ad exposure.
- **Behavior analysis:** compared the average behavior of churned and retained users, and churn rates across four equal bands of each behavior with 95% confidence intervals. Bar charts were used instead of boxplots because most ad values are zero and offline listening is a yes/no flag.
- [Statistical testing: Mann-Whitney U and chi-square tests. Fill in only if you ran them.]
- **Logistic regression:** standardized numeric features and one-hot encoded categories, to see the direction and size of each effect through coefficients and odds ratios.
- **Random forest:** class-weighted and scored with 5-fold cross-validation, so every user's churn probability comes from a model that never saw that user. Performance was measured with ROC-AUC, and users were grouped into High (top 20%), Medium and Low risk to check whether actual churn rises with predicted risk.

### Key findings

**Overall**
- About 26% of users churned. Churn is spread evenly: every segment sits within about 1.5 to 3 points of the average, so there is no single hotspot.

**Who churns**
- **Subscription type:** Family plans churn most (27.5%), followed by Student (26.2%), Premium (25.1%) and Free (24.9%). Free users do not churn more than paying users. The gap between Family and Free (2.6 points) is within the margin of error.
- **Device:** Mobile 26.9%, Desktop 25.7%, Web 25.0%. Device is not a meaningful driver, and lost users split about a third each.
- **Age:** users aged 45+ account for the largest share of churn (35%), mainly because they are the largest group. Their churn rate (26.2%) is average.
- **Country:** [add the country finding once you confirm the table, e.g. which countries lose the most subscribers and whether their rates are above 26%].

**Behavior**
- Listening time, songs per day, skip rate and offline listening show no clear relationship with churn. Churn stays within about 3 points of the average across every level.
- **Ads:** only Free users hear ads. Among them, churn drifts upward with ad exposure (about 23% in the lowest band to 27.5% in the highest), but the confidence intervals overlap, so it is a lead rather than a confirmed effect.
- Free users with medium skip rates churn at 21% versus 28% for high skippers. It is the largest gap in the data, but it was picked out of 12 groups and low-skip Free users (26%) do not follow the pattern, so it needs follow-up.

**Drivers (logistic regression)**
- Every effect is small, and the largest is about a 13% change in odds.
- **Lower risk:** Premium (about -11%) and Student plans (about -7%), compared with Family; India, the UK and Canada.
- **Higher risk:** ad exposure (about +10%), mobile devices (about +6%), Pakistan, Germany and France (about +8-9%).

**Where subscribers are lost**
- The biggest losses come from the biggest groups, not unusually risky ones. For example, Desktop and Mobile each account for about a third of all churned users.

**Prediction model**
- The random forest reached a **ROC-AUC of 0.514**. A ROC-AUC of 0.5 is random guessing, so the model is barely better than a coin flip: the available features carry very little predictive signal.
- Actual churn by predicted risk group:

| Risk group | Actual churn rate | Users |
|---|---|---|
| High (top 20%) | 28.3% | 1,652 |
| Medium | 25.4% | 2,398 |
| Low | 25.1% | 3,950 |

- Low and Medium are indistinguishable, and the High group churns only about 3 points more than the rest. Contacting the High group would reach about 23% of churners while contacting about 21% of users, little better than picking users at random.

**Overall conclusion:** churn in this dataset is not strongly explained by any single factor, so retention triggers based on plan, device or usage volume alone would have little payoff.

### Recommendations
1. **Do not build device-specific retention campaigns.** Device explains almost nothing, and each device holds about a third of churners.
2. **Test an ad-reduction or Premium-trial offer for heavy-ad Free users.** Ad exposure is the one behavior with an upward trend, and an A/B test would show whether it is real before it is rolled out.
3. **Look closer at Family plans.** They have the highest churn rate (27.5%), even though no ads are involved. Possible causes such as shared accounts or price sensitivity need testing, since this data cannot show them.
4. **Follow up on high-skip Free users,** the one group with a notable gap.
5. **Do not use the model's risk list for targeting.** With a ROC-AUC of 0.514, contacting the top 20% highest-risk users would capture little more churn than contacting users at random.
6. **Collect more data.** Revenue per plan, tenure, support contacts and listening trends over time would likely explain churn far better than the current columns, and the model should be retested once they are available.

### Limitations
- Results show associations, not causes.
- Differences between segments are small, so many may be random variation.
- The data is a snapshot, so it cannot show how behavior changed before users left.
- There is no revenue column, so lost subscribers stand in for lost revenue. A lost Premium subscriber likely costs more than a lost Free one.
- Ad exposure is entirely tied to the Free plan, so ads cannot be compared across plans.
- Each combined segment holds a few hundred to a couple thousand users, so small gaps may be noise.

### Dashboard
[Add a screenshot of the Tableau dashboard, e.g. `![Dashboard](images/dashboard.png)`. The Tableau Public link is under Links.]

Planned views: churned users by country, drivers of churn (logistic regression coefficients), and a risk-level breakdown (High, Medium, Low).

## 6. Future work

- Add revenue assumptions per plan to estimate the money lost.
- Compare more models and tune the decision threshold for retention outreach.
- Use SHAP values for richer explanations of each prediction.
- Schedule the pipeline as a `.py` script so the risk list refreshes on new data.
- Test retention offers with an A/B experiment.

## 7. Acknowledgements and references

- Dataset: [credit the dataset creator and link to the source]
- Built with pandas, NumPy, matplotlib, seaborn, SciPy, scikit-learn, SQLAlchemy and pyodbc


## 8. License
MIT License — Free to use, modify, distribute

## 9. Links

Lindsay

- LinkedIn: [add link]
- Tableau Public: [add link]
- Email or portfolio: [add link]