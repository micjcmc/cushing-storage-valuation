# Cushing Crude Storage Valuation



A quantitative research project examining the value of flexible crude-oil storage at Cushing, Oklahoma, the physical-market variables that drive storage economics, and the resulting price-risk and hedging implications.



## Project Status



Parts I-II are complete and comprise the following:



- EIA API ingestion pipeline

- SQLite research database

- Physical crude-market domain tables

- WTI spot and futures-curve data

- Calendar-spread construction

- Weekly feature engineering

- Point-in-time seasonal inventory statistics

- Validation and economic sanity checks



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



## Repository Structure



```text

src/

    ingestion/

        eia_api.py



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



The project uses public \[U.S. Energy Information Administration (EIA)](https://www.eia.gov/) data.



Local databases, generated data files, and API credentials are excluded from version control.


