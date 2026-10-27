import sqlite3
import pandas as pd
import matplotlib.pyplot as plt


def load_physical_financial_data():
    conn = sqlite3.connect(
        "C:/cushing-storage-valuation/data/cushing_storage.db"
    )

    try:
        df = pd.read_sql_query(
            """
            SELECT
                period,

                cushing_inventory_mbbl,
                cushing_total_utilization,
                cushing_tank_utilization,

                cushing_inventory_change_1w_mbbl,
                cushing_inventory_change_4w_mbbl,

                cl2_minus_cl1_usd_bbl AS f2_f1,
                cl4_minus_cl1_usd_bbl AS f4_f1

            FROM weekly_features

            WHERE cushing_total_utilization IS NOT NULL
              AND cl2_minus_cl1_usd_bbl IS NOT NULL
              AND cl4_minus_cl1_usd_bbl IS NOT NULL

            ORDER BY period;
            """,
            conn
        )

    finally:
        conn.close()

    df["period"] = pd.to_datetime(
        df["period"]
    )

    return df


if __name__ == "__main__":

    df = load_physical_financial_data()

    # Storage utilization vs. front calendar spread
    fig, ax = plt.subplots(
        figsize=(8, 5),
        constrained_layout=True
    )

    ax.scatter(
        df["cushing_total_utilization"] * 100,
        df["f2_f1"]
    )

    ax.axhline(
        0,
        linewidth=1
    )

    ax.set(
        xlabel="Cushing Storage Utilization (%)",
        ylabel=r"$F_2 - F_1$ (USD / bbl)",
        title="Cushing Storage Utilization vs. Front WTI Calendar Spread"
    )

    plt.show()


    # Storage utilization vs. cumulative calendar spread
    fig, ax = plt.subplots(
        figsize=(8, 5),
        constrained_layout=True
    )

    ax.scatter(
        df["cushing_total_utilization"] * 100,
        df["f4_f1"]
    )

    ax.axhline(
        0,
        linewidth=1
    )

    ax.set(
        xlabel="Cushing Storage Utilization (%)",
        ylabel=r"$F_4 - F_1$ (USD / bbl)",
        title="Cushing Storage Utilization vs. Cumulative WTI Calendar Spread"
    )

    plt.show()


    # Four-week inventory change vs. front calendar spread
    fig, ax = plt.subplots(
        figsize=(8, 5),
        constrained_layout=True
    )

    ax.scatter(
        df["cushing_inventory_change_4w_mbbl"],
        df["f2_f1"]
    )

    ax.axhline(
        0,
        linewidth=1
    )

    ax.axvline(
        0,
        linewidth=1
    )

    ax.set(
        xlabel="4-Week Cushing Inventory Change (MBBL)",
        ylabel=r"$F_2 - F_1$ (USD / bbl)",
        title="Cushing Inventory Accumulation vs. Front WTI Calendar Spread"
    )

    plt.show()


    # Four-week inventory change vs. cumulative calendar spread
    fig, ax = plt.subplots(
        figsize=(8, 5),
        constrained_layout=True
    )

    ax.scatter(
        df["cushing_inventory_change_4w_mbbl"],
        df["f4_f1"]
    )

    ax.axhline(
        0,
        linewidth=1
    )

    ax.axvline(
        0,
        linewidth=1
    )

    ax.set(
        xlabel="4-Week Cushing Inventory Change (MBBL)",
        ylabel=r"$F_4 - F_1$ (USD / bbl)",
        title="Cushing Inventory Accumulation vs. Cumulative WTI Calendar Spread"
    )

    plt.show()