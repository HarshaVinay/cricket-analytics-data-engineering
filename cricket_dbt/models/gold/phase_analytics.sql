{{ config(materialized='table') }}

select
    m.MATCH_ID,
    m.FORMAT,
    f.INNINGS_NO,
    f.OVER_PHASE,
    sum(f.TOTAL_RUNS) as TOTAL_RUNS,
    sum(f.IS_WICKET) as WICKETS,
    sum(f.LEGAL_BALL) as LEGAL_BALLS,
    count(*) as DELIVERIES,
    6.0 * sum(f.TOTAL_RUNS) / nullif(sum(f.LEGAL_BALL),0) as RUN_RATE,
    100.0 * sum(f.IS_DOT_BALL) / nullif(count(*),0) as DOT_BALL_PCT,
    100.0 * sum(f.IS_FOUR + f.IS_SIX) / nullif(count(*),0) as BOUNDARY_PCT
from {{ ref('fact_delivery') }} f
join {{ ref('dim_match') }} m on m.SK_MATCH = f.SK_MATCH
group by 1,2,3,4
