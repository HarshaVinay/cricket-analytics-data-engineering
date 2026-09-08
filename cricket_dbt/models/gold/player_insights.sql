{{ config(materialized='table') }}

with batting as (
    select
        f.SK_STRIKER as SK_PLAYER,
        sum(f.BATSMAN_RUNS) as RUNS,
        sum(f.LEGAL_BALL) as BALLS_FACED,
        sum(f.IS_FOUR) as FOURS,
        sum(f.IS_SIX) as SIXES,
        100.0 * sum(f.BATSMAN_RUNS) / nullif(sum(f.LEGAL_BALL),0) as STRIKE_RATE
    from {{ ref('fact_delivery') }} f
    group by 1
),
bowling as (
    select
        f.SK_BOWLER as SK_PLAYER,
        sum(f.TOTAL_RUNS - f.BYES - f.LEG_BYES) as RUNS_CONCEDED,
        sum(f.LEGAL_BALL) as BALLS_BOWLED,
        sum(f.IS_WICKET) as WICKETS,
        6.0 * sum(f.TOTAL_RUNS - f.BYES - f.LEG_BYES) / nullif(sum(f.LEGAL_BALL),0) as ECONOMY
    from {{ ref('fact_delivery') }} f
    group by 1
)
select
    p.SK_PLAYER,
    p.PLAYER_ID,
    p.FIRST_NAME,
    p.LAST_NAME,
    coalesce(b.RUNS,0) as RUNS,
    coalesce(b.BALLS_FACED,0) as BALLS_FACED,
    coalesce(b.FOURS,0) as FOURS,
    coalesce(b.SIXES,0) as SIXES,
    coalesce(b.STRIKE_RATE,0) as STRIKE_RATE,
    coalesce(w.WICKETS,0) as WICKETS,
    coalesce(w.RUNS_CONCEDED,0) as RUNS_CONCEDED,
    coalesce(w.BALLS_BOWLED,0) as BALLS_BOWLED,
    coalesce(w.ECONOMY,0) as ECONOMY
from {{ ref('dim_player') }} p
left join batting b on b.SK_PLAYER = p.SK_PLAYER
left join bowling w on w.SK_PLAYER = p.SK_PLAYER
where p.IS_CURRENT = true
