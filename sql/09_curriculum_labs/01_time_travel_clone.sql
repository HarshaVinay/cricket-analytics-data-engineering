-- Curriculum lab: Time Travel and zero-copy cloning.
USE DATABASE CRICKET_ANALYTICS_DB;

CREATE OR REPLACE TABLE DW.DIM_TEAM_CLONE
CLONE DW.DIM_TEAM;

-- Example inspection after an accidental change:
-- SELECT * FROM DW.DIM_TEAM AT (OFFSET => -60*5);
-- Restore into a new table rather than destroying the original during a lab.
