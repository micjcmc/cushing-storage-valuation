import simpy as sp
import pandas as pd
import random as rd

from src.optimization import intrinsic_storage_lp as isl
from src.simulation import simulation_visualization as sv

def simulate_schedule(
        schedule,
        capacity,
        initial_inventory = 0
):
    '''
    Reproduce a deterministic optimized storage schedule in SimPy.
    
    Parameters
    ----------
    schedule : list[dict] or pd.DataFrame
        Output from optimize_storage().

    capacity : float
        Maximum storage capacity.

    initial_inventory : float
        Initial tank inventory.

    Returns
    -------
    pd.DataFrame
        Simulated inventory path and executed operations.
    '''
    if not isinstance(schedule, pd.DataFrame):
        schedule = pd.DataFrame(schedule)

    env = sp.Environment()

    tank = sp.Container(
        env,
        capacity = capacity,
        init = initial_inventory
    )

    records = []

    def storage_process():

        for _, row in schedule.iterrows():
            period = int(row["Period"])
            price = row["Price"]

            planned_injection = row["Inject"]
            planned_withdrawal = row["Withdraw"]

            # Execute injection
            if planned_injection > 0:
                yield tank.put(planned_injection)

            # Execute withdrawal
            if planned_withdrawal > 0:
                yield tank.get(planned_withdrawal)

            records.append(
                {
                    "period": period,
                    "price": price,
                    "planned_injection": planned_injection,
                    "planned_withdrawal": planned_withdrawal,
                    "simulated_inventory": tank.level
                }
            )

            # Advance one deterministic period
            yield env.timeout(1)
            
    env.process(storage_process())

    env.run()

    if len(records) != len(schedule):
        raise RuntimeError(
            f"Simulation completed only {len(records)} "
            f"of {len(schedule)} periods."
        )

    return pd.DataFrame(records)


def simulate_stochastic_schedule(
        schedule,
        capacity,
        initial_inventory = 0,
        min_throughput_factor = 0.7,
        max_throughput_factor = 1.0,
        seed = None
):
    '''
    Simulate imperfect execution of an optimized storage schedule.

    Planned injection and withdrawal quantities are multiplied by
    random throughput-realization factors.

    Parameters
    ----------
    schedule : list[dict] or pd.DataFrame
        Output from optimize_storage().

    capacity : float
        Maximum storage capacity.

    initial_inventory : float
        Initial tank inventory.

    min_throughput_factor : float
        Minimum fraction of planned throughput realized.

    max_throughput_factor : float
        Maximum fraction of planned throughput realized.

    seed : int, optional
        Random seed for reproducibility.

    Returns
    -------
    pd.DataFrame
        Simulated realized operations and inventory path.
    '''

    rng = rd.Random(seed)

    if not isinstance(schedule, pd.DataFrame):
        schedule = pd.DataFrame(schedule)

    env = sp.Environment()

    tank = sp.Container(
        env,
        capacity=capacity,
        init=initial_inventory
    )

    records = []

    def storage_process():

        for _, row in schedule.iterrows():

            period = int(row["Period"])
            price = row["Price"]

            planned_injection = row["Inject"]
            planned_withdrawal = row["Withdraw"]

            injection_factor = rng.uniform(
                min_throughput_factor,
                max_throughput_factor
            )

            withdrawal_factor = rng.uniform(
                min_throughput_factor,
                max_throughput_factor
            )

            realized_injection = (
                planned_injection
                * injection_factor
            )

            realized_withdrawal = (
                planned_withdrawal
                * withdrawal_factor
            )

            # Injection can't exceed remaining tank capacity
            if realized_injection > 0:

                available_capacity = (
                    tank.capacity
                    - tank.level
                )

                realized_injection = min(
                    realized_injection,
                    available_capacity
                )

                yield tank.put(
                    realized_injection
                )

            # Withdrawal can't exceed available inventory
            if realized_withdrawal > 0:

                realized_withdrawal = min(
                    realized_withdrawal,
                    tank.level
                )

                yield tank.get(
                    realized_withdrawal
                )

            records.append(
                {
                    "period": period,

                    "price": price,

                    "planned_injection":
                        planned_injection,

                    "realized_injection":
                        realized_injection,

                    "injection_factor":
                        injection_factor,

                    "planned_withdrawal":
                        planned_withdrawal,

                    "realized_withdrawal":
                        realized_withdrawal,

                    "withdrawal_factor":
                        withdrawal_factor,

                    "simulated_inventory":
                        tank.level,

                    "cash_flow": (
                        price * realized_withdrawal
                        - price * realized_injection
                    ),

                    "injection_shortfall": (
                        planned_injection
                        - realized_injection
                    ),

                    "withdrawal_shortfall": (
                        planned_withdrawal
                        - realized_withdrawal
                    ),
                    "inventory_deviation": (
                        tank.level
                        - row["Inventory"]
                    )
                }
            )

            yield env.timeout(1)

    env.process(storage_process())

    env.run()

    if len(records) != len(schedule):
        raise RuntimeError(
            f"Simulation completed only {len(records)} "
            f"of {len(schedule)} periods."
        )

    return pd.DataFrame(records)



def run_monte_carlo(
        schedule,
        intrinsic_value,
        capacity,
        initial_inventory = 0,
        min_throughput_factor = 0.7,
        max_throughput_factor = 1.0,
        n_simulations = 1000
):
    rows = []

    for simulation_id in range(n_simulations):

        simulation = simulate_stochastic_schedule(
            schedule = schedule,
            capacity = capacity,
            initial_inventory = initial_inventory,
            min_throughput_factor = min_throughput_factor,
            max_throughput_factor = max_throughput_factor,
            seed = simulation_id
        )

        realized_value = simulation["cash_flow"].sum()

        terminal_inventory = (
            simulation.iloc[-1]["simulated_inventory"]
        )

        total_planned_injection = (
            simulation["planned_injection"].sum()
        )

        total_realized_injection = (
            simulation["realized_injection"].sum()
        )

        total_planned_withdrawal = (
            simulation["planned_withdrawal"].sum()
        )

        total_realized_withdrawal = (
            simulation["realized_withdrawal"].sum()
        )

        injection_execution_rate = (
            total_realized_injection
            / total_planned_injection
            if total_planned_injection > 0
            else 1.0
        )

        withdrawal_execution_rate = (
            total_realized_withdrawal
            / total_planned_withdrawal
            if total_planned_withdrawal > 0
            else 1.0
        )

        execution_shortfall = (
            intrinsic_value - realized_value
        )

        rows.append(
            {
                "simulation_id": simulation_id,
                "realized_value": realized_value,
                "execution_shortfall": execution_shortfall,
                "terminal_inventory": terminal_inventory,
                "injection_execution_rate": injection_execution_rate,
                "withdrawal_execution_rate": withdrawal_execution_rate
            }
        )

    return pd.DataFrame(rows)



# Testing output
if __name__ == "__main__":
    valuation_date = "2020-04-24"

    prices = isl.query_prices(
        dates = valuation_date
    )[valuation_date]

    schedule, intrinsic_value = isl.optimize_storage(
        prices = prices,
        capacity = 100,
        max_injection = 40,
        max_withdrawal = 40,
        initial_inventory = 0,
        injection_cost = 0,
        withdrawal_cost = 0,
        storage_cost = 0
    )

    deterministic_simulation = simulate_schedule(
        schedule = schedule,
        capacity = 100,
        initial_inventory = 0
    )

    print("\nDeterministic SimPy reproduction:")
    print(deterministic_simulation)

    simulation = simulate_stochastic_schedule(
        schedule = schedule,
        capacity = 100,
        initial_inventory = 0,
        min_throughput_factor = 0.7,
        max_throughput_factor = 1.0,
        seed = 42
    )

    print(simulation)

    realized_value = (
        simulation["cash_flow"].sum()
    )


    print(
        "MILP planned intrinsic value:",
        intrinsic_value
    )

    print(
        "SimPy realized value:",
        realized_value
    )


    terminal_inventory = simulation.iloc[-1]["simulated_inventory"]

    execution_shortfall = (
        intrinsic_value
        - realized_value
    )

    execution_shortfall_pct = (
        execution_shortfall
        / intrinsic_value
    )

    print(
        "Execution shortfall:",
        execution_shortfall
    )

    print(
        "Execution shortfall (%):",
        execution_shortfall_pct * 100
    )

    print(
        "Terminal simulated inventory:",
        terminal_inventory
    )

    total_planned_injection = (
        simulation["planned_injection"].sum()
    )

    total_realized_injection = (
        simulation["realized_injection"].sum()
    )

    total_planned_withdrawal = (
        simulation["planned_withdrawal"].sum()
    )

    total_realized_withdrawal = (
        simulation["realized_withdrawal"].sum()
    )

    print(
        "Injection execution rate:",
        total_realized_injection
        / total_planned_injection
    )

    print(
        "Withdrawal execution rate:",
        total_realized_withdrawal
        / total_planned_withdrawal
    )

    monte_carlo = run_monte_carlo(
        schedule=schedule,
        intrinsic_value=intrinsic_value,
        capacity=100,
        initial_inventory=0,
        min_throughput_factor=0.7,
        max_throughput_factor=1.0,
        n_simulations=1000
    )

    print(monte_carlo.head())

    summary = monte_carlo[
        [
            "realized_value",
            "execution_shortfall",
            "terminal_inventory",
            "injection_execution_rate",
            "withdrawal_execution_rate"
        ]
    ].describe(
        percentiles=[0.05, 0.50, 0.95]
    )

    print(summary)

    mean_realized_value = (
        monte_carlo["realized_value"].mean()
    )

    std_realized_value = (
        monte_carlo["realized_value"].std()
    )

    p5_realized_value = (
        monte_carlo["realized_value"].quantile(0.05)
    )

    median_realized_value = (
        monte_carlo["realized_value"].median()
    )

    p95_realized_value = (
        monte_carlo["realized_value"].quantile(0.95)
    )

    print(
        "Mean realized value:",
        mean_realized_value
    )

    print(
        "Standard deviation of realized value:",
        std_realized_value
    )

    print(
        "5th percentile realized value:",
        p5_realized_value
    )

    print(
        "Median realized value:",
        median_realized_value
    )

    print(
        "95th percentile realized value:",
        p95_realized_value
    )

    mean_shortfall_pct = (
        monte_carlo["execution_shortfall"].mean()
        / intrinsic_value
    )

    prob_terminal_inventory = (
        monte_carlo["terminal_inventory"] > 1e-9
    ).mean()

    print(
        "Mean realized value:",
        mean_realized_value
    )

    print(
        "Mean shortfall (%):",
        mean_shortfall_pct * 100
    )

    print(
        "Probability of residual terminal inventory:",
        prob_terminal_inventory * 100
    )

    prob_below_75pct_plan = (
        monte_carlo["realized_value"]
        < 0.75 * intrinsic_value
    ).mean()

    print(
        "Percentage of simulated runs that realize less than 75 percent of planned intrinsic value:",
        prob_below_75pct_plan * 100
    )

    sv.plot_realized_value_distribution(
        monte_carlo=monte_carlo,
        intrinsic_value=intrinsic_value
    )

    sv.plot_terminal_inventory_vs_value(
        monte_carlo
    )

    sv.plot_execution_rates_vs_value(
        monte_carlo
    )