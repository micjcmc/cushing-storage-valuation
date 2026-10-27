DROP TABLE IF EXISTS storage_capacity;

CREATE TABLE storage_capacity AS

SELECT
    reference_month,

    DATE(reference_month || '-01') AS effective_date,

    tank_working_capacity_mbbl
        AS cushing_working_capacity_mbbl,

    tank_shell_capacity_mbbl
        AS cushing_shell_capacity_mbbl,

    pipeline_fill_and_rail_mbbl
        AS cushing_pipeline_fill_mbbl,

    working_capacity_plus_transit_mbbl
        AS cushing_working_capacity_plus_transit_mbbl,

    reported_tank_utilization
        AS cushing_reported_tank_utilization,
        
    reported_alternate_utilization
        AS cushing_reported_alternate_utilization

FROM raw_eia_storage_capacity

ORDER BY reference_month;

-- Validate
SELECT *
FROM storage_capacity
ORDER BY reference_month;

SELECT COUNT(*) AS n_rows
FROM storage_capacity;

SELECT
    MIN(reference_month) AS first_month,
    MAX(reference_month) AS last_month,
    MIN(cushing_working_capacity_mbbl) AS min_working_capacity,
    MAX(cushing_working_capacity_mbbl) AS max_working_capacity
FROM storage_capacity;