{{ config(materialized='table') }}

-- A real date-spine dimension built natively in Databricks SQL (Spark SQL's
-- sequence()/explode(), no external dbt package needed) so
-- fct_daily_pipeline_snapshot has a full calendar to join against, not
-- just the dates that happen to already appear in the source data.
with date_spine as (
    select explode(sequence(to_date('2025-01-01'), to_date('2027-12-31'), interval 1 day)) as date_day
)

select
    date_day,
    year(date_day) as year,
    month(date_day) as month,
    day(date_day) as day_of_month,
    dayofweek(date_day) as day_of_week,
    dayofweek(date_day) in (1, 7) as is_weekend
from date_spine
