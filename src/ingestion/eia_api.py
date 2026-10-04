
### Configuration

# Imports
import os
import sqlite3
from pathlib import Path

import requests
from dotenv import load_dotenv

# Find project root
project_root = Path(__file__).resolve().parents[2]

# Build explicit path to C:\cushing-storage-valuation\.env
env_path = project_root / ".env"

# Load variables from .env
load_dotenv(env_path)

# Retrieve the API key
api_key = os.getenv("EIA_API_KEY")

# For debugging (string/comment out otherwise)
    # print(".env_path:", env_path)
    # print(".env exists:", env_path.exists())
    # print("API key loaded:", bool(api_key))
    # if not api_key:
        # raise RuntimeError("EIA_API_KEY could not be loaded.")
    # print(response.status_code)



### Building SQL Database


# Create a function to pull EIA API data for every desired variable

def fetch_eia_series(route, series_id, frequency, api_key, length=10):
    '''
    Pulls EIA API data by route (string), series ID (string), and frequency (string, e.g., 'weekly', 'monthly', etc.). 
    Authenticates with api_key (string) and clips output to desired length (int; defaults to 10).
    Returns rows of specified EIA API data.
    '''
    url = f"https://api.eia.gov/v2/{route}/data/"

    params = {
        "api_key": api_key,
        "frequency": frequency,
        "data[0]": "value",
        "facets[series][]": series_id,
        "sort[0][column]": "period",
        "sort[0][direction]": "desc",
        "offset": 0,
        "length": length,
    }

    response = requests.get(url, params=params)
    response.raise_for_status()

    data = response.json()

    rows = data["response"]["data"]

    return rows


# Establish connection to SQL database
db_path = project_root / "data" / "cushing_storage.db"


# Create function to input pulled EPI API data into SQL database
def store_eia_rows(rows, db_path):
    '''
    Inputs pulled EIA API data into SQL Database. 
    '''

    conn = sqlite3.connect(db_path)

    # Create cursor object to use to execute SQL statements
    cursor = conn.cursor()

    # Initialize Database. Here we build the first table in the database. The table is raw_eia_series. This query chunk will ONLY run the very first time this function is called
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS raw_eia_series (
            series_id TEXT NOT NULL,
            period TEXT NOT NULL,
            value REAL,
            units TEXT,
            series_description TEXT,
            frequency TEXT,
            retrieved_at TEXT,
            PRIMARY KEY (series_id, period)
        );
        """
    )

    # Insert Cushing Observations into Database, specifically into raw_eia_series table. We use OR REPLACE INTO and ON CONFLICT below since (series_id, period) is a primary key and we want rerunnability

    for row in rows:
        cursor.execute(                              
            """
            INSERT OR REPLACE INTO raw_eia_series(
                series_id,
                period,
                value,
                units,
                series_description,
                frequency,
                retrieved_at
            )
            VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
            ON CONFLICT(series_id, period) DO UPDATE SET
                value = excluded.value,
                units = excluded.units,
                series_description = excluded.series_description,
                frequency = excluded.frequency,
                retrieved_at = excluded.retrieved_at
            """,
            (
                row["series"],
                row["period"],
                float(row["value"]),
                row["units"],
                row["series-description"],
                "weekly",
            )
        )

    conn.commit()
    conn.close()

    print(f"Inserted {len(rows)} observations into {db_path}.")


### Implement/Run Pipeline

# Cushing crude inventories - direct measure of barrels sitting at WTI delivery hub
cushing_rows = fetch_eia_series(
    "petroleum/stoc/wstk",
    "W_EPC0_SAX_YCUOK_MBBL",
    "weekly",
    api_key,
    length = 5000
)

store_eia_rows(cushing_rows, db_path)

# PADD 2 crude inventories - Regional crude availability
padd_2_crude_inventories_rows = fetch_eia_series(
    "petroleum/stoc/wstk",
    "WCESTP21",
    "weekly",
    api_key,
    length = 5000
)

store_eia_rows(padd_2_crude_inventories_rows, db_path)


# PADD 2 Refinery Crude Inputs - Major source of physical crude demand
padd_2_refinery_input_rows = fetch_eia_series(
    "petroleum/pnp/wiup",
    "WCRRIP22",
    "weekly",
    api_key,
    length = 5000
)

store_eia_rows(padd_2_refinery_input_rows, db_path)


# Refinery Utilization - identifies outages/strong runs
refinery_utilization_rows = fetch_eia_series(
    "petroleum/pnp/unc",
    "MGIRI2A2",
    "monthly",                                               # "monthly" here since EIA only has refinery utilization data up to as frequently as monthly
    api_key,
    length = 5000
)

store_eia_rows(refinery_utilization_rows, db_path)


# U.S. Crude Production - Supply
us_crude_prod_rows = fetch_eia_series(
    "petroleum/crd/crpdn",
    "MCRFPUS2",
    "monthly",                                              # Again, "monthly" here for same reason as above
    api_key,
    length = 5000
)

store_eia_rows(us_crude_prod_rows, db_path)


# Imports - External Supply
import_rows = fetch_eia_series(
    "petroleum/move/wkly",
    "WCRIMUS2",
    "weekly",
    api_key,
    length = 5000
)

store_eia_rows(import_rows, db_path)


# Exports - External Demand
export_rows = fetch_eia_series(
    "petroleum/move/wkly",
    "WCREXUS2",
    "weekly",
    api_key,
    length = 5000
)

store_eia_rows(export_rows, db_path)


# WTI Spot - Prompt Crude Price
wti_spot_rows = fetch_eia_series(
    "petroleum/pri/spt",
    "RWTC",
    "weekly",
    api_key,
    length = 5000
)

store_eia_rows(wti_spot_rows, db_path)


# Front Futures Contracts - Curve/Storage Economics
futures_series = [
    "RCLC1",                                        # Contract 1
    "RCLC2",                                        # Contract 2
    "RCLC3",                                        # Contract 3
    "RCLC4",                                        # Contract 4
]

for series_id in futures_series:                    # Loop here for efficiency as opposed to calling fetch_eia_series four individual times
    futures_rows = fetch_eia_series(
        "petroleum/pri/fut",
        series_id,
        "weekly",
        api_key,
        length = 5000
    )

    store_eia_rows(futures_rows, db_path)


# PADD 2 Refinery Utilization - For refinery_activity table
padd2_ref_util_rows = fetch_eia_series(
    "petroleum/pnp/wiup",
    "W_NA_YUP_R20_PER",
    "weekly",
    api_key,
    length = 5000
)

store_eia_rows(padd2_ref_util_rows, db_path)


# Flows (Weekly production ESTIMATES by EIA) - used for flows.sql table
wkly_production_est_rows = fetch_eia_series(
    "petroleum/sum/sndw",
    "WCRFPUS2",
    "weekly",
    api_key,
    length = 5000
)

store_eia_rows(wkly_production_est_rows, db_path)

