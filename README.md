# dbt Analytics Engineering Assessment

This project evaluates your dbt and SQL skills using an embedded [DuckDB](https://duckdb.org/) database with sample Salesforce CRM data. No cloud accounts or credentials needed.

## Getting Started

Follow these steps in order to install requirements, install dbt packages, complete initial setup, and execute the project.

### 1. Clone the repository

```bash
git clone <repository-url>
cd dbt_interview/transformation
```

### 2. Install Python requirements

If you are using the dev container, Python dependency installation is handled automatically.

If you are running locally instead:

```bash
cd dbt_interview/transformation
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Install dbt packages

Install the dbt package dependencies defined in `packages.yml`:

```bash
cd dbt_interview/transformation
dbt deps
```

### 4. Initial project setup

Verify the dbt project and compile configuration:

```bash
cd dbt_interview/transformation
dbt debug
```

If the project includes seed data or snapshots, prepare them before running models:

```bash
# Seed static data if needed
dbt seed

# Run snapshots if present
dbt snapshot
```

### 5. Execute the project

Build the dbt models:

```bash
cd dbt_interview/transformation
dbt run
dbt test
```

To run models and tests together:

```bash
cd dbt_interview/transformation
dbt build
```

Seletive Runs Tag

```bash
cd dbt_interview/transformation
dbt build --select tag:marts            #only mart models + their tests
dbt build --select tag:intermediate     #only intermediate models + their tests
dbt run --select tag:sales              #only sales-domain models
dbt run --select tag:support            #only support-domain models
dbt test --select tag:dimension         #only dimension models tests
```

### 6. Validate project outputs

Run tests to validate schema, data quality, and relationships:

```bash
cd dbt_interview/transformation
dbt test
```

### Dev Container workflow

This repository supports an optional VS Code Dev Container setup.

1. Open the repository in VS Code
2. Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
3. Choose **Reopen in Container**

The container builds the Docker image and installs dependencies automatically. Once inside the container, go to `dbt_interview/transformation` and run:

```bash
dbt run
```

## Project Structure

This project follows a layered dbt architecture with clear separation between raw data staging, intermediate enrichment, and final marts.

- `dbt_interview/transformation/`
  - `dbt_project.yml` — project configuration, schema/materialization defaults, and model path settings
  - `packages.yml` — dbt package dependencies
  - `requirements.txt` — Python dependencies for dbt and DuckDB
  - `profiles.yml` — DuckDB connection configured to `./dbt.duckdb`
  - `dbt.duckdb` — local DuckDB database file used by the default profile
  - `models/`
    - `staging/`
      - 14 `stg_salesforce__*.sql` staging models
      - `_src__salesforce.yml` — source definitions
      - `_stg__salesforce.yml` — staging model metadata and tests
      - `docs.md` — staging documentation notes
    - `intermediate/`
      - `sales/` — `int_salesforce__opportunity_enriched.sql`, `int_salesforce__opportunity_stage_history.sql`
      - `support/` — `int_salesforce__case_events.sql`
      - `shared/` — `int_shared__date_spine.sql`
    - `marts/`
      - `dimesnsions/` — dimension models: account, campaign, contact, product, user, date
      - `facts/` — fact models: opportunity, case event
  - `macros/` — custom macros such as surrogate key generation, stage bucketing, and schema naming helpers
  - `snapshots/` — `snap_salesforce__account_scd2.sql` and snapshot metadata
  - `seeds/` — `seed_salesforce__opportunity_stage_targets.csv` and seed configuration
  - `tests/` — custom SQL tests such as `assert_opportunity_amount_non_negative.sql`

## Dataflow

1. Raw Salesforce source data and seed lookup values are modeled into the `staging` layer.
2. Staging views produce cleaned, typed data for upstream consumption.
3. Intermediate models enrich and normalize the staging output:
   - `int_salesforce__opportunity_enriched` combines opportunities with account, contact, campaign, and user details.
   - `int_salesforce__opportunity_stage_history` captures stage history events for opportunities.
   - `int_salesforce__case_events` models support case event streams.
   - `int_shared__date_spine` generates a reusable date spine for all time-based joins.
4. Mart models build final analytics-ready tables:
   - dimension tables for account, campaign, contact, product, user, and date
   - fact tables for opportunities and case events
5. Snapshots track SCD Type 2 history for accounts in `snapshots/`.

## Materialization Strategy

The project uses a deliberate materialization strategy for performance and maintainability:

- `staging` models are materialized as `view`.
  - These are lightweight transformations of raw source data and are ideal as views.
- `intermediate` models are materialized as `table`.
  - Intermediate tables provide stable, reusable building blocks for mart logic.
- `marts` models are materialized as `table`.
  - Final analytics models use tables for fast query performance and reliable downstream joins.
- `seeds` are materialized as tables and are used for static lookup values.
- `snapshots` are configured in their own schema and used to capture historical changes.

## Key dbt Features Used

- `dbt_project.yml` model-level configuration for schema and materialization defaults
- dbt packages:
  - `dbt_utils` for surrogate keys, unique combination tests, and other helpers
  - `dbt_date` for date-related logic and time zone handling
  - `codegen` for rapid model and macro scaffolding
- Source definitions in `models/staging/_src__salesforce.yml`
- `ref()` usage across staging, intermediate, and mart models
- Tags for model grouping and selective runs (`intermediate`, `mart`, `sales`, `support`, `dimension`)
- Custom macros in `macros/`, including surrogate key generation and stage bucketing
- Seed data for static lookup values in `seeds/`
- Snapshot-based SCD Type 2 history in `snapshots/`
- Model documentation and metadata in YAML files

## Testing Strategy

Model validation is enforced through a mix of built-in dbt tests and custom SQL tests:

- Primary key integrity using `not_null` and `unique` tests
- Referential integrity using `relationships` tests on foreign keys
- Business logic validation using `accepted_values` tests for categorical fields
- Composite uniqueness checks using `dbt_utils.unique_combination_of_columns`
- Additional custom SQL assertions in `tests/assert_opportunity_amount_non_negative.sql`
- Snapshot validation via dbt snapshot lifecycle

## Useful Command Reference

Use these commands from `dbt_interview/transformation`.

- `pip install -r requirements.txt`
- `dbt deps`
- `dbt debug`
- `dbt seed`
- `dbt snapshot`
- `dbt run`
- `dbt test`
- `dbt build`
- `dbt build --select tag:marts`
- `dbt build --select tag:intermediate`
- `dbt run --select tag:sales`
- `dbt run --select tag:support`
- `dbt test --select tag:dimension`
- `dbt ls --select state:modified`
- `dbt docs generate`
- `dbt docs serve`

## What's Provided

- **14 staging models** in `models/staging/` — views on raw Salesforce data (accounts, opportunities, leads, cases, contacts, users, campaigns, products, etc.)
- **Source definition** in `models/staging/_src__salesforce.yml`
- **Pre-configured schemas** in `dbt_project.yml`: `staging` (views), `intermediate` (tables), `marts` (tables)
- **Packages**: `dbt_utils`, `dbt_date`, `codegen`

## Your Task

**This is a technical skills demonstration.** The goal is to showcase as many dbt features and best practices as you can. We will **not** evaluate whether the data in your models makes business sense — we are looking at how you use dbt as a tool.

Using the staging models as input, build a dimensional model. The more dbt capabilities you demonstrate, the better.

### Minimum Expected

- Dimension and fact models in `models/marts/`
- dbt tests in YAML schema files
- Proper use of `{{ ref() }}` and materializations

### What Will Impress Us

The list below is not exhaustive — use your experience to decide what's appropriate:

- **Project structure** — clear layering (staging → intermediate → marts), consistent naming conventions (`dim_`, `fct_`, `int_` prefixes), logical file organization
- **SQL style** — CTE-based queries (no nested subqueries), meaningful CTE names, consistent column ordering
- **Schema YAML files** — model and column descriptions, tests co-located with models
- **Testing** — primary key tests (unique + not_null), referential integrity between facts and dimensions, accepted_values for enums, composite key tests
- **Materializations** — appropriate choice per layer, understanding of when to use views vs tables
- **dbt packages** — `dbt_utils` macros (e.g., `generate_surrogate_key`, `unique_combination_of_columns`), `dbt_date` for date dimensions
- **Custom macros** — reusable Jinja logic where it reduces repetition
- **Tags** — organizing models for selective runs
- **Seeds** — static lookup data where useful
- **Snapshots** — SCD Type 2 tracking (timestamp or check strategy)
- **Incremental models** — if you see a good use case for it
- **Window functions** — ROW_NUMBER, LAG/LEAD, running totals
- **Jinja** — loops, conditionals, dynamic SQL generation
- **Documentation** — `persist_docs`, doc blocks, or a brief design rationale

## Interview Format

You will present your solution in a live screen-sharing session. Be prepared to:

- Walk through your project and explain your design decisions
- Demonstrate running `dbt build` and show passing tests
- Discuss trade-offs and alternative approaches
- Answer follow-up questions about dbt concepts and patterns

Good luck!
