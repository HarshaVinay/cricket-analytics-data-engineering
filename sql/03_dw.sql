-- 03_dw.sql
-- Canonical dimensions/fact are built by dbt in SILVER. These DW views preserve
-- the P2 warehouse naming contract without maintaining a second copy of the data.
-- Run after `dbt build`.
USE DATABASE CRICKET_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS CRICKET_ANALYTICS.DW;

CREATE OR REPLACE VIEW DW.DIM_DATE AS SELECT * FROM SILVER.DIM_DATE;
CREATE OR REPLACE VIEW DW.DIM_TEAM AS SELECT * FROM SILVER.DIM_TEAM;
CREATE OR REPLACE VIEW DW.DIM_VENUE AS SELECT * FROM SILVER.DIM_VENUE;
CREATE OR REPLACE VIEW DW.DIM_PLAYER AS SELECT * FROM SILVER.DIM_PLAYER;
CREATE OR REPLACE VIEW DW.DIM_MATCH AS SELECT * FROM SILVER.DIM_MATCH;
CREATE OR REPLACE VIEW DW.FACT_DELIVERY AS SELECT * FROM SILVER.FACT_DELIVERY;

-- Unknown members are created by the dbt Silver models.
-- Keeping DW as views avoids duplicate storage and conflicting SCD2 implementations.
