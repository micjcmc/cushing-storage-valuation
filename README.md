# Cushing Crude Storage Valuation



A quantitative research project examining the value of flexible crude-oil storage at Cushing, Oklahoma, the physical-market variables that drive storage economics, and the resulting price-risk and hedging implications.



## Project Status



Parts I-III are complete and comprise the following:



- EIA API ingestion pipeline

- SQLite research database

- Physical crude-market domain tables

- WTI spot and futures-curve data

- Calendar-spread construction

- Weekly feature engineering

- Point-in-time seasonal inventory statistics

- Forward-curve slope and curvature analysis

- Historical contango and backwardation analysis

- Annualized calendar-carry measures

- Python term-structure visualizations

- Validation and economic sanity checks


Part IV will connect the physical state of Cushing inventories and storage capacity to WTI-forward curve structure through exploratory analysis and regression modeling.


Later stages will extend the project into storage valuation, stochastic modeling, hedging, and backtesting.



## Research Pipeline



```text

EIA API

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

   |

   v

weekly_features

   |

   +-- inventory / flow features

   +-- seasonal statistics

   +-- forward-curve spreads

   |

   v

Python Research & Visualization

   |

   +-- forward-curve snapshots

   +-- normalized term structures

   +-- adjacent calendar spreads

   +-- historical spread regimes

   +-- annualized carry

   |

   v

Physical / Financial Modeling

   |

   v

Storage Economics / Valuation / Hedging

```



## Current Features



The weekly research panel includes:



- Cushing crude inventories

- PADD 2 crude inventories

- PADD 2 refinery crude inputs

- Refinery utilization

- U.S. crude production

- U.S. crude imports and exports

- WTI spot prices

- Front WTI futures contracts

- Calendar spreads

- Inventory lags and changes

- Four-week rolling features

- Net crude imports

- ISO-week seasonality

- Point-in-time seasonal inventory z-scores



Seasonal statistics are constructed using only observations available prior to each date to avoid look-ahead bias.



## Forward-Curve Analysis

Part III studies the first four generic WTI futures contracts and the term structure of crude-oil carry.

Calendar spreads are defined using a deferred-minus-nearby convention:

```text

F2 - F1 > 0 -> contango
F2 - F1 < 0 -> backwardation

```

The analysis examines:

- Front and cumulative calendar spreads

- Forward-curve slope

- Adjacent-spread structure

- Front-loaded versus persistent curve curvature

- Raw and Cl1-normalized forward curves

- Historical contango and backwardation regimes

- Annualized carry across approximately one-, two-, and three-month horizons

Annualized carry is approximated as:

```text

Carry(1,2) = 12 * (F2 - F1) / F1
Carry(1,3) =  6 * (F3 - F1) / F1
Carry(1,4) =  4 * (F4 - F1) / F1 

```

These measures treat successive generic futures delivery months as approximately one month apart. They are intended as normalized measures of curve carry rather than expected investment returns.

Historical analysis highlights contrasting term-structure regimes including:

- Severe, front-loaded contango during 2008–2009
- Extreme prompt dislocation and contango during April 2020
- Broad, persistent backwardation during 2022

The project retains both raw dollar spreads and annualized percentage carry because percentage-normalized carry can become unstable when the nearby futures price approaches zero.



## Visualizations

Python visualizations currently include:

- Cl1-Cl4 forward-curve snapshots for selected historical dates

- Cl1-normalized forward-curve comparisons

- Adjacent calendar-spread bar charts

- Historical front and cumulative calendar-spread time series

- Full-sample and percentile-zoomed annualized carry plots



## Repository Structure



```text

src/

    ingestion/

        eia_api.py

    visualization/

        term_structure_of_carry.py


sql/

    inventories.sql

    refinery_activity.sql

    flows.sql

    prices.sql

    calendar_spreads.sql

    weekly_features.sql

    analytics.sql

    validation.sql

```



## Data



The project uses public [U.S. Energy Information Administration (EIA)](https://www.eia.gov/) data.


The EIA historical NYMEX WTI futures series used in the project ends after April 5, 2024. Historical forward-curve analysis therefore uses data through that cutoff. The project architecture is designed so that an alternative legitimate futures-data source can be incorporated later without redesigning the physical-market data pipeline.


Local databases, generated data files, and API credentials are excluded from version control.


