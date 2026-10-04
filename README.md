\# Cushing Crude Storage Valuation



A quantitative research project examining the value of flexible crude-oil storage at Cushing, Oklahoma, the physical-market variables that drive storage economics, and the resulting price-risk and hedging implications.



\## Project Status



Parts I-II are complete and comprise the following:



\- EIA API ingestion pipeline

\- SQLite research database

\- Physical crude-market domain tables

\- WTI spot and futures-curve data

\- Calendar-spread construction

\- Weekly feature engineering

\- Point-in-time seasonal inventory statistics

\- Validation and economic sanity checks



Later stages will extend the project into storage valuation, stochastic modeling, hedging, and backtesting.



\## Research Pipeline



```text

EIA API

&#x20;  |

&#x20;  v

Python ETL

&#x20;  |

&#x20;  v

SQLite Database

&#x20;  |

&#x20;  +-- inventories

&#x20;  +-- refinery\_activity

&#x20;  +-- flows

&#x20;  +-- prices

&#x20;  +-- calendar\_spreads

&#x20;  |

&#x20;  v

weekly\_features

&#x20;  |

&#x20;  v

Storage Economics / Valuation / Hedging

```



\## Current Features



The weekly research panel includes:

\- Cushing crude inventories

\- PADD 2 crude inventories

\- PADD 2 refinery crude inputs

\- Refinery utilization

\- U.S. crude production

\- U.S. crude imports and exports

\- WTI spot prices

\- Front WTI futures contracts

\- Calendar spreads

\- Inventory lags and changes

\- Four-week rolling features

\- Net crude imports

\- ISO-week seasonality

\- Point-in-time seasonal inventory z-scores



Seasonal statistics are constructed using only observations available prior to each date to avoid look-ahead bias.





\## Repository Structure

``` text

src/

&#x20;   ingestion/

&#x20;       eia\_api.py



sql/

&#x20;   inventories.sql

&#x20;   refinery\_activity.sql

&#x20;   flows.sql

&#x20;   prices.sql

&#x20;   calendar\_spreads.sql

&#x20;   weekly\_features.sql

&#x20;   analytics.sql

&#x20;   validation.sql

```



\## Data



The project uses public U.S. Energy Information Administration data. Local databases, generated data files, and API credentials are excluded from version control.

