-- A real singular business-rule test: an application's decision can never
-- be dated before the application itself was submitted. dbt fails this
-- test if the query returns any rows at all.
select application_id, applied_date, decision_date
from {{ ref('fct_application') }}
where decision_date is not null
  and decision_date < applied_date
