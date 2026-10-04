-- Open SQL and project database
PS C:\cushing-storage-valuation> & "C:\sqlite\sqlite-cli\sqlite3.exe" "C:\cushing-storage-valuation\data\cushing_storage.db"

-- Initial setup
sqlite> .headers on
sqlite> .mode column

-- Good check for whether data was inserted into raw_eia_series table. Will return number of observations for each specific series_id
sqlite> SELECT
   ...> series_id,
   ...> COUNT(*) AS observations
   ...> FROM raw_eia_series
   ...> GROUP BY series_id;

-- Validate ingested EIA series:
-- Observation count, historical coverage, and units
        SELECT
        ...> series_id,
        ...> COUNT(*) AS observations,
        ...> MIN(period) AS first_date,
        ...> MAX(period) AS last_date,
        ...> MIN(units) AS units
        ...> FROM raw_eia_series
        ...> GROUP BY series_id;

-- Example: Used above-style query to check futures data ingestion:
SELECT
    series_id,
    COUNT(*) AS observations,
    MIN(period) AS first_date,
    MAX(period) AS last_date,
    MIN(units) AS units
FROM raw_eia_series
WHERE series_id IN ('RCLC1', 'RCLC2', 'RCLC3', 'RCLC4')
GROUP BY series_id;

-- -- Checks after constructing "inventories" table
-- First check
sqlite> .read C:/cushing-storage-valuation/sql/inventories.sql -- Goal is no output/no parse errors
sqlite> .tables
inventories     raw_eia_series
sqlite> .headers on
sqlite> .mode column
sqlite> SELECT *
   ...> FROM inventories
   ...> ORDER BY period DESC
   ...> LIMIT 10;
-- First time running gave this terminal output
  period    cushing_inventory...  padd2_inventory_mbbl
----------  --------------------  --------------------
2026-09-18               23748.0              104070.0
2026-09-11               21482.0               99663.0
2026-09-04               21824.0              100103.0
2026-08-28               22508.0              100484.0
2026-08-21               22428.0              101195.0
2026-08-14               21252.0              100382.0
2026-08-07               22566.0              101893.0
2026-07-31               20955.0               99573.0
2026-07-24               18599.0               96941.0
2026-07-17               19370.0               97068.0
-- Second check
sqlite> SELECT
   ...> COUNT(*) AS rows,
   ...> MIN(period) AS first_date,
   ...> MAX(period) AS last_date
   ...> FROM inventories;
-- First time running gave this terminal output
rows  first_date  last_date
----  ----------  ----------
1916  1990-01-05  2026-09-18
-- Third check
sqlite> SELECT MIN(period) AS first_complete_inventory_week
   ...> FROM inventories
   ...> WHERE cushing_inventory_mbbl IS NOT NULL
   ...> AND padd2_inventory_mbbl IS NOT NULL;
-- First time running gave this terminal output
first_complete_in...
--------------------
2004-04-09
-- Fourth check
sqlite> SELECT
   ...> SUM(CASE WHEN cushing_inventory_mbbl IS NULL THEN 1 ELSE 0 END)
   ...> AS missing_cushing,
   ...> SUM(CASE WHEN padd2_inventory_mbbl IS NULL THEN 1 ELSE 0 END)
   ...> AS missing_padd2
   ...> FROM inventories;
-- First time running gave this terminal output
missing_cushing  missing_padd2
---------------  -------------
            744              0
sqlite>


-- Example check for refinery_activity table
sqlite> SELECT *
   ...> FROM refinery_activity
   ...> ORDER BY period DESC
   ...> LIMIT 10;
╭────────────┬──────────────────────┬──────────────────────╮
│   period   │ padd2_crude_input... │ padd2_refinery_ut... │
╞════════════╪══════════════════════╪══════════════════════╡
│ 2026-09-18 │               3802.0 │                 89.0 │
│ 2026-09-11 │               4241.0 │                100.0 │
│ 2026-09-04 │               4349.0 │                101.6 │
│ 2026-08-28 │               4425.0 │                103.5 │
│ 2026-08-21 │               4356.0 │                101.8 │
│ 2026-08-14 │               4329.0 │                101.2 │
│ 2026-08-07 │               4210.0 │                 98.6 │
│ 2026-07-31 │               4192.0 │                 98.2 │
│ 2026-07-24 │               4336.0 │                101.4 │
│ 2026-07-17 │               4280.0 │                100.3 │
╰────────────┴──────────────────────┴──────────────────────╯
sqlite> SELECT
   ...>     COUNT(*) AS rows,
   ...>     MIN(period) AS first_date,
   ...>     MAX(period) AS last_date
   ...> FROM refinery_activity;
╭──────┬────────────┬────────────╮
│ rows │ first_date │ last_date  │
╞══════╪════════════╪════════════╡
│ 1776 │ 1992-09-11 │ 2026-09-18 │
╰──────┴────────────┴────────────╯
sqlite> SELECT
   ...>     MIN(period) AS first_complete_refinery_week
   ...> FROM refinery_activity
   ...> WHERE padd2_crude_input_mbbl_d IS NOT NULL
   ...>   AND padd2_refinery_utilization_pct IS NOT NULL;
╭──────────────────────╮
│ first_complete_re... │
╞══════════════════════╡
│ 2010-06-04           │
╰──────────────────────╯
sqlite> SELECT
   ...>     SUM(
(x1...>         CASE
(x1...>             WHEN padd2_crude_input_mbbl_d IS NULL
(x1...>             THEN 1 ELSE 0
(x1...>         END
(x1...>     ) AS missing_crude_input,
   ...>
   ...>     SUM(
(x1...>         CASE
(x1...>             WHEN padd2_refinery_utilization_pct IS NULL
(x1...>             THEN 1 ELSE 0
(x1...>         END
(x1...>     ) AS missing_utilization
   ...>
   ...> FROM refinery_activity;
╭─────────────────────┬─────────────────────╮
│ missing_crude_input │ missing_utilization │
╞═════════════════════╪═════════════════════╡
│                   0 │                 925 │
╰─────────────────────┴─────────────────────╯
sqlite> SELECT *
   ...> FROM refinery_activity
   ...> WHERE padd2_crude_input_mbbl_d < 0;
sqlite> SELECT *
   ...> FROM refinery_activity
   ...> WHERE padd2_refinery_utilization_pct < 0;
sqlite> SELECT
   ...>     MIN(padd2_refinery_utilization_pct) AS min_utilization,
   ...>     MAX(padd2_refinery_utilization_pct) AS max_utilization
   ...> FROM refinery_activity;
╭─────────────────┬─────────────────╮
│ min_utilization │ max_utilization │
╞═════════════════╪═════════════════╡
│            65.0 │           103.5 │
╰─────────────────┴─────────────────╯

sqlite> WITH ordered AS (
(x1...>     SELECT
(x1...>         period,
(x1...>         LAG(period) OVER (ORDER BY period) AS previous_period
(x1...>     FROM refinery_activity
(x1...> )
   ...> SELECT
   ...>     previous_period,
   ...>     period,
   ...>     julianday(period) - julianday(previous_period) AS days_between
   ...> FROM ordered
   ...> WHERE previous_period IS NOT NULL
   ...>   AND julianday(period) - julianday(previous_period) <> 7;
sqlite>                                                                      -- No output is good and is what we wanted; this last query was to check for any missing weeks (missing data)







---- Validating flows.sql

sqlite> .read C:/cushing-storage-valuation/sql/flows.sql
sqlite> SELECT *
   ...> FROM flows
   ...> ORDER BY period DESC
   ...> LIMIT 10;
╭────────────┬──────────────────────┬──────────────────────┬──────────────────────╮
│   period   │ us_crude_producti... │ us_crude_imports_... │ us_crude_exports_... │
╞════════════╪══════════════════════╪══════════════════════╪══════════════════════╡
│ 2026-09-18 │              13939.0 │               5877.0 │               3281.0 │
│ 2026-09-11 │              13944.0 │               7058.0 │               4831.0 │
│ 2026-09-04 │              13947.0 │               6824.0 │               3417.0 │
│ 2026-08-28 │              13862.0 │               6770.0 │               4483.0 │
│ 2026-08-21 │              13843.0 │               6158.0 │               3792.0 │
│ 2026-08-14 │              13830.0 │               6593.0 │               4066.0 │
│ 2026-08-07 │              13805.0 │               7339.0 │               3058.0 │
│ 2026-07-31 │              13804.0 │               6198.0 │               3685.0 │
│ 2026-07-24 │              13796.0 │               5683.0 │               3467.0 │
│ 2026-07-17 │              13798.0 │               5806.0 │               3353.0 │
╰────────────┴──────────────────────┴──────────────────────┴──────────────────────╯

-- Validate coverage
sqlite> SELECT
   ...>     COUNT(*) AS rows,
   ...>     MIN(period) AS first_date,
   ...>     MAX(period) AS last_date
   ...> FROM flows;
╭──────┬────────────┬────────────╮
│ rows │ first_date │ last_date  │
╞══════╪════════════╪════════════╡
│ 2278 │ 1983-01-07 │ 2026-09-18 │
╰──────┴────────────┴────────────╯

-- Find when all three are available simultaneously
sqlite> SELECT
   ...>     MIN(period) AS first_complete_flow_week
   ...> FROM flows
   ...> WHERE us_crude_production_mbbl_d IS NOT NULL
   ...>   AND us_crude_imports_mbbl_d IS NOT NULL
   ...>   AND us_crude_exports_mbbl_d IS NOT NULL;
╭──────────────────────╮
│ first_complete_fl... │
╞══════════════════════╡
│ 1991-02-08           │
╰──────────────────────╯

-- Check missingness
sqlite> SELECT
   ...>     SUM(
(x1...>         CASE
(x1...>             WHEN us_crude_production_mbbl_d IS NULL
(x1...>             THEN 1 ELSE 0
(x1...>         END
(x1...>     ) AS missing_production,
   ...>
   ...>     SUM(
(x1...>         CASE
(x1...>             WHEN us_crude_imports_mbbl_d IS NULL
(x1...>             THEN 1 ELSE 0
(x1...>         END
(x1...>     ) AS missing_imports,
   ...>
   ...>     SUM(
(x1...>         CASE
(x1...>             WHEN us_crude_exports_mbbl_d IS NULL
(x1...>             THEN 1 ELSE 0
(x1...>         END
(x1...>     ) AS missing_exports
   ...>
   ...> FROM flows;
╭────────────────────┬─────────────────┬─────────────────╮
│ missing_production │ missing_imports │ missing_exports │
╞════════════════════╪═════════════════╪═════════════════╡
│                  0 │             362 │             419 │
╰────────────────────┴─────────────────┴─────────────────╯

-- Physical sanity check (want no output)
sqlite> SELECT *
   ...> FROM flows
   ...> WHERE us_crude_production_mbbl_d < 0
   ...>    OR us_crude_imports_mbbl_d < 0
   ...>    OR us_crude_exports_mbbl_d < 0;

-- Inspect ranges
sqlite> SELECT
   ...>     MIN(us_crude_production_mbbl_d) AS min_production,
   ...>     MAX(us_crude_production_mbbl_d) AS max_production,
   ...>
   ...>     MIN(us_crude_imports_mbbl_d) AS min_imports,
   ...>     MAX(us_crude_imports_mbbl_d) AS max_imports,
   ...>
   ...>     MIN(us_crude_exports_mbbl_d) AS min_exports,
   ...>     MAX(us_crude_exports_mbbl_d) AS max_exports
   ...>
   ...> FROM flows;
╭────────────────┬────────────────┬─────────────┬─────────────┬─────────────┬─────────────╮
│ min_production │ max_production │ min_imports │ max_imports │ min_exports │ max_exports │
╞════════════════╪════════════════╪═════════════╪═════════════╪═════════════╪═════════════╡
│         3813.0 │        13947.0 │      4278.0 │     11324.0 │        10.0 │      6438.0 │





---- Validating prices.sql
sqlite> .read C:/cushing-storage-valuation/sql/prices.sql
sqlite> SELECT *
   ...> FROM prices
   ...> ORDER BY period DESC
   ...> LIMIT 10;
╭────────────┬──────────────────┬─────────────┬─────────────┬─────────────┬─────────────╮
│   period   │ wti_spot_usd_bbl │ cl1_usd_bbl │ cl2_usd_bbl │ cl3_usd_bbl │ cl4_usd_bbl │
╞════════════╪══════════════════╪═════════════╪═════════════╪═════════════╪═════════════╡
│ 2026-09-18 │           103.54 │ NULL        │ NULL        │ NULL        │ NULL        │
│ 2026-09-11 │            99.08 │ NULL        │ NULL        │ NULL        │ NULL        │
│ 2026-09-04 │            91.18 │ NULL        │ NULL        │ NULL        │ NULL        │
│ 2026-08-28 │            84.62 │ NULL        │ NULL        │ NULL        │ NULL        │
│ 2026-08-21 │            87.35 │ NULL        │ NULL        │ NULL        │ NULL        │
│ 2026-08-14 │            84.05 │ NULL        │ NULL        │ NULL        │ NULL        │
│ 2026-08-07 │            78.94 │ NULL        │ NULL        │ NULL        │ NULL        │
│ 2026-07-31 │            84.51 │ NULL        │ NULL        │ NULL        │ NULL        │
│ 2026-07-24 │            88.58 │ NULL        │ NULL        │ NULL        │ NULL        │
│ 2026-07-17 │            80.77 │ NULL        │ NULL        │ NULL        │ NULL        │
╰────────────┴──────────────────┴─────────────┴─────────────┴─────────────┴─────────────╯

-- Validate the table
sqlite> SELECT
   ...>     COUNT(*) AS rows,
   ...>     MIN(period) AS first_date,
   ...>     MAX(period) AS last_date
   ...> FROM prices;
╭──────┬────────────┬────────────╮
│ rows │ first_date │ last_date  │
╞══════╪════════════╪════════════╡
│ 2270 │ 1983-03-18 │ 2026-09-18 │
╰──────┴────────────┴────────────╯

-- Find the first week where the entire five-column price set exists
sqlite> SELECT
   ...>     MIN(period) AS first_complete_price_week
   ...> FROM prices
   ...> WHERE wti_spot_usd_bbl IS NOT NULL
   ...>   AND cl1_usd_bbl IS NOT NULL
   ...>   AND cl2_usd_bbl IS NOT NULL
   ...>   AND cl3_usd_bbl IS NOT NULL
   ...>   AND cl4_usd_bbl IS NOT NULL;
╭──────────────────────╮
│ first_complete_pr... │
╞══════════════════════╡
│ 1986-01-03           │
╰──────────────────────╯

-- Find the last week where the entire five-column price set exists
sqlite> SELECT
   ...>     MAX(period) AS last_complete_price_week
   ...> FROM prices
   ...> WHERE wti_spot_usd_bbl IS NOT NULL
   ...>   AND cl1_usd_bbl IS NOT NULL
   ...>   AND cl2_usd_bbl IS NOT NULL
   ...>   AND cl3_usd_bbl IS NOT NULL
   ...>   AND cl4_usd_bbl IS NOT NULL;
╭──────────────────────╮
│ last_complete_pri... │
╞══════════════════════╡
│ 2024-04-05           │                                            -- Expected: 2024-04-05 since EIA discontinued this series after this date, so this checks out
╰──────────────────────╯

-- Missingness
sqlite> SELECT
   ...>     SUM(CASE WHEN wti_spot_usd_bbl IS NULL THEN 1 ELSE 0 END)
   ...>         AS missing_spot,
   ...>
   ...>     SUM(CASE WHEN cl1_usd_bbl IS NULL THEN 1 ELSE 0 END)
   ...>         AS missing_cl1,
   ...>
   ...>     SUM(CASE WHEN cl2_usd_bbl IS NULL THEN 1 ELSE 0 END)
   ...>         AS missing_cl2,
   ...>
   ...>     SUM(CASE WHEN cl3_usd_bbl IS NULL THEN 1 ELSE 0 END)
   ...>         AS missing_cl3,
   ...>
   ...>     SUM(CASE WHEN cl4_usd_bbl IS NULL THEN 1 ELSE 0 END)
   ...>         AS missing_cl4
   ...>
   ...> FROM prices;
╭──────────────┬─────────────┬─────────────┬─────────────┬─────────────╮
│ missing_spot │ missing_cl1 │ missing_cl2 │ missing_cl3 │ missing_cl4 │
╞══════════════╪═════════════╪═════════════╪═════════════╪═════════════╡
│          145 │         130 │         221 │         128 │         221 │                -- Not automatically errors. They come from different historical start dates plus the post-2024 futures cutoff.
╰──────────────┴─────────────┴─────────────┴─────────────┴─────────────╯

-- Inspect any negative prices
sqlite> SELECT
   ...>     period,
   ...>     cl1_usd_bbl
   ...> FROM prices
   ...> WHERE cl1_usd_bbl < 0
   ...> ORDER BY period;                                    -- Returned no output. There were negative trading days in April 2020, but we're storing the EIA series at weekly frequency. 
                                                            -- A negative daily settlement can be averaged together with positive prices on other days of the week, leaving the weekly observation positive.

-- Inspect ranges
sqlite> SELECT
   ...>     MIN(wti_spot_usd_bbl) AS min_spot,
   ...>     MAX(wti_spot_usd_bbl) AS max_spot,
   ...>
   ...>     MIN(cl1_usd_bbl) AS min_cl1,
   ...>     MAX(cl1_usd_bbl) AS max_cl1,
   ...>
   ...>     MIN(cl2_usd_bbl) AS min_cl2,
   ...>     MAX(cl2_usd_bbl) AS max_cl2,
   ...>
   ...>     MIN(cl3_usd_bbl) AS min_cl3,
   ...>     MAX(cl3_usd_bbl) AS max_cl3,
   ...>
   ...>     MIN(cl4_usd_bbl) AS min_cl4,
   ...>     MAX(cl4_usd_bbl) AS max_cl4
   ...>
   ...> FROM prices;
╭──────────┬──────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────╮
│ min_spot │ max_spot │ min_cl1 │ max_cl1 │ min_cl2 │ max_cl2 │ min_cl3 │ max_cl3 │ min_cl4 │ max_cl4 │
╞══════════╪══════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╪═════════╡
│     3.32 │   142.52 │    3.92 │  142.46 │   10.92 │  143.04 │   11.05 │  143.39 │   11.23 │  143.65 │
╰──────────┴──────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────╯

-- Inspecting specific April 2020 episode
sqlite> SELECT
   ...>     period,
   ...>     wti_spot_usd_bbl,
   ...>     cl1_usd_bbl,
   ...>     cl2_usd_bbl,
   ...>     cl3_usd_bbl,
   ...>     cl4_usd_bbl
   ...> FROM prices
   ...> WHERE period BETWEEN '2020-04-01' AND '2020-05-15'
   ...> ORDER BY period;
╭────────────┬──────────────────┬─────────────┬─────────────┬─────────────┬─────────────╮
│   period   │ wti_spot_usd_bbl │ cl1_usd_bbl │ cl2_usd_bbl │ cl3_usd_bbl │ cl4_usd_bbl │
╞════════════╪══════════════════╪═════════════╪═════════════╪═════════════╪═════════════╡
│ 2020-04-03 │            21.69 │       22.91 │       26.26 │       28.75 │       30.31 │
│ 2020-04-10 │            24.41 │       24.39 │       29.42 │        32.2 │       33.16 │
│ 2020-04-17 │            20.12 │       20.11 │       26.65 │       30.75 │       32.37 │
│ 2020-04-24 │             3.32 │        3.92 │       19.07 │       23.34 │        25.5 │
│ 2020-05-01 │            15.71 │       15.76 │       19.79 │       22.67 │       24.83 │
│ 2020-05-08 │            23.46 │       23.45 │       25.18 │       26.86 │       28.17 │
│ 2020-05-15 │             26.4 │       26.44 │        26.9 │       27.95 │       28.91 │
╰────────────┴──────────────────┴─────────────┴─────────────┴─────────────┴─────────────╯


-- Check whether any dates have futures deeper in the curve but are missing nearer contracts
sqlite> SELECT *
   ...> FROM prices
   ...> WHERE (cl2_usd_bbl IS NOT NULL AND cl1_usd_bbl IS NULL)
   ...>    OR (cl3_usd_bbl IS NOT NULL AND cl2_usd_bbl IS NULL)
   ...>    OR (cl4_usd_bbl IS NOT NULL AND cl3_usd_bbl IS NULL)
   ...> ORDER BY period;
╭────────────┬──────────────────┬─────────────┬─────────────┬─────────────┬─────────────╮
│   period   │ wti_spot_usd_bbl │ cl1_usd_bbl │ cl2_usd_bbl │ cl3_usd_bbl │ cl4_usd_bbl │
╞════════════╪══════════════════╪═════════════╪═════════════╪═════════════╪═════════════╡
│ 1983-03-18 │ NULL             │ NULL        │ NULL        │        29.3 │ NULL        │
│ 1983-04-01 │ NULL             │ NULL        │ NULL        │        29.3 │ NULL        │
│ 1983-04-08 │ NULL             │       29.92 │ NULL        │        29.6 │ NULL        │
│ 1983-04-15 │ NULL             │       30.61 │ NULL        │       30.45 │ NULL        │
│ 1983-04-22 │ NULL             │       30.73 │ NULL        │       30.65 │ NULL        │
│ 1983-04-29 │ NULL             │       30.74 │ NULL        │        30.7 │ NULL        │
│ 1983-05-06 │ NULL             │       30.44 │ NULL        │       30.25 │ NULL        │
│ 1983-05-13 │ NULL             │       29.98 │ NULL        │       29.52 │ NULL        │
│ 1983-05-20 │ NULL             │       30.01 │ NULL        │       29.84 │ NULL        │
│ 1983-05-27 │ NULL             │       30.21 │ NULL        │       30.09 │ NULL        │
│ 1983-06-03 │ NULL             │       30.34 │ NULL        │       30.16 │ NULL        │
│ 1983-06-10 │ NULL             │       30.56 │ NULL        │       30.37 │ NULL        │
│ 1983-06-17 │ NULL             │       31.26 │ NULL        │       30.98 │ NULL        │
│ 1983-06-24 │ NULL             │       31.17 │ NULL        │       31.06 │ NULL        │
│ 1983-07-01 │ NULL             │       31.27 │ NULL        │       31.11 │ NULL        │
│ 1983-07-08 │ NULL             │       31.32 │ NULL        │       31.15 │ NULL        │
│ 1983-07-15 │ NULL             │       31.76 │ NULL        │       31.59 │ NULL        │
│ 1983-07-22 │ NULL             │       31.59 │ NULL        │       31.54 │ NULL        │
│ 1983-07-29 │ NULL             │        31.7 │ NULL        │       31.62 │ NULL        │
│ 1983-08-05 │ NULL             │       32.16 │ NULL        │       32.08 │ NULL        │
│ 1983-08-12 │ NULL             │       32.01 │ NULL        │       31.96 │ NULL        │
│ 1983-08-19 │ NULL             │       31.84 │ NULL        │       31.83 │ NULL        │
│ 1983-08-26 │ NULL             │       31.66 │ NULL        │       31.63 │ NULL        │
│ 1983-09-02 │ NULL             │       31.62 │ NULL        │       31.53 │ NULL        │
│ 1983-09-09 │ NULL             │       31.32 │ NULL        │       31.15 │ NULL        │
│ 1983-09-16 │ NULL             │       31.36 │ NULL        │       31.25 │ NULL        │
│ 1983-09-23 │ NULL             │       31.35 │ NULL        │       31.25 │ NULL        │
│ 1983-09-30 │ NULL             │       30.81 │ NULL        │       30.76 │ NULL        │
│ 1983-10-07 │ NULL             │       30.19 │ NULL        │       30.01 │ NULL        │
│ 1983-10-14 │ NULL             │       30.63 │ NULL        │       30.44 │ NULL        │
│ 1983-10-21 │ NULL             │       30.45 │ NULL        │       30.23 │ NULL        │
│ 1983-10-28 │ NULL             │       30.33 │ NULL        │       30.11 │ NULL        │
│ 1983-11-04 │ NULL             │        30.4 │ NULL        │       30.21 │ NULL        │
│ 1983-11-11 │ NULL             │       30.31 │ NULL        │       29.99 │ NULL        │
│ 1983-11-18 │ NULL             │       29.68 │ NULL        │       29.09 │ NULL        │
│ 1983-11-25 │ NULL             │       29.12 │ NULL        │       28.81 │ NULL        │
│ 1983-12-02 │ NULL             │       29.39 │ NULL        │       29.02 │ NULL        │
│ 1983-12-09 │ NULL             │       29.25 │ NULL        │       28.68 │ NULL        │
│ 1983-12-16 │ NULL             │       29.09 │ NULL        │       28.46 │ NULL        │
│ 1983-12-23 │ NULL             │       28.91 │ NULL        │       28.53 │ NULL        │
│ 1983-12-30 │ NULL             │       29.77 │ NULL        │       29.28 │ NULL        │
│ 1984-01-06 │ NULL             │       29.35 │ NULL        │        28.7 │ NULL        │
│ 1984-01-13 │ NULL             │        29.5 │ NULL        │       29.06 │ NULL        │
│ 1984-01-20 │ NULL             │       29.76 │ NULL        │       29.59 │ NULL        │
│ 1984-01-27 │ NULL             │       29.82 │ NULL        │       29.43 │ NULL        │
│ 1984-02-03 │ NULL             │       30.09 │ NULL        │       29.67 │ NULL        │
│ 1984-02-10 │ NULL             │       29.98 │ NULL        │       29.59 │ NULL        │
│ 1984-02-17 │ NULL             │        29.8 │ NULL        │       29.37 │ NULL        │
│ 1984-02-24 │ NULL             │        29.9 │ NULL        │       29.58 │ NULL        │
│ 1984-03-02 │ NULL             │       30.64 │ NULL        │       30.37 │ NULL        │
│ 1984-03-09 │ NULL             │       30.81 │ NULL        │       30.57 │ NULL        │
│ 1984-03-16 │ NULL             │       30.83 │ NULL        │       30.45 │ NULL        │
│ 1984-03-23 │ NULL             │       30.52 │ NULL        │       30.34 │ NULL        │
│ 1984-03-30 │ NULL             │       30.73 │ NULL        │       30.54 │ NULL        │
│ 1984-04-06 │ NULL             │        30.8 │ NULL        │       30.55 │ NULL        │
│ 1984-04-13 │ NULL             │       30.74 │ NULL        │       30.56 │ NULL        │
│ 1984-04-20 │ NULL             │       30.59 │ NULL        │       30.46 │ NULL        │
│ 1984-04-27 │ NULL             │       30.53 │ NULL        │        30.4 │ NULL        │
│ 1984-05-04 │ NULL             │       30.23 │ NULL        │       30.17 │ NULL        │
│ 1984-05-11 │ NULL             │       30.28 │ NULL        │       30.32 │ NULL        │
│ 1984-05-18 │ NULL             │       30.73 │ NULL        │       30.97 │ NULL        │
│ 1984-05-25 │ NULL             │       30.77 │ NULL        │        30.9 │ NULL        │
│ 1984-06-01 │ NULL             │       30.76 │ NULL        │       30.85 │ NULL        │
│ 1984-06-08 │ NULL             │       30.56 │ NULL        │       30.68 │ NULL        │
│ 1984-06-15 │ NULL             │       30.13 │ NULL        │       30.24 │ NULL        │
│ 1984-06-22 │ NULL             │        29.6 │ NULL        │       29.79 │ NULL        │
│ 1984-06-29 │ NULL             │       29.49 │ NULL        │       29.85 │ NULL        │
│ 1984-07-06 │ NULL             │       29.58 │ NULL        │       29.92 │ NULL        │
│ 1984-07-13 │ NULL             │       29.25 │ NULL        │       29.69 │ NULL        │
│ 1984-07-20 │ NULL             │       28.77 │ NULL        │        29.1 │ NULL        │
│ 1984-07-27 │ NULL             │       27.99 │ NULL        │       28.24 │ NULL        │
│ 1984-08-03 │ NULL             │       28.24 │ NULL        │       28.63 │ NULL        │
│ 1984-08-10 │ NULL             │       29.25 │ NULL        │       29.57 │ NULL        │
│ 1984-08-17 │ NULL             │       29.12 │ NULL        │       29.51 │ NULL        │
│ 1984-08-24 │ NULL             │       29.74 │ NULL        │       30.04 │ NULL        │
│ 1984-08-31 │ NULL             │        29.6 │ NULL        │       29.97 │ NULL        │
│ 1984-09-07 │ NULL             │       29.11 │ NULL        │       29.53 │ NULL        │
│ 1984-09-14 │ NULL             │       29.37 │ NULL        │       29.75 │ NULL        │
│ 1984-09-21 │ NULL             │       29.42 │ NULL        │       29.65 │ NULL        │
│ 1984-09-28 │ NULL             │       29.56 │ NULL        │       29.76 │ NULL        │
│ 1984-10-05 │ NULL             │       29.54 │ NULL        │       29.72 │ NULL        │
│ 1984-10-12 │ NULL             │        29.3 │ NULL        │       29.45 │ NULL        │
│ 1984-10-19 │ NULL             │       28.11 │ NULL        │       28.14 │ NULL        │
│ 1984-10-26 │ NULL             │       28.51 │ NULL        │       28.25 │ NULL        │
│ 1984-11-02 │ NULL             │        28.5 │ NULL        │       28.19 │ NULL        │
│ 1984-11-09 │ NULL             │       28.64 │ NULL        │       28.34 │ NULL        │
│ 1984-11-16 │ NULL             │       28.33 │ NULL        │       27.95 │ NULL        │
│ 1984-11-23 │ NULL             │       27.81 │ NULL        │       27.51 │ NULL        │
│ 1984-11-30 │ NULL             │       27.32 │ NULL        │       27.07 │ NULL        │
│ 1984-12-07 │ NULL             │       27.53 │ NULL        │       27.29 │ NULL        │
│ 1984-12-14 │ NULL             │       26.89 │ NULL        │       26.88 │ NULL        │
│ 1984-12-21 │ NULL             │       26.56 │ NULL        │       26.41 │ NULL        │
│ 1984-12-28 │ NULL             │       26.51 │ NULL        │       26.26 │ NULL        │
╰────────────┴──────────────────┴─────────────┴─────────────┴─────────────┴─────────────╯

-- Verify whether the nesting gaps disappear after our complete-curve starting point
sqlite> SELECT *
   ...> FROM prices
   ...> WHERE period >= '1986-01-03'
   ...>   AND (
(x1...>        (cl2_usd_bbl IS NOT NULL AND cl1_usd_bbl IS NULL)
(x1...>     OR (cl3_usd_bbl IS NOT NULL AND cl2_usd_bbl IS NULL)
(x1...>     OR (cl4_usd_bbl IS NOT NULL AND cl3_usd_bbl IS NULL)
(x1...>   )
   ...> ORDER BY period;
sqlite>                                                                             -- No output - this is good!

-- Our clean conclusion is:
-- 1983–1984:
-- odd archival gaps exist

-- 1986-01-03 onward:
-- curve coverage is internally consistent

-- 2004-04-09 onward:
-- Cushing inventory data also exists

-- 2024-04-05:
-- EIA futures coverage ends






---- Validating calendar_spreads.sql

sqlite> .read C:/cushing-storage-valuation/sql/calendar_spreads.sql
sqlite> .tables
calendar_spreads     flows     inventories     prices     raw_eia_series     refinery_activity
sqlite> SELECT *
   ...> FROM calendar_spreads
   ...> ORDER BY period DESC
   ...> LIMIT 10;
╭────────────┬───────────────────────┬──────────────────────┬──────────────────────┬───────────────────────┬──────────────────────╮
│   period   │ cl2_minus_cl1_usd...  │ cl3_minus_cl2_usd... │ cl4_minus_cl3_usd... │ cl3_minus_cl1_usd...  │ cl4_minus_cl1_usd... │
╞════════════╪═══════════════════════╪══════════════════════╪══════════════════════╪═══════════════════════╪══════════════════════╡
│ 2024-04-05 │  -0.85000000000000853 │ -0.86999999999999034 │ -0.92000000000000171 │   -1.7199999999999989 │  -2.6400000000000006 │
│ 2024-03-29 │  -0.60999999999999943 │ -0.64000000000000057 │ -0.71999999999999886 │                 -1.25 │  -1.9699999999999989 │
│ 2024-03-22 │  -0.51999999999999602 │ -0.56000000000000227 │ -0.64999999999999147 │   -1.0799999999999983 │  -1.7299999999999898 │
│ 2024-03-15 │  -0.42000000000000171 │ -0.43999999999999773 │ -0.51000000000000512 │  -0.85999999999999943 │  -1.3700000000000046 │
│ 2024-03-08 │  -0.63000000000000966 │ -0.55999999999998806 │ -0.58000000000001251 │   -1.1899999999999977 │  -1.7700000000000102 │
│ 2024-03-01 │  -0.70000000000000284 │ -0.62000000000000455 │ -0.63999999999998636 │   -1.3200000000000074 │  -1.9599999999999938 │
│ 2024-02-23 │  -0.70999999999999375 │                 -0.5 │ -0.52000000000001023 │   -1.2099999999999938 │   -1.730000000000004 │
│ 2024-02-16 │  -0.37000000000000455 │ -0.31999999999999318 │ -0.37000000000000455 │  -0.68999999999999773 │  -1.0600000000000023 │
│ 2024-02-09 │  0.020000000000010232 │ -0.07000000000000739 │ -0.17000000000000171 │ -0.049999999999997158 │ -0.21999999999999886 │
│ 2024-02-02 │ -0.090000000000003411 │ -0.10999999999999943 │ -0.18999999999999773 │  -0.20000000000000284 │ -0.39000000000000057 │
╰────────────┴───────────────────────┴──────────────────────┴──────────────────────┴───────────────────────┴──────────────────────╯

-- Validate coverage
sqlite> SELECT
   ...>     COUNT(*) AS rows,
   ...>     MIN(period) AS first_date,
   ...>     MAX(period) AS last_date
   ...> FROM calendar_spreads;
╭──────┬────────────┬────────────╮
│ rows │ first_date │ last_date  │
╞══════╪════════════╪════════════╡
│ 2049 │ 1985-01-04 │ 2024-04-05 │
╰──────┴────────────┴────────────╯

-- Check missing deeper spreads
sqlite> SELECT
   ...>     SUM(CASE
(x1...>         WHEN cl2_minus_cl1_usd_bbl IS NULL
(x1...>         THEN 1 ELSE 0
(x1...>     END) AS missing_1_2,
   ...>
   ...>     SUM(CASE
(x1...>         WHEN cl3_minus_cl2_usd_bbl IS NULL
(x1...>         THEN 1 ELSE 0
(x1...>     END) AS missing_2_3,
   ...>
   ...>     SUM(CASE
(x1...>         WHEN cl4_minus_cl3_usd_bbl IS NULL
(x1...>         THEN 1 ELSE 0
(x1...>     END) AS missing_3_4,
   ...>
   ...>     SUM(CASE
(x1...>         WHEN cl3_minus_cl1_usd_bbl IS NULL
(x1...>         THEN 1 ELSE 0
(x1...>     END) AS missing_1_3,
   ...>
   ...>     SUM(CASE
(x1...>         WHEN cl4_minus_cl1_usd_bbl IS NULL
(x1...>         THEN 1 ELSE 0
(x1...>     END) AS missing_1_4
   ...>
   ...> FROM calendar_spreads;
╭─────────────┬─────────────┬─────────────┬─────────────┬─────────────╮
│ missing_1_2 │ missing_2_3 │ missing_3_4 │ missing_1_3 │ missing_1_4 │
╞═════════════╪═════════════╪═════════════╪═════════════╪═════════════╡
│           0 │           0 │           0 │           0 │           0 │             -- Good; this is what we wanted since CL1 and CL2 are required by the WHERE
╰─────────────┴─────────────┴─────────────┴─────────────┴─────────────╯

-- Revisit April 2020
sqlite> SELECT *
   ...> FROM calendar_spreads
   ...> WHERE period BETWEEN '2020-04-01' AND '2020-05-15'
   ...> ORDER BY period;
╭────────────┬──────────────────────┬──────────────────────┬──────────────────────┬──────────────────────┬──────────────────────╮
│   period   │ cl2_minus_cl1_usd... │ cl3_minus_cl2_usd... │ cl4_minus_cl3_usd... │ cl3_minus_cl1_usd... │ cl4_minus_cl1_usd... │
╞════════════╪══════════════════════╪══════════════════════╪══════════════════════╪══════════════════════╪══════════════════════╡
│ 2020-04-03 │   3.3500000000000014 │   2.4899999999999984 │   1.5599999999999987 │                 5.84 │   7.3999999999999986 │
│ 2020-04-10 │   5.0300000000000011 │   2.7800000000000011 │  0.95999999999999375 │   7.8100000000000023 │    8.769999999999996 │
│ 2020-04-17 │   6.5399999999999992 │   4.1000000000000014 │   1.6199999999999974 │                10.64 │   12.259999999999998 │
│ 2020-04-24 │                15.15 │                 4.27 │                 2.16 │                19.42 │                21.58 │
│ 2020-05-01 │   4.0299999999999994 │   2.8800000000000026 │   2.1599999999999966 │   6.9100000000000019 │   9.0699999999999985 │
│ 2020-05-08 │   1.7300000000000004 │   1.6799999999999997 │   1.3100000000000023 │                 3.41 │   4.7200000000000024 │
│ 2020-05-15 │   0.4599999999999973 │   1.0500000000000007 │  0.96000000000000085 │    1.509999999999998 │   2.4699999999999989 │
╰────────────┴──────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┴──────────────────────╯

-- Test cumulative arithmetic (F2 ​− F1​) + (F3 ​− F2​) = F3 ​− F1​
sqlite> SELECT *
   ...> FROM calendar_spreads
   ...> WHERE ABS(
(x1...>     (cl2_minus_cl1_usd_bbl + cl3_minus_cl2_usd_bbl)
(x1...>     - cl3_minus_cl1_usd_bbl
(x1...> ) > 0.000001;                                                                -- No output; good
sqlite> SELECT *
   ...> FROM calendar_spreads
   ...> WHERE ABS(
(x1...>     (
(x2...>         cl2_minus_cl1_usd_bbl
(x2...>         + cl3_minus_cl2_usd_bbl
(x2...>         + cl4_minus_cl3_usd_bbl
(x2...>     )
(x1...>     - cl4_minus_cl1_usd_bbl
(x1...> ) > 0.000001;                                                                -- No output; good


-- Count contango vs backwardation (VERY USEFUL; also in analytics.sql)
sqlite> SELECT
   ...>     SUM(
(x1...>         CASE
(x1...>             WHEN cl2_minus_cl1_usd_bbl > 0
(x1...>             THEN 1 ELSE 0
(x1...>         END
(x1...>     ) AS contango_weeks,
   ...>
   ...>     SUM(
(x1...>         CASE
(x1...>             WHEN cl2_minus_cl1_usd_bbl < 0
(x1...>             THEN 1 ELSE 0
(x1...>         END
(x1...>     ) AS backwardation_weeks,
   ...>
   ...>     SUM(
(x1...>         CASE
(x1...>             WHEN cl2_minus_cl1_usd_bbl = 0
(x1...>             THEN 1 ELSE 0
(x1...>         END
(x1...>     ) AS flat_weeks
   ...>
   ...> FROM calendar_spreads;
╭────────────────┬─────────────────────┬────────────╮
│ contango_weeks │ backwardation_weeks │ flat_weeks │
╞════════════════╪═════════════════════╪════════════╡
│           1099 │                 940 │         10 │
╰────────────────┴─────────────────────┴────────────╯

-- Inspect the most extreme curve states
sqlite> SELECT
   ...>     period,
   ...>     cl2_minus_cl1_usd_bbl
   ...> FROM calendar_spreads
   ...> ORDER BY cl2_minus_cl1_usd_bbl DESC
   ...> LIMIT 10;
╭────────────┬──────────────────────╮
│   period   │ cl2_minus_cl1_usd... │                                   -- These are the steepest contango weeks
╞════════════╪══════════════════════╡
│ 2020-04-24 │                15.15 │                                   -- As expected, our previous 2020 example jumps out
│ 2009-01-16 │   6.8300000000000054 │
│ 2020-04-17 │   6.5399999999999992 │
│ 2009-02-13 │   6.3300000000000054 │
│ 2020-04-10 │   5.0300000000000011 │                                   
│ 2008-12-19 │   4.9100000000000037 │
│ 2009-01-09 │   4.6499999999999986 │
│ 2009-02-06 │                 4.32 │
│ 2010-05-14 │   4.0900000000000034 │
│ 2020-05-01 │   4.0299999999999994 │
╰────────────┴──────────────────────╯
sqlite> SELECT
   ...>     period,
   ...>     cl2_minus_cl1_usd_bbl
   ...> FROM calendar_spreads
   ...> ORDER BY cl2_minus_cl1_usd_bbl ASC
   ...> LIMIT 10;
╭────────────┬──────────────────────╮
│   period   │ cl2_minus_cl1_usd... │                                    -- These are the steepest backwardation weeks
╞════════════╪══════════════════════╡
│ 2022-03-11 │  -3.4700000000000131 │
│ 2022-07-08 │  -3.3200000000000074 │
│ 2022-03-04 │  -3.1200000000000046 │
│ 2008-09-26 │  -2.9799999999999898 │
│ 1996-04-19 │  -2.9400000000000013 │
│ 2022-07-01 │  -2.9099999999999966 │
│ 2022-07-22 │  -2.7800000000000011 │
│ 2022-07-15 │   -2.769999999999996 │
│ 2022-05-27 │  -2.7199999999999989 │
│ 2022-03-25 │  -2.6700000000000017 │
╰────────────┴──────────────────────╯
sqlite>




-- To turn off variable name truncation in tables
sqlite> .mode box --titlelimit 0 --screenwidth off



-- ============================================================
-- Stage 4 Validation
-- Build temporary feature table once, then run all checks
-- ============================================================

DROP TABLE IF EXISTS temp.stage4_validation;

CREATE TEMP TABLE stage4_validation AS

WITH base_weekly AS (
    SELECT
        i.period,

        -- Inventories
        i.cushing_inventory_mbbl,
        i.padd2_inventory_mbbl,

        -- Refinery Activity
        r.padd2_crude_input_mbbl_d,
        r.padd2_refinery_utilization_pct,

        -- U.S. Crude Flows
        f.us_crude_production_mbbl_d,
        f.us_crude_imports_mbbl_d,
        f.us_crude_exports_mbbl_d,

        -- Prices
        p.wti_spot_usd_bbl,
        p.cl1_usd_bbl,
        p.cl2_usd_bbl,
        p.cl3_usd_bbl,
        p.cl4_usd_bbl,

        -- Calendar Spreads
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

        -- PADD 2 Inventory Changes
        padd2_inventory_mbbl
            - LAG(padd2_inventory_mbbl, 1) OVER (
                ORDER BY period
            )
            AS padd2_inventory_change_1w_mbbl,

        padd2_inventory_mbbl
            - LAG(padd2_inventory_mbbl, 4) OVER (
                ORDER BY period
            )
            AS padd2_inventory_change_4w_mbbl,

        -- Net Imports
        us_crude_imports_mbbl_d
            - us_crude_exports_mbbl_d
            AS us_crude_net_imports_mbbl_d,

        -- Front Spread Change
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
)

SELECT *
FROM seasonal_features;


-- ============================================================
-- Check 1: Basic Stage 4 preview
-- ============================================================

SELECT
    period,
    iso_week_year,
    iso_week_of_year,
    month_of_year,
    cushing_inventory_mbbl,
    cushing_inventory_change_4w_mbbl,
    cushing_inventory_4w_avg_mbbl
FROM stage4_validation
ORDER BY period
LIMIT 20;


-- ============================================================
-- Check 2: ISO week coverage
-- ============================================================

SELECT
    MIN(iso_week_of_year) AS min_week,
    MAX(iso_week_of_year) AS max_week,
    COUNT(DISTINCT iso_week_of_year) AS distinct_weeks
FROM stage4_validation;


-- ============================================================
-- Check 3: Week 53 observations
-- ============================================================

SELECT
    period,
    iso_week_year,
    iso_week_of_year,
    cushing_inventory_mbbl
FROM stage4_validation
WHERE iso_week_of_year = 53
ORDER BY period;


-- ============================================================
-- Check 4: ISO year behavior around New Year
-- ============================================================

SELECT
    period,
    iso_week_year,
    iso_week_of_year,
    month_of_year
FROM stage4_validation
WHERE period BETWEEN '2019-12-15' AND '2020-01-15'
ORDER BY period;


-- ============================================================
-- Check 5: April 2020 seasonal labels
-- ============================================================

SELECT
    period,
    iso_week_year,
    iso_week_of_year,
    month_of_year,
    cushing_inventory_mbbl
FROM stage4_validation
WHERE period BETWEEN '2020-03-20' AND '2020-05-15'
ORDER BY period;


-- ============================================================
-- Check 6: Historical inventory seasonality by ISO week
-- ============================================================

SELECT
    iso_week_of_year,
    COUNT(*) AS observations,
    AVG(cushing_inventory_mbbl) AS avg_cushing_inventory_mbbl,
    MIN(cushing_inventory_mbbl) AS min_cushing_inventory_mbbl,
    MAX(cushing_inventory_mbbl) AS max_cushing_inventory_mbbl
FROM stage4_validation
GROUP BY iso_week_of_year
ORDER BY iso_week_of_year;





---- weekly_features.sql Validation

-- Validation 1: Early-History Behavior
SELECT
    period,
    iso_week_of_year,
    cushing_inventory_mbbl,
    cushing_inventory_seasonal_n_hist,
    cushing_inventory_seasonal_mean_mbbl,
    cushing_inventory_seasonal_std_mbbl,
    cushing_inventory_seasonal_zscore
FROM weekly_features
ORDER BY period
LIMIT 20;

-- Validation 2: Prove No Look-Ahead
  -- For a given date, first determine its ISO week
SELECT
    period,
    iso_week_of_year,
    cushing_inventory_mbbl,
    cushing_inventory_seasonal_n_hist,
    cushing_inventory_seasonal_mean_mbbl,
    cushing_inventory_seasonal_std_mbbl,
    cushing_inventory_seasonal_zscore
FROM weekly_features
WHERE period = '2020-04-24';
    -- Then inspect every same-season historical observation available before it
SELECT
    period,
    iso_week_of_year,
    cushing_inventory_mbbl
FROM weekly_features
WHERE iso_week_of_year = (
    SELECT iso_week_of_year
    FROM weekly_features
    WHERE period = '2020-04-24'
)
AND period < '2020-04-24'
ORDER BY period;                                    -- There should be no later dates involved in the benchmark


-- Validation 3: Inspect Recent Values
SELECT
    period,
    iso_week_of_year,
    cushing_inventory_mbbl,
    cushing_inventory_seasonal_n_hist,
    ROUND(cushing_inventory_seasonal_mean_mbbl, 2)
        AS seasonal_mean_mbbl,
    ROUND(cushing_inventory_seasonal_std_mbbl, 2)
        AS seasonal_std_mbbl,
    ROUND(cushing_inventory_seasonal_zscore, 3)
        AS seasonal_zscore
FROM weekly_features
ORDER BY period DESC
LIMIT 20;                                           -- Note ROUND() here used only for display


-- Validation 4: Inspect Extreme Z-Scores
  -- First inspect the highest Z-Scores
SELECT
    period,
    iso_week_of_year,
    cushing_inventory_mbbl,
    cushing_inventory_seasonal_n_hist,
    ROUND(cushing_inventory_seasonal_mean_mbbl, 2)
        AS seasonal_mean_mbbl,
    ROUND(cushing_inventory_seasonal_std_mbbl, 2)
        AS seasonal_std_mbbl,
    ROUND(cushing_inventory_seasonal_zscore, 3)
        AS seasonal_zscore
FROM weekly_features
WHERE cushing_inventory_seasonal_zscore IS NOT NULL
ORDER BY cushing_inventory_seasonal_zscore DESC
LIMIT 10;
  -- Then the lowest
SELECT
    period,
    iso_week_of_year,
    cushing_inventory_mbbl,
    cushing_inventory_seasonal_n_hist,
    ROUND(cushing_inventory_seasonal_mean_mbbl, 2)
        AS seasonal_mean_mbbl,
    ROUND(cushing_inventory_seasonal_std_mbbl, 2)
        AS seasonal_std_mbbl,
    ROUND(cushing_inventory_seasonal_zscore, 3)
        AS seasonal_zscore
FROM weekly_features
WHERE cushing_inventory_seasonal_zscore IS NOT NULL
ORDER BY cushing_inventory_seasonal_zscore ASC
LIMIT 10;


-- Validation 5: Inspect Sparse ISO Week 53
SELECT
    period,
    iso_week_year,
    iso_week_of_year,
    cushing_inventory_mbbl,
    cushing_inventory_seasonal_n_hist,
    cushing_inventory_seasonal_zscore
FROM weekly_features
WHERE iso_week_of_year = 53
ORDER BY period;


-- Validation 6: April 2020 Economic Sanity Check
SELECT
    period,

    cushing_inventory_mbbl,
    cushing_inventory_change_1w_mbbl,
    cushing_inventory_change_4w_mbbl,
    cushing_inventory_4w_avg_mbbl,

    us_crude_net_imports_mbbl_d,
    us_crude_net_imports_4w_avg_mbbl_d,

    ROUND(cl2_minus_cl1_usd_bbl, 2)
        AS cl2_minus_cl1_usd_bbl,

    ROUND(front_spread_change_1w_usd_bbl, 2)
        AS front_spread_change_1w_usd_bbl,

    ROUND(front_spread_4w_avg_usd_bbl, 4)
        AS front_spread_4w_avg_usd_bbl,

    iso_week_of_year,

    cushing_inventory_seasonal_n_hist,

    ROUND(cushing_inventory_seasonal_mean_mbbl, 2)
        AS cushing_inventory_seasonal_mean_mbbl,

    ROUND(cushing_inventory_seasonal_std_mbbl, 2)
        AS cushing_inventory_seasonal_std_mbbl,

    ROUND(cushing_inventory_seasonal_zscore, 3)
        AS cushing_inventory_seasonal_zscore

FROM weekly_features
WHERE period BETWEEN '2020-04-01' AND '2020-05-15'
ORDER BY period;