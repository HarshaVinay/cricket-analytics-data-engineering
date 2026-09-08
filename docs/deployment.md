# Deployment

## 1. Snowflake foundation

1. Run `sql/00_setup.sql`.
2. Run `sql/01_raw.sql`.
3. Configure the landing stage and cloud notification integration appropriate to the Snowflake account.
4. Run `sql/02_snowpipe.sql`.

## 2. Load and validate source data

5. Upload the four CSV feeds under the entity folders in `/landing/cricket_analytics/` to the corresponding stage prefixes.
6. For manual/internal-stage loading, run the `ALTER PIPE ... REFRESH` statements documented in `sql/02_snowpipe.sql`.
7. Run the validation/quarantine workflow in `sql/09_dq_quarantine.sql`.
8. Review `OPS.REJECTS`, `OPS.QUARANTINE_AUDIT` and Snowpipe load history before continuing.

## 3. dbt transformation

9. Set `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD` and `SNOWFLAKE_ROLE` in the execution environment.
10. Copy `cricket_dbt/profiles.yml.example` to `profiles.yml` only when a local profile is required; the repository profile already uses environment variables.
11. From `cricket_dbt/`, run:

```bash
dbt debug --profiles-dir .
dbt snapshot --profiles-dir .
dbt build --profiles-dir .
```

12. Confirm the Bronze, Silver and Gold schemas contain the expected objects.

## 4. Semantic and security layer

13. Run `sql/05_semantic.sql` to expose controlled SEM views over the dbt Gold/Silver models.
14. Run `sql/07_security.sql` to apply role-based access.
15. Run `sql/08_dq_ops.sql` for operational validation and `OPS.LOAD_AUDIT` management.

## 5. Orchestration

16. Configure the Airflow environment variables for Snowflake.
17. Start Airflow from `airflow/` with Docker Compose.
18. Enable `cricket_dbt_pipeline` and monitor snapshot/build/test outcomes.

## 6. Streamlit

19. Configure the Streamlit Snowflake connection using the application role.
20. Start `streamlit_app/app.py`.
21. Verify Match Overview, Player Insights, Team/Venue and Explorer pages.

## Production notes

- Keep credentials out of Git.
- Use separate DEV/TEST/PROD credentials and schemas/roles.
- Keep RAW restricted to ingestion/ETL roles.
- Expose analytics applications through SEM rather than direct RAW access.
- Move known bad files to the quarantine stage only after recording the operational audit.
- The supplied match feed has no independent score-summary totals, so match-summary reconciliation must remain explicitly unavailable until such a source is provided.
