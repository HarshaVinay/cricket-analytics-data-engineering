{{ config(
    materialized='incremental',
    unique_key='DELIVERY_ID',
    incremental_strategy='merge'
) }}

SELECT
    DELIVERY_ID,
    MATCH_ID,
    INNINGS_NO,
    OVER_NO,
    BALL_NO,
    BATTING_TEAM_ID,
    BOWLING_TEAM_ID,
    STRIKER_PLAYER_ID,
    NON_STRIKER_PLAYER_ID,
    BOWLER_PLAYER_ID,
    BATSMAN_RUNS,
    WIDES,
    NO_BALLS,
    BYES,
    LEG_BYES,
    TOTAL_RUNS,
    IS_WICKET,
    DISMISSAL_TYPE,
    IS_FOUR,
    IS_SIX,
    IS_DOT_BALL,
    UPDATED_AT

FROM {{ ref('stg_deliveries') }}

{% if is_incremental() %}

WHERE UPDATED_AT > (
    SELECT COALESCE(MAX(UPDATED_AT), '1900-01-01'::TIMESTAMP)
    FROM {{ this }}
)

{% endif %}