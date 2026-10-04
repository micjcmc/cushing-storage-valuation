-- (This document is basically a pivot from a long to a wide table)

-- Build clean inventory domain table from raw_eia_series (raw EIA observation data table) 
CREATE TABLE IF NOT EXISTS inventories(
    period TEXT PRIMARY KEY,
    cushing_inventory_mbbl REAL,
    padd2_inventory_mbbl REAL
);

-- Rebuild from the current raw source data
DELETE FROM inventories;

INSERT INTO inventories(
    period,
    cushing_inventory_mbbl,
    padd2_inventory_mbbl
)
SELECT
    period,

    MAX(                                                -- MAX here since the below CASE returns NULL values for all the padd2 data and we want cushing data only. So e.g., for 9/11/26 SQL has something like
        CASE                                            -- like: Cushing CASE results: NULL, 21482. Then MAX(NULL, 21482) = 21482 which is the cushing data. Reverse for below padd2 CASE.
            WHEN series_id = 'W_EPC0_SAX_YCUOK_MBBL'
            THEN value
        END
    ) AS cushing_inventory_mbbl,

    MAX(                                                -- Now MAX again but for the padd2 CASE to return only padd2 data. The MAX(CASE WHEN ...) pattern is a common SQL pivot method.
        CASE
            WHEN series_id = 'WCESTP21'
            THEN value
        END
    ) AS padd2_inventory_mbbl

FROM raw_eia_series

WHERE series_id IN (
    'W_EPC0_SAX_YCUOK_MBBL',
    'WCESTP21'
)

GROUP BY period
ORDER BY period;