{{ config(materialized='table') }}

select
    t.TEAM_ID,
    t.TEAM_NAME,
    m.VENUE_ID,
    m.FORMAT,
    count(distinct m.MATCH_ID) as MATCHES,
    count(distinct iff(m.WINNER_TEAM_ID = t.TEAM_ID, m.MATCH_ID, null)) as WINS,
    sum(f.TOTAL_RUNS) as RUNS,
    sum(f.IS_WICKET) as WICKETS,
    6.0 * sum(f.TOTAL_RUNS) / nullif(sum(f.LEGAL_BALL),0) as RUN_RATE
from {{ ref('fact_delivery') }} f
join {{ ref('dim_match') }} m on m.SK_MATCH = f.SK_MATCH
join {{ ref('dim_team') }} t on t.SK_TEAM = f.SK_BATTING_TEAM
group by 1,2,3,4
