# Cricket dbt Project

This dbt project transforms Snowflake RAW cricket feeds into the P2 star schema and analytics marts.

## Run order

```bash
dbt debug --profiles-dir .
dbt snapshot --profiles-dir .
dbt build --profiles-dir .
```

## Layers

- `staging/` — type cleanup and delivery phase derivation
- `dimensions/` — date, team, venue, player SCD2 and match dimensions
- `facts/` — incremental `FACT_DELIVERY`, one row per `DELIVERY_ID`
- `marts/` — match, player, team/venue and phase analytics
- `snapshots/` — player SCD Type 2 history
- `tests/` — dbt data-quality assertions

Copy `profiles.yml.example` to a local `profiles.yml` and provide Snowflake credentials through your local environment. Do not commit credentials.
