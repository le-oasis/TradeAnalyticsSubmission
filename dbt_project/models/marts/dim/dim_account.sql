-- dim_account.sql
-- Gold layer: Account dimension

with spine as (
    select * from {{ ref('int_client_spine') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['account_id', 'platform']) }} as account_key,
    account_id,
    platform,
    client_id,
    base_currency,
    is_system,
    is_deleted,
    is_closed,
    account_created_at as created_at,
    
    -- Segment denormalized for easy filtering
    segment as client_segment,
    jurisdiction as client_jurisdiction

from spine
