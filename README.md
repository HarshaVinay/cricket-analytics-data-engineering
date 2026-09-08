# Cricket Analytics Platform — P2

An end-to-end cricket analytics data platform built on Snowflake, dbt, Snowpipe, Airflow, Informatica CDI design patterns, and Streamlit. The platform ingests match and ball-by-ball data and produces curated analytics for batting, bowling, phases, teams, venues, and formats.

## Overview

The implementation follows a layered data architecture with Snowflake as the warehouse and dbt as the primary transformation framework.

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

The RAW layer is loaded through four entity-specific Snowpipes:

- `PIPE_RAW_TEAMS`
- `PIPE_RAW_PLAYERS`
- `PIPE_RAW_MATCHES`
- `PIPE_RAW_DELIVERIES`

Each pipe uses the shared CSV file format and preserves ingestion metadata:

- `LOAD_TS`
- `FILE_NAME`
- `ROW_NUMBER`

`ON_ERROR = CONTINUE` is used so individual bad records do not stop the feed. The validated project environment uses an internal Snowflake stage with manual `ALTER PIPE ... REFRESH`; cloud notification wiring is environment-specific.

## dbt Medallion Architecture

### Bronze

Bronze models standardize and expose the four RAW feeds:

```text
BRONZE.BR_CRICKET_TEAMS
BRONZE.BR_CRICKET_PLAYERS
BRONZE.BR_CRICKET_MATCHES
BRONZE.BR_CRICKET_DELIVERIES
```

### Silver

Silver implements the conformed warehouse model:

```text
SILVER.DIM_DATE
SILVER.DIM_TEAM
SILVER.DIM_VENUE
SILVER.DIM_PLAYER
SILVER.DIM_MATCH
SILVER.FACT_DELIVERY
```

`FACT_DELIVERY` is maintained at one row per `DELIVERY_ID`.

`DIM_PLAYER` is SCD Type 2 and tracks nationality, role, batting style, bowling style, and current team. The implementation uses effective start/end timestamps, `IS_CURRENT`, and an MD5 `HASH_DIFF` across those tracked attributes. Because the delivery feed does not carry a player-version event timestamp, player surrogate-key resolution uses delivery `LOAD_TS`.

Other dimensions are Type 1.

### Gold

Gold contains business-ready analytics models:

```text
GOLD.MATCH_OVERVIEW
GOLD.PLAYER_INSIGHTS
GOLD.TEAM_VENUE_ANALYTICS
GOLD.PHASE_ANALYTICS
```

These models support dashboard KPIs and downstream analytical views.

## Semantic Layer

The `SEM` schema provides the controlled application interface:

```text
SEM.V_MATCH_SUMMARY
SEM.V_PLAYER_BATTING
SEM.V_PLAYER_BOWLING
SEM.V_TEAM_TRENDS
SEM.V_VENUE_TRENDS
SEM.V_DELIVERY_EXPLORER
```

The Streamlit application reads from the semantic layer rather than querying RAW directly.

## Streamlit Dashboard

The dashboard is deployed in Snowflake using the warehouse runtime and contains four areas:

**Match Overview**
- score and run metrics
- wickets and extras
- run rate, boundary %, and dot-ball %
- match, team, and innings filters

**Player Insights**
- top batters
- runs, balls, strike rate, boundaries
- top bowlers
- wickets, runs conceded, balls bowled, economy

**Team / Venue**
- team performance
- winning trends
- home/away analysis
- venue leaderboard

**Explorer**
- ball-by-ball drilldown
- match, innings, and phase filters
- CSV export
- phase analysis

## Operational Controls

### Data Quality

The implementation includes dbt tests and Snowflake DQ controls for:

- not-null fields
- unique business keys
- unique `DELIVERY_ID`
- referential integrity
- delivery run reconciliation
- legal-ball-aware rate calculations
- reject and quarantine handling
- operational load auditing

### Security

The security model separates ingestion, transformation, analytics, application, and administration responsibilities:

```text
ROLE_INGEST
ROLE_ETL
ROLE_ANALYST
ROLE_APP_STREAMLIT
ROLE_ADMIN
```

RAW is intentionally restricted from analyst/application access. Approved analytical access is provided through Silver, Gold, DW, and SEM objects as required by the workload.

The supplied cricket data contains no PII/PHI, so masking policies are not required for the current dataset.

## CDI Design Reference

The `cdi/` directory and `sql/04_cdi_reference.sql` capture the enterprise ETL design requested by the P2 architecture:

- dimension-then-fact processing
- surrogate-key lookups and Unknown members
- NEW / CHANGED / UNCHANGED / INVALID routing
- player SCD2 handling
- derived expressions and `HASH_DIFF`
- `$P_DB`, `$P_LOAD_DATE`, `$P_BATCH_ID` parameters
- `DELIVERY_ID` idempotency

The runtime transformation implementation is dbt; CDI is retained as the reference design.

## Airflow Orchestration

The repository contains an Airflow DAG that sequences:

```text
dbt deps
   ↓
Player SCD2 snapshot
   ↓
dbt build
```

The DAG is configured on a 30-minute schedule to support the target refresh cadence.

## Project Structure

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

## Setup and Execution

### Snowflake

Execute the SQL scripts in the following logical order:

```text
00_setup.sql
01_raw.sql
02_snowpipe.sql
Upload source CSVs
Refresh Snowpipes
03_dw.sql
05_semantic.sql
07_security.sql
08_dq_ops.sql
09_dq_quarantine.sql
```

### dbt

From `cricket_dbt/`:

```bash
dbt debug --profiles-dir .
dbt snapshot --profiles-dir .
dbt build --profiles-dir .
dbt test --profiles-dir .
```

The profile reads Snowflake connection values from environment variables rather than storing credentials in the repository.

### Streamlit

For local development:

```bash
cd streamlit_app
pip install -r requirements.txt
streamlit run app.py
```

For the validated Snowflake deployment, the application is deployed from the staged `app.py` and `environment.yml` using the Snowflake warehouse runtime.

## Validation

The validated dataset produced the following warehouse results:

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

The six SEM views were populated and the deployed Streamlit application was validated across all four dashboard areas.

## Design Notes

- `03_dw.sql` provides compatibility views over the canonical dbt Silver model rather than maintaining a second warehouse copy.
- The supplied match feed does not contain an independent score-summary measure; reconciliation is therefore performed at the delivery/fact level.
- The supplied feeds contain venue keys but no separate venue master feed, so the venue dimension preserves available keys and uses Unknown attributes where descriptive data is unavailable.
- The project separates the executable dbt transformation path from the Informatica CDI reference design.

## Technology

**Snowflake · Snowpipe · dbt · Apache Airflow · Informatica CDI · Docker · Python · SQL · Streamlit**
