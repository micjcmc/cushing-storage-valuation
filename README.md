# Cushing Crude Storage Valuation

A quantitative research and operations-research project examining the value of flexible crude-oil storage at Cushing, Oklahoma, the physical-market variables that drive storage economics, the information contained in the WTI forward curve, and the optimal use of a physically constrained storage asset.

The project combines:

- public EIA crude-market data,
- Python ETL and analysis,
- a SQLite research database,
- forward-curve and calendar-spread analysis,
- historical Cushing storage-capacity data,
- inventory-utilization modeling,
- mixed-integer optimization with PuLP/CBC,
- historical intrinsic storage valuation,
- sensitivity analysis of physical operating constraints,
- discrete-event simulation with SimPy,
- Monte Carlo analysis of operational execution risk,
- and decision-oriented visualization.

The broader objective is to connect physical crude-market conditions to financial prices, translate those prices into optimal storage decisions, and then test how operational uncertainty affects realized storage value.

---

## Project Status

The project currently includes the following completed components:

### Data Engineering

- EIA API ingestion pipeline
- SQLite research database
- Physical crude-market domain tables
- WTI spot and futures data
- Calendar-spread construction
- Historical Cushing storage-capacity ingestion
- Weekly storage-utilization construction
- Weekly feature engineering
- Point-in-time seasonal inventory statistics
- Validation and economic sanity checks

### Forward-Curve Research

- Forward-curve slope analysis
- Forward-curve curvature analysis
- Historical contango and backwardation regimes
- Adjacent and cumulative calendar spreads
- Annualized calendar-carry measures
- Raw and normalized forward-curve visualizations
- Historical stress-regime comparison

### Storage Optimization

- Deterministic intrinsic-value formulation
- Continuous inventory, injection, and withdrawal decisions
- Storage-capacity and throughput constraints
- Terminal-inventory constraint
- Binary operating-mode constraints
- Mixed-integer linear programming formulation
- PuLP/CBC implementation
- Historical forward-curve integration from SQLite
- Multi-date scenario optimization
- Historical intrinsic-storage-value time series
- Optimal operating-schedule visualizations
- One-way physical sensitivity-analysis framework

### Simulation and Operational Risk

- Deterministic SimPy reproduction of optimized storage schedules
- Stochastic injection and withdrawal throughput realization
- Physical enforcement of capacity and inventory feasibility
- Realized cash-flow and execution-shortfall calculation
- Terminal-inventory risk measurement
- Monte Carlo simulation across repeated stochastic execution paths
- Realized-value distribution analysis
- Injection and withdrawal execution-rate measurement
- Downside-threshold analysis
- Simulation visualizations linking execution outcomes to realized value

The physical-versus-financial regression stage is partially developed. Historical Cushing storage capacity and weekly utilization have been constructed and integrated into the research panel, while additional regression analysis remains planned.

The optimization and simulation work were advanced ahead of the remaining regression work in order to explore storage as an explicit constrained decision problem and then test the robustness of optimal schedules under imperfect operational execution.

Future extensions include:

- completed physical/financial regression analysis,
- nonlinear utilization effects,
- storage-cost sensitivity,
- richer stochastic operating models,
- stochastic forward-curve modeling,
- extrinsic storage valuation,
- dynamic re-optimization,
- hedging,
- and backtesting.

---

## Research Pipeline

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
        +-- inventory / flow features
        +-- storage utilization
        +-- seasonal statistics
        +-- forward-curve spreads
        |
        +-----------------------------+
        |                             |
        v                             v
Forward-Curve Research         Storage Optimization
        |                             |
        +-- curve snapshots           +-- PuLP / CBC MILP
        +-- slope / curvature         +-- optimal injection
        +-- calendar spreads          +-- optimal withdrawal
        +-- annualized carry          +-- inventory scheduling
        +-- stress regimes            +-- intrinsic value
        |                             +-- sensitivity analysis
        |                             |
        |                             v
        |                      SimPy Execution Model
        |                             |
        |                             +-- throughput uncertainty
        |                             +-- realized operations
        |                             +-- terminal inventory
        |                             +-- realized cash flow
        |                             |
        |                             v
        |                      Monte Carlo Simulation
        |                             |
        |                             +-- realized-value distribution
        |                             +-- execution shortfall
        |                             +-- downside probabilities
        |                             +-- operational-risk metrics
        |                             |
        +-------------+---------------+
                      |
                      v
          Physical / Financial Modeling
                      |
                      v
           Stochastic Valuation / Hedging
```

---

## Data and Research Panel

The weekly research panel includes:

- Cushing crude inventories
- PADD 2 crude inventories
- PADD 2 refinery crude inputs
- PADD 2 refinery utilization
- U.S. crude production
- U.S. crude imports
- U.S. crude exports
- WTI spot prices
- CL1-CL4 generic WTI futures prices
- Calendar spreads
- Inventory lags and changes
- Four-week rolling features
- Net crude imports
- ISO-week seasonality
- Point-in-time seasonal inventory statistics
- Cushing working storage capacity
- Cushing shell capacity
- Cushing pipeline fill
- Cushing working capacity plus transit
- Estimated tank inventory
- Tank-only storage utilization
- Total Cushing storage utilization

Seasonal inventory statistics use only observations available prior to each date in order to avoid look-ahead bias.

---

## Cushing Storage Capacity and Utilization

Historical Cushing storage-capacity data are sourced from the EIA crude-oil storage-capacity workbook.

The project retains several physical capacity concepts, including:

- tank working storage capacity,
- shell capacity,
- pipeline fill and rail transit,
- working storage capacity plus transit,
- reported tank utilization,
- and reported alternate utilization.

Because the EIA capacity observations describe the physical system for a reference month rather than a weekly observation date, each capacity observation is treated as effective beginning with the first day of its reference month for descriptive physical-market analysis.

Weekly Cushing inventories are then matched to the most recent applicable capacity observation.

Two utilization measures are constructed.

Tank-only utilization:

$$
U_t^{tank}
=
\frac{
Inventory_t - PipelineFill_t
}{
WorkingCapacity_t
}
$$
and total utilization:

$$
U_t^{total}
=
\frac{
Inventory_t
}{
WorkingCapacity_t + Transit_t
}.
$$
The total-utilization measure is used as the primary weekly storage-state variable, while tank-only utilization is retained as a robustness measure.

An important descriptive result is that the highest aggregate utilization observations occur in periods such as 2016-2017 rather than during April 2020.

This implies that the extreme 2020 forward-curve dislocation cannot be explained by utilization level alone. Inventory accumulation rates, expectations, operational bottlenecks, and broader market conditions likely matter as well.

---

## Forward-Curve Analysis

The forward-curve analysis studies the first four generic WTI futures contracts and the term structure of crude-oil carry.

Calendar spreads use a deferred-minus-nearby convention:

```text
F2 - F1 > 0  -> contango
F2 - F1 < 0  -> backwardation
```

The analysis examines:

- front and cumulative calendar spreads,
- forward-curve slope,
- adjacent-spread structure,
- curve curvature,
- front-loaded versus persistent curve dislocations,
- raw forward curves,
- CL1-normalized forward curves,
- historical contango and backwardation regimes,
- and annualized carry across approximately one-, two-, and three-month horizons.

Annualized carry is approximated as:

```text
Carry(1,2) = 12 * (F2 - F1) / F1
Carry(1,3) =  6 * (F3 - F1) / F1
Carry(1,4) =  4 * (F4 - F1) / F1
```

These calculations treat successive generic futures delivery months as approximately one month apart.

They are interpreted as normalized measures of curve carry rather than expected annual investment returns.

Historical analysis highlights several contrasting regimes:

- severe contango during 2008-2009,
- extreme front-loaded contango during April 2020,
- and broad persistent backwardation during 2022.

For example:

### February 13, 2009

```text
CL1 = 36.91
CL2 = 43.24
CL3 = 46.45
CL4 = 48.19
```

### April 24, 2020

```text
CL1 =  3.92
CL2 = 19.07
CL3 = 23.34
CL4 = 25.50
```

### March 11, 2022

```text
CL1 = 113.43
CL2 = 109.96
CL3 = 106.14
CL4 = 102.60
```

The project retains both dollar spreads and percentage-normalized carry because percentage carry becomes unstable when the nearby futures price approaches zero, as occurred during April 2020.

---

# Storage Optimization

## Objective

The storage optimization model treats Cushing storage as a constrained intertemporal resource-allocation problem.

Given an observed WTI forward curve, the model determines the optimal sequence of crude-oil injections, withdrawals, and ending inventories that maximizes deterministic intrinsic storage value subject to physical operating constraints.

For periods

$$
t=1,\ldots,T,
$$
define the decision variables:

$$
I_t
=
\text{crude injected during period }t
$$
$$
W_t
=
\text{crude withdrawn during period }t
$$
$$
S_t
=
\text{ending inventory after period }t.
$$
The primary market input is:

$$
F_t
=
\text{WTI futures price associated with period }t.
$$
Physical and economic parameters include:

$$
Q
=
\text{maximum storage capacity}
$$
$$
I^{\max}
=
\text{maximum injection throughput}
$$
$$
W^{\max}
=
\text{maximum withdrawal throughput}
$$
$$
c_I
=
\text{injection cost per unit}
$$
$$
c_W
=
\text{withdrawal cost per unit}
$$
$$
c_S
=
\text{storage cost per unit per period}.
$$
The objective is:

$$
\max
\sum_{t=1}^{T}
\left[
F_tW_t
-
F_tI_t
-
c_I I_t
-
c_W W_t
-
c_S S_t
\right].
$$
The model earns revenue from withdrawn crude, incurs the market cost of acquiring crude for injection, and subtracts modeled operating and carrying costs.

---

## Inventory Balance

Every barrel must be physically accounted for:

$$
S_t
=
S_{t-1}
+
I_t
-
W_t
\qquad
\forall t.
$$
Inventory is bounded by storage capacity:

$$
0
\leq
S_t
\leq
Q
\qquad
\forall t.
$$
Injection is constrained by maximum injection throughput:

$$
0
\leq
I_t
\leq
I^{\max}.
$$
Withdrawal is constrained by maximum withdrawal throughput:

$$
0
\leq
W_t
\leq
W^{\max}.
$$
---

## Terminal Inventory

The current formulation requires:

$$
S_T=S_0.
$$
This prevents the optimizer from generating artificial value by ending the horizon with a different inventory position from the one with which it began.

For most historical intrinsic-value experiments:

$$
S_0=0.
$$
---

## Mixed-Integer Operating Constraint

The first linear-programming formulation allowed simultaneous injection and withdrawal when operating costs were zero.

Such solutions could have no effect on either inventory or objective value:

$$
I_t=W_t
$$
implies:

$$
S_t=S_{t-1}
$$
and, if injection and withdrawal occur at the same market price with zero operating cost:

$$
F_tW_t-F_tI_t=0.
$$
Although mathematically feasible, this behavior is not operationally meaningful.

A binary operating-mode variable was therefore introduced:

$$
y_t\in\{0,1\}.
$$
The model imposes:

$$
I_t
\leq
I^{\max}y_t
$$
and:

$$
W_t
\leq
W^{\max}(1-y_t).
$$
When:

$$
y_t=1,
$$
the facility may inject but cannot withdraw.

When:

$$
y_t=0,
$$
the facility may withdraw but cannot inject.

The resulting optimization problem is a mixed-integer linear program.

The model is implemented in Python with PuLP and solved using CBC.

---

## Historical Forward-Curve Integration

Historical CL1-CL4 WTI futures curves are queried directly from the SQLite `weekly_features` table.

The same optimization formulation can therefore be solved against:

- individual historical dates,
- selected stress-regime dates,
- or continuous ranges of weekly observations.

The optimization pipeline is:

```text
SQLite weekly_features
        |
        v
Historical CL1-CL4 curve
        |
        v
PuLP MILP
        |
        +-- injection decisions
        +-- withdrawal decisions
        +-- ending inventory
        +-- operating mode
        |
        v
Optimal intrinsic value
```

---

## Example: April 24, 2020

The April 24, 2020 forward curve was approximately:

$$
F_1=3.92,
\qquad
F_2=19.07,
\qquad
F_3=23.34,
\qquad
F_4=25.50.
$$
Using the illustrative facility assumptions:

$$
Q=100
$$
$$
I^{\max}=40
$$
$$
W^{\max}=40
$$
$$
S_0=0,
$$
with zero operating costs, the optimizer produces:

| Contract | Price | Injection | Withdrawal | Ending Inventory |
|---|---:|---:|---:|---:|
| CL1 | 3.92 | 40 | 0 | 40 |
| CL2 | 19.07 | 40 | 0 | 80 |
| CL3 | 23.34 | 0 | 40 | 40 |
| CL4 | 25.50 | 0 | 40 | 0 |

The modeled intrinsic value is:

$$
\boxed{V^{*}=1034}
$$
under the illustrative asset scale.

The optimizer responds to the steep contango by acquiring and injecting crude during the cheaper early periods, accumulating inventory, and withdrawing later when futures prices are higher.

The withdrawal-rate constraint is operationally important.

Although CL4 has the highest futures price, the facility cannot wait until CL4 to liquidate all 80 stored units because:

$$
W^{\max}=40.
$$
It must therefore begin withdrawing during CL3.

This demonstrates the distinction between observing a calendar spread and determining how much of that spread a physically constrained asset can actually capture.

---

## Backwardation Sanity Check: March 11, 2022

For March 11, 2022:

$$
113.43
>
109.96
>
106.14
>
102.60.
$$
The curve is strongly backwardated.

With:

$$
S_0=0,
$$
the optimal policy is:

$$
I_t=W_t=S_t=0
\qquad
\forall t.
$$
The modeled intrinsic value is:

$$
\boxed{V^{*}=0}.
$$
This is economically sensible.

An initially empty facility has no incentive to acquire crude at a high nearby price and carry it forward to lower future prices.

The 2022 regime therefore provides a useful sanity check against the positive-value contango cases.

---

## Historical Intrinsic Storage Value

The model is solved repeatedly over the historical CL1-CL4 sample.

For each valuation date $d$:

$$
V_d^{*}
=
\max_{\{I,W,S,y\}}
\text{Storage Profit}.
$$
Using identical physical asset assumptions across dates produces a historical series of deterministic intrinsic storage value.

This transforms the forward curve from a descriptive market object into a measure of economically realizable storage value.

The resulting historical series exhibits:

- repeated positive-value contango episodes,
- elevated modeled storage value during 2015-2017,
- smaller positive episodes around 2019,
- an exceptional spike during April 2020,
- and long near-zero periods during backwardated markets.

Under the illustrative asset assumptions, the April 24, 2020 curve produces approximately:

$$
\frac{V^{*}}{Q}
=
\frac{1034}{100}
=
10.34
$$
units of intrinsic value per unit of storage capacity.

---

## Sensitivity Analysis

The optimization model is parameterized as:

$$
V^{*}(\theta)
$$
where:

$$
\theta
=
\left(
Q,
I^{\max},
W^{\max},
c_I,
c_W,
c_S
\right).
$$
One-way sensitivity analysis varies one model parameter while holding the others fixed.

The current analysis focuses first on the three primary physical constraints:

$$
Q,
\qquad
I^{\max},
\qquad
W^{\max}.
$$
For storage capacity:

$$
V_Q(Q)
=
V^{*}
\left(
Q,
\bar I^{\max},
\bar W^{\max},
\ldots
\right).
$$
For injection throughput:

$$
V_I(I^{\max})
=
V^{*}
\left(
\bar Q,
I^{\max},
\bar W^{\max},
\ldots
\right).
$$
For withdrawal throughput:

$$
V_W(W^{\max})
=
V^{*}
\left(
\bar Q,
\bar I^{\max},
W^{\max},
\ldots
\right).
$$
Discrete marginal value is estimated using:

$$
MV_p
=
\frac{
V^{*}(p_k)-V^{*}(p_{k-1})
}{
p_k-p_{k-1}
}.
$$
This measures the approximate incremental value generated by relaxing a physical constraint.

For example:

$$
MV_Q
=
\frac{\Delta V^{*}}{\Delta Q}
$$
estimates the value of additional storage capacity over a tested interval.

If:

$$
MV_Q=0,
$$
additional tank capacity no longer increases optimized value under that scenario, implying that another constraint such as injection or withdrawal throughput has become the binding operational bottleneck.

The broader sensitivity question is:

> If only one physical capability of the storage facility could be expanded, which constraint would be most economically valuable to relax?

This converts the valuation problem into an operational-capability and resource-allocation problem.

---

# Simulation and Operational Execution Risk

## Purpose

The deterministic MILP answers:

> What should the storage operator do if the observed forward curve is known and the optimized operating schedule can be executed perfectly?

The simulation layer asks a different question:

> What happens if the optimized operating plan cannot be executed perfectly?

The optimizer produces planned injection and withdrawal decisions:

$$
I_t^{*},
\qquad
W_t^{*}.
$$
The SimPy model then executes those decisions through a physically constrained storage process.

The deterministic simulation is first used to reproduce the optimized inventory path exactly and verify consistency between the optimization and simulation models.

For the April 24, 2020 scenario:

$$
0
\rightarrow
40
\rightarrow
80
\rightarrow
40
\rightarrow
0
$$
is reproduced by the SimPy storage process.

---

## Stochastic Throughput Model

Operational uncertainty is introduced through random throughput-realization factors.

Planned injection becomes:

$$
I_t^{realized}
=
A_t^I I_t^{*}
$$
and planned withdrawal becomes:

$$
W_t^{realized}
=
A_t^W W_t^{*}.
$$
In the current illustrative implementation:

$$
A_t^I,
A_t^W
\sim
U(0.7,1.0).
$$
This represents execution degradation in which the facility realizes between 70% and 100% of planned throughput.

The simulation preserves physical feasibility.

Realized injection cannot exceed remaining tank capacity:

$$
I_t^{realized}
\leq
Q-S_{t-1},
$$
and realized withdrawal cannot exceed available inventory:

$$
W_t^{realized}
\leq
S_{t-1}+I_t^{realized}.
$$
The realized inventory path therefore evolves according to the actual simulated operations rather than the optimizer's planned inventory path.

---

## Realized Storage Value

For each stochastic execution path, realized cash flow is calculated as:

$$
CF_t
=
F_tW_t^{realized}
-
F_tI_t^{realized}.
$$
Under the current zero-operating-cost simulation:

$$
V^{sim}
=
\sum_{t=1}^{T} CF_t.
$$
The deterministic MILP optimum remains:

$$
V^{*}=1034
$$
for the April 24, 2020 test case.

One illustrative stochastic realization produces approximately:

$$
V^{sim}=846.92,
$$
corresponding to an execution shortfall of:

$$
1034-846.92
=
187.08,
$$
or approximately:

$$
18.1\%.
$$
This path realizes approximately:

- 83.7% of planned injection,
- 81.5% of planned withdrawal,
- and finishes with approximately 1.81 units of residual inventory.

This demonstrates that a profitable deterministic operating plan can lose substantial economic value when physical execution is imperfect.

---

## Monte Carlo Simulation

The stochastic execution model is repeated across 1,000 Monte Carlo replications.

Each run generates:

- realized storage value,
- execution shortfall,
- terminal inventory,
- injection execution rate,
- and withdrawal execution rate.

For the April 24, 2020 illustrative case, the simulation produces approximately:

$$
E[V^{sim}]
=
805.28
$$
compared with:

$$
V^{*}
=
1034.
$$
The mean execution shortfall is therefore approximately:

$$
228.72,
$$
or:

$$
22.1\%
$$
of planned deterministic intrinsic value.

The realized-value distribution has approximately:

$$
P_5
=
652.06,
$$
$$
P_{50}
=
807.35,
$$
and:

$$
P_{95}
=
941.27.
$$
The simulated sample ranges from approximately:

$$
518.16
$$
to:

$$
1008.93.
$$
Approximately:

$$
34.4\%
$$
of simulations realize less than 75% of planned intrinsic value.

The mean simulated injection execution rate is approximately:

$$
84.9\%,
$$
while mean withdrawal execution is approximately:

$$
81.4\%.
$$
Approximately:

$$
49.7\%
$$
of simulated paths end with positive residual terminal inventory.

---

## Interpretation of Simulation Results

The simulation framework distinguishes between planned economic value and realized operational value.

The deterministic optimizer provides:

$$
V^{*}
=
\text{value under ideal execution}.
$$
The simulation provides:

$$
V^{sim}
=
\text{value under uncertain execution}.
$$
The difference:

$$
V^{*}-V^{sim}
$$
can therefore be interpreted as an execution-related value shortfall under the modeled operating uncertainty.

The current simulation produces three important observations.

### 1. Operational uncertainty materially reduces realized value

The deterministic value of 1034 lies well above the center of the Monte Carlo realized-value distribution.

The average simulated value of approximately 805 implies that imperfect throughput materially reduces the amount of forward-curve value that the storage operator is able to capture.

### 2. Residual terminal inventory is associated with weaker outcomes

The deterministic optimizer imposes:

$$
S_T=S_0=0.
$$
Stochastic execution does not necessarily satisfy this terminal condition.

If realized withdrawal performance is insufficient relative to prior injection, inventory may remain in storage at the end of the modeled horizon.

Simulation results show a strong negative relationship between terminal inventory and realized storage value.

The current cash-flow model does not assign a salvage value to residual terminal inventory, so stranded inventory directly contributes to weaker measured outcomes.

### 3. Balanced operational execution matters

Higher execution rates generally support higher realized value.

However, high injection execution alone does not guarantee a strong economic outcome.

A facility can successfully acquire and store cheap crude but still fail to monetize the position if later withdrawals underperform.

Operational performance must therefore be evaluated across the full inventory cycle rather than through injection or withdrawal capability in isolation.

---

## Simulation Visualizations

The Monte Carlo framework includes three primary decision and risk visualizations.

### Realized-Value Distribution

A histogram of Monte Carlo realized storage values compares:

- the deterministic MILP optimum,
- the mean realized value,
- the 5th and 95th percentiles,
- and a 75%-of-optimum downside threshold.

This figure shows how far realized operational outcomes can deviate from the deterministic optimum.

### Terminal Inventory vs. Realized Value

A scatterplot compares ending inventory with realized storage value.

The results show a pronounced negative relationship between stranded terminal inventory and economic performance.

### Operational Execution vs. Realized Value

Injection and withdrawal execution rates are compared with realized storage value.

The visualization demonstrates that stronger execution generally supports higher realized value, while also showing that injection success alone does not ensure successful monetization of the storage position.

---

## Decision Visualizations

The project also includes decision-focused optimization visualizations that jointly display:

1. the observed CL1-CL4 WTI forward curve, and
2. the optimizer's resulting injection, withdrawal, and ending-inventory schedule.

These figures are designed to communicate the connection:

$$
\text{Market Structure}
\rightarrow
\text{Optimal Operational Response}.
$$
For April 24, 2020, the sharply rising forward curve produces aggressive early injection followed by later withdrawal.

For March 11, 2022, the downward-sloping curve produces an idle optimal policy and zero intrinsic value.

Together with the simulation figures, the visualization framework now connects:

$$
\text{Market Structure}
\rightarrow
\text{Optimal Decision}
\rightarrow
\text{Execution Uncertainty}
\rightarrow
\text{Realized Outcome}.
$$
---

## Interpretation

The project increasingly distinguishes four related but different questions.

### 1. What does the forward curve look like?

This is answered through:

- spreads,
- slope,
- curvature,
- normalized curves,
- and carry.

### 2. What physical conditions are associated with the curve?

This is addressed through:

- Cushing inventory,
- capacity,
- utilization,
- inventory changes,
- refinery conditions,
- production,
- flows,
- seasonality,
- and planned regression analysis.

### 3. What should a constrained storage operator do with the curve?

This is answered through optimization.

Instead of asking only:

> How steep is the WTI forward curve?

the optimization model asks:

> Given this forward curve and the physical characteristics of a storage asset, what injection, withdrawal, and inventory schedule maximizes realizable intrinsic value?

### 4. What happens when the optimal plan cannot be executed perfectly?

This is answered through simulation.

The SimPy and Monte Carlo framework tests how stochastic throughput degradation changes:

- realized injection,
- realized withdrawal,
- inventory trajectories,
- terminal inventory,
- realized storage value,
- and execution shortfall.

The project therefore progresses from descriptive market analysis toward explicit decision modeling and operational-risk analysis.

---

## Intrinsic vs. Extrinsic Storage Value

The optimization model calculates deterministic intrinsic storage value.

Conceptually:

$$
\text{Total Storage Value}
=
\text{Intrinsic Value}
+
\text{Extrinsic Value}.
$$
Intrinsic value is the value obtainable from the currently observed forward curve under modeled operating constraints.

Extrinsic value arises from the ability to adapt future operating decisions as uncertain prices and forward curves evolve.

The current MILP estimates the intrinsic component.

The current SimPy model does **not** yet estimate extrinsic option value. Instead, it stress-tests execution of a fixed optimized schedule under stochastic operational throughput.

This distinction is important.

The current simulation asks:

> How robust is the deterministic optimal schedule to imperfect execution?

A future stochastic valuation model would instead ask:

> How valuable is the ability to change decisions dynamically as uncertain prices evolve?

---

## Current Modeling Assumptions and Limitations

The optimization and simulation models are intentionally simplified so that the mathematical structure and operational mechanics remain transparent.

Current assumptions include:

- CL1-CL4 generic futures prices represent four sequential optimization periods.
- Successive generic contracts are treated as approximately one month apart.
- Futures prices are deterministic inputs within each optimization horizon.
- Capacity is fixed within each scenario.
- Planned injection and withdrawal limits are fixed within each optimization scenario.
- Inventory balance is lossless.
- The MILP requires terminal inventory to equal initial inventory.
- Injection, withdrawal, and storage costs are parameterized but may be zero in illustrative experiments.
- Simultaneous injection and withdrawal are prohibited through binary operating-mode variables.
- The MILP currently values only intrinsic storage economics.
- SimPy throughput uncertainty is currently modeled using independent uniform realization factors.
- The current stochastic model represents operational execution risk rather than stochastic price evolution.
- Residual terminal inventory currently receives no salvage value in simulated cash flow.
- Simulation does not yet include outages, transfer delays, correlated failures, price shocks, or adaptive re-optimization.
- Futures prices are generic-contract histories rather than exact contract-specific delivery schedules.
- The historical EIA futures series ends after April 5, 2024.

These assumptions make the current framework suitable for transparent operations-research analysis while leaving several paths for greater realism.

---

## Visualizations

Python visualizations currently include:

### Forward-Curve Research

- CL1-CL4 forward-curve snapshots
- CL1-normalized forward curves
- Adjacent calendar-spread charts
- Historical front-spread time series
- Historical cumulative-spread time series
- Full-sample annualized-carry plots
- Percentile-zoomed annualized-carry plots

### Physical / Financial Research

- Cushing utilization versus front calendar spread
- Cushing utilization versus cumulative calendar spread
- inventory-change versus spread analysis

### Optimization

- Historical intrinsic-storage-value time series
- forward curve plus optimal operating schedule
- injection and withdrawal decisions by contract period
- ending inventory by contract period
- generalized historical-date optimization visualizations
- sensitivity-analysis outputs

### Simulation

- Monte Carlo realized-value distribution
- MILP optimum versus realized-value distribution
- realized-value percentile markers
- downside-threshold visualization
- terminal inventory versus realized value
- injection execution versus realized value
- withdrawal execution versus realized value

---

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
        sensitivity_analysis.py
        optimization_visualization.py

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

The optimization code is separated into:

```text
intrinsic_storage_lp.py
    core optimization model
    historical curve queries
    solver validation
    single-scenario optimization
    multi-scenario optimization

sensitivity_analysis.py
    parameter experiments
    finite-difference marginal values
    physical bottleneck analysis

optimization_visualization.py
    forward-curve visualization
    optimal operating-schedule visualization
```

The simulation code is separated into:

```text
storage_simulation.py
    deterministic SimPy validation
    stochastic throughput simulation
    realized cash-flow calculation
    Monte Carlo replication
    execution-risk statistics

simulation_visualization.py
    realized-value distribution
    terminal-inventory relationship
    operational-execution relationship
```

---

## Data

The project uses public data from the U.S. Energy Information Administration.

Primary sources include:

- weekly Cushing crude inventories,
- PADD 2 inventories,
- refinery inputs and utilization,
- U.S. crude production,
- crude imports and exports,
- WTI spot prices,
- historical generic WTI futures prices,
- and EIA crude-oil storage-capacity data.

The EIA historical NYMEX WTI futures series used in the project ends after April 5, 2024.

Historical forward-curve and optimization analysis therefore use data through that cutoff.

The project architecture is designed so that another legitimate futures-data source can later replace or extend the EIA futures history without redesigning the underlying physical-market data pipeline.

Local databases, downloaded raw files, generated artifacts, and API credentials are excluded from version control.

---

## Planned Extensions

Near-term work includes:

- complete storage-capacity sensitivity analysis,
- injection-rate sensitivity analysis,
- withdrawal-rate sensitivity analysis,
- storage-cost and transaction-cost sensitivity,
- comparison of physical bottlenecks across historical regimes,
- completion of physical-versus-financial regressions,
- nonlinear inventory-utilization effects,
- explicit analysis of the April 2020 storage crisis,
- terminal-inventory salvage-value modeling,
- richer operational uncertainty distributions,
- simulated outages and transfer delays,
- and comparison of execution risk across historical curve regimes.

Longer-term extensions include:

- stochastic forward-curve modeling,
- dynamic re-optimization,
- stochastic dynamic programming,
- extrinsic storage valuation,
- hedging analysis,
- risk measurement,
- and strategy backtesting.

---

## Core Research Question

The project ultimately asks:

> What is the value of flexible crude-oil storage at Cushing, what physical-market conditions drive that value, and how should a constrained storage operator use and hedge that flexibility?

The project approaches that question sequentially:

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

The current optimization stage converts historical market structure into explicit operating decisions, while the simulation stage tests how operational uncertainty affects the realization of those decisions.

Together, they provide a foundation for later dynamic stochastic valuation, hedging, and risk analysis.