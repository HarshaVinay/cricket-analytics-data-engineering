# Cricket Analytics Platform — P2

End-to-end Match + Ball-by-Ball analytics platform built from the P2 specification and aligned with the data-engineering curriculum.

## Purpose

Ingest teams, players, matches and deliveries and enable ball-level analytics for batting, bowling, phases, venues and formats.

## Architecture

```text
CSV Source Files
      |
      v
Landing: /landing/cricket_analytics/
      |
      v
Snowflake Stage
      |
      +--> Snowpipe --> RAW_TEAMS
      +--> Snowpipe --> RAW_PLAYERS
      +--> Snowpipe --> RAW_MATCHES
      +--> Snowpipe --> RAW_DELIVERIES
                              |
                              v
                       dbt Staging
                              |
                              v
                 Dimensions + FACT_DELIVERY
                              |
                              v
                       dbt Analytics Marts
                              |
                              v
                        Streamlit App

Airflow orchestrates dbt snapshot/build execution.
Informatica CDI mapping specifications document the required dimension-then-fact taskflow.
```

## P2 implementation

- Landing folders: teams, players, matches, deliveries, quarantine and archive.
- One Snowpipe per RAW entity with `LOAD_TS`, `FILE_NAME` and `ROW_NUMBER` metadata.
- Star schema: `DIM_DATE`, `DIM_TEAM`, `DIM_VENUE`, `DIM_PLAYER`, `DIM_MATCH`, `FACT_DELIVERY`.
- Fact grain: exactly one row per `DELIVERY_ID`.
- `DIM_PLAYER` is SCD Type 2 for nationality, role, batting style, bowling style and current team.
- Other dimensions are Type 1.
- Unknown members are used when a dimension lookup cannot resolve a business key.
- Idempotent delivery loading is based on `DELIVERY_ID`.
- DQ and operational objects cover rejects, audit and validation requirements.

## dbt

`cricket_dbt/` is the transformation layer and follows a curriculum-friendly staging → dimensions/facts → marts pattern.

```text
cricket_dbt/
├── models/
│   ├── staging/
│   ├── dimensions/
│   ├── facts/
│   └── marts/
├── snapshots/
├── tests/
├── macros/
└── dbt_project.yml
```

The player SCD2 is implemented with a dbt snapshot using `PLAYER_ID` as the business key and `UPDATED_AT` as the change timestamp. The resulting dimension calculates `HASH_DIFF` from the five tracked attributes.

The incremental `FACT_DELIVERY` model preserves the one-row-per-ball grain and resolves surrogate keys to the dimensions.

## Airflow

`airflow/dags/cricket_dbt_pipeline.py` orchestrates the dbt workflow:

1. `dbt deps`
2. player SCD2 snapshot
3. `dbt build` including model and data tests

## Streamlit

The dashboard contains the four P2 pages:

1. Match Overview
2. Player Insights
3. Team/Venue
4. Explorer

Required KPIs include Total Runs, Wickets, Run Rate, Boundary %, Dot Ball % and Extras.

## Data-quality coverage

- Unique business keys and delivery IDs
- Referential integrity between deliveries, matches, teams and players
- Delivery run reconciliation
- Ball/over completeness checks
- Match-summary reconciliation contract
- Schema-drift and quarantine controls

The supplied match feed does not contain match-level score summary totals, so exact delivery-to-match-summary reconciliation cannot be calculated from the supplied files and must be reported as unavailable rather than fabricated.

The supplied match feed contains `VENUE_ID` but there is no separate venue master feed. Venue business keys are preserved and unavailable descriptive venue attributes remain Unknown.

## Environments

CDI parameter templates are provided for DEV, TEST and PROD using:

- `$P_DB`
- `$P_LOAD_DATE`
- `$P_BATCH_ID`

Credentials are not committed to the repository.

## Repository layout

- `landing/` — supplied source feeds and landing controls
- `sql/` — Snowflake setup, RAW, Snowpipe, warehouse, semantic, security and DQ/OPS SQL
- `cricket_dbt/` — dbt transformations, snapshot, tests and marts
- `cdi/` — CDI mapping/taskflow reference and environment parameters
- `airflow/` — dbt orchestration
- `streamlit_app/` — dashboard application
- `tests/` — source-level validation
- `docs/` — deployment documentation

## Technology alignment

Snowflake, Snowpipe, dbt, Apache Airflow, Docker, Python/SQL, Informatica CDI, data transformation/import, data analysis and Streamlit are used where they support the project and curriculum requirements.
