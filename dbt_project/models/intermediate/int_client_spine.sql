-- int_client_spine.sql
-- Silver layer: Client-Account mapping spine

with clients as (
    select * from {{ ref('stg_clients') }}
),

accounts as (
    select * from {{ ref('stg_accounts') }}
),

-- Build comprehensive mapping
spine as (
    select
        c.client_id,
        c.client_external_id,
        c.segment,
        c.jurisdiction,
        a.account_id,
        a.platform,
        a.base_currency,
        a.is_system,
        a.is_deleted,
        a.is_closed,
        a.created_at as account_created_at,
        c.created_at as client_created_at
        
    from clients c
    inner join accounts a on c.client_id = a.client_id
)

select * from spine
