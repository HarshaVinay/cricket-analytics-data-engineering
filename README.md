# Cricket Analytics Platform — P2

End-to-end Match + Ball-by-Ball analytics platform built from the P2 specification and aligned with the data-engineering curriculum.

## Purpose

Ingest teams, players, matches and deliveries and enable ball-level analytics for batting, bowling, phases, venues and formats.

## Architecture

```text
CSV source files
      |
      v
Landing: /landing/cricket_analytics/
      |
      v
Snowflake internal stage
      |
      v
Snowpipe (one pipe per entity)
      |
      v
RAW
      |
      v
dbt Bronze
      |
      v
dbt Silver
  DIM_DATE / DIM_TEAM / DIM_VENUE
  DIM_PLAYER (SCD2) / DIM_MATCH / FACT_DELIVERY
      |
      v
dbt Gold
  MATCH_OVERVIEW / PLAYER_INSIGHTS
  TEAM_VENUE_ANALYTICS / PHASE_ANALYTICS
      |
      +------------------+
      |                  |
      v                  v
DW compatibility      SEM semantic views
views                     |
                          v
                 Streamlit in Snowflake

Airflow orchestrates the dbt snapshot and build workflow.
Informatica CDI specifications document the dimension-then-fact enterprise ETL alternative.
```

## Source feeds

```text
cricket_teams.csv        ~15 rows
cricket_players.csv      ~20 rows
cricket_matches.csv      ~15 rows
cricket_deliveries.csv   ~25 rows
```

Landing folders:

```text
landing/cricket_analytics/
├── teams/
├── players/
├── matches/
├── deliveries/
├── quarantine/
└── archive/
```

## Snowpipe ingestion

Four Snowpipes are defined:

- `PIPE_RAW_TEAMS`
- `PIPE_RAW_PLAYERS`
- `PIPE_RAW_MATCHES`
- `PIPE_RAW_DELIVERIES`

Each pipe loads the corresponding `RAW_*` table using `ON_ERROR = CONTINUE` and preserves:

- `LOAD_TS`
- `FILE_NAME`
- `ROW_NUMBER`

The validated environment uses manual `ALTER PIPE ... REFRESH` with an internal stage. Cloud `AUTO_INGEST` notification wiring remains an environment-level configuration rather than a repository requirement.

## dbt Medallion architecture

### Bronze

```text
BRONZE.BR_CRICKET_TEAMS
BRONZE.BR_CRICKET_PLAYERS
BRONZE.BR_CRICKET_MATCHES
BRONZE.BR_CRICKET_DELIVERIES
```

Bronze standardizes source data types, preserves ingestion metadata, and derives delivery phase information.

### Silver

```text
SILVER.DIM_DATE
SILVER.DIM_TEAM
SILVER.DIM_VENUE
SILVER.DIM_PLAYER
SILVER.DIM_MATCH
SILVER.FACT_DELIVERY
```

`FACT_DELIVERY` has one row per `DELIVERY_ID`.

`DIM_PLAYER` is SCD Type 2 and tracks:

- nationality
- role
- batting style
- bowling style
- current team

The SCD2 implementation uses `PLAYER_ID` as the business key, effective start/end timestamps, `IS_CURRENT`, and `HASH_DIFF` over all five tracked attributes. Delivery-to-player SCD2 key resolution uses the delivery ingestion timestamp (`LOAD_TS`) because the delivery feed does not contain a player-version event timestamp.

Other dimensions are Type 1.

### Gold

```text
GOLD.MATCH_OVERVIEW
GOLD.PLAYER_INSIGHTS
GOLD.TEAM_VENUE_ANALYTICS
GOLD.PHASE_ANALYTICS
```

These models provide business-ready cricket analytics.

## CDI

`sql/04_cdi_reference.sql` and the `cdi/` directory document the Informatica CDI alternative required by the P2 design:

- dimension-then-fact processing
- surrogate-key lookups and Unknown members
- NEW / CHANGED / UNCHANGED / INVALID routing
- player SCD2 processing
- parameterization with `$P_DB`, `$P_LOAD_DATE`, `$P_BATCH_ID`
- idempotency using `DELIVERY_ID`

The runnable transformation path used for this project is dbt; CDI is maintained as the enterprise ETL design/reference layer.

## Analytics and Streamlit

Streamlit provides four dashboard areas:

1. **Match Overview** — score/run metrics, wicket metrics and match/team/innings filters.
2. **Player Insights** — top batters, strike rate, boundaries, top bowlers, wickets and economy.
3. **Team/Venue** — team performance, venue leaderboard and winning/home-away trends.
4. **Explorer** — ball-by-ball drilldown, filtering, CSV export and phase analysis.

Core KPIs:

- Total Runs
- Wickets
- Run Rate
- Boundary %
- Dot Ball %
- Extras

The deployed Snowflake Streamlit application runs with the Snowflake warehouse runtime and reads the controlled `SEM` views.

## Semantic layer

The `SEM` schema exposes application-ready views:

```text
SEM.V_MATCH_SUMMARY
SEM.V_PLAYER_BATTING
SEM.V_PLAYER_BOWLING
SEM.V_TEAM_TRENDS
SEM.V_VENUE_TRENDS
SEM.V_DELIVERY_EXPLORER
```

Applications query `SEM`, not `RAW`.

## Security and governance

Roles:

```text
ROLE_INGEST
ROLE_ETL
ROLE_ANALYST
ROLE_APP_STREAMLIT
ROLE_ADMIN
```

RAW is restricted. Analyst and application access is through approved analytical/semantic objects. `OPS.LOAD_AUDIT` and `OPS.REJECTS` provide operational audit and exception tracking.

The supplied cricket dataset contains no PII/PHI, so no masking policy is required for the current data; least-privilege access is implemented for the available objects.

## Data quality

Implemented/validated controls include:

- unique business keys and delivery IDs
- not-null checks
- referential integrity
- delivery run reconciliation
- legal-ball-aware rate calculations
- DQ reject/quarantine workflow
- operational load audit

The supplied match feed does not contain an independent match-level score summary, so a true delivery-to-match-summary reconciliation cannot be calculated from the supplied source and is documented as unavailable rather than fabricated.

The supplied feeds contain `VENUE_ID` but no venue master feed, so the venue dimension preserves the key and unavailable descriptive attributes are retained as Unknown.

## Orchestration

Airflow DAG:

```text
dbt deps
   |
   v
player SCD2 snapshot
   |
   v
dbt build (models + tests)
```

The DAG is configured for a 30-minute cadence to support the DW refresh target. SLA performance itself is not automatically measured by the repository.

## SQL scripts

```text
sql/
├── 00_setup.sql
├── 01_raw.sql
├── 02_snowpipe.sql
├── 03_dw.sql
├── 04_cdi_reference.sql
├── 05_semantic.sql
├── 07_security.sql
├── 08_dq_ops.sql
└── 09_dq_quarantine.sql
```

`04_cdi_reference.sql` is a design/reference artifact rather than a prerequisite to the dbt runtime path.

## Validation evidence

The supplied dataset was validated in Snowflake with:

```text
RAW_TEAMS       = 15
RAW_PLAYERS     = 20
RAW_MATCHES     = 15
RAW_DELIVERIES  = 25
FACT_DELIVERY   = 25
TOTAL_RUNS      = 72
WICKETS         = 7
```

The dbt project passed:

```text
60/60 build resources
45/45 data tests
```

The SEM layer was populated and the Snowflake-hosted Streamlit application was validated against all four dashboard areas.

## P2 requirements coverage

| Requirement | Status |
|---|---|
| Snowpipe per entity | ✅ Implemented |
| RAW metadata | ✅ Implemented |
| Star schema / fact grain | ✅ Implemented |
| Player SCD2 | ✅ Implemented |
| Type 1 dimensions | ✅ Implemented |
| CDI dim-then-fact design | ✅ Reference implemented |
| dbt Bronze / Silver / Gold | ✅ Implemented |
| Streamlit dashboard | ✅ Deployed in Snowflake |
| Core KPIs | ✅ Implemented |
| Semantic views | ✅ Implemented |
| RBAC / least privilege | ✅ Implemented |
| DQ / OPS / quarantine | ✅ Implemented |
| Airflow orchestration | ✅ Repository implementation |
| Ingestion < 5 min SLA | ⚠️ Target documented; not automatically measured |
| DW refresh < 30 min SLA | ⚠️ 30-minute cadence configured; not automatically measured |
| Full ball/over completeness automation | ⚠️ Validation design present; not a comprehensive automated framework |
| Independent match-summary reconciliation | ⚠️ Source does not provide independent summary totals |
| True graphical heatmap | ⚠️ Phase analysis is currently presented through the Explorer phase pivot/table |
| Cortex RAG / Cortex Analyst | ❌ Out of scope / not implemented |

## Scope note

This implementation intentionally excludes Cortex/RAG/Cortex Analyst because those features are not part of the implemented project scope. No Cortex functionality is required for the validated Snowflake/dbt/Streamlit P2 pipeline.

## Technology alignment

Snowflake, Snowpipe, dbt, Apache Airflow, Docker, Python/SQL, Informatica CDI, data transformation/import, data analysis and Streamlit are used where they support the P2 project and curriculum requirements.
