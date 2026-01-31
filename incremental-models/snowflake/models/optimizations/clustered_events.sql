{{
  config(
    materialized='incremental',
    incremental_strategy='append',
    on_schema_change='fail',
    query_tag='dbt_incremental_events'
  )
}}

/*
  Snowflake Clustering Best Practices
  
  Clustering optimizes for queries filtering on:
  - event_date AND user_id (primary clustering)
  - Improves scan performance
  - Helps with range queries
  - Automatic maintenance (Snowflake handles)
  
  Note: Use post-hooks to add clustering keys after table creation
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
  WHERE event_timestamp > (
    SELECT DATEADD('minute', -10, MAX(event_timestamp))
    FROM {{ this }}
  )
  AND event_timestamp IS NOT NULL
{% endif %}

ORDER BY event_timestamp
