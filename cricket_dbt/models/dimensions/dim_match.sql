{{ config(materialized='table') }}

select
    abs(hash(m.MATCH_ID)) as SK_MATCH,
    m.MATCH_ID,
    m.COMPETITION,
    m.FORMAT,
    m.MATCH_DATE,
    coalesce(d.SK_DATE, 0) as SK_DATE,
    coalesce(v.SK_VENUE, 0) as SK_VENUE,
    coalesce(v.VENUE_ID, 'UNKNOWN') as VENUE_ID,
    m.TEAM_A_ID,
    coalesce(ta.SK_TEAM, 0) as SK_TEAM_A,
    m.TEAM_B_ID,
    coalesce(tb.SK_TEAM, 0) as SK_TEAM_B,
    m.TOSS_WINNER_TEAM_ID,
    m.WINNER_TEAM_ID,
    m.RESULT_TYPE,
    m.RESULT_MARGIN,
    m.MATCH_STATUS
from {{ ref('stg_cricket_matches') }} m
left join {{ ref('dim_date') }} d on d.DATE_VALUE = m.MATCH_DATE
left join {{ ref('dim_venue') }} v on v.VENUE_ID = coalesce(m.VENUE_ID, 'UNKNOWN')
left join {{ ref('dim_team') }} ta on ta.TEAM_ID = coalesce(m.TEAM_A_ID, 'UNKNOWN')
left join {{ ref('dim_team') }} tb on tb.TEAM_ID = coalesce(m.TEAM_B_ID, 'UNKNOWN')
