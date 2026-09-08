# Cricket Analytics Platform — P2

Match + ball-by-ball analytics platform built strictly to the P2 project specification.

## Scope

CSV feeds for teams, players, matches and deliveries are landed under `/landing/cricket_analytics/`.

Snowpipe loads four RAW tables. Informatica CDI performs dimension-first, fact-last transformations into a Snowflake star schema. `DIM_PLAYER` is SCD Type 2; the other dimensions are Type 1. Streamlit consumes only semantic views.

## Data flow

```text
CSV Landing
    |
    +--> Teams --------> Snowpipe --------> RAW_TEAMS
    +--> Players ------> Snowpipe --------> RAW_PLAYERS
    +--> Matches ------> Snowpipe --------> RAW_MATCHES
    +--> Deliveries ---> Snowpipe --------> RAW_DELIVERIES
                                      |
                                      v
                              Informatica CDI
                                      |
                    +-----------------+------------------+
                    |                                    |
                 Dimensions                            Fact
                    |                                    |
          DATE / TEAM / VENUE /                   FACT_DELIVERY
             PLAYER / MATCH                         1 row / ball
                    +-----------------+------------------+
                                      |
                                      v
                                  SEM.V_*
                                      |
                                      +--> Streamlit
                                      +--> Cortex Analyst
                                      +--> Cortex Search / RAG
```

## Repository layout

- `landing/` — source CSVs, quarantine and archive folders
- `sql/` — Snowflake setup, RAW, Snowpipe, DW, semantic, Cortex, security and DQ/OPS SQL
- `cdi/` — Informatica CDI mapping/taskflow specifications and parameters
- `cortex/rag_docs/` — KPI glossary, SOP, data dictionary and feed specification content
- `streamlit_app/` — four dashboard pages
- `tests/` — source-level validation tests
- `docs/` — implementation notes

## Star schema

`FACT_DELIVERY` grain: one row per `DELIVERY_ID`.

Dimensions:

- `DIM_DATE`
- `DIM_TEAM`
- `DIM_VENUE`
- `DIM_PLAYER` — SCD2
- `DIM_MATCH`

## Player SCD2

Tracked attributes: `NATIONALITY, ROLE, BATTING_STYLE, BOWLING_STYLE, CURRENT_TEAM_ID`.

`HASH_DIFF = MD5(concat of tracked attributes)`.

New rows are inserted as current. Changed rows expire the old version and insert a new current version. Unchanged rows are ignored.

## CDI

Taskflow order:

`DIM_DATE -> DIM_TEAM -> DIM_VENUE -> DIM_PLAYER_SCD2 -> DIM_MATCH -> FACT_DELIVERY`

Parameters: `$P_DB`, `$P_LOAD_DATE`, `$P_BATCH_ID`

Lookups use surrogate keys and Unknown members. Router branches are new/changed/unchanged/invalid. Delivery loads are idempotent by `DELIVERY_ID`.

## Streamlit

Pages:

1. Match Overview
2. Player Insights
3. Team/Venue
4. Explorer

KPIs: Total Runs, Wickets, Run Rate, Boundary %, Dot Ball %, Extras.

## Cortex

Cortex Search/RAG indexes KPI glossary, SOPs, data dictionary and feed specifications. Cortex Analyst is restricted to semantic views.

## Source-data note

The supplied match feed contains `VENUE_ID` but no separate venue master file, so the implementation preserves the venue business key and provides an Unknown venue member until venue attributes are supplied. The supplied match feed also has no match score summary columns; therefore delivery-to-match-summary reconciliation is a DQ rule that reports `NOT_AVAILABLE` rather than inventing a source total.

## Deployment

Run SQL in the order documented in `docs/deployment.md`, configure the external stage/event integration for Snowpipe, then configure the CDI connections/mappings from `cdi/`.

This project intentionally does not use dbt, Snowpark, custom UDFs, stored procedures, or unrelated curriculum labs.