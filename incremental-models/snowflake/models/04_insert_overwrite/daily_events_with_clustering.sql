{{
  config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='event_date',
    on_schema_change='fail'
  )
}}

/*
  INSERT_OVERWRITE Pattern with Clustering
  
  Snowflake Clustering:
  - Use post-hooks to add clustering after table creation
  - Automatically orders data by specified columns
  - Improves query performance (automatic)
  - No manual maintenance needed
  - Ideal for date + user_id combinations
*/

SELECT
    event_date,
    user_id,
    event_name,
    COUNT(*) as event_count,
    SUM(amount) as total_amount,
    MIN(event_timestamp) as first_event,
    MAX(event_timestamp) as last_event,
    CURRENT_TIMESTAMP() as processed_at

FROM {{ ref('events') }}

{% if is_incremental() %}
  WHERE event_date >= CURRENT_DATE() - 1
{% endif %}

GROUP BY event_date, user_id, event_name

ORDER BY event_date DESC, total_amount DESC
