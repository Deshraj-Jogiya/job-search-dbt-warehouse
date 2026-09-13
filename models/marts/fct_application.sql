with applications as (
    select * from {{ ref('stg_applications') }}
),

postings as (
    select * from {{ ref('stg_job_postings') }}
),

interview_counts as (
    select
        application_id,
        count(*) as interview_round_count
    from {{ ref('stg_interview_events') }}
    group by application_id
)

select
    a.application_id,
    a.posting_id,
    p.company_id,
    a.applied_date,
    a.status,
    a.decision_date,
    coalesce(ic.interview_round_count, 0) as interview_round_count,
    coalesce(ic.interview_round_count, 0) > 0 as reached_interview,
    datediff(a.decision_date, a.applied_date) as days_to_decision,
    a.status in ('offer', 'rejected', 'withdrawn') as is_closed
from applications a
left join postings p on p.posting_id = a.posting_id
left join interview_counts ic on ic.application_id = a.application_id
