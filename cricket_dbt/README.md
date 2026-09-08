# Cricket dbt Project

This dbt project independently implements the Cricket Analytics Medallion architecture on top of the Snowflake RAW ingestion layer.

## Medallion layers

```text
Snowflake RAW
     |
     v
Bronze  -> standardized source data
     |
     v
Silver  -> conformed dimensions + delivery fact
     |
     v
Gold    -> business analytics models
```

### Bronze

- `br_cricket_teams`
- `br_cricket_players`
- `br_cricket_matches`
- `br_cricket_deliveries`

Bronze models standardize datatypes, retain ingestion metadata, and derive delivery phase information.

### Silver

- `dim_date`
- `dim_team`
- `dim_venue`
- `dim_player`
- `dim_match`
- `fact_delivery`

`dim_player` is SCD Type 2 and tracks nationality, role, batting style, bowling style, and current team. `fact_delivery` is maintained at one row per `DELIVERY_ID`.

### Gold

- `match_overview`
- `player_insights`
- `team_venue_analytics`
- `phase_analytics`

These models provide the business-ready cricket analytics used for reporting and downstream application consumption.

## Run order

```bash
dbt debug --profiles-dir .
dbt snapshot --profiles-dir .
dbt build --profiles-dir .
```

`dbt snapshot` captures player history before the Silver player dimension is rebuilt. `dbt build` then executes models and tests according to dbt's dependency graph.

## Configuration

`dbt_project.yml` materializes Bronze as views and Silver/Gold as tables in `BRONZE`, `SILVER`, and `GOLD` schemas.

Copy `profiles.yml.example` to a local `profiles.yml` and provide Snowflake credentials through your local environment. Do not commit credentials.
