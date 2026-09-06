{{ config(materialized='view') }}

SELECT
    TEAM_ID,
    TEAM_NAME,
    TEAM_CODE,
    COUNTRY,
    COMPETITION,
    REGION,
    ESTABLISHED_DATE,
    STATUS
FROM {{ source('raw', 'raw_teams') }}