# Findings

What the checks in this project found, with the numbers from the run that produced them. The seed data is synthetic job-search data
(10 companies, 15 postings, 17 applications, 14 interview rounds), so the findings are about the pipeline, not about a job market.

## 1. Can the same dbt models run on two warehouses without silent errors?

**Why it matters.** A model that compiles on a second engine can still return wrong numbers. Two of the expressions here run on both
Databricks SQL and DuckDB but mean different things on each.

**Test.** Build all 10 models on DuckDB (`--target ci`), then compare each engine-specific expression with what a straight copy of the
Databricks SQL would return on the same 1,095-day calendar (2025-01-01 to 2027-12-31) and the same 17 applications.

**Results.**

| Expression | Databricks SQL | DuckDB | A straight copy on DuckDB |
|---|---|---|---|
| Day of week | Sunday = 1, Saturday = 7 | Sunday = 0, Saturday = 6 | `dayofweek(d) in (1, 7)` is wrong on 468 of 1,095 days: 156 Mondays flagged as weekend, all 312 weekend days missed |
| Days between two dates | `datediff(end, start)` | `date_diff('day', start, end)` | with the arguments in Databricks order, all 10 decided applications come out negative |
| Date spine | `explode(sequence(...))` | `range(...)` | does not run |
| Date literal, today | `to_date('...')`, `current_date()` | `cast('...' as date)`, `current_date` | does not run |

**Decision.** Five macros in `macros/portable.sql` (`as_date`, `today`, `days_between`, `date_spine`, `day_of_week`) choose the right form
for the target, and the models call the macros instead of the functions. On DuckDB, 2025-01-04 (a Saturday) is day 7 and 2025-01-05
(a Sunday) is day 1, the same as on Databricks, and the 312 weekend days match.

## 2. Does the incremental snapshot avoid duplicate days?

**Why it matters.** `fct_daily_pipeline_snapshot` adds one row per calendar day. A second run that re-inserted earlier days would
double every count behind it.

**Test.** Build the snapshot, run it again on its own, then count rows against distinct days.

**Results.** After both runs the row count equals the count of distinct days: one row per day from 2025-01-01 to the run date, none
twice. The incremental filter only selects days after
the latest loaded `date_day`, and the key on `date_day` (`merge` on Databricks, `delete+insert` on DuckDB) replaces a day instead of
adding it twice. The second run is part of CI.

## 3. Do the 22 tests pass on both engines?

**Results.** On DuckDB, `dbt test` passes 22 of 22: 20 schema tests (6 unique, 9 not-null, 4 referential-integrity, 1 accepted-values)
and the two business rules (a decision date never comes before the applied date; snapshot counts never go negative). The same tests
passed on the Databricks SQL warehouse when it was built there.

## Reproduce

```bash
pip install -r requirements-ci.txt
dbt seed --profiles-dir . --target ci --full-refresh
dbt run  --profiles-dir . --target ci
dbt run  --profiles-dir . --target ci --select fct_daily_pipeline_snapshot
dbt test --profiles-dir . --target ci
```
