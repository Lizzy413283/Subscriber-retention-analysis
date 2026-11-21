

create database churn

use churn

select * from [dbo].[spotify_churn_dataset]

USE churn;

-- 1.Duplicate Records by user_id
SELECT user_id, COUNT(*) AS dup_count
FROM [dbo].[spotify_churn_dataset]
GROUP BY user_id
HAVING COUNT(*) > 1;


-- NULL Values Across Key Columns
SELECT 
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_age,
    SUM(CASE WHEN subscription_type IS NULL THEN 1 ELSE 0 END) AS null_sub_type,
    SUM(CASE WHEN listening_time IS NULL THEN 1 ELSE 0 END) AS null_listening_time,
    SUM(CASE WHEN skip_rate IS NULL THEN 1 ELSE 0 END) AS null_skip_rate,
    SUM(CASE WHEN is_churned IS NULL THEN 1 ELSE 0 END) AS null_churned
FROM [dbo].[spotify_churn_dataset]


-- 3.Data Anomalies / Outliers (e.g., negative values or extreme percentages)
SELECT 
    MIN(age) AS min_age, MAX(age) AS max_age,
    MIN(listening_time) AS min_listening, MAX(listening_time) AS max_listening,
    MIN(skip_rate) AS min_skip, MAX(skip_rate) AS max_skip
FROM [dbo].[spotify_churn_dataset]


CREATE OR ALTER VIEW [dbo.cleaned_spotify_churn] AS
SELECT 
    CAST(user_id AS INT) AS user_id,
    gender,
    CAST(age AS INT) AS age,
    country,
    subscription_type,
    CAST(listening_time AS INT) AS listening_time,
    CAST(songs_played_per_day AS INT) AS songs_played_per_day,
    ROUND(CAST(skip_rate AS FLOAT), 2) AS skip_rate,
    device_type,
    CAST(ads_listened_per_week AS INT) AS ads_listened_per_week,
    CAST(offline_listening AS INT) AS offline_listening,
    CAST(is_churned AS INT) AS is_churned
FROM [dbo].[spotify_churn_dataset]
GO

select * from [dbo.cleaned_spotify_churn]

--Overall Top-Line Churn Rate KPI
SELECT 
    COUNT(*) AS total_users,
    SUM(is_churned) AS churned_users,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 2) AS overall_churn_rate_pct
FROM [dbo.cleaned_spotify_churn]

--Churn Rate & Engagement by Subscription Tier
SELECT 
    subscription_type,
    COUNT(*) AS total_users,
    SUM(is_churned) AS churned_users,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(CAST(listening_time AS FLOAT)), 1) AS avg_listening_time
FROM [dbo.cleaned_spotify_churn]
GROUP BY subscription_type
ORDER BY churn_rate_pct DESC

select * from [dbo.cleaned_spotify_churn]

select * from [dbo].[spotify_churn_dataset]


--Ad Load Impact on Churn (Free & Ad-Supported Users)
SELECT 
    CASE 
        WHEN ads_listened_per_week = 0 THEN '0 Ads (Paid/Other)'
        WHEN ads_listened_per_week BETWEEN 1 AND 10 THEN '1-10 Ads (Low)'
        WHEN ads_listened_per_week BETWEEN 11 AND 25 THEN '11-25 Ads (Medium)'
        ELSE '26+ Ads (High Load)'
    END AS ad_exposure_bucket,
    COUNT(*) AS total_users,
    SUM(is_churned) AS churned_users,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 2) AS churn_rate_pct
FROM [dbo.cleaned_spotify_churn]
GROUP BY 
    CASE 
        WHEN ads_listened_per_week = 0 THEN '0 Ads (Paid/Other)'
        WHEN ads_listened_per_week BETWEEN 1 AND 10 THEN '1-10 Ads (Low)'
        WHEN ads_listened_per_week BETWEEN 11 AND 25 THEN '11-25 Ads (Medium)'
        ELSE '26+ Ads (High Load)'
    END
ORDER BY churn_rate_pct DESC

-- Feature Stickiness (Offline Listening) & Platform Device Friction
SELECT 
    device_type,
    offline_listening,
    COUNT(*) AS total_users,
    SUM(is_churned) AS churned_users,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 2) AS churn_rate_pct
FROM [dbo.cleaned_spotify_churn]
GROUP BY device_type, offline_listening
ORDER BY device_type, offline_listening

--Engagement Quartiles vs Churn
WITH engagement_cohorts AS (
    SELECT 
        user_id,
        songs_played_per_day,
        skip_rate,
        is_churned,
        NTILE(4) OVER (ORDER BY songs_played_per_day DESC) AS engagement_quartile
    FROM [dbo.cleaned_spotify_churn]
)
SELECT 
    engagement_quartile, -- Q1 = Most Active, Q4 = Least Active
    COUNT(user_id) AS total_users,
    ROUND(AVG(CAST(songs_played_per_day AS FLOAT)), 1) AS avg_daily_songs,
    ROUND(AVG(skip_rate), 2) AS avg_skip_rate,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 2) AS churn_rate_pct
FROM engagement_cohorts
GROUP BY engagement_quartile
ORDER BY engagement_quartile


-- subscription type vs churn rate
SELECT 
    subscription_type,
    COUNT(*) AS total_users,
    SUM(is_churned) AS churned_users,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(CAST(listening_time AS FLOAT)), 1) AS avg_listening_time
FROM [dbo.cleaned_spotify_churn]
GROUP BY subscription_type
ORDER BY churn_rate_pct DESC


WITH daily_churn_by_country AS (
    SELECT 
        country,
        COUNT(*) AS daily_churn_count
    FROM [dbo.cleaned_spotify_churn]
    WHERE is_churned = 1
    GROUP BY country
)
SELECT 
    AVG(daily_churn_count) AS avg_churn_per_country
FROM daily_churn_by_country

-- country churn rate and offline listening
SELECT 
    country,
    offline_listening,
    COUNT(*) AS total_users,
    SUM(is_churned) AS total_churned,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(CAST(listening_time AS FLOAT)), 1) AS avg_listening_time
FROM [dbo.cleaned_spotify_churn]
GROUP BY country, offline_listening
ORDER BY churn_rate_pct DESC


 --Countries represented in the dataset
SELECT COUNT(DISTINCT country) AS unique_country_count
FROM [dbo.cleaned_spotify_churn]

--distinct countries by subscription
SELECT 
    country,
    COUNT(*) AS total_users,
    SUM(is_churned) AS churned_users,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 2) AS churn_rate_pct
FROM [dbo.cleaned_spotify_churn]
GROUP BY country
ORDER BY churn_rate_pct DESC


--Age by listening time
SELECT 
    age,
    COUNT(*) AS total_users,
    ROUND(AVG(CAST(listening_time AS FLOAT)), 1) AS avg_listening_time
FROM [dbo.cleaned_spotify_churn]
GROUP BY age
ORDER BY age ASC


-- Age by Listening time
SELECT 
    CASE 
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 49 THEN '35-49'
        ELSE '50+'
    END AS age_group,
    COUNT(*) AS total_users,
    ROUND(AVG(CAST(listening_time AS FLOAT)), 1) AS avg_listening_time
FROM [dbo.cleaned_spotify_churn]
GROUP BY 
    CASE 
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 49 THEN '35-49'
        ELSE '50+'
    END
ORDER BY avg_listening_time DESC


--Age by user device type
SELECT 
    CASE 
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 49 THEN '35-49'
        ELSE '50+'
    END AS age_group,
    device_type,
    COUNT(*) AS total_users
FROM [dbo.cleaned_spotify_churn]
GROUP BY 
    CASE 
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 49 THEN '35-49'
        ELSE '50+'
    END,
    device_type
ORDER BY age_group, total_users DESC


-- Agegroup by churn rate
SELECT 
    CASE 
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 49 THEN '35-49'
        ELSE '50+'
    END AS age_group,
    COUNT(*) AS total_users,
    SUM(CAST(is_churned AS INT)) AS total_churned,
    ROUND(AVG(CAST(is_churned AS FLOAT)) * 100, 2) AS churn_rate_pct
FROM dbo.[dbo.cleaned_spotify_churn]
GROUP BY 
    CASE 
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 49 THEN '35-49'
        ELSE '50+'
    END
ORDER BY churn_rate_pct DESC