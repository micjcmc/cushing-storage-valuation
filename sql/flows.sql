-- Build clean U.S. crude-oil flow domain table from weekly EIA observations

CREATE TABLE IF NOT EXISTS flows (
    period TEXT PRIMARY KEY,
    us_crude_production_mbbl_d REAL,
    us_crude_imports_mbbl_d REAL,
    us_crude_exports_mbbl_d REAL
);

DELETE FROM flows;

INSERT INTO flows (
    period,
    us_crude_production_mbbl_d,
    us_crude_imports_mbbl_d,
    us_crude_exports_mbbl_d
)

SELECT
    period,

    MAX (
        CASE
            WHEN series_id = 'WCRFPUS2'
            THEN value
        END
    ) AS us_crude_production_mbbl_d,

    MAX (
        CASE
            WHEN series_id = 'WCRIMUS2'
            THEN value
        END
    ) AS us_crude_imports_mbbl_d,

    MAX (
        CASE
            WHEN series_id = 'WCREXUS2'
            THEN value
        END
    ) AS us_crude_exports_mbbl_d

FROM raw_eia_series

WHERE series_id in (
    'WCRFPUS2',
    'WCRIMUS2',
    'WCREXUS2'
)

GROUP BY period
ORDER BY period;