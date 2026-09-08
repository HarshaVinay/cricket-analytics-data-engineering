-- 08_dq_ops.sql
USE DATABASE CRICKET_ANALYTICS;

CREATE TABLE IF NOT EXISTS OPS.LOAD_AUDIT (
    BATCH_ID VARCHAR,
    ENTITY VARCHAR,
    LOAD_TS TIMESTAMP_LTZ,
    SOURCE_FILE VARCHAR,
    SOURCE_ROW_COUNT NUMBER,
    RAW_ROW_COUNT NUMBER,
    SILVER_ROW_COUNT NUMBER,
    GOLD_ROW_COUNT NUMBER,
    REJECT_COUNT NUMBER,
    STATUS VARCHAR,
    MESSAGE VARCHAR
);

-- Duplicate delivery check
SELECT DELIVERY_ID, COUNT(*) AS CNT
FROM SILVER.FACT_DELIVERY
GROUP BY DELIVERY_ID
HAVING COUNT(*) > 1;

-- Delivery reference check
SELECT f.DELIVERY_ID
FROM SILVER.FACT_DELIVERY f
JOIN SILVER.DIM_PLAYER p ON f.SK_STRIKER = p.SK_PLAYER
WHERE p.PLAYER_ID = 'UNKNOWN' AND f.SK_STRIKER <> 0;

-- Delivery run reconciliation
SELECT DELIVERY_ID
FROM SILVER.FACT_DELIVERY
WHERE TOTAL_RUNS <> BATSMAN_RUNS + WIDES + NO_BALLS + BYES + LEG_BYES;

-- Match-summary reconciliation is NOT_AVAILABLE for the supplied source because
-- the match feed has no independent score-summary totals.

-- Ball/over completeness is validated against feed rules. Wides/no-balls are
-- retained as deliveries but excluded from LEGAL_BALL calculations.

-- Snowpipe load errors are reviewed with COPY_HISTORY / VALIDATE and captured
-- in OPS.REJECTS. Bad files are copied to the quarantine stage after audit.
