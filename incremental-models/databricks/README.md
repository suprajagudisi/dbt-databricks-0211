# Databricks Incremental Models - Implementation Guide

This folder contains complete implementations of all 5 dbt incremental strategies optimized for **Databricks and Delta Lake**.

---

## ✅ **Project Status: Fully Working**

- **Seeds**: 4 tables in `bronze` schema ✅
- **Models**: 9 models in `silver` schema ✅
- **Microbatch**: 2 batches successfully processing ✅

---

## 🏗️ **Schema Architecture**

```
workspace (Unity Catalog)
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
    ├── daily_events_partitioned     # Insert overwrite
    ├── events_insert_overwrite      # Insert overwrite
    ├── events_microbatch_example    # ⭐ Microbatch (2 batches)
    └── delta_optimized_events       # Optimized Delta table
```

---

## 🚀 **Quick Start**

### 1. Prerequisites

- Databricks workspace with SQL Warehouse
- Python 3.12 installed
- Personal access token from Databricks

### 2. Setup

```bash
# Navigate to project
cd /path/to/dbt-complete-guide/incremental-models/databricks

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
databricks_dev:
  target: dev
  outputs:
    dev:
      type: databricks
      host: your-workspace.cloud.databricks.com  # WITHOUT https://
      http_path: /sql/1.0/warehouses/your_warehouse_id
      token: your_personal_access_token
      catalog: workspace
      schema: default                             # Allows custom schema macro
      threads: 4
```

**Get your credentials:**
1. **Host**: Databricks workspace URL (remove `https://`)
2. **HTTP Path**: SQL Warehouse → Connection Details → HTTP Path
3. **Token**: User Settings → Developer → Access Tokens → Generate New Token

**Note**: `profiles.yml` is git-ignored to protect your credentials. Only commit `profiles.yml.example`.

### 4. Run

```bash
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
workspace.bronze.events
workspace.bronze.customers
workspace.bronze.products
workspace.bronze.sales_detail
```

### Models (silver schema)
```sql
-- 9 models created
workspace.silver.events_incremental
workspace.silver.customers_incremental
workspace.silver.customers_with_surrogate_key
workspace.silver.daily_sales_by_customer
workspace.silver.daily_sales_summary
workspace.silver.daily_events_partitioned
workspace.silver.events_insert_overwrite
workspace.silver.events_microbatch_example  -- ⭐ 2 batches!
workspace.silver.delta_optimized_events
```

---

## 🎯 **Databricks-Specific Features**

### Delta Lake Optimizations

All models use Delta Lake format with optimizations:

```sql
config(
  file_format='delta',
  post_hook=[
    "OPTIMIZE {{ this }}",
    "ANALYZE TABLE {{ this }} COMPUTE STATISTICS"
  ]
)
```

### Liquid Clustering

Instead of ZORDER, modern models use liquid clustering:

```sql
config(
  cluster_by=['event_date', 'user_id']
)
```

### Unity Catalog Support

Project configured for Unity Catalog:
- Catalog: `workspace`
- Schemas: `bronze` (seeds) and `silver` (models)
- Custom macro for clean schema naming

---

## 🔑 **Key Configuration Files**

### 1. `dbt_project.yml`
- Seeds go to `bronze` schema
- Models go to `silver` schema
- Delta format and optimizations enabled

### 2. `profiles.yml`
- Connection to Databricks
- Schema set to `default` for custom macro

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
3. Check compiled SQL: `dbt compile --select events_incremental`

### Intermediate
4. Study `02_merge/customers_with_surrogate_key.sql`
5. Understand `03_delete_insert/daily_sales_summary.sql`
6. Learn Delta optimizations in `optimizations/`

### Advanced
7. Master `04_insert_overwrite/` for partition management
8. Explore `05_microbatch/events_microbatch_example.sql`
9. Study all schema.yml files for gotchas

---

## ⚡ **Performance Tips**

1. **OPTIMIZE regularly** for large tables
2. **Use liquid clustering** instead of ZORDER
3. **Enable auto-optimize** in table properties
4. **Partition** by frequently filtered columns
5. **ANALYZE TABLE** after significant updates

---

## 🐛 **Common Issues**

### Issue: "Invalid access to Org"
**Solution:** Remove `https://` from host in profiles.yml

### Issue: Schema named `default_silver`
**Solution:** Ensure `schema: default` in profiles.yml and custom macro exists

### Issue: Microbatch fails
**Solution:** Check sources.yml has `event_time: event_timestamp` configuration

---

## 📚 **Resources**

- [Databricks dbt Documentation](https://docs.databricks.com/partners/prep/dbt.html)
- [Delta Lake Best Practices](https://docs.delta.io/latest/best-practices.html)
- [Unity Catalog Guide](https://docs.databricks.com/data-governance/unity-catalog/index.html)

---

**Status: ✅ All 9 models working perfectly on Databricks!**
