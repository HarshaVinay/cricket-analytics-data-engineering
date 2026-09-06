{{ config(materialized='table') }}

SELECT
    m.MATCH_ID,
    m.COMPETITION,
    m.FORMAT,
    m.MATCH_DATE,
    m.VENUE_ID,
    m.TEAM_A_ID,
    m.TEAM_B_ID,
    m.WINNER_TEAM_ID,
    m.RESULT_TYPE,
    m.RESULT_MARGIN,

    COUNT(d.DELIVERY_ID) AS TOTAL_DELIVERIES,

    SUM(COALESCE(d.TOTAL_RUNS, 0)) AS TOTAL_RUNS,

    SUM(
        CASE
            WHEN d.IS_FOUR = TRUE THEN 1
            ELSE 0
        END
    ) AS TOTAL_FOURS,

    SUM(
        CASE
            WHEN d.IS_SIX = TRUE THEN 1
            ELSE 0
        END
    ) AS TOTAL_SIXES,

    SUM(
        CASE
            WHEN d.IS_WICKET = TRUE THEN 1
            ELSE 0
        END
    ) AS TOTAL_WICKETS,

    SUM(
        CASE
            WHEN d.IS_DOT_BALL = TRUE THEN 1
            ELSE 0
        END
    ) AS TOTAL_DOT_BALLS

FROM {{ ref('stg_matches') }} m

LEFT JOIN {{ ref('stg_deliveries') }} d
    ON m.MATCH_ID = d.MATCH_ID

GROUP BY
    m.MATCH_ID,
    m.COMPETITION,
    m.FORMAT,
    m.MATCH_DATE,
    m.VENUE_ID,
    m.TEAM_A_ID,
    m.TEAM_B_ID,
    m.WINNER_TEAM_ID,
    m.RESULT_TYPE,
    m.RESULT_MARGIN