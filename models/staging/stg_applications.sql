select
    application_id,
    posting_id,
    cast(applied_date as date) as applied_date,
    status,
    cast(nullif(decision_date, '') as date) as decision_date
from {{ ref('raw_applications') }}
