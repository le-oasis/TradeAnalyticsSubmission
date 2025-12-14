-- stg_accounts.sql
-- Bronze layer: type casting and flag standardization

with source as (
    select * from {{ source('raw', 'accounts_raw') }}
),

cleaned as (
    select
        account_id,
        platform,
        client_id,
        upper(base_currency) as base_currency,
        salesforce_account_id,
        
        -- Boolean flags (handle string/bool variations)
        coalesce(is_system, false) as is_system,
        coalesce(is_deleted, false) as is_deleted,
        
        -- Timestamps
        cast(created_at as timestamp) as created_at,
        cast(closed_at as timestamp) as closed_at,
        
        -- Derived flags
        case when closed_at is not null then true else false end as is_closed
        
    from source
    where account_id is not null
)

select * from cleaned
