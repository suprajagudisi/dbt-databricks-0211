{{
  config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key=['sale_date', 'customer_id'],
    file_format='delta',
    partition_by='sale_date',
    cluster_by=['customer_id'],
    on_schema_change='fail'
  )
}}

-- DELETE+INSERT with Composite Key

SELECT
    sale_date,
    customer_id,
    COUNT(DISTINCT sale_id) as num_purchases,
    SUM(total_amount) as daily_spend,
    AVG(total_amount) as avg_order_value,
    SUM(quantity) as units_purchased,
    MAX(updated_at) as last_transaction_update

FROM {{ ref('sales_detail') }}

{% if is_incremental() %}
  WHERE sale_date >= CURRENT_DATE() - INTERVAL 3 DAYS
{% endif %}

GROUP BY sale_date, customer_id

ORDER BY sale_date DESC, daily_spend DESC
