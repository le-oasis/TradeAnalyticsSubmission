-- dim_client.sql
-- Gold layer: Client dimension

with clients as (
    select * from {{ ref('stg_clients') }}
),

account_stats as (
    select
        client_id,
        count(distinct account_id) as account_count,
        min(account_created_at) as first_account_date,
        max(account_created_at) as last_account_date
    from {{ ref('int_client_spine') }}
    where not is_system
    group by 1
)

select
    {{ dbt_utils.generate_surrogate_key(['c.client_id']) }} as client_key,
    c.client_id,
    c.client_external_id,
    c.segment,
    c.jurisdiction,
    c.created_at as client_created_at,
    coalesce(s.account_count, 0) as account_count,
    s.first_account_date,
    s.last_account_date

from clients c
left join account_stats s on c.client_id = s.client_id
