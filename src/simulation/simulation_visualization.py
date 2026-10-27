import matplotlib.pyplot as plt

def plot_realized_value_distribution(
        monte_carlo,
        intrinsic_value
):
    fig, ax = plt.subplots(
        figsize=(10, 6)
    )

    ax.hist(
        monte_carlo["realized_value"],
        bins=30,
        edgecolor="black",
        alpha=0.75
    )

    mean_value = (
        monte_carlo["realized_value"].mean()
    )

    p5 = (
        monte_carlo["realized_value"]
        .quantile(0.05)
    )

    p95 = (
        monte_carlo["realized_value"]
        .quantile(0.95)
    )

    ax.axvline(
        intrinsic_value,
        linestyle="--",
        linewidth=2,
        label=f"MILP optimum = {intrinsic_value:.1f}"
    )

    ax.axvline(
        mean_value,
        linestyle="-",
        linewidth=2,
        label=f"Mean realized = {mean_value:.1f}"
    )

    ax.axvline(
        p5,
        linestyle=":",
        linewidth=2,
        label=f"5th percentile = {p5:.1f}"
    )

    ax.axvline(
        p95,
        linestyle=":",
        linewidth=2,
        label=f"95th percentile = {p95:.1f}"
    )

    threshold_75 = 0.75 * intrinsic_value

    ax.axvline(
        threshold_75,
        linestyle="-.",
        linewidth=1.5,
        label=f"75% of optimum = {threshold_75:.1f}"
    )

    ax.set_title(
        "Monte Carlo Distribution of Realized Storage Value"
    )

    ax.set_xlabel(
        "Realized intrinsic value"
    )

    ax.set_ylabel(
        "Simulation count"
    )

    ax.legend()

    ax.grid(
        alpha=0.3
    )

    plt.tight_layout()
    plt.show()

    return fig, ax


def plot_terminal_inventory_vs_value(
        monte_carlo
):
    fig, ax = plt.subplots(
        figsize=(10, 6)
    )

    ax.scatter(
        monte_carlo["terminal_inventory"],
        monte_carlo["realized_value"],
        alpha=0.6
    )

    ax.set_title(
        "Terminal Inventory vs Realized Storage Value"
    )

    ax.set_xlabel(
        "Terminal inventory"
    )

    ax.set_ylabel(
        "Realized intrinsic value"
    )

    ax.grid(
        alpha=0.3
    )

    plt.tight_layout()
    plt.show()

    return fig, ax


def plot_execution_rates_vs_value(
        monte_carlo
):
    fig, ax = plt.subplots(
        figsize=(10, 6)
    )

    ax.scatter(
        monte_carlo[
            "injection_execution_rate"
        ],
        monte_carlo["realized_value"],
        alpha=0.5,
        label="Injection execution"
    )

    ax.scatter(
        monte_carlo[
            "withdrawal_execution_rate"
        ],
        monte_carlo["realized_value"],
        alpha=0.5,
        label="Withdrawal execution"
    )

    ax.set_title(
        "Operational Execution vs Realized Storage Value"
    )

    ax.set_xlabel(
        "Execution rate"
    )

    ax.set_ylabel(
        "Realized intrinsic value"
    )

    ax.legend()

    ax.grid(
        alpha=0.3
    )

    plt.tight_layout()
    plt.show()

    return fig, ax