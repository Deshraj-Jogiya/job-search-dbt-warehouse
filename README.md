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
                                         |
                                  fct_interview_event
```

- `dim_company`, `dim_job_posting` -- dimension tables.
- `fct_application` -- one row per application: joined back to its posting/company,
  `days_to_decision` (a real `datediff`), `interview_round_count`, and `reached_interview`
  / `is_closed` flags.
- `fct_interview_event` -- one row per interview round, with `round_sequence` computed via
  a `row_number()` window function partitioned by application.

Tests (`models/marts/schema.yml`): `unique` + `not_null` on every primary key,
`relationships` foreign-key tests between facts and dimensions, and an `accepted_values`
test on application status.

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
