{{ config(materialized='view') }}

select
    PLAYER_ID,
    FIRST_NAME,
    LAST_NAME,
    NATIONALITY,
    BATTING_STYLE,
    BOWLING_STYLE,
    ROLE,
    CURRENT_TEAM_ID,
    try_to_date(CONTRACT_START) as CONTRACT_START,
    STATUS,
    try_to_timestamp_ntz(UPDATED_AT) as UPDATED_AT,
    LOAD_TS,
    FILE_NAME,
    ROW_NUMBER
from {{ source('cricket_raw', 'RAW_PLAYERS') }}
where PLAYER_ID is not null
