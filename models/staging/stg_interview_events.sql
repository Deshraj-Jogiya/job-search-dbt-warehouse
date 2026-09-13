select
    event_id,
    application_id,
    round_name,
    cast(scheduled_date as date) as scheduled_date,
    outcome
from {{ ref('raw_interview_events') }}
