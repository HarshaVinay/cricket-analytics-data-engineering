# Cricket Analytics Platform

An end-to-end cricket analytics data platform built with **Snowflake, Snowpipe, dbt, Apache Airflow, Informatica CDI design/reference patterns, Python, SQL, Docker, and Streamlit**.

## What this project demonstrates

- Data ingestion from CSV source feeds into a Snowflake RAW layer
- Snowpipe-based ingestion with source metadata and error-tolerant loading
- dbt transformations using **Bronze, Silver, and Gold** layers
- Dimensional modeling with fact and dimension tables
- **SCD Type 2** handling for player attributes
- Data-quality validation, reject/quarantine handling, and operational load auditing
- Semantic views for controlled application access
- Streamlit analytics for match, player, team, venue, and ball-by-ball analysis
- Airflow orchestration of dbt snapshot/build steps
- Role-based access design for ingestion, ETL, analytics, application, and administration

## Architecture

```text
Source CSVs
    ↓
Landing Stage
    ↓
Snowpipe
    ↓
RAW
    ↓
dbt Bronze
    ↓
dbt Silver
Dimensions + FACT_DELIVERY
    ↓
dbt Gold
Business Analytics
    ↓
SEM Views
    ↓
Streamlit

Airflow → dbt snapshot + build workflow
CDI     → enterprise ETL design/reference
```

## Source data

The supplied sample contains:

| Feed | Rows | Purpose |
|---|---:|---|
| Teams | 15 | Team master data |
| Players | 20 | Player master data |
| Matches | 15 | Match metadata and results |
| Deliveries | 25 | Ball-by-ball events |

The landing structure separates entity feeds and includes quarantine/archive areas.

## Snowflake ingestion

Four entity-specific Snowpipes load the RAW layer:

- `PIPE_RAW_TEAMS`
- `PIPE_RAW_PLAYERS`
- `PIPE_RAW_MATCHES`
- `PIPE_RAW_DELIVERIES`

The pipes retain ingestion metadata such as load timestamp, source filename, and file row number. The repository documents both manual refresh and cloud notification setup.

## dbt data modeling

### Bronze

Bronze models standardize source datatypes, preserve ingestion metadata, and derive delivery-phase information.

### Silver

The Silver layer contains:

- `DIM_DATE`
- `DIM_TEAM`
- `DIM_VENUE`
- `DIM_PLAYER`
- `DIM_MATCH`
- `FACT_DELIVERY`

`FACT_DELIVERY` is maintained at one row per `DELIVERY_ID`.

`DIM_PLAYER` implements SCD Type 2 for tracked player attributes using effective dating, `IS_CURRENT`, and an MD5 `HASH_DIFF`.

### Gold

Gold models expose business-ready analytics:

- `MATCH_OVERVIEW`
- `PLAYER_INSIGHTS`
- `TEAM_VENUE_ANALYTICS`
- `PHASE_ANALYTICS`

## Streamlit analytics

The Streamlit application reads from semantic views rather than querying RAW directly.

### Match Overview
- Runs, wickets, extras
- Run rate
- Boundary and dot-ball percentages
- Match, team, and innings filters

### Player Insights
- Batting and bowling leaderboards
- Runs, strike rate, boundaries
- Wickets, economy, and bowling metrics

### Team / Venue
- Team performance
- Winning trends
- Venue rankings

### Ball-by-Ball Explorer
- Match, innings, and over-phase filters
- Delivery-level exploration
- CSV export
- Phase analysis

## Data quality and operations

The repository includes validation for:

- Not-null and uniqueness checks
- Referential integrity
- Delivery/run reconciliation
- Legal-ball-aware rate calculations
- Reject and quarantine handling
- Operational load auditing

The dataset is sample data and does not contain PII/PHI.

## Security design

Roles separate ingestion, transformation, analytical, application, and administrative access:

```text
ROLE_INGEST
ROLE_ETL
ROLE_ANALYST
ROLE_APP_STREAMLIT
ROLE_ADMIN
```

RAW access is restricted from analyst/application roles in the documented design.

## Enterprise ETL reference

The `cdi/` directory documents an Informatica CDI alternative covering:

- Dimension-then-fact processing
- Surrogate-key lookups
- NEW / CHANGED / UNCHANGED / INVALID routing
- Player SCD2 handling
- Parameterized processing
- Idempotency using `DELIVERY_ID`

The executable transformation path is dbt; CDI is maintained as a design/reference layer.

## Validation

The repository documents the validated sample environment as:

- RAW_TEAMS: 15
- RAW_PLAYERS: 20
- RAW_MATCHES: 15
- RAW_DELIVERIES: 25
- FACT_DELIVERY: 25
- TOTAL_RUNS: 72
- WICKETS: 7
- dbt build resources passed: 60/60
- dbt data tests passed: 45/45

## Repository structure

```text
cricket-analytics-data-engineering/
├── airflow/
├── cdi/
├── cricket_dbt/
│   ├── models/
│   ├── snapshots/
│   ├── tests/
│   └── macros/
├── docs/
├── landing/
├── sql/
├── streamlit_app/
├── tests/
└── README.md
```

## Deployment sequence

```text
1. SQL setup
2. RAW and Snowpipe configuration
3. Upload source feeds
4. Refresh Snowpipes
5. dbt debug
6. dbt snapshot
7. dbt build
8. dbt test
9. Analytical / semantic SQL setup
10. Security and data-quality setup
11. Streamlit deployment
```

## Technology

**Snowflake · Snowpipe · dbt · Apache Airflow · Informatica CDI · Python · SQL · Docker · Streamlit**

## Author

Harsha Vinay Garagaparthi
