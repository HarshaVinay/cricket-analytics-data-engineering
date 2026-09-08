{{ config(materialized='table') }}

with venues as (
    select distinct VENUE_ID
    from {{ ref('stg_cricket_matches') }}
    where VENUE_ID is not null
)
select
    abs(hash(VENUE_ID)) as SK_VENUE,
    VENUE_ID,
    'Unknown' as VENUE_NAME,
    'Unknown' as CITY,
    'Unknown' as STATE,
    'Unknown' as COUNTRY,
    'Unknown' as REGION,
    'ACTIVE' as STATUS
from venues
union all
select 0, 'UNKNOWN', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'UNKNOWN'
where not exists (select 1 from venues where VENUE_ID = 'UNKNOWN')
