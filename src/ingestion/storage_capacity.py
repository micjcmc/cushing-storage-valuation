import numpy as np
import pandas as pd
import sqlite3
from datetime import datetime, timezone

path = "C:/cushing-storage-valuation/data/raw/crudeoilstorage.xlsx"

# For inspection of data (run after coding only this chunk to inspect before coding the rest)
raw = pd.read_excel(
    path,
    sheet_name = "Cushing",
    header = None
)

# print(raw.iloc[:10, :6])


# Now we know that the dates are on row 3 and begin in column 1
reference_months = (
    pd.to_datetime(raw.iloc[3, 1:])
    .dt.to_period("M")
)

# print (reference_months)


# Identify rows by labels
row_labels = raw.iloc[:, 0].astype(str).str.strip()

def get_row(label):
    mask = row_labels == label

    if not mask.any():
        raise ValueError(f"Could not find row: {label}")

    return pd.to_numeric(
        raw.loc[mask].iloc[0, 1:],
        errors = "coerce"
    ).to_numpy()


# Construct capacity measure
capacity = pd.DataFrame({
    "reference_month": reference_months.to_numpy(),

    "pipeline_and_tank_farm_mbbl":
    get_row("Pipeline and Tank Farm1"),

    "tank_farm_mbbl":
    get_row("Tank Farm"),

    "pipeline_fill_and_rail_mbbl":
    get_row("Pipeline Fill and in Transit by Rail"),

    "tank_shell_capacity_mbbl":
    get_row("Tank Net Available Shell Storage Capacity"),

    "tank_working_capacity_mbbl":
    get_row("Tank Working Storage Capacity"),

    "reported_tank_utilization":
    get_row("Tank Capacity Utilization Rate (percent)2"),

    "working_capacity_plus_transit_mbbl":
    get_row("Sum of Working Storage Capacity and Stocks in Transit3"),

    "reported_alternate_utilization":
    get_row("Alternate Utilization Rate4")
})


# Validate the Data Algebraically
np.testing.assert_allclose(
    capacity["pipeline_and_tank_farm_mbbl"],
    capacity["tank_farm_mbbl"]
        + capacity["pipeline_fill_and_rail_mbbl"],
    rtol = 0,
    atol = 1
)

np.testing.assert_allclose(
    capacity["reported_tank_utilization"],
    capacity["tank_farm_mbbl"]
        / capacity["tank_working_capacity_mbbl"],
    rtol = 1e-4
)

np.testing.assert_allclose(
    capacity["working_capacity_plus_transit_mbbl"],
    capacity["tank_working_capacity_mbbl"]
        + capacity["pipeline_fill_and_rail_mbbl"],
    rtol = 0,
    atol = 1
)

np.testing.assert_allclose(
    capacity["reported_alternate_utilization"],
    capacity["pipeline_and_tank_farm_mbbl"]
        / capacity["working_capacity_plus_transit_mbbl"],
    rtol = 1e-4
)


# Check output
print(capacity)
print(capacity.dtypes)
print(capacity.isna().sum())
print(
    capacity[
        [
            "reference_month",
            "tank_working_capacity_mbbl",
            "pipeline_fill_and_rail_mbbl",
            "reported_tank_utilization"
        ]
    ]
)


# Record when our pipeline ingested the source into the database
capacity["retrieved_at"] = (
    datetime.now(timezone.utc)
    .isoformat()
)


# Convert reference month to string for SQL
capacity["reference_month"] = (
    capacity["reference_month"]
    .astype(str)
)


### Now insert into SQL
db_path = "C:/cushing-storage-valuation/data/cushing_storage.db"
conn = sqlite3.connect(db_path)


# Create raw_eia_storage_capacity (using a new raw table here separate from raw_eia_series due to the difference in data type for this table)
conn.execute(
    """
    CREATE TABLE IF NOT EXISTS raw_eia_storage_capacity (
        reference_month TEXT PRIMARY KEY,

        pipeline_and_tank_farm_mbbl INTEGER,
        tank_farm_mbbl INTEGER,
        pipeline_fill_and_rail_mbbl INTEGER,

        tank_shell_capacity_mbbl INTEGER,
        tank_working_capacity_mbbl INTEGER,

        reported_tank_utilization REAL,

        working_capacity_plus_transit_mbbl INTEGER,
        reported_alternate_utilization REAL,

        retrieved_at TEXT NOT NULL
    );
    """
)

# Turn db rows into tuples
rows = capacity[
    [
        "reference_month",
        "pipeline_and_tank_farm_mbbl",
        "tank_farm_mbbl",
        "pipeline_fill_and_rail_mbbl",
        "tank_shell_capacity_mbbl",
        "tank_working_capacity_mbbl",
        "reported_tank_utilization",
        "working_capacity_plus_transit_mbbl",
        "reported_alternate_utilization",
        "retrieved_at"
    ]
].itertuples(
    index = False,
    name = None
)



conn.executemany(
    """
    INSERT INTO raw_eia_storage_capacity (
        reference_month,
        pipeline_and_tank_farm_mbbl,
        tank_farm_mbbl,
        pipeline_fill_and_rail_mbbl,
        tank_shell_capacity_mbbl,
        tank_working_capacity_mbbl,
        reported_tank_utilization,
        working_capacity_plus_transit_mbbl,
        reported_alternate_utilization,
        retrieved_at
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

    ON CONFLICT(reference_month)
    DO UPDATE SET
        pipeline_and_tank_farm_mbbl = excluded.pipeline_and_tank_farm_mbbl,
        tank_farm_mbbl = excluded.tank_farm_mbbl,
        pipeline_fill_and_rail_mbbl = excluded.pipeline_fill_and_rail_mbbl,
        tank_shell_capacity_mbbl = excluded.tank_shell_capacity_mbbl,
        tank_working_capacity_mbbl = excluded.tank_working_capacity_mbbl,
        reported_tank_utilization = excluded.reported_tank_utilization,
        working_capacity_plus_transit_mbbl = excluded.working_capacity_plus_transit_mbbl,
        reported_alternate_utilization = excluded.reported_alternate_utilization,
        retrieved_at = excluded.retrieved_at;
    """,
    rows
)

conn.commit()


# Validate
check = pd.read_sql_query(
    """
    SELECT *
    FROM raw_eia_storage_capacity
    ORDER BY reference_month;
    """,
    conn
)
print(check)
print(len(check))

conn.close()