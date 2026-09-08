# CDI Mapping Specification

| Mapping | Source | Target | Logic |
|---|---|---|---|
| m_dim_date_load | RAW_MATCHES.MATCH_DATE | DW.DIM_DATE | calendar attributes |
| m_dim_team_load | RAW_TEAMS | DW.DIM_TEAM | Type 1 upsert by TEAM_ID |
| m_dim_venue_load | RAW_MATCHES.VENUE_ID | DW.DIM_VENUE | Type 1 upsert; Unknown member |
| m_dim_player_scd2 | RAW_PLAYERS | DW.DIM_PLAYER | HASH_DIFF + SCD2 |
| m_dim_match_load | RAW_MATCHES + dimensions | DW.DIM_MATCH | surrogate-key lookups |
| m_fact_delivery_load | RAW_DELIVERIES + dimensions | DW.FACT_DELIVERY | surrogate-key lookups + derived phase |

Player HASH_DIFF: `MD5(NATIONALITY || '|' || ROLE || '|' || BATTING_STYLE || '|' || BOWLING_STYLE || '|' || CURRENT_TEAM_ID)`.

Player lookup uses `PLAYER_ID` with `IS_CURRENT=TRUE`. Router outputs NEW/CHANGED/UNCHANGED/INVALID.

Fact lookups resolve match/date/venue/team/player SKs. `OVER_PHASE` is POWERPLAY for overs < 6, MIDDLE for overs < 15, otherwise DEATH. `DELIVERY_ID` is the idempotency key.
