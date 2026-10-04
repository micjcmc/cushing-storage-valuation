-- Build clean PADD 2 refinery activity domain table from raw_eia_series (from raw EIA observation data)
-- -- **NOTE**: Utilization levels may exceed 100%. This is not necessarily erroneous since EIA calculates weekly utilization relative to latest reported monthly operable capacity,
-- -- ^         so weekly gross inputs may exceed nominal calendar-day capacity measure. (Also, EIA's own PADD 2 series has some utilization above 100%.)

CREATE TABLE IF NOT EXISTS refinery_activity (
    period TEXT PRIMARY KEY,
    padd2_crude_input_mbbl_d REAL,
    padd2_refinery_utilization_pct REAL
);

DELETE FROM refinery_activity;

INSERT INTO refinery_activity (
    period, 
    padd2_crude_input_mbbl_d,
    padd2_refinery_utilization_pct
)

SELECT
    period,

    MAX (                                                   -- Same pivot MAX(CASE WHEN...) concept as used in inventories.sql
        CASE
            WHEN series_id = 'WCRRIP22'
            THEN value
        END
    ) AS padd_2_crude_input_mbbl_d,

    MAX (
        CASE
            WHEN series_id = 'W_NA_YUP_R20_PER'
            THEN VALUE
        END
    ) AS padd_2_refinery_utilization_pct

    FROM raw_eia_series

    WHERE series_id IN (
        'WCRRIP22',
        'W_NA_YUP_R20_PER'
    )

    GROUP BY period
    ORDER BY period;