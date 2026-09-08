# Cricket Analytics Platform — P2

End-to-end Match + Ball-by-Ball analytics platform built from the P2 specification and aligned with the data-engineering curriculum.

## Purpose

Ingest teams, players, matches and deliveries and enable ball-level analytics for batting, bowling, phases, venues and formats.

## End-to-end architecture

```text
CSV Source Files
      |
      v
Landing: /landing/cricket_analytics/
      |
      v
Snowflake Internal Stage
      |
      +--> Snowpipe --> RAW_TEAMS
      +--> Snowpipe --> RAW_PLAYERS
      +--> Snowpipe --> RAW_MATCHES
      +--> Snowpipe --> RAW_DELIVERIES
                              |
                              v
                         dbt Bronze
                              |
                              v
                         dbt Silver
                 DIM_DATE / DIM_TEAM
                 DIM_VENUE / DIM_PLAYER
                 DIM_MATCH / FACT_DELIVERY
                              |
                              v
                          dbt Gold
             Match / Player / Team-Venue / Phase
                              |
                              v
                       SEM semantic views
                              |
                              v
                        Streamlit App

Airflow orchestrates dbt snapshot + build.
Informatica CDI specifications document the dimension-then-fact enterprise ETL alternative.
```

## P2 implementation

- Landing folders: teams, players, matches, deliveries, quarantine and archive.
- One Snowpipe per RAW entity with `LOAD_TS`, `FILE_NAME` and `ROW_NUMBER` metadata.
- Star schema: `DIM_DATE`, `DIM_TEAM`, `DIM_VENUE`, `DIM_PLAYER`, `DIM_MATCH`, `FACT_DELIVERY`.
- Fact grain: exactly one row per `DELIVERY_ID`.
- `DIM_PLAYER` is SCD Type 2 for nationality, role, batting style, bowling style and current team.
- Other dimensions are Type 1.
- Unknown members are used when a dimension lookup cannot resolve a business key.
- Delivery fact processing is incremental and idempotent on `DELIVERY_ID`.
- `LEGAL_BALL` is derived so cricket run-rate, strike-rate and economy metrics use legal deliveries.
- DQ and operational objects cover rejects, audit, validation and quarantine controls.

## dbt Medallion layers

```text
cricket_dbt/
├── models/
│   ├── bronze/
│   │   ├── br_cricket_teams.sql
│   │   ├── br_cricket_players.sql
│   │   ├── br_cricket_matches.sql
│   │   └── br_cricket_deliveries.sql
│   ├── silver/
│   │   ├── dim_date.sql
│   │   ├── dim_team.sql
│   │   ├── dim_venue.sql
│   │   ├── dim_player.sql
│   │   ├── dim_match.sql
│   │   └── fact_delivery.sql
│   └── gold/
│       ├── match_overview.sql
│       ├── player_insights.sql
│       ├── team_venue_analytics.sql
│       └── phase_analytics.sql
├── snapshots/
├── tests/
└── dbt_project.yml
```

Bronze models standardize the four RAW feeds. Silver contains the conformed P2 star schema and player SCD2. Gold contains business-ready analytics models. SEM exposes a controlled interface to Streamlit.

The player SCD2 uses `PLAYER_ID` as the business key, `UPDATED_AT` as the change timestamp, and a `HASH_DIFF` over the five tracked attributes.

## Airflow

`airflow/dags/cricket_dbt_pipeline.py` orchestrates:

1. `dbt deps`
2. player SCD2 snapshot
3. `dbt build` including models and tests

Snowflake credentials are supplied to the Airflow container through environment variables and are not committed.

## Streamlit

The dashboard contains the four P2 pages:

1. Match Overview — score/run-rate/wicket metrics and filters
2. Player Insights — top batters, strike rate, boundaries, top bowlers and economy
3. Team/Venue — home/away and winning trends plus venue leaderboard
4. Explorer — ball-by-ball drilldown, phase analysis and CSV export

Required KPIs include Total Runs, Wickets, Run Rate, Boundary %, Dot Ball % and Extras.

## Data quality

- Unique business keys and delivery IDs
- Referential integrity between deliveries, matches, teams and players
- Delivery run reconciliation
- Legal-ball-aware run-rate calculations
- Ball/over completeness controls
- Match-summary reconciliation contract
- Schema-drift and quarantine controls
- Operational `OPS.LOAD_AUDIT`, `OPS.REJECTS` and quarantine audit

The supplied match feed does not contain independent match-level score summary totals, so exact delivery-to-match-summary reconciliation is reported as unavailable rather than fabricated.

The supplied match feed contains `VENUE_ID` but no separate venue master feed. Venue keys are preserved and unavailable descriptive attributes remain Unknown.

## Environments

CDI parameter templates cover DEV, TEST and PROD using:

- `$P_DB`
- `$P_LOAD_DATE`
- `$P_BATCH_ID`

The dbt profile also supports DEV/TEST/PROD through environment variables.

## Deployment order

```text
1. sql/00_setup.sql
2. sql/01_raw.sql
3. sql/02_snowpipe.sql
4. Upload the four CSV feeds to the landing stage
5. Trigger/refresh Snowpipes as required
6. sql/09_dq_quarantine.sql
7. dbt snapshot
8. dbt build
9. sql/05_semantic.sql
10. sql/07_security.sql
11. Start Streamlit
```

## Technology alignment

Snowflake, Snowpipe, dbt, Apache Airflow, Docker, Python/SQL, Informatica CDI, data transformation/import, data analysis and Streamlit are used where they support the project and curriculum requirements.
