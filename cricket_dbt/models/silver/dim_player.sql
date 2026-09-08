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
        DBT_VALID_FROM as EFF_START_TS,
        coalesce(DBT_VALID_TO, '9999-12-31'::timestamp_ntz) as EFF_END_TS,
        iff(DBT_VALID_TO is null, true, false) as IS_CURRENT,
        md5(concat_ws('|', coalesce(NATIONALITY,''), coalesce(ROLE,''), coalesce(BATTING_STYLE,''), coalesce(CURRENT_TEAM_ID,''))) as HASH_DIFF
    from {{ ref('snap_cricket_players') }}
)
select
    abs(hash(PLAYER_ID, EFF_START_TS)) as SK_PLAYER,
    *
from versions
union all
select 0, 'UNKNOWN', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'UNKNOWN', 'UNKNOWN', '1900-01-01'::timestamp_ntz, '9999-12-31'::timestamp_ntz, true, md5('UNKNOWN')
where not exists (select 1 from versions where PLAYER_ID = 'UNKNOWN')
