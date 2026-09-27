-- Singular test: returns records that fail assertion (total_events_logged < 0)
select
    user_key,
    user_id,
    total_events_logged
from {{ ref('dim_users') }}
where total_events_logged < 0
