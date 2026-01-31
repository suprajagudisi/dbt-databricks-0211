{{
  config(
    materialized='incremental',
    incremental_strategy='append',
    file_format='delta',
    partition_by='event_date',
    cluster_by=['user_id', 'event_name'],
    post_hook=[
      "OPTIMIZE {{ this }} WHERE event_date >= CURRENT_DATE() - INTERVAL 7 DAYS",
      "ANALYZE TABLE {{ this }} COMPUTE STATISTICS FOR ALL COLUMNS"
    ],
    on_schema_change='fail'
  )
}}

-- Fully Optimized Delta Lake Table

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
  WHERE event_timestamp > (
    SELECT MAX(event_timestamp) - INTERVAL 10 MINUTES
    FROM {{ this }}
  )
  AND event_timestamp IS NOT NULL
{% endif %}

ORDER BY event_timestamp
