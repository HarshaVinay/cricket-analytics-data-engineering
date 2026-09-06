USE DATABASE CRICKET_ANALYTICS_DB;

-- Pruning-friendly filter
SELECT MATCH_DATE, COUNT(*)
FROM DW.DIM_MATCH
WHERE MATCH_DATE >= '2026-01-01'
GROUP BY MATCH_DATE;

-- Query profile should be inspected in Snowsight after execution.
-- Use clustering only when data volume and filter patterns justify it.
