{{ config(materialized='view') }}

select
    MATCH_ID,
    COMPETITION,
    FORMAT,
    try_to_date(MATCH_DATE) as MATCH_DATE,
    VENUE_ID,
    TEAM_A_ID,
    TEAM_B_ID,
    TOSS_WINNER_TEAM_ID,
    TOSS_DECISION,
    WINNER_TEAM_ID,
    RESULT_TYPE,
    RESULT_MARGIN,
    MATCH_STATUS,
    try_to_timestamp_ntz(UPDATED_AT) as UPDATED_AT,
    LOAD_TS,
    FILE_NAME,
    ROW_NUMBER
from {{ source('cricket_raw', 'RAW_MATCHES') }}
where MATCH_ID is not null
