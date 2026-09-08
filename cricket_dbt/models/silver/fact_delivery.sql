{{ config(materialized='incremental', unique_key='DELIVERY_ID', on_schema_change='sync_all_columns') }}

with src as (
    select * from {{ ref('br_cricket_deliveries') }}
    {% if is_incremental() %}
    where UPDATED_AT >= (select coalesce(max(UPDATED_AT), '1900-01-01') from {{ this }})
       or DELIVERY_ID not in (select DELIVERY_ID from {{ this }})
    {% endif %}
)
select
    s.DELIVERY_ID,
    s.MATCH_ID,
    coalesce(d.SK_DATE, 0) as SK_DATE,
    coalesce(m.SK_MATCH, 0) as SK_MATCH,
    coalesce(v.SK_VENUE, 0) as SK_VENUE,
    coalesce(bt.SK_TEAM, 0) as SK_BATTING_TEAM,
    coalesce(bw.SK_TEAM, 0) as SK_BOWLING_TEAM,
    coalesce(sp.SK_PLAYER, 0) as SK_STRIKER,
    coalesce(np.SK_PLAYER, 0) as SK_NON_STRIKER,
    coalesce(bp.SK_PLAYER, 0) as SK_BOWLER,
    s.INNINGS_NO,
    s.OVER_NO,
    s.BALL_NO,
    s.OVER_PHASE,
    s.BATSMAN_RUNS,
    s.WIDES,
    s.NO_BALLS,
    s.BYES,
    s.LEG_BYES,
    s.TOTAL_RUNS,
    s.IS_WICKET,
    s.DISMISSAL_TYPE,
    s.IS_FOUR,
    s.IS_SIX,
    s.IS_DOT_BALL,
    s.UPDATED_AT,
    s.LOAD_TS,
    md5(concat_ws('|', s.DELIVERY_ID, s.MATCH_ID, s.INNINGS_NO, s.OVER_NO, s.BALL_NO)) as RECORD_HASH
from src s
left join {{ ref('dim_match') }} m on m.MATCH_ID = s.MATCH_ID
left join {{ ref('dim_date') }} d on d.DATE_VALUE = m.MATCH_DATE
left join {{ ref('dim_venue') }} v on v.SK_VENUE = m.SK_VENUE
left join {{ ref('dim_team') }} bt on bt.TEAM_ID = coalesce(s.BATTING_TEAM_ID, 'UNKNOWN')
left join {{ ref('dim_team') }} bw on bw.TEAM_ID = coalesce(s.BOWLING_TEAM_ID, 'UNKNOWN')
left join {{ ref('dim_player') }} sp on sp.PLAYER_ID = coalesce(s.STRIKER_PLAYER_ID, 'UNKNOWN')
    and coalesce(s.UPDATED_AT, '9999-12-31') >= sp.EFF_START_TS
    and coalesce(s.UPDATED_AT, '9999-12-31') < sp.EFF_END_TS
left join {{ ref('dim_player') }} np on np.PLAYER_ID = coalesce(s.NON_STRIKER_PLAYER_ID, 'UNKNOWN')
    and coalesce(s.UPDATED_AT, '9999-12-31') >= np.EFF_START_TS
    and coalesce(s.UPDATED_AT, '9999-12-31') < np.EFF_END_TS
left join {{ ref('dim_player') }} bp on bp.PLAYER_ID = coalesce(s.BOWLER_PLAYER_ID, 'UNKNOWN')
    and coalesce(s.UPDATED_AT, '9999-12-31') >= bp.EFF_START_TS
    and coalesce(s.UPDATED_AT, '9999-12-31') < bp.EFF_END_TS
