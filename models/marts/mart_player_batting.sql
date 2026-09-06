{{ config(materialized='table') }}

SELECT
    p.PLAYER_ID,
    p.FIRST_NAME,
    p.LAST_NAME,
    p.CURRENT_TEAM_ID,
    p.ROLE,

    COUNT(d.DELIVERY_ID) AS BALLS_FACED,

    SUM(COALESCE(d.BATSMAN_RUNS, 0)) AS RUNS,

    SUM(
        CASE
            WHEN d.IS_FOUR = TRUE THEN 1
            ELSE 0
        END
    ) AS FOURS,

    SUM(
        CASE
            WHEN d.IS_SIX = TRUE THEN 1
            ELSE 0
        END
    ) AS SIXES,

    SUM(
        CASE
            WHEN d.IS_DOT_BALL = TRUE THEN 1
            ELSE 0
        END
    ) AS DOT_BALLS,

    SUM(
        CASE
            WHEN d.IS_WICKET = TRUE
             AND d.STRIKER_PLAYER_ID = p.PLAYER_ID
            THEN 1
            ELSE 0
        END
    ) AS DISMISSALS

FROM {{ ref('stg_players') }} p

LEFT JOIN {{ ref('stg_deliveries') }} d
    ON p.PLAYER_ID = d.STRIKER_PLAYER_ID

GROUP BY
    p.PLAYER_ID,
    p.FIRST_NAME,
    p.LAST_NAME,
    p.CURRENT_TEAM_ID,
    p.ROLE