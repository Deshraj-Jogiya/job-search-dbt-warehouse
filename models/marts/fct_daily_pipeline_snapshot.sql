{{
    config(
        materialized='incremental',
        unique_key='date_day',
        incremental_strategy='merge'
    )
}}

-- A real incremental model: one row per calendar day, showing the
-- cumulative shape of the whole application pipeline as of that day. On a
-- fresh build every day up to today is computed; on every later run only
-- days after the latest already-loaded date_day are recomputed and merged
-- in (via unique_key + incremental_strategy='merge', which needs Delta --
-- the default table format on a Databricks SQL warehouse), so re-running
-- this daily doesn't mean rescanning the full application history again.
with dates as (
    select date_day
    from {{ ref('dim_date') }}
    where date_day <= current_date()
    {% if is_incremental() %}
        and date_day > (select coalesce(max(date_day), to_date('1900-01-01')) from {{ this }})
    {% endif %}
),

applications as (
    select * from {{ ref('fct_application') }}
)

select
    d.date_day,
    count(a.application_id) as cumulative_applied_count,
    sum(case when a.is_closed and a.decision_date <= d.date_day then 1 else 0 end) as cumulative_closed_count,
    sum(case when a.decision_date is null or a.decision_date > d.date_day then 1 else 0 end) as open_count,
    sum(case when a.status = 'offer' and a.decision_date <= d.date_day then 1 else 0 end) as cumulative_offer_count,
    sum(case when a.status = 'rejected' and a.decision_date <= d.date_day then 1 else 0 end) as cumulative_rejected_count
from dates d
left join applications a
    on a.applied_date <= d.date_day
group by d.date_day
order by d.date_day
