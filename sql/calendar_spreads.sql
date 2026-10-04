-- Build WTI calendar spreads from weekly futures prices

-- Our variables are F_1 = CL1, F_2 = CL2, F_3 = CL3, F_4 = CL4

-- Define the front spread as S_{1,2} := F_2 - F_1

-- Sign convention: deferred minus nearby

-- Positive spread -> contango; negative spread -> backwardation

DROP TABLE IF EXISTS calendar_spreads;

CREATE TABLE IF NOT EXISTS calendar_spreads (
    period TEXT PRIMARY KEY,
    cl2_minus_cl1_usd_bbl REAL,
    cl3_minus_cl2_usd_bbl REAL,
    cl4_minus_cl3_usd_bbl REAL,
    cl3_minus_cl1_usd_bbl REAL,
    cl4_minus_cl1_usd_bbl REAL
);

INSERT INTO calendar_spreads (
    period,
    cl2_minus_cl1_usd_bbl,
    cl3_minus_cl2_usd_bbl,
    cl4_minus_cl3_usd_bbl,
    cl3_minus_cl1_usd_bbl,
    cl4_minus_cl1_usd_bbl
)

SELECT
    period,

    cl2_usd_bbl - cl1_usd_bbl
        AS cl2_minus_cl1_usd_bbl,

    cl3_usd_bbl - cl2_usd_bbl
        AS cl3_minus_cl2_usd_bbl,

    cl4_usd_bbl - cl3_usd_bbl
        AS cl4_minus_cl3_usd_bbl,

    cl3_usd_bbl - cl1_usd_bbl
        AS cl3_minus_cl1_usd_bbl,

    cl4_usd_bbl - cl1_usd_bbl
        AS cl4_minus_cl1_usd_bbl

FROM prices

WHERE cl1_usd_bbl IS NOT NULL                 -- Filter on CL1 and CL2 since a row belongs in calendar_spreads only when at least the basic front calendar spread can actually be calculated
AND cl2_usd_bbl IS NOT NULL                   -- Without this, our table would contain all the 2024–2026 null rows from prices where spot exists but futures don't.
                                              -- We don't require CL3 or CL4 though; if either is unavailable, SQL naturally returns NULL - something = NULL
                                              -- So we preserve any valid front spread even if deeper-curve data is unavailable
ORDER BY period;