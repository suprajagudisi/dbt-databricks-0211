# dbt Complete Guide

> **The complete dbt resource for data engineers, analytics engineers, and anyone building production data pipelines.**

This repository provides comprehensive, production-ready examples and best practices for dbt (data build tool) across multiple cloud data platforms. Learn by doing with real-world examples that include detailed explanations of common gotchas and how to avoid them.

---

## 📚 What's Covered

### Current Topics

- **[Incremental Models](./incremental-models/)** - Master all 5 incremental materialization strategies with platform-specific implementations for Databricks and Snowflake


---

## 🚀 Incremental Models

Incremental models are essential for building efficient data pipelines that process only new or changed data instead of rebuilding entire tables. This section covers all 5 incremental strategies with detailed examples.

### Directory Structure

```
incremental-models/
├── databricks/          # Databricks/Delta Lake implementation
│   ├── models/
│   │   ├── 01_append/
│   │   ├── 02_merge/
│   │   ├── 03_delete_insert/
│   │   ├── 04_insert_overwrite/
│   │   ├── 05_microbatch/          # ⭐ Working with 2 batches!
│   │   ├── optimizations/
│   │   └── sources.yml             # Source configuration for microbatch
│   ├── macros/
│   │   └── generate_schema_name.sql  # Custom schema naming
│   ├── seeds/
│   ├── venv/                      # Python virtual environment
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── packages.yml
│   └── requirements.txt
│
└── snowflake/           # Snowflake implementation
    ├── models/
    │   ├── 01_append/
    │   ├── 02_merge/
    │   ├── 03_delete_insert/
    │   ├── 04_insert_overwrite/
    │   ├── 05_microbatch/          # ⭐ Working with 2 batches!
    │   ├── optimizations/
    │   └── sources.yml             # Source configuration for microbatch
    ├── macros/
    │   └── generate_schema_name.sql  # Custom schema naming
    ├── seeds/
    ├── venv/                      # Python virtual environment
    ├── dbt_project.yml
    ├── profiles.yml
    ├── packages.yml
    └── requirements.txt
```

**Schema Architecture (Both Platforms):**
```
Database
├── bronze/                 # Seeds (raw data from CSV files)
│   ├── events
│   ├── customers
│   ├── products
│   └── sales_detail
│
└── silver/                 # Models (transformed data)
    ├── events_incremental
    ├── customers_incremental
    ├── customers_with_surrogate_key
    ├── daily_sales_by_customer
    ├── daily_sales_summary
    ├── events_insert_overwrite
    ├── events_microbatch_example  ⭐ NEW!
    ├── delta_optimized_events (Databricks)
    └── clustered_events (Snowflake)
```

### The 5 Incremental Strategies

| Strategy | Use Case | Best For | Performance | Complexity |
|----------|----------|----------|-------------|------------|
| **1. Append** | Insert-only, no updates | Event logs, immutable data | ⚡ Fastest | 🟢 Simple |
| **2. Merge** | Insert + Update (upsert) | Dimension tables, SCD Type 1 | 🐢 Slower | 🟡 Medium |
| **3. Delete+Insert** | Replace specific partitions | Daily aggregations, rollups | ⚡ Fast | 🟡 Medium |
| **4. Insert Overwrite** | Atomic partition replacement | Time-partitioned data | ⚡ Fast | 🟢 Simple |
| **5. Microbatch** | Automatic batch processing | Streaming data, late arrivals | ⚡ Fast | 🟢 Simple |

### Quick Decision Guide

**Choose APPEND when:**
- Data is immutable (never updates)
- Simple event logging
- Highest performance needed
- Example: Click streams, audit logs

**Choose MERGE when:**
- Records can be inserted OR updated
- Need to maintain latest state
- Working with dimension tables
- Example: Customer profiles, product catalogs

**Choose DELETE+INSERT when:**
- Need to completely recalculate periods
- Late-arriving data requires reprocessing
- Working with aggregations
- Example: Daily sales summaries, hourly metrics

**Choose INSERT OVERWRITE when:**
- Need atomic partition replacement
- Time-based partitioning
- Platform supports it natively (Databricks, BigQuery)
- Example: Daily event rollups

**Choose MICROBATCH when:**
- Processing streaming/real-time data
- Frequent late arrivals
- Need automatic batch management
- Requires dbt 1.9+
- Example: IoT sensors, real-time events

---

## 🎯 Key Features

### Real-World Examples
- ✅ Production-ready code with proper error handling
- ✅ Sample data included (CSV seeds)
- ✅ Comprehensive schema tests
- ✅ Performance optimizations

### Platform-Specific Optimizations

**Databricks/Delta Lake:**
- Delta Lake file format
- OPTIMIZE and ANALYZE TABLE post-hooks
- Liquid Clustering
- Unity Catalog support
- Change Data Feed integration

**Snowflake:**
- Clustering keys
- Warehouse sizing hints
- Query tags for cost tracking
- Transient table options
- Time travel considerations

### Gotcha Documentation
Each strategy includes:
- 🚨 Common pitfalls and how to avoid them
- 🔍 Edge cases with solutions
- 💡 Best practices and tips
- ⚠️ CRITICAL warnings in code comments

---

## 🛠️ Getting Started

### Prerequisites

- Python 3.12 (recommended) or 3.8+
- dbt-core 1.11.2+
- dbt-databricks 1.11.4+ OR dbt-snowflake 1.11.1+
- Access to Databricks workspace OR Snowflake account

### Installation

#### For Databricks

```bash
cd incremental-models/databricks

# Create virtual environment with Python 3.12
python3.12 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install dbt packages
dbt deps

# Configure your profile
# Copy the example file and edit with your credentials
cp profiles.yml.example profiles.yml
nano profiles.yml  # Edit with your actual credentials
# - host: your-workspace.cloud.databricks.com (without https://)
# - http_path: /sql/1.0/warehouses/your_warehouse_id
# - token: your_personal_access_token
# - catalog: workspace (or your Unity Catalog)
# - schema: default (allows custom schema macro to work)

# Load sample data to bronze schema
dbt seed --full-refresh

# Run all models to silver schema
dbt run --full-refresh
```

#### For Snowflake

```bash
cd incremental-models/snowflake

# Create virtual environment with Python 3.12
python3.12 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies  
pip install -r requirements.txt

# Install dbt packages
dbt deps

# Configure your profile
# Copy the example file and edit with your credentials
cp profiles.yml.example profiles.yml
nano profiles.yml  # Edit with your actual credentials
# - account: YOUR_ACCOUNT_ID (e.g., WDGKXQD-GS23287)
# - user: your_username
# - password: your_password (or use authenticator: externalbrowser)
# - warehouse: COMPUTE_WH (must exist)
# - database: SNOWFLAKE_LEARNING_DB (or your database)
# - schema: default (allows custom schema macro to work)

# Load sample data to bronze schema
dbt seed --full-refresh

# Run all models to silver schema
dbt run --full-refresh
```

### Running the Examples

```bash
# 1. Load sample data (creates tables in bronze schema)
dbt seed --full-refresh

# 2. Run all incremental models (creates tables in silver schema)
dbt run --full-refresh

# 3. Test the models
dbt test

# 4. Run specific strategy
dbt run --select tag:append
dbt run --select tag:merge
dbt run --select tag:delete_insert
dbt run --select tag:insert_overwrite_alternative  # Snowflake
dbt run --select tag:insert_overwrite              # Databricks
dbt run --select tag:microbatch

# 5. Run the microbatch example specifically
dbt run --select events_microbatch_example --full-refresh

# 6. Simulate incremental run (runs with existing data)
dbt run

# 7. View generated SQL
dbt compile --select events_microbatch_example
# Check: target/compiled/.../events_microbatch_example.sql

# 8. Debug connection
dbt debug
```

### Expected Results

**Seeds (bronze schema):**
- ✅ events: 20 rows (2 days: Jan 30-31, 2026)
- ✅ customers: 8 rows
- ✅ products: 4 rows
- ✅ sales_detail: 10 rows

**Models (silver schema):**
- ✅ 9 models successfully created
- ✅ Microbatch processes 2 batches automatically
  - Batch 1: 2026-01-30 (10 events)
  - Batch 2: 2026-01-31 (10 events)

---

## 📖 Learn by Strategy

### 1. Append Strategy
**Location:** `incremental-models/{platform}/models/01_append/`

Perfect for immutable event data. This is the fastest and simplest incremental strategy.

**Key Example:** [`events_incremental.sql`](./incremental-models/databricks/models/01_append/events_incremental.sql)

**Common Gotchas:**
- Clock skew between systems → Add 10-minute buffer
- NULL timestamps break MAX() filter
- Source system retries can cause duplicates

### 2. Merge Strategy
**Location:** `incremental-models/{platform}/models/02_merge/`

Upsert pattern (insert OR update) for slowly changing dimensions.

**Key Examples:**
- [`customers_incremental.sql`](./incremental-models/databricks/models/02_merge/customers_incremental.sql) - Basic merge
- [`customers_with_surrogate_key.sql`](./incremental-models/databricks/models/02_merge/customers_with_surrogate_key.sql) - **Recommended for production**

**Common Gotchas:**
- NULL in unique_key causes silent duplicates
- Composite keys fail mysteriously on some platforms
- Race conditions with concurrent runs
- **Solution:** Use surrogate keys

### 3. Delete+Insert Strategy
**Location:** `incremental-models/{platform}/models/03_delete_insert/`

Deletes matching records then inserts fresh data. Perfect for aggregations.

**Key Examples:**
- [`daily_sales_summary.sql`](./incremental-models/databricks/models/03_delete_insert/daily_sales_summary.sql) - Daily aggregation
- [`daily_sales_by_customer.sql`](./incremental-models/databricks/models/03_delete_insert/daily_sales_by_customer.sql) - Composite key

**Common Gotchas:**
- NOT atomic by default on Snowflake (DELETE succeeds, INSERT fails → data loss)
- Wrong WHERE clause can delete everything
- Date boundary misalignment
- **Solution:** Use explicit transactions, test thoroughly

### 4. Insert Overwrite Strategy
**Location:** `incremental-models/{platform}/models/04_insert_overwrite/`

Atomically replaces entire partitions. Native on Databricks, emulated on Snowflake.

**Key Examples:**
- Databricks: [`events_insert_overwrite.sql`](./incremental-models/databricks/models/04_insert_overwrite/events_insert_overwrite.sql)
- Snowflake: [`snowflake_alternative.sql`](./incremental-models/snowflake/models/04_insert_overwrite/snowflake_alternative.sql) (uses delete+insert)

**Common Gotchas:**
- Partition pruning failures lead to full table overwrites
- Platform differences (Snowflake doesn't support natively)

### 5. Microbatch Strategy (dbt 1.9+)
**Location:** `incremental-models/{platform}/models/05_microbatch/`

Automatically divides data into time-based batches. Perfect for streaming data with late arrivals.

**Key Example:** [`events_microbatch_example.sql`](./incremental-models/databricks/models/05_microbatch/events_microbatch_example.sql)

**What's Special:**
- ✨ Automatic batch processing (no manual date filtering!)
- 🎯 Processes 2 batches in this demo (Jan 30-31, 2026)
- 🔄 Handles late-arriving data with `lookback` parameter
- 📦 Requires source configuration with `event_time`

**Common Gotchas:**
- event_time column must be NOT NULL and TIMESTAMP (not DATE)
- Requires source configuration: `config: { event_time: event_timestamp }`
- Batch size affects performance
- Timezone inconsistencies can cause issues
- **Solution:** Always configure source with event_time for proper filtering

---

## 🔬 Sample Data

All examples include realistic sample data in the `seeds/` folder:

- **events.csv** - 20 user events across 2 days (Jan 30-31, 2026)
  - 10 events on Jan 30
  - 10 events on Jan 31
  - Perfect for demonstrating microbatch with 2 batches
- **customers.csv** - 8 customer records with updates
- **sales_detail.csv** - 10 transaction details
- **products.csv** - 4 product records

The data is designed to demonstrate:
- Initial loads and incremental updates
- Late-arriving data scenarios
- Update patterns for dimension tables
- Time-based partitioning
- Microbatch processing with multiple batches

**Schema Structure:**
- Seeds load into `bronze` schema (raw data layer)
- Models transform into `silver` schema (curated data layer)
- Custom `generate_schema_name` macro ensures clean naming

---

## 🎓 Learning Path

### Beginner
1. Start with **Append** strategy - simplest to understand
2. Run `dbt seed` and `dbt run --select tag:append`
3. Examine the generated SQL with `dbt compile`
4. Add new rows to `events.csv` and run again (incremental)

### Intermediate
5. Move to **Merge** strategy - understand upserts
6. Study the difference between basic and surrogate key approaches
7. Learn **Delete+Insert** for aggregations
8. Understand platform differences (Databricks vs Snowflake)

### Advanced
9. Master **Insert Overwrite** for partition management
10. Explore **Microbatch** for streaming patterns
11. Study the optimization examples in `models/optimizations/`
12. Review all gotchas and edge cases in schema.yml files

---

## 📊 Performance Tips

### General
- Use appropriate unique_key to minimize scan scope
- Add proper WHERE clauses in incremental block
- Partition by frequently filtered columns
- Use clustering for large tables

### Databricks Specific
- Enable auto-optimize with `delta.autoOptimize.optimizeWrite`
- Use liquid clustering instead of ZORDER
- Run OPTIMIZE regularly on large tables
- Enable Change Data Feed for CDC patterns

### Snowflake Specific
- Use appropriate warehouse size
- Cluster keys on frequently filtered columns
- Consider transient tables for intermediate data
- Use query tags for cost attribution

---

## 🤝 Contributing

Found a gotcha not covered here? Have a better example? Contributions welcome!

1. Fork the repository
2. Create your feature branch
3. Add your example with comprehensive comments
4. Include tests and documentation
5. Submit a pull request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🔗 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Discourse Community](https://discourse.getdbt.com/)
- [Databricks dbt Documentation](https://docs.databricks.com/partners/prep/dbt.html)
- [Snowflake dbt Documentation](https://docs.snowflake.com/en/user-guide/dbt)

---

## ⭐ Support

If you find this guide helpful:
- Star this repository
- Share it with your team
- Contribute your own examples
- Report issues or suggest improvements

---

**Made with ❤️ for the dbt community**
