{{ config(materialized='table') }}

with dates as (
    select distinct MATCH_DATE as DATE_VALUE
    from {{ ref('br_cricket_matches') }}
    where MATCH_DATE is not null
)
select
    abs(hash(DATE_VALUE)) as SK_DATE,
    DATE_VALUE,
    year(DATE_VALUE) as YEAR,
    quarter(DATE_VALUE) as QUARTER,
    month(DATE_VALUE) as MONTH,
    monthname(DATE_VALUE) as MONTH_NAME,
    weekofyear(DATE_VALUE) as WEEK_OF_YEAR,
    day(DATE_VALUE) as DAY_OF_MONTH,
    dayname(DATE_VALUE) as DAY_NAME,
    iff(dayofweekiso(DATE_VALUE) in (6,7), true, false) as IS_WEEKEND
from dates
union all
select 0, '1900-01-01'::date, 1900, 1, 1, 'January', 1, 1, 'Monday', false
where not exists (select 1 from dates where DATE_VALUE = '1900-01-01'::date)
