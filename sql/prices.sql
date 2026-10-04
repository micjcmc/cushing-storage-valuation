-- Build clean WTI spot and futures price domain table from raw EIA observations

CREATE TABLE IF NOT EXISTS prices (
    period TEXT PRIMARY KEY,
    wti_spot_usd_bbl,               -- Spot price
    cl1_usd_bbl,                    -- Contract 1 price
    cl2_usd_bbl,                    -- Contract 2 price
    cl3_usd_bbl,                    -- Contract 3 price
    cl4_usd_bbl                     -- Contract 4 price
);

DELETE FROM prices;

INSERT INTO prices (
    period,
    wti_spot_usd_bbl,
    cl1_usd_bbl,
    cl2_usd_bbl,
    cl3_usd_bbl,
    cl4_usd_bbl
)

SELECT
    period,

    MAX (
        CASE
            WHEN series_id = 'RWTC'
            THEN value
        END
    ) AS wti_spot_usd_bbl,

    MAX (
        CASE
            WHEN series_id = 'RCLC1'
            THEN value
        END
    ) AS cl1_usd_bbl,

    MAX (
        CASE
            WHEN series_id = 'RCLC2'
            THEN value
        END
    ) AS cl2_usd_bbl,

    MAX (
        CASE
            WHEN series_id = 'RCLC3'
            THEN value
        END
    ) AS cl3_usd_bbl,

    MAX (
        CASE
            WHEN series_id = 'RCLC4'
            THEN value
        END
    ) AS cl4_usd_bbl

FROM raw_eia_series

WHERE series_id IN (
    'RWTC',
    'RCLC1',
    'RCLC2',
    'RCLC3',
    'RCLC4'
)

GROUP BY period
ORDER BY period;