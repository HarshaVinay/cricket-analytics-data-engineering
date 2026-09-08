{{ config(materialized='view') }}

select
    TEAM_ID,
    TEAM_NAME,
    TEAM_CODE,
    COUNTRY,
    COMPETITION,
    REGION,
    try_to_date(ESTABLISHED_DATE) as ESTABLISHED_DATE,
    STATUS,
    LOAD_TS,
    FILE_NAME,
    ROW_NUMBER
from {{ source('cricket_raw', 'RAW_TEAMS') }}
where TEAM_ID is not null
