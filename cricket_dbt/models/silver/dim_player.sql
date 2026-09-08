{{ config(materialized='table') }}

with versions as (
    select
        PLAYER_ID,
        FIRST_NAME,
        LAST_NAME,
        NATIONALITY,
        BATTING_STYLE,
        BOWLING_STYLE,
        ROLE,
        CURRENT_TEAM_ID,
        STATUS,
        DBT_VALID_FROM::timestamp_ltz as EFF_START_TS,
        coalesce(DBT_VALID_TO::timestamp_ltz, '9999-12-31'::timestamp_ltz) as EFF_END_TS,
        iff(DBT_VALID_TO is null, true, false) as IS_CURRENT,
        md5(
            concat_ws(
                '|',
                coalesce(NATIONALITY, ''),
                coalesce(ROLE, ''),
                coalesce(BATTING_STYLE, ''),
                coalesce(BOWLING_STYLE, ''),
                coalesce(CURRENT_TEAM_ID, '')
            )
        ) as HASH_DIFF
    from {{ ref('snap_cricket_players') }}
)

select
    abs(hash(PLAYER_ID, EFF_START_TS)) as SK_PLAYER,
    PLAYER_ID,
    FIRST_NAME,
    LAST_NAME,
    NATIONALITY,
    BATTING_STYLE,
    BOWLING_STYLE,
    ROLE,
    CURRENT_TEAM_ID,
    STATUS,
    EFF_START_TS,
    EFF_END_TS,
    IS_CURRENT,
    HASH_DIFF
from versions

union all

select
    0 as SK_PLAYER,
    'UNKNOWN' as PLAYER_ID,
    'Unknown' as FIRST_NAME,
    'Unknown' as LAST_NAME,
    'Unknown' as NATIONALITY,
    'Unknown' as BATTING_STYLE,
    'Unknown' as BOWLING_STYLE,
    'Unknown' as ROLE,
    'UNKNOWN' as CURRENT_TEAM_ID,
    'UNKNOWN' as STATUS,
    '1900-01-01'::timestamp_ltz as EFF_START_TS,
    '9999-12-31'::timestamp_ltz as EFF_END_TS,
    true as IS_CURRENT,
    md5('UNKNOWN') as HASH_DIFF
where not exists (
    select 1
    from versions
    where PLAYER_ID = 'UNKNOWN'
)
