import math
import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

conn = sqlite3.connect("C:/cushing-storage-valuation/data/cushing_storage.db")

cur = conn.cursor()

# Loading dataframe. Similar to query from analytics.sql that inspects term structure of carry
df = pd.read_sql_query(
    """
    SELECT
    period,
    cl1_usd_bbl AS cl1,
    cl2_usd_bbl AS cl2,
    cl3_usd_bbl AS cl3,
    cl4_usd_bbl AS cl4,

    cl2_minus_cl1_usd_bbl AS f2_f1,
    cl3_minus_cl2_usd_bbl AS f3_f2,
    cl4_minus_cl3_usd_bbl AS f4_f3,
    cl3_minus_cl1_usd_bbl AS f3_f1,
    cl4_minus_cl1_usd_bbl AS f4_f1

    FROM weekly_features

    WHERE cl1_usd_bbl IS NOT NULL
      AND cl2_usd_bbl IS NOT NULL
      AND cl3_usd_bbl IS NOT NULL
      AND cl4_usd_bbl IS NOT NULL

    ORDER BY period;
    """,
    conn
)

### Annualized Carry
 ## NOTE: EIA API data lacks expiry date history (lacks Ti variable) for futures contracts. Thus, for the purposes of this project, we will use T2-T1 ≈ 365/12, so thus 365/(T2-T1) ≈ 12.
 ## Thus our formula for annualized carry, AnnCarry_{1,2} = (F2-F1)/(F1) * (365)/(T2-T1), becomes AnnCarry_{1,2} ≈ 12(F2-F1)/F1.

df["annualized_carry_1_2"] = (
    df["f2_f1"]
    / df["cl1"].replace(0, np.nan)      # nan used here because when F1 = 0 annualized carry is undefined. We prefer to generate missing numbers rather than infinity in these cases.
    * 12
)

# Longer-Horizon Carries
df["annualized_carry_1_3"] = (          # Using AnnCarry_{1,3} ≈ 6(F2-F1)/F1. 6 here since T3-T2 = T2-T1, so T3-T1=2(T2-T1) = 2(365/12) = 365/6 -> AnnCarry_{1,3} ≈ (F3-F1)/(F1)*(365)/(T3-T1)=6(F3-F1)/F1.
    df["f3_f1"]
    / df["cl1"].replace(0, np.nan)
    * 6
)

df["annualized_carry_1_4"] = (          # Similarly, T4-T3 = T2-T1 -> T4-T1 = 3(T2-T1) -> AnnCarry_{1,4} ≈ (F4-F1)/(F1) * (365)/(T4-T1) = 4(F4-F1)/F1.
    df["f4_f1"]
    / df["cl1"]
    * 4
)

conn.close()

df["period"] = pd.to_datetime(df["period"])


print(df.head())
print(df.columns)
print(df.dtypes)
print(
    df[
        [
            "period",
            "cl1",
            "f2_f1",
            "annualized_carry_1_2"
        ]
    ].head()
)


# Contract numbers on the curve 1 to 4 and contract labels for plotting axes
contract_numbers = np.arange(1,5)
contract_labels = ["CL1", "CL2", "CL3", "CL4"]



def plot_futures_curve(dates, ncols = 2):
    '''
    Plots futures curve for CL1-CL4 for each of a given list of dates, inputted as an array of string literals.
    '''

    nplots = len(dates)
    nrows = math.ceil(nplots / ncols)


    fig, axs = plt.subplots(
        nrows, 
        ncols, 
        figsize = (8, 7), 
        sharex = False, 
        constrained_layout = True
    )

    # Make axs iterable even if there is only one subplot
    axs = np.atleast_1d(axs).ravel()

    # Loop through code for plotting future prices since all future prices plots will have same structure
    for ax, date in zip(axs, dates):
        row = df.loc[df["period"] == date].iloc[0]          # Here, df.loc[df["period"] == date] finds the location in the dataframe where "period" = date. date is from our iterable here so it cycles through
                                                            # our chosen dates. Basically telling python to filter df to row whose date matches. Then .iloc[0] finds the index 0th (so first) row of that filtered
                                                            # dataframe as a pandas series.
        futures_prices = np.array([
            row["cl1"],
            row["cl2"],
            row["cl3"],
            row["cl4"]
        ])

        ax.plot (
            contract_numbers,
            futures_prices,
            marker = "o"
        )

        ax.set (
            ylabel = "USD / bbl",
            title = f"WTI Forward Curve: {date}"
        )

        ax.set_xticks(
            contract_numbers,
            labels = contract_labels

        )

    # Remove unused subplot axes
    for ax in axs[nplots:]:
        ax.remove()

    plt.show()

def plot_futures_spreads(dates, ncols = 2):
    '''
    Plots spreads for inputted dates on bar charts. Can and will make an alternative using a line graph to model spread evolution over time for given dates.
    '''
    spread_labels = [
        "F2 - F1",
        "F3 - F2",
        "F4 - F3"
    ]

    nplots = len(dates)
    nrows = math.ceil(nplots / ncols)

    fig, axs = plt.subplots(
        nrows,
        ncols,
        figsize = (8, 8),
        sharex = True,
        constrained_layout = True
    )

    axs = np.atleast_1d(axs).ravel()

    for ax, date in zip(axs, dates):

        row = df.loc[df["period"] == pd.to_datetime(date)].iloc[0]

        spreads = np.array([
            row["f2_f1"],
            row["f3_f2"],
            row["f4_f3"]
        ])

        ax.bar(
            spread_labels,
            spreads
        )

        ax.axhline(
            0,
            linewidth = 1
        )

        ax.set(
            ylabel = "USD / bbl",
            title = f"WTI Calendar Spreads: {date}"
        )

    for ax in axs[nplots:]:
        ax.remove()

    plt.show()

# Chosen dates we want to compare
dates = [
    "2009-02-13",
    "2020-04-24",
    "2022-03-11"
]

plot_futures_curve(dates)
plot_futures_spreads(dates)



# Now Visualizing Normalized Forward Curves

fig, ax = plt.subplots(
    figsize = (8,5),
    constrained_layout = True
)

for date in dates:

    row = df.loc[df["period"] == pd.to_datetime(date)].iloc[0]

    futures_prices = np.array([
        row["cl1"],
        row["cl2"],
        row["cl3"],
        row["cl4"]
    ])

    normalized_prices = futures_prices - futures_prices[0]

    ax.plot(
        contract_numbers,
        normalized_prices,
        marker = "o",
        label = date
    )

ax.axhline(0, linewidth = 1)

ax.set(
    xlabel = "Futures Contract",
    ylabel = r"$F_i - F_1$ (USD / bbl)",
    title = "WTI Forward Curve Shape Relative to CL1"
)

ax.set_xticks(
    contract_numbers,
    labels = contract_labels
)

ax.legend()

plt.show()


# Long-Run Regime Picture

fig, ax = plt.subplots(
    figsize = (10, 5),
    constrained_layout = True
)

ax.plot(
    df["period"],
    df["f2_f1"],
    label = r"$F_2 - F_1$"
)

ax.plot(
    df["period"],
    df["f4_f1"],
    label = r"$F_4 - F_1$"
)

ax.axhline(
    0,
    linewidth = 1
)

ax.set(
    xlabel = "Date",
    ylabel = "USD / bbl",
    title = "Historical WTI Calendar Spreads"
)

ax.legend()

plt.show()



# Inspecting Extreme Values Numerically

print(
    df.nlargest(
        10,
        "annualized_carry_1_2"
    )[
        [
            "period",
            "cl1",
            "cl2",
            "f2_f1",
            "annualized_carry_1_2"
        ]
    ]
)

print(
    df.nsmallest(
        10,
        "annualized_carry_1_2"
    )[
        [
            "period",
            "cl1",
            "cl2",
            "f2_f1",
            "annualized_carry_1_2"
        ]
    ]
)

print(
    df["annualized_carry_1_2"].describe(
        percentiles = [0.01, 0.05, 0.25, 0.50, 0.75, 0.95, 0.99]
    )
)

lower_bound = (
    df["annualized_carry_1_2"].quantile(0.01) * 100
)

upper_bound = (
    df["annualized_carry_1_2"].quantile(0.99) * 100
)

print(lower_bound, upper_bound)



# Historical Carry Plot (Note the scale here is suboptimal due to April 2020's annualized carry being north of 4000%, but this unaltered scale is left for clarity. Another graph follows.)
fig, ax = plt.subplots(
    figsize = (10, 5),
    constrained_layout = True
)

ax.plot(
    df["period"],
    df["annualized_carry_1_2"] * 100
)

ax.axhline(
    0,
    linewidth = 1
)

ax.set(
    xlabel = "Date",
    ylabel = "Annualized Carry (%)",
    title = r"Annualized WTI Front Calendar Carry: $F_2 - F_1$"
)

plt.show()


# Clipped-View Plot (1st to 99th percentile to eliminate April 2020 outlier)

fig, ax = plt.subplots(
    figsize = (10, 5),
    constrained_layout = True
)

ax.plot(
    df["period"],
    df["annualized_carry_1_2"] * 100
)

ax.axhline(
    0,
    linewidth = 1
)

ax.set(
    xlabel = "Date",
    ylabel = "Annualized Carry (%)",
    title = r"Annualized WTI Front Calendar Carry: $F_2 - F_1$"
)

ax.set_ylim(
    lower_bound,
    upper_bound
)

plt.show()



# More Inspection

print(
    df.loc[
        df["period"].isin(pd.to_datetime(dates)),
        [
            "period",
            "annualized_carry_1_2",
            "annualized_carry_1_3",
            "annualized_carry_1_4"
        ]
    ]
)

carry_comparison = df.loc[
    df["period"].isin(pd.to_datetime(dates)),
    [
        "period",
        "annualized_carry_1_2",
        "annualized_carry_1_3",
        "annualized_carry_1_4"
    ]
].copy()

carry_columns = [
    "annualized_carry_1_2",
    "annualized_carry_1_3",
    "annualized_carry_1_4"
]

carry_comparison[carry_columns] *= 100

print(carry_comparison)