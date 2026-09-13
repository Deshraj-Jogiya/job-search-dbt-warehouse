select
    event_id,
    application_id,
    round_name,
    scheduled_date,
    outcome,
    row_number() over (
        partition by application_id
        order by scheduled_date
    ) as round_sequence
from {{ ref('stg_interview_events') }}
