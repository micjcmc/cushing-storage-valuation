# Cushing Crude Storage Valuation

A quantitative research and operations-research project for valuing flexible crude-oil storage at Cushing, Oklahoma.

The project connects physical crude-market conditions to the WTI forward curve, converts observed curve structure into optimal storage decisions, and measures how imperfect execution affects realized value.

## Highlights

Some current highlights of the project are:

- EIA crude-market and storage-capacity data
- Python ETL and analysis
- SQLite research tables
- WTI forward-curve and calendar-spread research
- Cushing storage-capacity and utilization modeling
- mixed-integer optimization with PuLP/CBC
- one-way physical sensitivity analysis
- SimPy discrete-event simulation
- Monte Carlo execution-risk analysis
- decision-oriented visualization

## Overview

The project currently asks a few related questions:

1. What physical conditions are associated with the WTI forward curve?
2. Given that curve, how should a physically constrained storage asset operate?
3. How much planned storage value is lost when execution is imperfect?

The current research pipeline is:

```text
EIA API / EIA Storage Capacity Data
        |
        v
Python ETL
        |
        v
SQLite Database
        |
        +-- inventories
        +-- refinery_activity
        +-- flows
        +-- prices
        +-- calendar_spreads
        +-- storage_capacity
        +-- weekly_storage_state
        |
        v
weekly_features
        |
        +-- inventory and flow features
        +-- storage utilization
        +-- seasonal statistics
        +-- forward-curve spreads
        |
        +-----------------------------+
        |                             |
        v                             v
Forward-Curve Research         Storage Optimization
                                      |
                                      v
                               SimPy Execution Model
                                      |
                                      v
                               Monte Carlo Analysis
```

## Current Capabilities

### Physical-market data

The project has a panel for weekly research. Currently this includes the following:

- Cushing crude inventories
- PADD 2 crude inventories
- PADD 2 refinery crude inputs
- PADD 2 refinery utilization
- U.S. crude production
- U.S. crude imports and exports
- WTI spot prices
- CL1-CL4 generic WTI futures prices
- calendar spreads
- inventory lags and changes
- four-week rolling features
- point-in-time seasonal inventory statistics
- Cushing working storage capacity
- Cushing shell capacity
- pipeline fill and rail transit
- estimated tank inventory
- tank-only storage utilization
- total Cushing storage utilization

As an important note, seasonal features use only information available prior to each observation date. This was done to avoid lookahead bias.

### Forward-curve research

The project does some research w.r.t forward curves. This includes:

- front and cumulative calendar spreads
- curve slope and curvature
- raw and CL1-normalized forward curves
- contango and backwardation regimes
- annualized carry
- historical stress regimes

In this project, calendar spreads are calculated using the following:

```text
F2 - F1 > 0  -> contango
F2 - F1 < 0  -> backwardation
```

Some example historical curves for reference. These were a few cases of either contango or backwardation from the ingested EIA data:

| Date | CL1 | CL2 | CL3 | CL4 | Regime |
|---|---:|---:|---:|---:|---|
| 2009-02-13 | 36.91 | 43.24 | 46.45 | 48.19 | Contango |
| 2020-04-24 | 3.92 | 19.07 | 23.34 | 25.50 | Extreme contango |
| 2022-03-11 | 113.43 | 109.96 | 106.14 | 102.60 | Backwardation |

### Storage-state modeling

For sourcing, the project uses the EIA crude-oil storage-capacity workbook. [Here](https://www.eia.gov/petroleum/storagecapacity/) is a link.

During analysis, each capacity observation is treated as effective from the first day of its reference month. Then, the weekly inventories are matched to the most recent applicable capacity observation.

Two utilization measures are used in this project:

```text
tank utilization
= (inventory - pipeline fill) / working tank capacity

total utilization
= inventory / (working capacity + transit)
```

Total utilization is the primary weekly storage-state variable. Tank-only utilization is also included as a robustness measure.

As an example of a descriptive result, data showed the highest aggregate utilization observations occured in periods such as 2016-2017 rather than April 2020. From this we know that the extreme 2020 contango we saw above cannot be explained by only utilization level.

## Storage Optimization

To optimize, PuLP was used with CBC solver and storage was treated as a constrained intertemporal resource-allocation problem.

For each period `t`, the project is set up so that the CBC model chooses:

```math
I_t = injection
```
```math
W_t = withdrawal
```
```math
S_t = ending \_ inventory
```
```math
y_t = operating \_ mode
```

The objective is:

```math
\max \sum_t \left(
F_t W_t
- F_t I_t
- c_I I_t
- c_W W_t
- c_S S_t
\right)
```

subject to the following constraints:

```math
S_t = S_{t-1} + I_t - W_t
```

```math
0 \leq S_t \leq Q
```

```math
0 \leq I_t \leq I_{\max}
```

```math
0 \leq W_t \leq W_{\max}
```

```math
S_T = S_0
```

A binary operating-mode variable was added as well. This was done to prevent simultaneous injection and withdrawal:

```math
I_t \leq I_{\max} y_t
```

```math
W_t \leq W_{\max}(1-y_t)
```

```math
y_t \in \{0,1\}
```

### As an example: Take April 24, 2020

Using:

```math
capacity       = 100,\ \
max \_ injection  = 40, \ \
max \_ withdrawal = 40, \ \
initial \_ stock  = 0, \ \
operating \_ cost = 0,
```

the optimizer produced:

| Contract | Price | Injection | Withdrawal | Ending Inventory |
|---|---:|---:|---:|---:|
| CL1 | 3.92 | 40 | 0 | 40 |
| CL2 | 19.07 | 40 | 0 | 80 |
| CL3 | 23.34 | 0 | 40 | 40 |
| CL4 | 25.50 | 0 | 40 | 0 |

The modeled intrinsic value was:

```math
1034
```

The interpretation here is that it is optimal to buy and inject crude in the cheaper early periods, then withdraw later. And because withdrawal throughput is limited in this example to 40 units per period, liquidation must begin in CL3 rather than waiting entirely for CL4.

And for the strongly backwardated March 11, 2022 curve, the optimal policy is to remain idle and intrinsic value is zero.

## Sensitivity Analysis

The optimizer is parameterized by:

```math
capacity
```
```math
max \_ injection
```
```math
max \_ withdrawal
```
```math
injection \_ cost
```
```math
withdrawal \_ cost
```
```math
storage \_ cost
```

The project has a one-way sensitivity framework. This means our sensitivity function varies one parameter at a time while holding the others fixed. This allows for comparative statics so we can see the effect of each variable in isolation.

Discrete marginal value is calculated as:

```math
marginal \_ value_{parameter}
= \frac{\Delta optimized \_ value} {\Delta parameter}
```

This allows the project to ask:

> If only one physical capability could be expanded, which constraint would be most valuable to relax?

The first sensitivity experiments focused on storage capacity, injection throughput, and withdrawal throughput.

## Simulation and Execution Risk

One way to understand operational risk is as follows. Note that the deterministic MILP assumes the optimized schedule can be executed perfectly. In contrast, the SimPy layer asks what happens when actual throughput falls short of plan.

The spread between the two is essentially operational risk.

### Deterministic validation

A deterministic simulation was also added. It reproduces the optimized inventory path. Using the max injection/withdrawal threshold of 40 again as an example, we get

```math
0 \rightarrow 40 \rightarrow 80 \rightarrow 40 \rightarrow 0
```

This checks consistency between the optimizer and the execution model. Good sanity check.

### Stochastic throughput

Planned injection and withdrawal are deterministic. But again, in practice we often see frictions. So a stochastic process is introduced to the model:

```math
throughput \_ factor \sim Uniform(0.7, 1.0)
```

For simplicity at this stage the above uniform distribution was used. However, future versions will incorporate other distributions for a more realistic model.

The project makes sure that all operations are physically feasible, i.e., that:

```math
realized \_ injection \leq remaining \_ capacity
```
```math
realized \_ withdrawal \leq available \_ inventory
```

Each simulation records:

- planned and realized injection
- planned and realized withdrawal
- execution factors
- simulated inventory
- realized cash flow
- injection and withdrawal shortfall
- inventory deviation from plan

### Monte Carlo results

For the April 24, 2020 scenario, the current experiment is 1,000-run. The results are approximately:

| Metric | Result |
|---|---:|
| Deterministic intrinsic value | 1034.00 |
| Mean realized value | 805.28 |
| Mean execution shortfall | 228.72 |
| Mean shortfall | 22.1% |
| 5th percentile realized value | 652.06 |
| Median realized value | 807.35 |
| 95th percentile realized value | 941.27 |
| Mean injection execution rate | 84.9% |
| Mean withdrawal execution rate | 81.4% |
| Probability of residual terminal inventory | 49.7% |
| Probability realized value is below 75% of plan | 34.4% |

At this stage of the project the simulation measures execution risk, so prices remain fixed and the operating plan is not re-optimized dynamically.

## Visualizations

The repository includes visualizations for:

### Forward-curve research

- CL1-CL4 forward-curve snapshots
- CL1-normalized forward curves
- adjacent calendar spreads
- historical front and cumulative spreads
- annualized carry

### Physical-financial relationships

- Cushing utilization vs. front calendar spread
- Cushing utilization vs. cumulative calendar spread
- inventory accumulation vs. calendar spreads

### Optimization

- historical intrinsic storage value
- forward curve plus optimal operating schedule
- injection and withdrawal decisions
- ending inventory
- sensitivity outputs

### Simulation

- realized-value distribution
- deterministic optimum vs. simulated outcomes
- terminal inventory vs. realized value
- injection execution vs. realized value
- withdrawal execution vs. realized value

## Repository Structure

```text
src/
    ingestion/
        eia_api.py
        storage_capacity.py

    visualization/
        term_structure_of_carry.py
        physical_financial_link.py

    optimization/
        __init__.py
        intrinsic_storage_lp.py
        optimization_visualization.py
        sensitivity_analysis.py

    simulation/
        __init__.py
        storage_simulation.py
        simulation_visualization.py

sql/
    inventories.sql
    refinery_activity.sql
    flows.sql
    prices.sql
    calendar_spreads.sql
    storage_capacity.sql
    weekly_storage_state.sql
    weekly_features.sql
    analytics.sql
    validation.sql
```

## Running the Project

### Getting Started

The project uses Python packages including:

```text
pandas
numpy
matplotlib
pulp
simpy
openpyxl
```

SQLite access uses Python's standard-library `sqlite3` module. CBC must be available to PuLP for MILP solves.

### Executing files

Once the above packages are installed, run commands from the repository root to actually execute the project.

As an example:

For running an optimization:

```bash
python -m src.optimization.intrinsic_storage_lp
```

For optimization visualization:

```bash
python -m src.optimization.optimization_visualization
```

For sensitivity analysis:

```bash
python -m src.optimization.sensitivity_analysis
```

For simulation and Monte Carlo analysis:

```bash
python -m src.simulation.storage_simulation
```

## Data

Primary data come from the U.S. Energy Information Administration.

The project uses:

- weekly Cushing crude inventories
- PADD 2 inventories
- refinery inputs and utilization
- U.S. crude production
- crude imports and exports
- WTI spot prices
- generic WTI futures prices
- EIA crude-oil storage-capacity data

The historical EIA NYMEX WTI futures series used here ends after April 5, 2024. Historical forward-curve and optimization analysis therefore use data through that cutoff.

Note that local databases, downloaded raw files, generated artifacts, and API credentials are excluded from version control.

Also note that the project architecture should allow other data sources to be added/swapped in. May implement this in future versions of the project.

## Limitations

The current model intentionally keeps the economics and operations transparent.

Important simplifications made for this project include assumptions that, in practice, may not be exactly observed.

Here is a list of limitations planned to be addressed in the future:

- CL1-CL4 are treated as four sequential operating periods
- the project uses rolling CL1-CL4 futures series as an approximation to the forward curve instead of modeling each actual futures contract and its precise delivery schedule 
- prices are deterministic within each optimization horizon (whereas prices in practice are almost certainly anything but deterministic)
- capacity and throughput limits are fixed within each scenario
- inventory balance is lossless
- the MILP values intrinsic storage economics only
- stochastic execution uses independent uniform throughput factors (important future adjustment, as uniformity here is likely far from the most apt distribution to use)
- residual terminal inventory receives no salvage value
- the simulation does not yet include outages, delays, correlated failures, price shocks, or adaptive re-optimization (important for future modelling)

## Roadmap

Near-term extensions that are planned for the project include:

- regression analysis (physical-versus-financial)
- nonlinear utilization effects
- storage-cost and transaction-cost sensitivity analysis
- comparison of physical bottlenecks across historical periods
- adding terminal-inventory salvage value
- using richer operational uncertainty distributions
- incorporating outages and transfer delays
- comparing execution risk across historical curve periods

Some longer-term extensions currently planned include adding:

- stochastic forward-curve modeling
- dynamic re-optimization
- stochastic dynamic programming
- extrinsic storage valuation
- hedging analysis
- risk measurement
- strategy backtesting

## Research Question

The project ultimately asks:

> What is the value of flexible crude-oil storage at Cushing, what physical-market conditions drive that value, and how should a constrained storage operator use and hedge that flexibility?

The project's goal is to approach the problem as follows:

```text
barrels
    ->
infrastructure
    ->
inventories
    ->
flows
    ->
forward curve
    ->
storage economics
    ->
optimization
    ->
simulation
    ->
stochastic valuation
    ->
hedging
```
