# Job Search dbt Warehouse

A small dbt project that builds a dimensional model on top of a Databricks SQL warehouse
(Databricks Free Edition) -- staging views over raw seed data, then dimension and fact
tables with real joins, a window function, and dbt's built-in data tests.

## Data

The four `seeds/raw_*.csv` files are **synthetic sample data** in the job-search domain
(companies, postings, applications, interview rounds) -- not a real company's data. This
project exists to demonstrate the transformation pipeline (dbt seed -> staging -> marts ->
tests) against a real warehouse, not to model this author's actual job search (that data
lives in the separate Career Pilot CRM).

## Model

```
raw_companies  raw_job_postings  raw_applications  raw_interview_events   (dbt seed)
      |               |                  |                   |
stg_companies   stg_job_postings   stg_applications   stg_interview_events (views)
      |               |                  |                   |
      +-------> dim_company             |                   |
                      |                  |                   |
              dim_job_posting   <--------+                   |
                                         |                   |
                                  fct_application  <----------+
                                    |         |
                                    |    fct_interview_event
                                    |
                     dim_date  ->  fct_daily_pipeline_snapshot  (incremental)
```

- `dim_company`, `dim_job_posting`, `dim_date` -- dimension tables. `dim_date` is a real
  date spine (2025-01-01 through 2027-12-31) built natively in Databricks SQL
  (`sequence()` + `explode()`, no external dbt package needed).
- `fct_application` -- one row per application: joined back to its posting/company,
  `days_to_decision` (a real `datediff`), `interview_round_count`, and `reached_interview`
  / `is_closed` flags.
- `fct_interview_event` -- one row per interview round, with `round_sequence` computed via
  a `row_number()` window function partitioned by application.
- `fct_daily_pipeline_snapshot` -- **a real incremental model**, one row per calendar day
  showing the cumulative shape of the whole pipeline as of that day (applied/closed/open/
  offer/rejected counts). Materialized `incremental` with `unique_key='date_day'` and
  `incremental_strategy='merge'`: a fresh build computes every day up to today, but a later
  run only recomputes and merges in days after the latest already-loaded `date_day`, rather
  than rescanning the full application history on every run.

Tests (`models/marts/schema.yml`): `unique` + `not_null` on every primary key,
`relationships` foreign-key tests between facts and dimensions, and an `accepted_values`
test on application status. Two real singular tests (`tests/*.sql`) check business rules
a generic schema test can't express: a decision date can never be before the applied date,
and the daily snapshot's derived counts can never go negative.

## Running it

Requires a Databricks SQL warehouse and a personal access token.

```bash
pip install -r requirements.txt

export DATABRICKS_HOST=<your-workspace-hostname>
export DATABRICKS_HTTP_PATH=<your-warehouse-http-path>
export DATABRICKS_TOKEN=<your-personal-access-token>

dbt seed --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .
```

`profiles.yml` reads all three values from the environment (`env_var(...)`) -- nothing
sensitive is committed to this repo.

## CI

`.github/workflows/ci.yml` runs `dbt seed`, `dbt run`, and `dbt test` against the real
Databricks warehouse on every push, using repository secrets for the credentials, into a
separate `job_search_dbt_ci` schema so it never collides with manual runs against the
`job_search_dbt` schema.
