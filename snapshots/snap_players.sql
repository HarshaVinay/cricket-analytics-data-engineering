{% snapshot snap_players %}

{{
    config(
        target_schema='DW',
        unique_key='PLAYER_ID',
        strategy='timestamp',
        updated_at='UPDATED_AT'
    )
}}

SELECT
    PLAYER_ID,
    FIRST_NAME,
    LAST_NAME,
    NATIONALITY,
    BATTING_STYLE,
    BOWLING_STYLE,
    ROLE,
    CURRENT_TEAM_ID,
    CONTRACT_START,
    STATUS,
    UPDATED_AT
FROM {{ ref('stg_players') }}

{% endsnapshot %}