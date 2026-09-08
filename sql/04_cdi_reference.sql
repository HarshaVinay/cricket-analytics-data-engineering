-- 04_cdi_reference.sql
-- Informatica CDI is the transformation/orchestration layer.
-- Parameters: $P_DB, $P_LOAD_DATE, $P_BATCH_ID

-- Player HASH_DIFF:
MD5(COALESCE(NATIONALITY,'') || '|' || COALESCE(ROLE,'') || '|' || COALESCE(BATTING_STYLE,'') || '|' || COALESCE(BOWLING_STYLE,'') || '|' || COALESCE(CURRENT_TEAM_ID,''))

-- Delivery phase:
CASE WHEN OVER_NO < 6 THEN 'POWERPLAY' WHEN OVER_NO < 15 THEN 'MIDDLE' ELSE 'DEATH' END

-- Flow:
-- DIM_DATE -> DIM_TEAM -> DIM_VENUE -> DIM_PLAYER_SCD2 -> DIM_MATCH -> FACT_DELIVERY.
-- Player lookup by PLAYER_ID where IS_CURRENT=TRUE.
-- Router: NEW / CHANGED / UNCHANGED / INVALID.
-- CHANGED: expire current row, then insert new current row.
-- NEW: insert current row. UNCHANGED: no action. INVALID: quarantine.
-- Fact lookups resolve match/team/player/date/venue SKs and use Unknown members when needed.
-- DELIVERY_ID provides idempotency.
