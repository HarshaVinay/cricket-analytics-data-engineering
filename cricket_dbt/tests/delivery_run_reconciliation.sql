select *
from {{ ref('fact_delivery') }}
where TOTAL_RUNS <> BATSMAN_RUNS + WIDES + NO_BALLS + BYES + LEG_BYES
