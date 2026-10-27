import intrinsic_storage_lp as isl
import pandas as pd

def run_sensitivity(
        prices,
        parameter_name,
        parameter_values,
        baseline_params
):
    '''
    Runs one-way sensitivity analysis for a single model parameter.

    Parameters
    ----------
    prices : dict
        Forward curve passed to optimize_storage()

    parameter_name : str
        One of the following:
            "capacity"
            "max_injection"
            "max_withdrawal"
            "injection_cost"
            "withdrawal_cost"
            "storage_cost"

    parameter_values : iterable
        Values to test for the chosen parameter.

    baseline_params : dict
        Baseline optimization parameters.

    Returns
    -------
    pd.DataFrame
        One row per tested parameter value.
    '''
    rows = []

    for value in parameter_values:
        params = baseline_params.copy()

        params[parameter_name] = value

        _, intrinsic_value = isl.optimize_storage(
            prices = prices,
            capacity = params["capacity"],
            max_injection = params["max_injection"],
            max_withdrawal = params["max_withdrawal"],
            initial_inventory = params["initial_inventory"],
            injection_cost = params["injection_cost"],
            withdrawal_cost = params["withdrawal_cost"],
            storage_cost = params["storage_cost"]
        )

        rows.append(
            {
                "parameter": parameter_name,
                "parameter_value": value,
                "intrinsic_value": intrinsic_value
            }
        )

    return pd.DataFrame(rows)


def add_marginal_value(df):
    df = (
        df
        .sort_values("parameter_value")
        .reset_index(drop=True)
        .copy()
    )

    df = df.copy()

    df["delta_parameter"] = (
        df["parameter_value"].diff()
    )

    df["delta_value"] = (
        df["intrinsic_value"].diff()
    )

    df["marginal_value"] = (
        df["delta_value"]
        / df["delta_parameter"]
    )

    return df





if __name__ == "__main__":
    # Define testing parameters
    baseline_params = {
        "capacity": 100,
        "max_injection": 40,
        "max_withdrawal": 40,
        "initial_inventory": 0,
        "injection_cost": 0,
        "withdrawal_cost": 0,
        "storage_cost": 0
    }

    curve_2020 = isl.query_prices(
        dates="2020-04-24"
    )["2020-04-24"]

    capacity_values = [
        20, 40, 60, 80,
        100, 120, 140, 160
    ]

    injection_values = [
        10, 20, 30, 40,
        50, 60, 80, 100
    ]

    withdrawal_values = [
        10, 20, 30, 40,
        50, 60, 80, 100
    ]


    # Testing capacity sensitivity
    capacity_sensitivity = add_marginal_value(
        run_sensitivity(
            prices=curve_2020,
            parameter_name="capacity",
            parameter_values=capacity_values,
            baseline_params=baseline_params
        )
    )
    print("\nCapacity sensitivity")
    print(capacity_sensitivity)


    # Testing injection sensitivity
    injection_sensitivity = add_marginal_value(
        run_sensitivity(
            prices=curve_2020,
            parameter_name="max_injection",
            parameter_values=injection_values,
            baseline_params=baseline_params
        )
    )
    print("\nInjection sensitivity")
    print(injection_sensitivity)


    # Testing withdrawal sensitivity
    withdrawal_sensitivity = add_marginal_value(
        run_sensitivity(
            prices=curve_2020,
            parameter_name="max_withdrawal",
            parameter_values=withdrawal_values,
            baseline_params=baseline_params
        )
    )
    print("\nWithdrawal sensitivity")
    print(withdrawal_sensitivity)