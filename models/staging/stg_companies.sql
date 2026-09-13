select
    company_id,
    company_name,
    industry,
    size_band,
    sponsors_h1b
from {{ ref('raw_companies') }}
