---- Scratch/research work to practice SQL/research on database

-- Join
SELECT
    i.period,
    i.cushing_inventory_mbbl,
    i.padd2_inventory_mbbl,
    r.padd2_crude_input_mbbl_d,
    r.padd2_refinery_utilization_pct
FROM inventories AS i
LEFT JOIN refinery_activity AS r
    ON i.period = r.period
WHERE i.cushing_inventory_mbbl IS NOT NULL
ORDER BY i.period;


-- Conceptually, the above join is something like:
-- inventories                     refinery_activity

-- 2004-04-09 | 21000 | 95000      2004-04-09 | 3500 | NULL
-- 2004-04-16 | 22000 | 96000      2004-04-16 | 3600 | NULL
--           \                         /
--            \      JOIN period      /
--             -----------------------
-- 2004-04-09 | 21000 | 95000 | 3500 | NULL
-- 2004-04-16 | 22000 | 96000 | 3600 | NULL



---- Lags
  -- (First lag is to calculate \deltaI_t = I_t - I_{t-1}, the weekly change in Cushing inventory)
    -- First, inspect the previous observation
SELECT
    period,
    cushing_inventory_mbbl,

    LAG (cushing_inventory_mbbl)                            -- Lag() is a window function (distinction: GROUP BY collapses rows; window functions do not)
        OVER (ORDER BY period)
        AS previous_week_inventory

FROM inventories
WHERE cushing_inventory_mbbl IS NOT NULL
ORDER BY period;
    -- Next, calculate the change. Recall the interpretation here is \deltaI_t > 0 implies Cushing stocks built; \deltaI_t < 0 implies Cushing stocks drew.
SELECT
    period,
    cushing_inventory_mbbl,

    LAG (cushing_inventory_mbbl)
        OVER (ORDER BY period)
        AS previous_week_inventory,

    cushing_inventory_mbbl
        - LAG (cushing_inventory_mbbl)
            OVER (ORDER BY period)
        AS inventory_change_mbbl

FROM inventories
WHERE cushing_inventory_mbbl IS NOT NULL
ORDER BY period;

  -- (Second lag is to calculate \deltaI_t = I_t - I_{t-4}, the four-week change in Cushing inventory, i.e., the monthly change in Cushing inventory)
SELECT
    period,
    cushing_inventory_mbbl,

    cushing_inventory_mbbl
        - LAG (cushing_inventroy_mbbl, 4)                      -- Here the 4 means four ROWS ago, but we already know and have validated that these observations are weekly
        OVER (ORDER BY period)
        AS four_week_inventory_change_mbbl

FROM inventories
WHERE cushing_inventory_mbbl IS NOT NULL
ORDER BY period;


---- Rolling Averages
  -- This is to calculate a four-week trailing average: Iˉ_t(4)​ = (I_t + I_{t-1} + I_{t-2} + I_{t-3})/4
SELECT
    period,
    cushing_inventory_mbbl,

    AVG (cushing_inventory_mbbl)
        OVER (
            ORDER BY period
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW           -- Here SQL averages the window t-3, t-2, t-1, and t. So as SQL moves to the next date t, the window does too.
        ) AS cushing_inventory_4w_avg

FROM inventories
WHERE cushing_inventory_mbbl IS NOT NULL
ORDER BY period;



---- Combining a JOIN with Window Functions
  -- This uses a Common Table Expression (CTE). Think of it as "Construct this temporary intermediate result, call it 'combined', and then perform another query on it."
WITH combined AS (
    SELECT
        i.period,
        i.cushing_inventory_mbbl,
        i.padd2_inventory_mbbl,
        r.padd2_crude_input_mbbl_d,
        r.padd2_refinery_utilization_pct
    FROM inventories AS i
    LEFT JOIN refinery_activity AS r
        ON i.period = r.period
    WHERE i.cushing_inventory_mbbl IS NOT NULL
)
SELECT
    period,

    cushing_inventory_mbbl,

    cushing_inventory_mbbl
        - LAG(cushing_inventory_mbbl)
            OVER (ORDER BY period)
        AS cushing_inventory_change_mbbl,

    AVG(cushing_inventory_mbbl)
        OVER (
            ORDER BY period
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ) AS cushing_inventory_4w_avg,

    padd2_crude_input_mbbl_d,

    AVG(padd2_crude_input_mbbl_d)
        OVER (
            ORDER BY period
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ) AS refinery_input_4w_avg

FROM combined
ORDER BY period;


---- Full point-in-time Z-Score Calculation (ONLY use query below the last comment to avoid redundancy as this section shows bit-by-bit buildup of workflow)
  -- This calculates InventoryZ_t ​= (​Inventory_t ​− μ_{same week of year​​})/σ_{same week of year}

  -- First, create the week_of_year variable
SELECT
    period,
    cushing_inventory_mbbl,
    CAST(strftime('%W', period)) AS INTEGER) AS week_of_year    -- strftime() extracts date components. For example, strftime('%Y', period) gives year; strftime('%W', period) gives a week number.
                                                                -- CAST above converts one datatype to another. Here we used CAST to change the output of strftime() to an INTEGER.
FROM combined
ORDER BY period;

  -- Second, calculate the seasonal means. Now group across YEARS, while holding week number fixed
WITH inventory_weeks AS (
    SELECT
        period,
        cushing_inventory_mbbl,
        CAST(strftime('%W', period) AS INTEGER) AS week_of_year
    FROM inventories
    WHERE cushing_inventory_mbbl IS NOT NULL
)
SELECT
    week_of_year,
    COUNT(*) AS observations,
    AVG(cushing_inventory_mbbl) AS mean_inventory_mbbl
FROM inventory_weeks
GROUP BY week_of_year                                           -- Note we now group and order by week_of_year instead of period
ORDER BY week_of_year;

    -- Finally, calculate the point-in-time seasonal Z-score. Note SQLite doesn't have a built-in STDEV() function, so we will implement one manually.
WITH inventory_weeks AS (
    SELECT
        period,
        cushing_inventory_mbbl,
        CAST(strftime('%W', period) AS INTEGER) AS week_of_year
    FROM inventories
    WHERE cushing_inventory_mbbl IS NOT NULL
),
historical AS (
    SELECT
        period,
        week_of_year,
        cushing_inventory_mbbl,

        COUNT(*) OVER (
            PARTITION BY week_of_year                           -- This PARTITION BY line tells SQL to create separate windows for Week 0, Week 1, Week 2, etc.
            ORDER BY period                                     -- Then this ORDER BY line puts each seasonal group into chronological order
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING    -- This line means uses all data up to present. Critically, it does NOT include current or future observations to avoid look-ahead bias.
        ) AS n_hist,

        SUM (cushing_inventory_mbbl) OVER (
            PARTITION BY week_of_year
            ORDER BY period
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS sum_hist,

        SUM (
            cushing_inventory_mbbl * cushing_inventory_mbbl
        ) OVER (
            PARTITION BY week_of_year
            ORDER BY period
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS sumsq_hist

    FROM inventory_weeks
),

historical_stats AS (                                                   -- Calculating historical mean and standard deviation 
    SELECT
        *,

        CASE
            WHEN n_hist > 0
            THEN sum_hist / n_hist
        END AS historical_mean,

        CASE
            WHEN n_hist > 1
            THEN sqrt (
                (
                    sumsq_hist
                    - sum_hist * sum_hist / n_hist
                )
                / (n_hist - 1)
            )
        END AS historical_std
    
    FROM historical
)

SELECT
    period,
    week_of_year,
    cushing_inventory_mbbl,
    n_hist,
    historical_mean,
    historical_std,

    (                                                              -- Calculating Z-Score
        cushing_inventory_mbbl - historical_mean
    )
    / NULLIF(historical_std, 0)             
        AS inventory_zscore

FROM historical_stats
ORDER BY period;






---- Revised Z-Score Query (to protect against tiny-sample Z-Score fluctuations)
WITH inventory_weeks AS (
    SELECT
        period,
        cushing_inventory_mbbl,
        CAST(strftime('%V', period) AS INTEGER) AS week_of_year
    FROM inventories
    WHERE cushing_inventory_mbbl IS NOT NULL
),

historical AS (
    SELECT
        period,
        week_of_year,
        cushing_inventory_mbbl,

        COUNT(*) OVER (
            PARTITION BY week_of_year
            ORDER BY period
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS n_hist,

        SUM(cushing_inventory_mbbl) OVER (
            PARTITION BY week_of_year
            ORDER BY period
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS sum_hist,

        SUM(cushing_inventory_mbbl * cushing_inventory_mbbl) OVER (
            PARTITION BY week_of_year
            ORDER BY period
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS sumsq_hist

    FROM inventory_weeks
),

historical_stats AS (
    SELECT
        *,

        CASE
            WHEN n_hist > 0
            THEN sum_hist / n_hist
        END AS historical_mean,

        CASE
            WHEN n_hist > 1
            THEN sqrt(
                (
                    sumsq_hist
                    - sum_hist * sum_hist / n_hist
                )
                / (n_hist - 1)
            )
        END AS historical_std

    FROM historical
)

SELECT
    period,
    week_of_year,
    cushing_inventory_mbbl,
    n_hist,
    historical_mean,
    historical_std,

    CASE
        WHEN n_hist >= 5
             AND historical_std > 0
        THEN
            (cushing_inventory_mbbl - historical_mean)
            / historical_std
    END AS inventory_zscore

FROM historical_stats
ORDER BY period;


-- Count contango vs backwardation in calendar_spreads.sql
SELECT
    SUM(
        CASE
            WHEN cl2_minus_cl1_usd_bbl > 0
            THEN 1 ELSE 0
        END
    ) AS contango_weeks,

    SUM(
        CASE
            WHEN cl2_minus_cl1_usd_bbl < 0
            THEN 1 ELSE 0
        END
    ) AS backwardation_weeks,

    SUM(
        CASE
            WHEN cl2_minus_cl1_usd_bbl = 0
            THEN 1 ELSE 0
        END
    ) AS flat_weeks

FROM calendar_spreads;






---- Full weekly_features.sql Stage 2 query
WITH base_weekly AS (
    SELECT
        i.period,

        i.cushing_inventory_mbbl,
        i.padd2_inventory_mbbl,

        r.padd2_crude_input_mbbl_d,
        r.padd2_refinery_utilization_pct,

        f.us_crude_production_mbbl_d,
        f.us_crude_imports_mbbl_d,
        f.us_crude_exports_mbbl_d,

        p.wti_spot_usd_bbl,
        p.cl1_usd_bbl,
        p.cl2_usd_bbl,
        p.cl3_usd_bbl,
        p.cl4_usd_bbl,

        c.cl2_minus_cl1_usd_bbl,
        c.cl3_minus_cl2_usd_bbl,
        c.cl4_minus_cl3_usd_bbl,
        c.cl3_minus_cl1_usd_bbl,
        c.cl4_minus_cl1_usd_bbl

    FROM inventories AS i

    LEFT JOIN refinery_activity AS r
        ON i.period = r.period

    LEFT JOIN flows AS f
        ON i.period = f.period

    LEFT JOIN prices AS p
        ON i.period = p.period

    LEFT JOIN calendar_spreads AS c
        ON i.period = c.period
    
    WHERE i.cushing_inventory_mbbl IS NOT NULL
),

lagged_features AS (
    SELECT
        *,

        -- Cushing Inventory Lags
        LAG(cushing_inventory_mbbl, 1) OVER (
            ORDER BY period
        ) AS cushing_inventory_lag1_mbbl,

        LAG(cushing_inventory_mbbl, 4) OVER (
            ORDER BY period
        ) AS cushing_inventory_lag4_mbbl,

        -- Cushing Inventory Changes
        cushing_inventory_mbbl
            - LAG(cushing_inventory_mbbl, 1) OVER (
                ORDER BY period
            )
            AS cushing_inventory_change_1w_mbbl,

        cushing_inventory_mbbl
            - LAG(cushing_inventory_mbbl, 4) OVER (
                ORDER BY period
            )
            AS cushing_inventory_change_4w_mbbl,

        padd2_inventory_mbbl                                           ---- 2C: Add PADD 2 Inventory Changes
            - LAG(padd2_inventory_mbbl, 1) OVER (
                ORDER BY period
            ) AS padd2_inventory_change_1w_mbbl,

        padd2_inventory_mbbl
            - LAG(padd2_inventory_mbbl, 4) OVER (
                ORDER BY period
            ) AS padd2_inventory_change_4w_mbbl,

        us_crude_imports_mbbl_d                                         ---- 2D: Derive Net Imports (not technically a lag but a useful derived feature)
            - us_crude_exports_mbbl_d                                        -- ^ Did this here rather than in flows.sql to keep clean source measurements and derived features separate
            AS us_crude_net_imports_mbbl_d,

        cl2_minus_cl1_usd_bbl                                           ---- 2E: Derive the change in the front calendar spread
            - LAG(cl2_minus_cl1_usd_bbl, 1) OVER (
                ORDER BY period
            )
            AS front_spread_change_1w_usd_bbl

    FROM base_weekly
)
-- Inspect around a known period
SELECT
    period,
    cushing_inventory_mbbl,
    cushing_inventory_lag1_mbbl,
    cushing_inventory_change_1w_mbbl,
    cushing_inventory_change_4w_mbbl,
    cl2_minus_cl1_usd_bbl,
    front_spread_change_1w_usd_bbl
FROM lagged_features
WHERE period BETWEEN '2020-04-01' AND '2020-05-15'
ORDER BY period;



---- To determine contango or backwardation
  -- Contango using DESC at bottom
SELECT
    period,
    cushing_inventory_mbbl,
    cl1_usd_bbl,
    cl2_usd_bbl,
    cl4_usd_bbl,

    cl2_minus_cl1_usd_bbl,
    cushing_inventory_change_1w_mbbl,
    
    cl4_minus_cl1_usd_bbl,
    cushing_inventory_change_4w_mbbl

FROM weekly_features

ORDER BY cl4_minus_cl1_usd_bbl DESC

LIMIT 15;

  -- Backwardation using ASC at bottom (IS NOT NULL to avoid null values)
SELECT
    period,
    cushing_inventory_mbbl,
    cl1_usd_bbl,
    cl2_usd_bbl,
    cl4_usd_bbl,

    cl2_minus_cl1_usd_bbl,
    cushing_inventory_change_1w_mbbl,
    
    cl4_minus_cl1_usd_bbl,
    cushing_inventory_change_4w_mbbl

FROM weekly_features

WHERE cl4_minus_cl1_usd_bbl IS NOT NULL

ORDER BY cl4_minus_cl1_usd_bbl ASC

LIMIT 15;



---- To check term structure of carry. Here, for a given F4 - F1 spread, we analyze the subspreads F2 - F1, F3 - F2, and F4 - F3 to inspect
---- ^ the concentration of either contango or backwardation. Two leading contango dates and the leading backwardation date chosen from 
---- ^ the output of the above query.

SELECT
    period,

    ROUND(cl1_usd_bbl, 2) AS cl1,
    ROUND(cl2_usd_bbl, 2) AS cl2,
    ROUND(cl3_usd_bbl, 2) AS cl3,
    ROUND(cl4_usd_bbl, 2) AS cl4,

    ROUND(cl2_minus_cl1_usd_bbl, 2) AS f2_f1,
    ROUND(cl3_minus_cl2_usd_bbl, 2) AS f3_f2,
    ROUND(cl4_minus_cl3_usd_bbl, 2) AS f4_f3,
    ROUND(cl4_minus_cl1_usd_bbl, 2) AS f4_f1

FROM weekly_features

WHERE period IN (
    '2009-02-13',
    '2020-04-24',
    '2022-03-11'
)

ORDER BY period;



---- Analyzing front slope share and front vs. back curvature
SELECT
    period,

    ROUND(cl2_minus_cl1_usd_bbl, 2) AS f2_f1,
    ROUND(cl3_minus_cl2_usd_bbl, 2) AS f3_f2,
    ROUND(cl4_minus_cl3_usd_bbl, 2) AS f4_f3,
    ROUND(cl4_minus_cl1_usd_bbl, 2) AS f4_f1,

    ROUND (
        cl2_minus_cl1_usd_bbl
        / NULLIF(cl4_minus_cl1_usd_bbl, 0),
        3
    ) AS front_share_of_total_slope,

    ROUND(
        cl2_minus_cl1_usd_bbl
        - cl4_minus_cl3_usd_bbl,
        2
    ) AS front_vs_back_curvature

FROM weekly_features

WHERE period IN (
    '2009-02-13',
    '2020-04-24',
    '2022-03-11'
)

ORDER BY period;