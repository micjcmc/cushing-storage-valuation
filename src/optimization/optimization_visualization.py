import matplotlib.pyplot as plt
import pandas as pd

import intrinsic_storage_lp as isl

def plot_storage_strategy(
    valuation_date,
    capacity=100,
    max_injection=40,
    max_withdrawal=40,
    initial_inventory=0,
    injection_cost=0,
    withdrawal_cost=0,
    storage_cost=0
):
    """
    Plot the forward curve and optimal storage operating schedule
    for a single valuation date.
    """

    prices = isl.query_prices(
        dates=valuation_date
    )[valuation_date]

    schedule, intrinsic_value = isl.optimize_storage(
        prices=prices,
        capacity=capacity,
        max_injection=max_injection,
        max_withdrawal=max_withdrawal,
        initial_inventory=initial_inventory,
        injection_cost=injection_cost,
        withdrawal_cost=withdrawal_cost,
        storage_cost=storage_cost
    )

    schedule = pd.DataFrame(schedule)

    schedule["Contract"] = [
        f"CL{i + 1}"
        for i in range(len(schedule))
    ]

    fig, (ax_price, ax_ops) = plt.subplots(
        2,
        1,
        figsize=(9, 7),
        sharex=True,
        constrained_layout=True
    )

    # Forward curve

    ax_price.plot(
        schedule["Contract"],
        schedule["Price"],
        marker="o",
        linewidth=2
    )

    ax_price.set(
        ylabel="WTI Futures Price ($/bbl)",
        title=f"Optimal Cushing Storage Strategy — {valuation_date}"
    )

    ax_price.grid(
        axis="y",
        alpha=0.3
    )

    # Optimal operating schedule

    x = range(len(schedule))
    bar_width = 0.35

    ax_ops.bar(
        [i - bar_width / 2 for i in x],
        schedule["Inject"],
        width=bar_width,
        label="Injection"
    )

    ax_ops.bar(
        [i + bar_width / 2 for i in x],
        schedule["Withdraw"],
        width=bar_width,
        label="Withdrawal"
    )

    ax_ops.plot(
        x,
        schedule["Inventory"],
        marker="o",
        linewidth=2,
        label="Ending inventory"
    )

    ax_ops.set_xticks(x)
    ax_ops.set_xticklabels(
        schedule["Contract"]
    )

    ax_ops.set(
        xlabel="Forward Contract Period",
        ylabel="Storage Units",
        title="Optimal Operating Schedule"
    )

    ax_ops.legend()

    ax_ops.grid(
        axis="y",
        alpha=0.3
    )


    # Figure title

    fig.suptitle(
    (
        "Cushing Storage Optimization\n"
        f"{valuation_date} | "
        f"Intrinsic Value = {intrinsic_value:.2f} | "
        f"Q={capacity}, Imax={max_injection}, Wmax={max_withdrawal}"
    ),
    fontsize=14
    )

    plt.show()

    return schedule, intrinsic_value



if __name__ == "__main__":
    # Three extreme test cases
    schedule1, intrinsic_value1 = plot_storage_strategy(
    "2020-04-24"
    )
    schedule2, intrinsic_value2 = plot_storage_strategy(
    "2009-02-13"
    )
    schedule3, intrinsic_value3 = plot_storage_strategy(
    "2022-03-11"
    )