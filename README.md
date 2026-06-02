![Snowflake](https://img.shields.io/badge/Snowflake-Data%20Warehouse-29B5E8?style=flat-square&logo=snowflake)
![dbt](https://img.shields.io/badge/dbt-Transformation-FF694B?style=flat-square&logo=dbt)
![AWS](https://img.shields.io/badge/AWS-S3-FF9900?style=flat-square&logo=amazonaws)
![Python](https://img.shields.io/badge/Python-3.x-blue?style=flat-square&logo=python)

# Airbnb Data Pipeline — Snowflake + dbt + AWS

## What This Is

A end-to-end data engineering pipeline built from scratch to process Airbnb data — listings, bookings, and hosts — through a structured medallion architecture using Snowflake as the warehouse and dbt as the transformation layer. Source files land in AWS S3, get staged into Snowflake, and flow through Bronze → Silver → Gold layers to produce analytics-ready datasets.

---

## Tech Stack

| Tool | Role |
|------|------|
| Snowflake | Cloud data warehouse |
| dbt (Data Build Tool) | SQL transformations and orchestration |
| AWS S3 | Raw file storage |
| Python 3.12+ | Project environment |
| uv / pip | Dependency management |

---

## Architecture

```
CSV Files → AWS S3 → Snowflake Staging → Bronze → Silver → Gold
                                            ↓         ↓        ↓
                                         Raw       Cleaned  Analytics
```

Data moves through three layers:

**Bronze** — Raw ingestion with minimal changes. Three tables: `bronze_bookings`, `bronze_hosts`, `bronze_listings`.

**Silver** — Cleaned, validated, and standardized records. Adds price categorization, host quality metrics, and data type enforcement.

**Gold** — Business-ready. Includes a denormalized One Big Table (`obt`) joining all three entities, plus a `fact` table for dimensional analysis. Intermediate joins are handled via ephemeral models.

**Snapshots (SCD Type 2)** — Historical tracking for bookings, hosts, and listings using dbt snapshots with automatic valid-from/valid-to date management.

---

## Project Layout

```
aws_dbt_snowflake/
├── main.py
├── pyproject.toml
├── SourceData/
│   ├── bookings.csv
│   ├── hosts.csv
│   └── listings.csv
├── DDL/
│   ├── ddl.sql
│   └── resources.sql
└── aws_dbt_snowflake_project/
    ├── dbt_project.yml
    ├── ExampleProfiles.yml
    ├── models/
    │   ├── sources/sources.yml
    │   ├── bronze/
    │   ├── silver/
    │   └── gold/
    │       └── ephemeral/
    ├── macros/
    ├── snapshots/
    ├── tests/
    └── analyses/
```

---

## Setup

### Prerequisites

- Python 3.12+
- A Snowflake account
- An AWS account (for S3)

### Installation

```bash
git clone <repository-url>
cd aws_dbt_snowflake

# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate      # Mac/Linux
.venv\Scripts\Activate.ps1    # Windows

# Install dependencies
pip install -e .
```

### Snowflake Connection

Create `~/.dbt/profiles.yml` — **do not commit this file**:

```yaml
aws_dbt_snowflake_project:
  outputs:
    dev:
      type: snowflake
      account: <your-account-identifier>
      user: <your-username>
      password: <your-password>
      role: ACCOUNTADMIN
      database: AIRBNB
      warehouse: COMPUTE_WH
      schema: dbt_schema
      threads: 4
  target: dev
```

### Database Setup

1. Run `DDL/ddl.sql` in Snowflake to create the staging tables
2. Load the CSVs from `SourceData/` into Snowflake:
   - `bookings.csv` → `AIRBNB.STAGING.BOOKINGS`
   - `hosts.csv` → `AIRBNB.STAGING.HOSTS`
   - `listings.csv` → `AIRBNB.STAGING.LISTINGS`

---

## Running the Pipeline

```bash
cd aws_dbt_snowflake_project

dbt debug          # Verify connection
dbt deps           # Install packages

dbt run            # Run all models
dbt test           # Run data quality tests
dbt snapshot       # Apply SCD Type 2 snapshots

# Run individual layers
dbt run --select bronze.*
dbt run --select silver.*
dbt run --select gold.*

# Full build (models + tests + snapshots)
dbt build

# Generate and view docs
dbt docs generate
dbt docs serve
```

---

## Notable Features

**Incremental Loading** — Bronze and silver models only process new records on each run, using `CREATED_AT` timestamps to determine what's changed since the last load.

**Custom Macros** — Reusable Jinja functions handle common logic: `tag()` for bucketing prices into low/medium/high categories, `trimmer()` for string cleanup, and `generate_schema_name()` to keep each layer in its own Snowflake schema (BRONZE, SILVER, GOLD).

**Ephemeral Models** — Intermediate joins in the gold layer run in-memory without materializing extra tables in Snowflake.

**SCD Type 2 Snapshots** — dbt snapshots track changes to bookings, hosts, and listings over time, enabling point-in-time querying without overwriting history.

**Data Quality Tests** — Source-level tests enforce uniqueness, not-null constraints, and referential integrity before data moves downstream.

---

## Schema Layout in Snowflake

```
AIRBNB
├── STAGING      ← Raw CSV data loaded here
├── BRONZE       ← bronze_bookings, bronze_hosts, bronze_listings
├── SILVER       ← silver_bookings, silver_hosts, silver_listings
└── GOLD         ← obt, fact + snapshot tables
```

---

## Security Notes

- `profiles.yml` is in `.gitignore` — credentials are never committed
- Use environment variables or a secrets manager in production
- Snowflake RBAC roles should be scoped down from `ACCOUNTADMIN` for production use

---

## What's Next

- [ ] Add CI/CD with GitHub Actions (`dbt compile` on pull requests)
- [ ] Connect to a BI tool (Metabase, Tableau, or Looker)
- [ ] Add monitoring and alerting on pipeline failures
- [ ] Expand test coverage with custom data quality checks
- [ ] Implement data masking for any PII fields

---

## Dependencies

```toml
dbt-core >= 1.11.2
dbt-snowflake >= 1.11.0
```

Managed via `pyproject.toml` using `uv` or `pip`.
