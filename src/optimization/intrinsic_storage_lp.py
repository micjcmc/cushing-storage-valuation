import sqlite3
import pulp as pl
import pandas as pd

db_path = "C:/cushing-storage-valuation/data/cushing_storage.db"

def query_prices(
    dates=None,
    start_date=None,
    end_date=None
):
    '''
    Queries CL1-CL4 futures curves from weekly_features. Accepts single dates or date range(s).

    Parameters
    ----------
    dates : str or iterable[str], optional
        One date or multiple exact dates in YYYY-MM-DD format.

    start_date : str, optional
        Inclusive start date for a date range.

    end_date : str, optional
        Inclusive end date for a date range.

    Returns
    -------
    dict
        Mapping:
            valuation_date -> {0: CL1, 1: CL2, 2: CL3, 3: CL4}
    '''

    if dates is not None and (start_date is not None or end_date is not None):
        raise ValueError(
            "Use either exact dates or a date range, not both."
        )

    conn = sqlite3.connect(db_path)

    try:
        cursor = conn.cursor()

        if dates is not None:

            if isinstance(dates, str):
                dates = [dates]

            dates = list(dates)

            if not dates:
                return {}

            placeholders = ", ".join("?" for _ in dates)

            query = f"""
                SELECT
                    period,
                    cl1_usd_bbl,
                    cl2_usd_bbl,
                    cl3_usd_bbl,
                    cl4_usd_bbl
                FROM weekly_features
                WHERE period IN ({placeholders})
                ORDER BY period
            """

            cursor.execute(query, dates)

        elif start_date is not None and end_date is not None:

            cursor.execute(
                """
                SELECT
                    period,
                    cl1_usd_bbl,
                    cl2_usd_bbl,
                    cl3_usd_bbl,
                    cl4_usd_bbl
                FROM weekly_features
                WHERE period BETWEEN ? AND ?
                ORDER BY period
                """,
                (start_date, end_date)
            )

        else:
            raise ValueError(
                "Provide either dates or both start_date and end_date."
            )

        rows = cursor.fetchall()

    finally:
        conn.close()

    curves = {}

    for row in rows:

        valuation_date = row[0]

        prices = {
            0: row[1],
            1: row[2],
            2: row[3],
            3: row[4]
        }

        if any(price is None for price in prices.values()):
            continue

        curves[valuation_date] = prices

    return curves


# Validation helper function. Added this after discovering edge GapLimit case for CBC when the objective = 0 = bound.
# ^ Don't want to allow all GapLimits so included a specific edge case in the set of accepted possibilities. 
def validate_solve(stats, tol=1e-9):
    '''
    Accepts one of the following:
    1. An explicitly Optimal solution.
    2. A GapLimit solve only when:
       - A feasible solution exists, and
       - The incumbent objective and best bound are numerically equal.

    Rejects all genuine nonzero-gap terminations.
    '''
    if stats.status_str == "Optimal":
        return

    if (
        stats.status_str == "GapLimit"
        and stats.has_solution
        and stats.objective is not None
        and stats.best_bound is not None
        and abs(stats.objective - stats.best_bound) <= tol
    ):
        return

    raise RuntimeError(
        "Optimization failed or stopped without acceptable optimality proof: "
        f"status={stats.status_str}, "
        f"objective={stats.objective}, "
        f"best_bound={stats.best_bound}, "
        f"gap={None if stats.objective is None or stats.best_bound is None else abs(stats.objective - stats.best_bound)}, "
        f"has_solution={stats.has_solution}"
    )

# Create optimizer function
def optimize_storage(
        prices,
        capacity,
        max_injection,
        max_withdrawal,
        initial_inventory = 0,
        injection_cost = 0,
        withdrawal_cost = 0,
        storage_cost = 0
):
    '''
    Uses PuLP/COIN_CMD to optimize storage schedule for a given curve (prices) and other above parameters. 
    Optimizes by maximizing storage profit over periods 1,...,T:
        max(sum{t=1}{T}(F_t*W_t - F_t*I_t - c_I*I_t - c_W*W_t - c_S*S_t))
    subject to the following constraints:
        S_T = S_0, and for all t,
            0<=S_t<=capacity,
            0<=I_t<=max_injection,
            0<=W_t<=max_withdrawal, and
            S_t = S{t-1} + I_t - W_t.

    '''

    periods = range(len(prices))

    model = pl.LpProblem(
        "Intrinsic_Crude_Storage",
        pl.LpMaximize
    )

    # Decision variables
    inject = {
    t: model.add_variable(
        f"Inject_{t}",
        lowBound = 0,
        upBound = max_injection
    )
    for t in periods
    }
    withdraw = {
        t: model.add_variable(
            f"Withdraw_{t}",
            lowBound = 0,
            upBound = max_withdrawal
        )
        for t in periods
    }
    inventory = {
        t: model.add_variable(
            f"Inventory_{t}",
            lowBound = 0,
            upBound = capacity
        )
        for t in periods
    }
    operating_mode = {                          # This turns the Linear Problem into a Mixed-Integer Linear Problem (MILP). We use this binary variable to avoid simultaneous injection and withdrawal
        t: model.add_variable(
            f"Operating_Mode_{t}",
            cat = pl.LpBinary
        )
        for t in periods
    }

    # Objective function
    model += pl.lpSum(
        prices[t] * withdraw[t]
        - prices[t] * inject[t]
        - injection_cost * inject[t]
        - withdrawal_cost * withdraw[t]
        - storage_cost * inventory[t]
        for t in periods
    )

    # Inventory balance
    model += (
        inventory[0]
        == initial_inventory
        + inject[0]
        - withdraw[0]
    )

    for t in periods:
        if t == 0:
            continue
        model += (
            inventory[t]
            == inventory[t - 1]
            + inject[t]
            - withdraw[t]
        )

    # Terminal inventory condition
    model += (
        inventory[max(periods)]
        == initial_inventory
    )

    # Mode constraints
    for t in periods:
        model += (
            inject[t]
            <= max_injection * operating_mode[t]
        )
        model += (
            withdraw[t]
            <= max_withdrawal * (1- operating_mode[t])
        )

    # Solve the MILP
    solver = pl.COIN_CMD(               # For tolerance purposes in the GapLimit edge case
        gapRel = 0.0,
        gapAbs = 0.0
    )
    stats = model.solve(solver)

    # Use our validation function
    validate_solve(stats)

    # Extract solution
    schedule = []

    for t in periods:
        schedule.append(
            {
                "Period": t,
                "Price": prices[t],
                "Inject": inject[t].value(),
                "Withdraw": withdraw[t].value(),
                "Inventory": inventory[t].value(),
                "Operating_Mode": operating_mode[t].value()
            }
        )

    intrinsic_value = pl.value(model.objective)

    return schedule, intrinsic_value



# Second function that optimizes over multiple scenarios
def optimize_storage_scenarios(
    curves,
    capacity,
    max_injection,
    max_withdrawal,
    initial_inventory=0,
    injection_cost=0,
    withdrawal_cost=0,
    storage_cost=0
):
    '''
    Solves the storage optimization model for multiple forward curves.

    Returns a pd.DataFrame with one row per valuation date and optimization period.
    '''

    rows = []

    for valuation_date, prices in curves.items():

        schedule, intrinsic_value = optimize_storage(
            prices=prices,
            capacity=capacity,
            max_injection=max_injection,
            max_withdrawal=max_withdrawal,
            initial_inventory=initial_inventory,
            injection_cost=injection_cost,
            withdrawal_cost=withdrawal_cost,
            storage_cost=storage_cost
        )

        for period_result in schedule:

            rows.append(
                {
                    "valuation_date": valuation_date,
                    "period": period_result["Period"],
                    "price": period_result["Price"],
                    "inject": period_result["Inject"],
                    "withdraw": period_result["Withdraw"],
                    "inventory": period_result["Inventory"],
                    "operating_mode": period_result["Operating_Mode"],
                    "intrinsic_value": intrinsic_value
                }
            )

    results = pd.DataFrame(rows)

    results["valuation_date"] = pd.to_datetime(
        results["valuation_date"]
    )

    results = results.sort_values(
        ["valuation_date", "period"]
    ).reset_index(drop=True)

    return results


if __name__ == "__main__":
    # Testing our functions

    curves = query_prices(
        dates=[
            "2009-02-13",
            "2020-04-24",
            "2022-03-11"
        ]
    )

    results = optimize_storage_scenarios(
        curves=curves,
        capacity=100,
        max_injection=40,
        max_withdrawal=40
    )

    print(results)



    # Testing with time-series data

    curves = query_prices(
        start_date="2011-03-04",
        end_date="2024-04-05"
    )

    results = optimize_storage_scenarios(
        curves=curves,
        capacity=100,
        max_injection=40,
        max_withdrawal=40
    )

    intrinsic_values = (
        results[
            ["valuation_date", "intrinsic_value"]
        ]
        .drop_duplicates()
        .sort_values("valuation_date")
        .reset_index(drop=True)
    )

    intrinsic_values["intrinsic_value_per_capacity"] = (
        intrinsic_values["intrinsic_value"]
        / 100
    )


    # Plot output
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(
        figsize=(10, 5),
        constrained_layout=True
    )

    ax.plot(
        intrinsic_values["valuation_date"],
        intrinsic_values["intrinsic_value_per_capacity"]
    )

    ax.axhline(
        0,
        linewidth=1
    )

    ax.set(
        xlabel="Valuation Date",
        ylabel="Intrinsic Storage Value ($ per unit of capacity)",
        title="Historical Intrinsic Value of Cushing Storage"
    )

    plt.show()