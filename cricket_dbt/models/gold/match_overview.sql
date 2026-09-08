{{ config(materialized='table') }}

select
    m.MATCH_ID,
    m.COMPETITION,
    m.FORMAT,
    m.MATCH_DATE,
    m.VENUE_ID,
    m.TEAM_A_ID,
    m.TEAM_B_ID,
    f.INNINGS_NO,
    sum(f.TOTAL_RUNS) as TOTAL_RUNS,
    sum(f.IS_WICKET) as WICKETS,
    sum(f.LEGAL_BALL) as LEGAL_BALLS,
    count(*) as DELIVERIES,
    sum(f.TOTAL_RUNS) / nullif(sum(f.LEGAL_BALL) / 6.0, 0) as RUN_RATE,
    100.0 * sum(f.IS_FOUR + f.IS_SIX) / nullif(count(*), 0) as BOUNDARY_PCT,
    100.0 * sum(f.IS_DOT_BALL) / nullif(count(*), 0) as DOT_BALL_PCT,
    sum(f.WIDES + f.NO_BALLS + f.BYES + f.LEG_BYES) as EXTRAS
from {{ ref('fact_delivery') }} f
join {{ ref('dim_match') }} m on m.SK_MATCH = f.SK_MATCH
group by 1,2,3,4,5,6,7,8
