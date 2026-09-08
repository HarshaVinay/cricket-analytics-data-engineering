# Cricket Analytics dbt Project

The dbt project implements the Bronze → Silver → Gold transformation layers for the Cricket Analytics Platform on top of the Snowflake RAW ingestion layer.

## Architecture

```text
Snowflake RAW
     │
     ▼
Bronze
standardized source data
     │
     ▼
Silver
conformed dimensions + FACT_DELIVERY
     │
     ▼
Gold
business-ready analytics
```

## Models

### Bronze

- `br_cricket_teams`
- `br_cricket_players`
- `br_cricket_matches`
- `br_cricket_deliveries`

Bronze models standardize source datatypes, retain ingestion metadata, and derive delivery phase information.

### Silver

- `dim_date`
- `dim_team`
- `dim_venue`
- `dim_player`
- `dim_match`
- `fact_delivery`

`dim_player` is SCD Type 2 for nationality, role, batting style, bowling style, and current team. `fact_delivery` is maintained at one row per `DELIVERY_ID` and uses surrogate-key lookups to conformed dimensions.

### Gold

- `match_overview`
- `player_insights`
- `team_venue_analytics`
- `phase_analytics`

These models provide the business-ready metrics consumed by the semantic layer and Streamlit application.

## Player SCD2

Player history is captured by `snap_cricket_players` using a timestamp strategy on `UPDATED_AT` and `PLAYER_ID` as the business key.

`dim_player` stores:

- `EFF_START_TS`
- `EFF_END_TS`
- `IS_CURRENT`
- `HASH_DIFF`
- surrogate key `SK_PLAYER`

The tracked-attribute hash covers nationality, role, batting style, bowling style, and current team.

For delivery-to-player resolution, `fact_delivery` uses delivery `LOAD_TS` because the delivery feed does not provide a player-version event timestamp.

## Tests

Schema tests cover not-null, uniqueness, relationships, and delivery-level integrity/reconciliation checks.

The validated project completed **45/45 dbt data tests** successfully.

## Commands

Run from this directory:

```bash
dbt debug --profiles-dir .
dbt snapshot --profiles-dir .
dbt build --profiles-dir .
dbt test --profiles-dir .
```

For an incremental fact rebuild after logic changes:

```bash
dbt build --full-refresh --select fact_delivery+
```

## Configuration

`profiles.yml` reads connection settings from environment variables:

```text
SNOWFLAKE_ACCOUNT
SNOWFLAKE_USER
SNOWFLAKE_PASSWORD
SNOWFLAKE_ROLE
```

The committed profile contains no hard-coded credentials. Use `profiles.yml.example` as the local template and never commit secrets.

## Materialization

`dbt_project.yml` configures:

- Bronze → views
- Silver → tables
- Gold → tables
- Snapshots → `SILVER`

The DW layer in the parent project is implemented as compatibility views over the canonical dbt Silver objects.
