{{ config(materialized='table') }}

select
    abs(hash(TEAM_ID)) as SK_TEAM,
    TEAM_ID,
    TEAM_NAME,
    TEAM_CODE,
    COUNTRY,
    COMPETITION,
    REGION,
    ESTABLISHED_DATE,
    STATUS
from {{ ref('stg_cricket_teams') }}
union all
select 0, 'UNKNOWN', 'Unknown', null, null, null, null, null, 'UNKNOWN'
where not exists (select 1 from {{ ref('stg_cricket_teams') }} where TEAM_ID = 'UNKNOWN')
