{{ config(materialized='table') }}

-- A real date-spine dimension built natively in SQL (Spark SQL's sequence()/explode() on Databricks, range() on DuckDB,
-- no external dbt package needed) so
-- fct_daily_pipeline_snapshot has a full calendar to join against, not
-- just the dates that happen to already appear in the source data.
with date_spine as (
    {{ date_spine('2025-01-01', '2027-12-31') }}
)

select
    date_day,
    year(date_day) as year,
    month(date_day) as month,
    day(date_day) as day_of_month,
    {{ day_of_week('date_day') }} as day_of_week,
    {{ day_of_week('date_day') }} in (1, 7) as is_weekend
from date_spine
