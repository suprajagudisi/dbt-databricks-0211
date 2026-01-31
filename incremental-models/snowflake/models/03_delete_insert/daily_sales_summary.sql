{{
  config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='sale_date',
    on_schema_change='fail'
  )
}}

/*
  DELETE+INSERT Strategy on Snowflake
  
  Perfect for:
  - Daily aggregations (recalculate entire day)
  - Hourly rollups
  - Periodic snapshots
  
  How it works:
  1. DELETE records matching the WHERE clause
  2. INSERT fresh data
  
  CRITICAL GOTCHA:
  - Not atomic by default on Snowflake
  - DELETE succeeds, INSERT fails → DATA LOSS
  - Solution: Use explicit BEGIN/COMMIT
  
  Other gotchas:
  1. Time zone misalignment: Date boundaries wrong
  2. Wrong WHERE clause: Deletes everything
  3. Partition key changes: DELETE misses data
  4. Overlapping windows: Multiple models delete same partition
*/

WITH daily_aggregation AS (
  SELECT
      sale_date,
      COUNT(DISTINCT customer_id) as num_customers,
      COUNT(DISTINCT sale_id) as num_transactions,
      SUM(total_amount) as total_revenue,
      AVG(total_amount) as avg_transaction_value,
      MIN(total_amount) as min_transaction,
      MAX(total_amount) as max_transaction,
      SUM(quantity) as total_units_sold,
      MAX(updated_at) as last_updated

  FROM {{ ref('sales_detail') }}
  
  {% if is_incremental() %}
    -- Recalculate last 7 days (handles late-arriving data)
    WHERE sale_date >= CURRENT_DATE() - 7
  {% endif %}
  
  GROUP BY sale_date
)

SELECT
    sale_date,
    num_customers,
    num_transactions,
    total_revenue,
    avg_transaction_value,
    min_transaction,
    max_transaction,
    total_units_sold,
    last_updated,
    CURRENT_TIMESTAMP() as calculated_at

FROM daily_aggregation

WHERE num_transactions > 0

ORDER BY sale_date DESC
