select
    posting_id,
    company_id,
    job_title,
    seniority,
    cast(posted_date as date) as posted_date,
    source
from {{ ref('raw_job_postings') }}
