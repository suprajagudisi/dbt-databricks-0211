{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customer_id',
    merge_update_columns=['customer_name', 'email', 'phone', 'country', 'updated_at'],
    on_schema_change='fail'
  )
}}

/*
  MERGE Strategy on Snowflake
  
  Perfect for:
  - Dimension tables (slowly changing)
  - Customer/product masters with updates
  - Upsert patterns (insert OR update)
  
  How it works:
  1. Match records on unique_key
  2. UPDATE matching records with new values
  3. INSERT non-matching records
  
  Critical gotchas:
  1. NULL in unique_key: NULL != NULL in SQL
     Result: Duplicates created every run
  2. Composite keys: Can fail mysteriously on Snowflake
     Solution: Use surrogate key instead
  3. Lost updates: Race conditions with concurrent runs
*/

SELECT
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
  -- Only process recently updated customers
  WHERE updated_at > (
    SELECT MAX(updated_at)
    FROM {{ this }}
  )
  -- CRITICAL: Filter NULL unique_key
  -- Without this, NULL records create duplicates
  AND customer_id IS NOT NULL
{% endif %}

WHERE customer_name IS NOT NULL
