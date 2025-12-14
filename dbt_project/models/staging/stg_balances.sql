-- stg_balances.sql
-- Bronze layer: EOD balance snapshots

with source as (
    select * from {{ source('raw', 'balances_eod_raw') }}
),

cleaned as (
    select
        -- Surrogate key for uniqueness
        {{ dbt_utils.generate_surrogate_key(['account_id', 'platform', 'date']) }} as balance_key,
        
        account_id,
        platform,
        cast(date as date) as snapshot_date,
        
        -- Measures
        cast(balance as decimal(18,4)) as balance,
        cast(equity as decimal(18,4)) as equity,
        cast(floating_pnl as decimal(18,4)) as floating_pnl,
        cast(credit as decimal(18,4)) as credit,
        cast(margin_level as decimal(18,4)) as margin_level
        
    from source
    where account_id is not null
)

select * from cleaned
