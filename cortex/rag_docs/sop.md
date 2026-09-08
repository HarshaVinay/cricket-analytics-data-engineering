# SOP

Land each entity under its entity-specific landing folder. Snowpipe loads valid records into RAW. Monitor load history and reject counts. Invalid files/records are routed to quarantine and recorded in OPS.REJECTS. CDI loads dimensions before FACT_DELIVERY. Dashboard and NLQ consumers use SEM views only.
