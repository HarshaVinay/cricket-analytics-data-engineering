{% snapshot snap_cricket_players %}

{{ config(
    target_schema='DW',
    unique_key='PLAYER_ID',
    strategy='timestamp',
    updated_at='UPDATED_AT',
    invalidate_hard_deletes=True
) }}

select
    PLAYER_ID,
    FIRST_NAME,
    LAST_NAME,
    NATIONALITY,
    BATTING_STYLE,
    BOWLING_STYLE,
    ROLE,
    CURRENT_TEAM_ID,
    STATUS,
    UPDATED_AT
from {{ ref('stg_cricket_players') }}

{% endsnapshot %}
