# Deployment

1. Run `sql/00_setup.sql`.
2. Run `sql/01_raw.sql`.
3. Configure the external stage URL/integration for landing storage.
4. Run `sql/02_snowpipe.sql` and connect each pipe to the storage event notification.
5. Configure Informatica CDI connection to Snowflake.
6. Create CDI mappings/taskflow from `cdi/`.
7. Run `sql/03_dw.sql`.
8. Deploy CDI with dimensions before FACT_DELIVERY.
9. Run `sql/05_semantic.sql` and `sql/07_security.sql`.
10. Load `cortex/rag_docs/` into `CORTEX.RAG_DOCUMENTS`, then run `sql/06_cortex.sql`.
11. Create the Cortex Analyst semantic view from `cortex/semantic_views/cricket_analytics.yaml`.
12. Deploy Streamlit from `streamlit_app/`.
