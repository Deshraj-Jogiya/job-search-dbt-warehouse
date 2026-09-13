select
    p.posting_id,
    p.company_id,
    c.company_name,
    p.job_title,
    p.seniority,
    p.posted_date,
    p.source
from {{ ref('stg_job_postings') }} p
left join {{ ref('stg_companies') }} c on c.company_id = p.company_id
