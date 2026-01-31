{{
  config(
    materialized='incremental',
    incremental_strategy='append',
    on_schema_change='fail',
    unique_constraints=['event_id']
  )
}}

/*
  APPEND Strategy on Snowflake
  
  Perfect for:
  - Immutable event logs
  - Insert-only data patterns
  - High-volume appends
  
  Benefits:
  - Fastest incremental strategy
  - Lowest compute cost
  - Simple logic
  
  Gotchas to avoid:
  - Clock skew between systems (add buffer)
  - NULL timestamps (breaks MAX filter)
  - Source data retries causing duplicates
*/

SELECT
    event_id,
    user_id,
    event_name,
    event_timestamp,
    product_id,
    amount,
    event_date,
    CURRENT_TIMESTAMP() as processed_at

FROM {{ ref('events') }}

{% if is_incremental() %}
  -- Only process events since last run
  WHERE event_timestamp > (
    -- Add 10-minute buffer for clock skew between systems
    SELECT DATEADD('minute', -10, MAX(event_timestamp))
    FROM {{ this }}
  )
  -- CRITICAL: Ensure no NULL timestamps
  -- NULL breaks MAX comparison
  AND event_timestamp IS NOT NULL
{% endif %}

ORDER BY event_timestamp
