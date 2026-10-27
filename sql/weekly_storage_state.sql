DROP TABLE IF EXISTS weekly_storage_state;

CREATE TABLE weekly_storage_state AS

WITH matched_capacity AS (
    SELECT
        i.period,

        i.cushing_inventory_mbbl,

        c.reference_month,
        c.effective_date,

        c.cushing_working_capacity_mbbl,
        c.cushing_shell_capacity_mbbl,
        c.cushing_pipeline_fill_mbbl,
        c.cushing_working_capacity_plus_transit_mbbl,
        
        -- For each weekly observation, rank all capacity observations already effective by that date from newest to oldest
        ROW_NUMBER() OVER (
            PARTITION BY i.period
            ORDER BY c.effective_date DESC
        ) AS rn

    FROM inventories i

    LEFT JOIN storage_capacity c
        ON c.effective_date <= i.period
)

SELECT
    period,

    reference_month AS capacity_reference_month,
    effective_date AS capacity_effective_date,

    cushing_inventory_mbbl,

    cushing_working_capacity_mbbl,
    cushing_shell_capacity_mbbl,

    cushing_pipeline_fill_mbbl,
    cushing_working_capacity_plus_transit_mbbl,

    -- Estimate of barrels actually occupying tank storage
    cushing_inventory_mbbl
        - cushing_pipeline_fill_mbbl
        AS estimated_cushing_tank_inventory_mbbl,

    -- Tank-only utilization estimate
    (
        cushing_inventory_mbbl
        - cushing_pipeline_fill_mbbl
    )
        / NULLIF(cushing_working_capacity_mbbl, 0)
        AS cushing_tank_utilization,

    -- EIA-aligned utilization measure for weekly reported stocks
    cushing_inventory_mbbl
        / NULLIF (
            cushing_working_capacity_plus_transit_mbbl,
            0
        )
        AS cushing_total_utilization

FROM matched_capacity

WHERE rn = 1

ORDER BY period;