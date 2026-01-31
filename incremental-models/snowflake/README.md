# Snowflake Incremental Models - Implementation Guide

This folder contains complete implementations of all 5 dbt incremental strategies optimized for **Snowflake**.

---

## ✅ **Project Status: Fully Working**

- **Seeds**: 4 tables in `bronze` schema ✅
- **Models**: 9 models in `silver` schema ✅
- **Microbatch**: 2 batches successfully processing ✅

---

## 🏗️ **Schema Architecture**

```
SNOWFLAKE_LEARNING_DB
├── bronze/                          # Raw data from seeds
│   ├── events (20 rows)
│   ├── customers (8 rows)
│   ├── products (4 rows)
│   └── sales_detail (10 rows)
│
└── silver/                          # Transformed data from models
    ├── events_incremental           # Append strategy
    ├── customers_incremental        # Merge strategy
    ├── customers_with_surrogate_key # Merge with surrogate key
    ├── daily_sales_by_customer      # Delete+insert
    ├── daily_sales_summary          # Delete+insert aggregation
    ├── daily_events_with_clustering # Delete+insert with clustering
    ├── snowflake_alternative        # Insert overwrite alternative
    ├── events_microbatch_example    # ⭐ Microbatch (2 batches)
    └── clustered_events             # Append with clustering
```

---

## 🚀 **Quick Start**

### 1. Prerequisites

- Snowflake account
- Python 3.12 installed
- Snowflake user with appropriate permissions

### 2. Setup

```bash
# Navigate to project
cd /path/to/dbt-complete-guide/incremental-models/snowflake

# Create virtual environment
python3.12 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install dbt packages
dbt deps
```

### 3. Configure Connection

Create your `profiles.yml` from the example:

```bash
# Copy the example file
cp profiles.yml.example profiles.yml

# Edit with your credentials
nano profiles.yml  # or use your preferred editor
```

Edit `profiles.yml`:

```yaml
snowflake_dev:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: YOUR_ACCOUNT_ID                    # Your account ID
      user: your_username
      password: your_password
      # OR use browser authentication:
      # authenticator: externalbrowser
      role: ACCOUNTADMIN
      database: SNOWFLAKE_LEARNING_DB
      warehouse: COMPUTE_WH
      schema: default                             # Allows custom schema macro
      threads: 4
```

**Get your credentials:**
1. **Account ID**: Snowflake URL → Admin → Account → Copy account identifier
2. **User**: Your Snowflake username
3. **Password**: Your Snowflake password
4. **Warehouse**: Must exist (Admin → Warehouses)

**Note**: `profiles.yml` is git-ignored to protect your credentials. Only commit `profiles.yml.example`.

### 4. Create Required Objects in Snowflake

Run these SQL commands in Snowflake:

```sql
-- Create warehouse if needed
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WAREHOUSE_SIZE = 'X-SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- Create database
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_LEARNING_DB;

-- Grant permissions to user
GRANT ALL ON DATABASE SNOWFLAKE_LEARNING_DB TO ROLE ACCOUNTADMIN;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ACCOUNTADMIN;
```

### 5. Run

```bash
# Test connection
dbt debug

# Load seed data to bronze schema
dbt seed --full-refresh

# Run all models to silver schema
dbt run --full-refresh

# Test everything
dbt test

# Run microbatch specifically
dbt run --select events_microbatch_example --full-refresh
```

---

## 📊 **What Gets Created**

### Seeds (bronze schema)
```sql
-- 4 tables created
SNOWFLAKE_LEARNING_DB.bronze.events
SNOWFLAKE_LEARNING_DB.bronze.customers
SNOWFLAKE_LEARNING_DB.bronze.products
SNOWFLAKE_LEARNING_DB.bronze.sales_detail
```

### Models (silver schema)
```sql
-- 9 models created
SNOWFLAKE_LEARNING_DB.silver.events_incremental
SNOWFLAKE_LEARNING_DB.silver.customers_incremental
SNOWFLAKE_LEARNING_DB.silver.customers_with_surrogate_key
SNOWFLAKE_LEARNING_DB.silver.daily_sales_by_customer
SNOWFLAKE_LEARNING_DB.silver.daily_sales_summary
SNOWFLAKE_LEARNING_DB.silver.daily_events_with_clustering
SNOWFLAKE_LEARNING_DB.silver.snowflake_alternative
SNOWFLAKE_LEARNING_DB.silver.events_microbatch_example  -- ⭐ 2 batches!
SNOWFLAKE_LEARNING_DB.silver.clustered_events
```

---

## ❄️ **Snowflake-Specific Features**

### Clustering

Models use clustering for query performance:

```sql
-- Note: Clustering is managed via post-hooks or Snowflake auto-clustering
-- The cluster_by config parameter is not used in dbt-snowflake
```

### Time Travel

All tables support Snowflake's time travel:

```sql
-- Query historical data
SELECT * FROM silver.events_incremental
AT(OFFSET => -3600);  -- 1 hour ago
```

### Transient Tables

For intermediate data, consider transient tables:

```sql
config(
  transient=true  -- No Fail-safe, lower storage costs
)
```

### Query Tags

Track costs and usage:

```sql
config(
  query_tag='dbt_incremental_events'
)
```

---

## 🔑 **Key Configuration Files**

### 1. `dbt_project.yml`
- Seeds go to `bronze` schema
- Models go to `silver` schema
- Snowflake-specific column types configured

### 2. `profiles.yml`
- Connection to Snowflake
- Schema set to `default` for custom macro
- Supports password or browser auth

### 3. `macros/generate_schema_name.sql`
- Custom schema naming
- Prevents `default_silver` concatenation
- Returns clean schema names

### 4. `models/sources.yml`
- Defines `bronze.events` source
- Includes `event_time: event_timestamp` for microbatch
- Enables automatic filtering

---

## 🎓 **Learning Path**

### Beginner
1. Start with `01_append/events_incremental.sql`
2. Run: `dbt run --select events_incremental`
3. Query in Snowflake: `SELECT * FROM silver.events_incremental;`

### Intermediate
4. Study `02_merge/customers_with_surrogate_key.sql`
5. Understand `03_delete_insert/daily_sales_summary.sql`
6. Learn clustering in `optimizations/`

### Advanced
7. Compare to Databricks implementation
8. Explore `05_microbatch/events_microbatch_example.sql`
9. Study all schema.yml files for gotchas

---

## ⚡ **Performance Tips**

1. **Right-size your warehouse** - Start with X-SMALL
2. **Use clustering keys** for frequently filtered columns
3. **Monitor query history** for optimization opportunities
4. **Use RESULT_SCAN** to avoid re-running expensive queries
5. **Consider materialized views** for frequently accessed aggregations

---

## 🐛 **Common Issues**

### Issue: "Incorrect username or password"
**Solution:** 
- Verify credentials are correct
- Check user has been granted ACCOUNTADMIN role
- Verify warehouse and database exist

### Issue: Schema named `default_silver`
**Solution:** Ensure `schema: default` in profiles.yml and custom macro exists

### Issue: Microbatch fails
**Solution:** Check sources.yml has `event_time: event_timestamp` configuration

### Issue: Warehouse not found
**Solution:** Create warehouse in Snowflake UI or run CREATE WAREHOUSE SQL

---

## 🔄 **Platform Differences from Databricks**

| Feature | Databricks | Snowflake |
|---------|-----------|-----------|
| **File Format** | Delta Lake | Snowflake native |
| **Insert Overwrite** | Native support | Use delete+insert |
| **Optimization** | OPTIMIZE command | Auto-clustering |
| **Clustering** | Liquid clustering | Clustering keys |
| **Catalog** | Unity Catalog | Database/Schema |

---

## 📚 **Resources**

- [Snowflake dbt Documentation](https://docs.snowflake.com/en/user-guide/dbt)
- [Snowflake Best Practices](https://docs.snowflake.com/en/user-guide/intro-key-concepts)
- [dbt-snowflake Adapter](https://docs.getdbt.com/reference/warehouse-setups/snowflake-setup)

---

**Status: ✅ All 9 models working perfectly on Snowflake!**
