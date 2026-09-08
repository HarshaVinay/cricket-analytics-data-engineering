# Cricket Analytics Platform — P2

An end-to-end cricket analytics data platform built on **Snowflake, Snowpipe, dbt, Airflow, Informatica CDI design patterns, and Streamlit**. The platform ingests match and ball-by-ball data and produces curated analytics for batting, bowling, phases, teams, venues, and formats.

## Overview

The implementation uses Snowflake as the warehouse, Snowpipe for ingestion, dbt for the primary transformation path, and Streamlit as the analytics application. Medallion-style Bronze, Silver, and Gold layers provide clear separation between standardized source data, conformed warehouse data, and business-ready analytics.

```text
Source CSVs
    │
    ▼
Landing Stage
    │
    ▼
Snowpipe
    │
    ▼
RAW
    │
    ▼
DBT BRONZE
    │
    ▼
DBT SILVER
Dimensions + FACT_DELIVERY
    │
    ▼
DBT GOLD
Business analytics
    │
    ├──────────────► DW compatibility views
    │
    ▼
SEM semantic views
    │
    ▼
Streamlit in Snowflake

Airflow ─────────► dbt snapshot + build workflow
CDI ─────────────► enterprise ETL design/reference
```

## Source Data

| Feed | Approx. rows | Purpose |
|---|---:|---|
| `cricket_teams.csv` | 15 | Team master data |
| `cricket_players.csv` | 20 | Player master and attributes |
| `cricket_matches.csv` | 15 | Match metadata and results |
| `cricket_deliveries.csv` | 25 | Ball-by-ball events |

Landing layout:

```text
landing/cricket_analytics/
├── teams/
├── players/
├── matches/
├── deliveries/
├── quarantine/
└── archive/
```

## Snowflake Ingestion

Four entity-specific Snowpipes load the RAW layer:

- `PIPE_RAW_TEAMS`
- `PIPE_RAW_PLAYERS`
- `PIPE_RAW_MATCHES`
- `PIPE_RAW_DELIVERIES`

The pipes use the shared CSV format, retain `LOAD_TS`, `FILE_NAME`, and `ROW_NUMBER`, and use `ON_ERROR = CONTINUE`. The validated environment uses an internal stage with manual `ALTER PIPE ... REFRESH`; cloud notification integration is environment-specific.

## dbt Medallion Architecture

### Bronze

```text
BRONZE.BR_CRICKET_TEAMS
BRONZE.BR_CRICKET_PLAYERS
BRONZE.BR_CRICKET_MATCHES
BRONZE.BR_CRICKET_DELIVERIES
```

Bronze standardizes source datatypes, preserves ingestion metadata, and derives delivery phase information.

### Silver

```text
SILVER.DIM_DATE
SILVER.DIM_TEAM
SILVER.DIM_VENUE
SILVER.DIM_PLAYER
SILVER.DIM_MATCH
SILVER.FACT_DELIVERY
```

`FACT_DELIVERY` is maintained at one row per `DELIVERY_ID`.

`DIM_PLAYER` implements SCD Type 2 for nationality, role, batting style, bowling style, and current team. The dimension uses effective dating, `IS_CURRENT`, and an MD5 `HASH_DIFF` across the tracked attributes. Player surrogate-key resolution in the fact uses delivery `LOAD_TS` because the delivery feed does not contain a player-version event timestamp.

Other dimensions are Type 1.

### Gold

```text
GOLD.MATCH_OVERVIEW
GOLD.PLAYER_INSIGHTS
GOLD.TEAM_VENUE_ANALYTICS
GOLD.PHASE_ANALYTICS
```

Gold models expose business-ready cricket analytics for reporting and application consumption.

## Semantic Layer

The `SEM` schema is the controlled application interface:

```text
SEM.V_MATCH_SUMMARY
SEM.V_PLAYER_BATTING
SEM.V_PLAYER_BOWLING
SEM.V_TEAM_TRENDS
SEM.V_VENUE_TRENDS
SEM.V_DELIVERY_EXPLORER
```

The Streamlit application reads these semantic views instead of querying RAW directly.

## Streamlit Dashboard

The Snowflake-hosted application provides:

**Match Overview**
- score/run metrics
- wickets and extras
- run rate, boundary percentage, and dot-ball percentage
- match, team, and innings filters

**Player Insights**
- top batters and strike rate
- boundaries
- top bowlers
- wickets, runs conceded, balls bowled, and economy

**Team / Venue**
- team performance
- winning trends
- home/away analysis
- venue leaderboard

**Explorer**
- ball-by-ball drilldown
- match, innings, and over-phase filters
- CSV export
- phase analysis

## Security and Operations

Roles separate ingestion, transformation, analytical, application, and administrative access:

```text
ROLE_INGEST
ROLE_ETL
ROLE_ANALYST
ROLE_APP_STREAMLIT
ROLE_ADMIN
```

RAW is intentionally restricted from analyst/application roles. Operational objects include `OPS.LOAD_AUDIT`, `OPS.REJECTS`, and quarantine audit support.

The supplied cricket dataset contains no PII/PHI, so masking policies are not required for the current data. Access is controlled through role-based least privilege for available objects.

## Data Quality

The implementation includes dbt and Snowflake validation for:

- not-null constraints
- unique business keys and `DELIVERY_ID`
- referential integrity
- delivery run reconciliation
- legal-ball-aware rate calculations
- reject and quarantine handling
- operational load auditing

The supplied match feed does not contain an independent score-summary measure, so delivery-to-match-summary reconciliation is not applicable to this dataset. Venue keys are present, but there is no separate venue master feed; unavailable descriptive attributes are retained as Unknown.

## Informatica CDI Design Reference

The `cdi/` directory and `sql/04_cdi_reference.sql` document the enterprise ETL alternative:

- dimension-then-fact processing
- surrogate-key lookups and Unknown members
- NEW / CHANGED / UNCHANGED / INVALID routing
- player SCD2 handling
- derived expressions and `HASH_DIFF`
- `$P_DB`, `$P_LOAD_DATE`, `$P_BATCH_ID` parameters
- `DELIVERY_ID` idempotency

The executable transformation path used by this project is dbt; CDI is maintained as the enterprise design/reference layer.

## Airflow Orchestration

The repository contains an Airflow DAG that sequences:

```text
dbt deps
   ↓
Player SCD2 snapshot
   ↓
dbt build
```

The DAG is scheduled on a 30-minute cadence to support the target refresh frequency.

## Repository Structure

```text
cricket-analytics-data-engineering/
├── airflow/
│   ├── dags/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── requirements.txt
├── cdi/
├── cricket_dbt/
│   ├── models/
│   │   ├── bronze/
│   │   ├── silver/
│   │   └── gold/
│   ├── snapshots/
│   ├── tests/
│   ├── macros/
│   ├── dbt_project.yml
│   ├── profiles.yml.example
│   └── requirements.txt
├── docs/
├── landing/
├── sql/
│   ├── 00_setup.sql
│   ├── 01_raw.sql
│   ├── 02_snowpipe.sql
│   ├── 03_dw.sql
│   ├── 04_cdi_reference.sql
│   ├── 05_semantic.sql
│   ├── 07_security.sql
│   ├── 08_dq_ops.sql
│   └── 09_dq_quarantine.sql
├── streamlit_app/
│   ├── app.py
│   ├── environment.yml
│   └── requirements.txt
├── tests/
└── README.md
```

## Deployment Sequence

```text
1. sql/00_setup.sql
2. sql/01_raw.sql
3. sql/02_snowpipe.sql
4. Upload the four CSV feeds to the landing stage
5. Refresh the four Snowpipes
6. dbt debug
7. dbt snapshot
8. dbt build
9. dbt test
10. sql/03_dw.sql
11. sql/05_semantic.sql
12. sql/07_security.sql
13. sql/08_dq_ops.sql
14. sql/09_dq_quarantine.sql
15. Deploy Streamlit in Snowflake
```

`sql/04_cdi_reference.sql` documents the CDI alternative and is not a prerequisite to the dbt runtime path.

## Validation

The validated environment produced:

```text
RAW_TEAMS        = 15
RAW_PLAYERS      = 20
RAW_MATCHES      = 15
RAW_DELIVERIES   = 25
FACT_DELIVERY    = 25
TOTAL_RUNS       = 72
WICKETS          = 7
```

The dbt project completed with:

```text
60/60 build resources passed
45/45 data tests passed
```

All six SEM views were populated and the Snowflake-hosted Streamlit application was validated across all four dashboard areas, including player batting and bowling metrics and ball-by-ball exploration.

## Technology

**Snowflake · Snowpipe · dbt · Apache Airflow · Informatica CDI · Docker · Python · SQL · Streamlit**
