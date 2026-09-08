{{ config(materialized='view') }}

select
    DELIVERY_ID,
    MATCH_ID,
    INNINGS_NO,
    OVER_NO,
    BALL_NO,
    BATTING_TEAM_ID,
    BOWLING_TEAM_ID,
    STRIKER_PLAYER_ID,
    NON_STRIKER_PLAYER_ID,
    BOWLER_PLAYER_ID,
    BATSMAN_RUNS,
    WIDES,
    NO_BALLS,
    BYES,
    LEG_BYES,
    TOTAL_RUNS,
    IS_WICKET,
    DISMISSAL_TYPE,
    IS_FOUR,
    IS_SIX,
    IS_DOT_BALL,
    case
        when OVER_NO between 1 and 6 then 'POWERPLAY'
        when OVER_NO between 7 and 15 then 'MIDDLE'
        else 'DEATH'
    end as OVER_PHASE,
    try_to_timestamp_ntz(UPDATED_AT) as UPDATED_AT,
    LOAD_TS,
    FILE_NAME,
    ROW_NUMBER
from {{ source('cricket_raw', 'RAW_DELIVERIES') }}
where DELIVERY_ID is not null
