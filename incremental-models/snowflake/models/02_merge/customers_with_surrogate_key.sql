{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customer_sk',
    on_schema_change='fail'
  )
}}

/*
  MERGE with Surrogate Key (RECOMMENDED)
  
  Why use surrogate key:
  - Composite keys unreliable on Snowflake MERGE
  - Single hash key always works
  - Faster join operations
  - Future-proof if natural key changes
*/

SELECT
    -- Generate surrogate key (MD5 hash of natural key)
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_sk,
    
    customer_id,
    customer_name,
    email,
    phone,
    country,
    signup_date,
    updated_at,
    CURRENT_TIMESTAMP() as last_processed_at

FROM {{ ref('customers') }}

{% if is_incremental() %}
  WHERE updated_at > (
    SELECT COALESCE(MAX(updated_at), '1970-01-01'::TIMESTAMP_NTZ)
    FROM {{ this }}
  )
  AND customer_id IS NOT NULL
{% endif %}

WHERE customer_name IS NOT NULL
