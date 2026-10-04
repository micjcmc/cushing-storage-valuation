-- ============================================================
-- Rebuild permanent weekly_features table
-- ============================================================

DROP TABLE IF EXISTS weekly_features;

CREATE TABLE weekly_features (
    period TEXT PRIMARY KEY,

    -- Base physical variables
    cushing_inventory_mbbl REAL,
    padd2_inventory_mbbl REAL,

    padd2_crude_input_mbbl_d REAL,
    padd2_refinery_utilization_pct REAL,

    us_crude_production_mbbl_d REAL,
    us_crude_imports_mbbl_d REAL,
    us_crude_exports_mbbl_d REAL,

    -- Base price variables
    wti_spot_usd_bbl REAL,
    cl1_usd_bbl REAL,
    cl2_usd_bbl REAL,
    cl3_usd_bbl REAL,
    cl4_usd_bbl REAL,

    -- Calendar spreads
    cl2_minus_cl1_usd_bbl REAL,
    cl3_minus_cl2_usd_bbl REAL,
    cl4_minus_cl3_usd_bbl REAL,
    cl3_minus_cl1_usd_bbl REAL,
    cl4_minus_cl1_usd_bbl REAL,

    -- Lagged / change features
    cushing_inventory_lag1_mbbl REAL,
    cushing_inventory_lag4_mbbl REAL,

    cushing_inventory_change_1w_mbbl REAL,
    cushing_inventory_change_4w_mbbl REAL,

    padd2_inventory_change_1w_mbbl REAL,
    padd2_inventory_change_4w_mbbl REAL,

    us_crude_net_imports_mbbl_d REAL,

    front_spread_change_1w_usd_bbl REAL,

    -- Rolling features
    cushing_inventory_4w_avg_mbbl REAL,
    padd2_inventory_4w_avg_mbbl REAL,

    padd2_crude_input_4w_avg_mbbl_d REAL,
    padd2_refinery_utilization_4w_avg_pct REAL,

    us_crude_production_4w_avg_mbbl_d REAL,
    us_crude_net_imports_4w_avg_mbbl_d REAL,

    front_spread_4w_avg_usd_bbl REAL,

    -- Seasonal identifiers
    iso_week_year INTEGER,
    iso_week_of_year INTEGER,
    month_of_year INTEGER,

    -- Point-in-time seasonal Cushing statistics
    cushing_inventory_seasonal_n_hist INTEGER,
    cushing_inventory_seasonal_mean_mbbl REAL,
    cushing_inventory_seasonal_std_mbbl REAL,
    cushing_inventory_seasonal_zscore REAL
);


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

        padd2_inventory_mbbl                                           
            - LAG(padd2_inventory_mbbl, 1) OVER (
                ORDER BY period
            ) AS padd2_inventory_change_1w_mbbl,

        padd2_inventory_mbbl
            - LAG(padd2_inventory_mbbl, 4) OVER (
                ORDER BY period
            ) AS padd2_inventory_change_4w_mbbl,

        us_crude_imports_mbbl_d                                         
            - us_crude_exports_mbbl_d                                        
            AS us_crude_net_imports_mbbl_d,

        cl2_minus_cl1_usd_bbl                                          
            - LAG(cl2_minus_cl1_usd_bbl, 1) OVER (
                ORDER BY period
            )
            AS front_spread_change_1w_usd_bbl

    FROM base_weekly
),
                                                                                                
rolling_features AS (
    SELECT
        *,

        -- Cushing Inventory Rolling Level
        CASE
            WHEN COUNT(cushing_inventory_mbbl) OVER w4 = 4
            THEN AVG(cushing_inventory_mbbl) OVER w4
        END AS cushing_inventory_4w_avg_mbbl,

        -- PADD 2 Inventory Rolling Level
        CASE
            WHEN COUNT(padd2_inventory_mbbl) OVER w4 = 4
            THEN AVG(padd2_inventory_mbbl) OVER w4
        END AS padd2_inventory_4w_avg_mbbl,

        -- Refinery Activity
        CASE
            WHEN COUNT(padd2_crude_input_mbbl_d) OVER w4 = 4
            THEN AVG(padd2_crude_input_mbbl_d) OVER w4
        END AS padd2_crude_input_4w_avg_mbbl_d,

        CASE
            WHEN COUNT(padd2_refinery_utilization_pct) OVER w4 = 4
            THEN AVG(padd2_refinery_utilization_pct) OVER w4
        END AS padd2_refinery_utilization_4w_avg_pct,

        -- U.S. Crude Supply
        CASE
            WHEN COUNT(us_crude_production_mbbl_d) OVER w4 = 4
            THEN AVG(us_crude_production_mbbl_d) OVER w4
        END AS us_crude_production_4w_avg_mbbl_d,

        CASE
            WHEN COUNT(us_crude_net_imports_mbbl_d) OVER w4 = 4
            THEN AVG(us_crude_net_imports_mbbl_d) OVER w4
        END AS us_crude_net_imports_4w_avg_mbbl_d,

        -- Front of Futures Curve
        CASE
            WHEN COUNT(cl2_minus_cl1_usd_bbl) OVER w4 = 4
            THEN AVG(cl2_minus_cl1_usd_bbl) OVER w4
        END AS front_spread_4w_avg_usd_bbl

    FROM lagged_features

    WINDOW w4 AS (
        ORDER BY period
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    )
),

seasonal_features AS (
    SELECT
        *,

        CAST(strftime('%G', period) AS INTEGER)
            AS iso_week_year,
        
        CAST(strftime('%V', period) AS INTEGER)
            AS iso_week_of_year,

        CAST(strftime('%m', period) AS INTEGER)
            AS month_of_year
    
    FROM rolling_features
),

seasonal_history AS (
    SELECT
        *,

        COUNT (cushing_inventory_mbbl) OVER (
            PARTITION BY iso_week_of_year
            ORDER BY period
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS cushing_inventory_seasonal_n_hist,

        SUM (cushing_inventory_mbbl) OVER (
            PARTITION BY iso_week_of_year
            ORDER BY PERIOD
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS cushing_inventory_seasonal_sum_hist,

        SUM (cushing_inventory_mbbl * cushing_inventory_mbbl) OVER (
            PARTITION BY iso_week_of_year
            ORDER BY period
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS cushing_inventory_seasonal_sumsq_hist

    FROM seasonal_features
),

-- Build mean and standard deviation since SQLite doesn't have built-in functions for these
seasonal_stats AS (
    SELECT
        *,

        CASE
            WHEN cushing_inventory_seasonal_n_hist >= 1
            THEN 
                cushing_inventory_seasonal_sum_hist
                / cushing_inventory_seasonal_n_hist
        END AS cushing_inventory_seasonal_mean_mbbl,

        CASE
            WHEN cushing_inventory_seasonal_n_hist >= 2
            THEN SQRT (
                MAX (
                    (
                        cushing_inventory_seasonal_sumsq_hist
                        - 
                        (
                            cushing_inventory_seasonal_sum_hist
                            * cushing_inventory_seasonal_sum_hist
                            / cushing_inventory_seasonal_n_hist
                        )
                    )
                    / (cushing_inventory_seasonal_n_hist - 1),
                    0.0
                )
            )
        END AS cushing_inventory_seasonal_std_mbbl

    FROM seasonal_history
),

-- Build Z-Score (here, WHEN cushing_inventory_seasonal_n_hist >= 5 is used as a minimum-history guard to avoid giant early Z-scores from tiny historical stdevs)
standardized_features AS (
    SELECT
        *,

        CASE
            WHEN cushing_inventory_seasonal_n_hist >= 5
            AND cushing_inventory_seasonal_std_mbbl > 0
            THEN
                (
                    cushing_inventory_mbbl
                    - cushing_inventory_seasonal_mean_mbbl
                )
                / cushing_inventory_seasonal_std_mbbl
        END AS cushing_inventory_seasonal_zscore

    FROM seasonal_stats
)

-- Interpretation of Z-Score
-- positive z-score   → seasonally high inventories
-- near zero          → seasonally normal inventories
-- negative z-score   → seasonally low inventories



-- Populate the permanent weekly_features table we created at the top of this file
INSERT INTO weekly_features (
    period,

    cushing_inventory_mbbl,
    padd2_inventory_mbbl,

    padd2_crude_input_mbbl_d,
    padd2_refinery_utilization_pct,

    us_crude_production_mbbl_d,
    us_crude_imports_mbbl_d,
    us_crude_exports_mbbl_d,

    wti_spot_usd_bbl,
    cl1_usd_bbl,
    cl2_usd_bbl,
    cl3_usd_bbl,
    cl4_usd_bbl,

    cl2_minus_cl1_usd_bbl,
    cl3_minus_cl2_usd_bbl,
    cl4_minus_cl3_usd_bbl,
    cl3_minus_cl1_usd_bbl,
    cl4_minus_cl1_usd_bbl,

    cushing_inventory_lag1_mbbl,
    cushing_inventory_lag4_mbbl,

    cushing_inventory_change_1w_mbbl,
    cushing_inventory_change_4w_mbbl,

    padd2_inventory_change_1w_mbbl,
    padd2_inventory_change_4w_mbbl,

    us_crude_net_imports_mbbl_d,
    front_spread_change_1w_usd_bbl,

    cushing_inventory_4w_avg_mbbl,
    padd2_inventory_4w_avg_mbbl,

    padd2_crude_input_4w_avg_mbbl_d,
    padd2_refinery_utilization_4w_avg_pct,

    us_crude_production_4w_avg_mbbl_d,
    us_crude_net_imports_4w_avg_mbbl_d,

    front_spread_4w_avg_usd_bbl,

    iso_week_year,
    iso_week_of_year,
    month_of_year,

    cushing_inventory_seasonal_n_hist,
    cushing_inventory_seasonal_mean_mbbl,
    cushing_inventory_seasonal_std_mbbl,
    cushing_inventory_seasonal_zscore
)

SELECT
    period,

    cushing_inventory_mbbl,
    padd2_inventory_mbbl,

    padd2_crude_input_mbbl_d,
    padd2_refinery_utilization_pct,

    us_crude_production_mbbl_d,
    us_crude_imports_mbbl_d,
    us_crude_exports_mbbl_d,

    wti_spot_usd_bbl,
    cl1_usd_bbl,
    cl2_usd_bbl,
    cl3_usd_bbl,
    cl4_usd_bbl,

    cl2_minus_cl1_usd_bbl,
    cl3_minus_cl2_usd_bbl,
    cl4_minus_cl3_usd_bbl,
    cl3_minus_cl1_usd_bbl,
    cl4_minus_cl1_usd_bbl,

    cushing_inventory_lag1_mbbl,
    cushing_inventory_lag4_mbbl,

    cushing_inventory_change_1w_mbbl,
    cushing_inventory_change_4w_mbbl,

    padd2_inventory_change_1w_mbbl,
    padd2_inventory_change_4w_mbbl,

    us_crude_net_imports_mbbl_d,
    front_spread_change_1w_usd_bbl,

    cushing_inventory_4w_avg_mbbl,
    padd2_inventory_4w_avg_mbbl,

    padd2_crude_input_4w_avg_mbbl_d,
    padd2_refinery_utilization_4w_avg_pct,

    us_crude_production_4w_avg_mbbl_d,
    us_crude_net_imports_4w_avg_mbbl_d,

    front_spread_4w_avg_usd_bbl,

    iso_week_year,
    iso_week_of_year,
    month_of_year,

    cushing_inventory_seasonal_n_hist,
    cushing_inventory_seasonal_mean_mbbl,
    cushing_inventory_seasonal_std_mbbl,
    cushing_inventory_seasonal_zscore

FROM standardized_features

ORDER BY period;