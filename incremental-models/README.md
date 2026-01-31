# Incremental Models - Complete Guide

This folder contains comprehensive examples of all 5 dbt incremental materialization strategies, implemented for both **Databricks (Delta Lake)** and **Snowflake**.

---

## 📁 Folder Structure

```
incremental-models/
├── databricks/          # Databricks/Delta Lake implementation
│   ├── dbt_project.yml  # Project configuration
│   ├── profiles.yml     # Connection profile (edit with your credentials)
│   ├── packages.yml     # dbt package dependencies
│   ├── requirements.txt # Python dependencies
│   ├── seeds/          # Sample CSV data
│   │   ├── events.csv
│   │   ├── customers.csv
│   │   ├── sales_detail.csv
│   │   └── products.csv
│   └── models/
│       ├── 01_append/              # Append strategy examples
│       ├── 02_merge/               # Merge (upsert) strategy examples
│       ├── 03_delete_insert/       # Delete+Insert strategy examples
│       ├── 04_insert_overwrite/    # Insert Overwrite strategy examples
│       ├── 05_microbatch/          # Microbatch strategy examples (dbt 1.9+)
│       └── optimizations/          # Advanced optimization examples
│
└── snowflake/           # Snowflake implementation
    └── (same structure as databricks)
```

---

## 🎯 Strategy Overview

### 1. Append (`01_append/`)
**What it does:** Simply appends new rows to the table without any updates or deletes.

**Best for:**
- Immutable event logs
- Click streams
- Audit trails
- IoT sensor data

**Performance:** ⚡⚡⚡ Fastest (no merge logic)

**Key Example Files:**
- `events_incremental.sql` - Basic append with timestamp filtering

**Common Gotchas:**
- Clock skew between source and target
- NULL timestamps break incremental logic
- Duplicate rows if source retries

---

### 2. Merge (`02_merge/`)
**What it does:** Inserts new rows and updates existing rows based on a unique key (UPSERT pattern).

**Best for:**
- Dimension tables (customers, products)
- Slowly Changing Dimensions (SCD Type 1)
- Any table where records can be created or updated

**Performance:** 🐢🐢 Slower (requires matching logic)

**Key Example Files:**
- `customers_incremental.sql` - Basic merge with unique_key
- `customers_with_surrogate_key.sql` - **RECOMMENDED:** Uses surrogate key for reliability

**Common Gotchas:**
- NULL in unique_key creates duplicates on every run
- Composite keys fail mysteriously on some platforms
- Concurrent runs can cause race conditions
- **Solution:** Always use surrogate keys for production

---

### 3. Delete+Insert (`03_delete_insert/`)
**What it does:** Deletes rows matching a condition, then inserts fresh data.

**Best for:**
- Daily/hourly aggregations
- Rolling up raw data
- Reprocessing time windows
- Late-arriving data scenarios

**Performance:** ⚡⚡ Fast (no row-level matching)

**Key Example Files:**
- `daily_sales_summary.sql` - Daily aggregation with 7-day lookback
- `daily_sales_by_customer.sql` - Composite key deletion pattern

**Common Gotchas:**
- NOT ATOMIC on Snowflake (DELETE succeeds, INSERT fails = data loss)
- Wrong WHERE clause can delete all data
- Date boundary misalignment
- Overlapping time windows between models

---

### 4. Insert Overwrite (`04_insert_overwrite/`)
**What it does:** Atomically replaces entire partitions of data.

**Best for:**
- Time-partitioned data
- Daily/hourly event rollups
- Atomic partition replacement

**Performance:** ⚡⚡⚡ Very fast

**Platform Support:**
- ✅ Databricks: Native support (`incremental_strategy='insert_overwrite'`)
- ⚠️ Snowflake: No native support - use `delete+insert` as alternative

**Key Example Files:**
- Databricks: `events_insert_overwrite.sql` - Native insert overwrite
- Snowflake: `snowflake_alternative.sql` - Delete+insert workaround

**Common Gotchas:**
- Partition pruning failures overwrite entire table
- Platform differences require different approaches
- Must partition properly for efficiency

---

### 5. Microbatch (`05_microbatch/`)
**What it does:** Automatically divides data into time-based batches and processes them independently.

**Best for:**
- Streaming/real-time data
- High-volume event logs with late arrivals
- Automatic batch management
- CDC (Change Data Capture) patterns

**Performance:** ⚡⚡⚡ Fast + automatic late data handling

**Requirements:**
- dbt 1.9+
- `event_time` column (must be NOT NULL timestamp)

**Key Example Files:**
- `events_microbatch.sql` - Hourly batches with 3-hour lookback
- `events_microbatch_daily.sql` - Daily batches with 2-day lookback

**Common Gotchas:**
- event_time must be NOT NULL
- Must be timestamp, not date
- Batch size affects performance (too large or too small)
- Timezone inconsistencies cause issues

---

## 🚀 Quick Start

### For Databricks

```bash
cd databricks

# 1. Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt
dbt deps

# 3. Configure connection (edit profiles.yml with your credentials)
# - host: your-workspace.cloud.databricks.com
# - http_path: /sql/1.0/warehouses/your_warehouse_id
# - token: your_personal_access_token

# 4. Load sample data
dbt seed

# 5. Run all models
dbt run

# 6. Run specific strategy
dbt run --select tag:append
dbt run --select tag:merge
dbt run --select tag:delete_insert
dbt run --select tag:insert_overwrite
dbt run --select tag:microbatch

# 7. Test everything
dbt test

# 8. Simulate incremental run (add data to seeds and run again)
dbt run
```

### For Snowflake

```bash
cd snowflake

# Same steps as Databricks, but configure profiles.yml with:
# - account: your_account_id (e.g., abc12345.us-east-1)
# - user: your_username
# - password: your_password
# - warehouse: compute_wh
# - database: dbt_demo
# - schema: public
```

---

## 🎓 Learning Path

### Level 1: Basics (Start Here)
1. **Understand the problem:** Why incremental models?
   - Full refresh on large tables = expensive + slow
   - Incremental = process only new/changed data

2. **Start with Append:**
   - Read `01_append/events_incremental.sql`
   - Notice the `{% if is_incremental() %}` block
   - Run: `dbt run --select events_incremental`
   - Add rows to `seeds/events.csv` and run again (see incremental!)

3. **Study the generated SQL:**
   - Run: `dbt compile --select events_incremental`
   - Check: `target/compiled/.../events_incremental.sql`
   - See how dbt translates your Jinja to SQL

### Level 2: Upserts & Updates
4. **Master Merge Strategy:**
   - Read both merge examples
   - Understand why surrogate keys are better
   - Test with `seeds/customers.csv` (has updates)

5. **Learn Delete+Insert:**
   - Perfect for aggregations
   - Understand the 7-day lookback pattern
   - See how it handles late data

### Level 3: Advanced Patterns
6. **Platform Differences:**
   - Compare Databricks vs Snowflake implementations
   - Note platform-specific optimizations
   - Understand Insert Overwrite vs Delete+Insert

7. **Microbatch (dbt 1.9+):**
   - Newest strategy, most automated
   - Study the `event_time` configuration
   - Understand lookback windows

8. **Optimizations:**
   - Check `models/optimizations/` folder
   - Learn about clustering, partitioning
   - Platform-specific performance tuning

---

## 🔍 Understanding Each Strategy's Code

### Anatomy of an Incremental Model

```sql
{{
  config(
    materialized='incremental',           -- Makes this incremental
    incremental_strategy='append',        -- Which strategy to use
    unique_key='id',                      -- For merge/delete+insert
    on_schema_change='fail'               -- Schema evolution behavior
  )
}}

-- Your SELECT query
SELECT
    id,
    created_at,
    data
FROM {{ ref('source_table') }}

{% if is_incremental() %}
  -- This block runs only on incremental runs (not first run)
  WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})
{% endif %}
```

**Key concepts:**
- `{{ config() }}` - Model configuration
- `{{ ref() }}` - Reference to seeds or other models
- `{{ this }}` - Reference to the current model
- `{% if is_incremental() %}` - Jinja conditional for incremental logic

---

## 📊 Strategy Comparison Matrix

| Feature | Append | Merge | Delete+Insert | Insert Overwrite | Microbatch |
|---------|--------|-------|---------------|------------------|------------|
| **Inserts new rows** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Updates existing rows** | ❌ | ✅ | ❌ | ❌ | ✅ |
| **Deletes rows** | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Needs unique_key** | ❌ | ✅ | ✅ | ❌ | ❌ |
| **Performance** | Fastest | Slowest | Fast | Fast | Fast |
| **Handles late data** | ❌ | ✅ | ✅ | ✅ | ✅✅ |
| **Complexity** | Low | Medium | Medium | Low | Low |
| **Atomic operations** | ✅ | ✅ | ⚠️ | ✅ | ✅ |
| **Best for** | Events | Dimensions | Aggregations | Partitions | Streaming |

---

## 🚨 Common Gotchas (All Strategies)

### 1. NULL in Filtering Columns
```sql
-- ❌ BAD: NULL breaks MAX()
WHERE event_timestamp > (SELECT MAX(event_timestamp) FROM {{ this }})

-- ✅ GOOD: Filter NULLs explicitly
WHERE event_timestamp > (SELECT MAX(event_timestamp) FROM {{ this }})
  AND event_timestamp IS NOT NULL
```

### 2. Clock Skew
```sql
-- ❌ BAD: Misses records if source ahead of target
WHERE event_timestamp > (SELECT MAX(event_timestamp) FROM {{ this }})

-- ✅ GOOD: Add buffer for clock skew
WHERE event_timestamp > (
  SELECT TIMESTAMPADD('minute', -10, MAX(event_timestamp)) 
  FROM {{ this }}
)
```

### 3. First Run vs Incremental Run
```sql
-- ✅ ALWAYS use is_incremental() check
{% if is_incremental() %}
  -- Incremental logic here
{% endif %}
-- Without this, first run (full refresh) also tries to use incremental logic
```

### 4. Schema Changes
```sql
-- Configure how to handle schema changes
config(
  on_schema_change='fail'  -- Fail if schema changes (safest)
  -- OR
  on_schema_change='append_new_columns'  -- Add new columns automatically
  -- OR
  on_schema_change='sync_all_columns'  -- Sync all changes (dangerous!)
)
```

---

## 🎯 When to Use Each Strategy

### Decision Tree

```
Do records ever get updated?
├─ NO → Are you processing streaming data?
│   ├─ YES → Use MICROBATCH (automatic late data handling)
│   └─ NO → Use APPEND (simplest and fastest)
│
└─ YES → Are you updating entire time periods (days/hours)?
    ├─ YES → Does your platform support INSERT OVERWRITE natively?
    │   ├─ YES (Databricks/BigQuery) → Use INSERT OVERWRITE
    │   └─ NO (Snowflake) → Use DELETE+INSERT
    │
    └─ NO (row-level updates) → Are you updating aggregations or raw data?
        ├─ Aggregations → Use DELETE+INSERT
        └─ Raw data (dimensions) → Use MERGE with SURROGATE KEY
```

---

## 📚 Further Reading

Each strategy folder contains:
- **schema.yml** - Detailed documentation, gotchas, and test configurations
- **SQL files** - Production-ready examples with inline comments
- **Multiple examples** - Different patterns and edge cases

### Recommended Reading Order:
1. Read this README
2. Pick a strategy
3. Read its schema.yml for detailed docs
4. Study the SQL files with comments
5. Run the examples
6. Modify and experiment

---

## 💡 Pro Tips

### Development Workflow
```bash
# 1. Full refresh during development
dbt run --select my_model --full-refresh

# 2. Test incremental logic
dbt run --select my_model

# 3. View compiled SQL
dbt compile --select my_model
# Check: target/compiled/...

# 4. Test with production-size data
# Add more rows to seeds or point to real source
```

### Debugging
```bash
# Check what dbt will do
dbt run --select my_model --dry-run

# See full logs
dbt run --select my_model --debug

# Compile to see generated SQL
dbt compile --select my_model
```

### Performance Testing
```bash
# Compare strategies
dbt run --select tag:append    # Measure time
dbt run --select tag:merge     # Compare
```

---

## 🤝 Need Help?

- **Read the comments** in the SQL files - they're comprehensive
- **Check schema.yml** for detailed gotchas
- **Review the main README** in the root folder
- **Open an issue** if you find a bug or have questions

---

**Happy incremental modeling! 🚀**
