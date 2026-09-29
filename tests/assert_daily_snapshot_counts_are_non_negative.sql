-- The daily pipeline snapshot's derived counts should never go negative --
-- a negative count here would mean the incremental aggregation logic is
-- double-subtracting or mis-joining somewhere. dbt fails this test if the
-- query returns any rows at all.
select
    date_day, cumulative_applied_count, cumulative_closed_count,
    open_count, cumulative_offer_count, cumulative_rejected_count
from {{ ref('fct_daily_pipeline_snapshot') }}
where cumulative_applied_count < 0
   or cumulative_closed_count < 0
   or open_count < 0
   or cumulative_offer_count < 0
   or cumulative_rejected_count < 0
