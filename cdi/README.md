# Informatica CDI implementation

This directory contains the CDI design required by P2. Executable Informatica tenant metadata is account/environment specific, so the repository contains the mapping and taskflow specification rather than pretending to contain portable tenant objects.

## Taskflow

`tf_cricket_dw`: `m_dim_date_load -> m_dim_team_load -> m_dim_venue_load -> m_dim_player_scd2 -> m_dim_match_load -> m_fact_delivery_load -> m_dq_post_load -> m_load_audit_close`

## Transformations

Source, Expression, Lookup, Router, Filter, Joiner, Target.

## Player SCD2 router

NEW, CHANGED, UNCHANGED, INVALID. Changed rows expire the current record and insert a new current record.

## Parameters

`$P_DB`, `$P_LOAD_DATE`, `$P_BATCH_ID`
