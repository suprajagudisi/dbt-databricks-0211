{{
  config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='event_date',
    on_schema_change='fail'
  )
}}

/*
  INSERT_OVERWRITE Alternative for Snowflake
  
  Snowflake doesn't support INSERT_OVERWRITE natively.
  This is the recommended pattern to achieve similar behavior.
  
  If you're migrating from BigQuery/Databricks:
  - BigQuery: incremental_strategy='insert_overwrite'
  - Databricks: incremental_strategy='insert_overwrite'
  - Snowflake: incremental_strategy='delete+insert' (this pattern)
  
  Result: Atomic replacement of date partitions
*/

SELECT
    event_date,
    COUNT(DISTINCT event_id) as num_events,
    COUNT(DISTINCT user_id) as num_users,
    SUM(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) as num_purchases,
    SUM(CASE WHEN event_name = 'view' THEN 1 ELSE 0 END) as num_views,
    SUM(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) as num_cart_adds,
    SUM(amount) as total_transaction_value,
    MAX(event_timestamp) as last_event_time

FROM {{ ref('events') }}

{% if is_incremental() %}
  -- Process only last 2 days
  WHERE event_date >= CURRENT_DATE() - 2
{% endif %}

GROUP BY event_date

ORDER BY event_date DESC
