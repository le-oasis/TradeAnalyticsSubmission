-- fact_account_eod.sql
-- Gold layer: Daily account snapshot with drawdown calculations

{{
    config(
        materialized='incremental',
        unique_key='balance_key',
        partition_by={'field': 'snapshot_date', 'data_type': 'date'}
    )
}}

with balances as (
    select * from {{ ref('stg_balances') }}
),

accounts as (
    select * from {{ ref('dim_account') }}
),

with_peaks as (
    select
        b.*,
        a.client_id,
        a.client_segment,
        a.is_system,
        a.is_deleted,
        
        -- Running max equity for drawdown calc
        max(b.equity) over (
            partition by b.account_id, b.platform 
            order by b.snapshot_date
            rows between unbounded preceding and current row
        ) as peak_equity
        
    from balances b
    left join accounts a on b.account_id = a.account_id and b.platform = a.platform
)

select
    balance_key,
    account_id,
    platform,
    client_id,
    client_segment,
    snapshot_date,
    
    -- Measures
    balance,
    equity,
    floating_pnl,
    credit,
    margin_level,
    
    -- Drawdown metrics
    peak_equity,
    equity - peak_equity as drawdown_absolute,
    case 
        when peak_equity > 0 then (equity - peak_equity) / peak_equity 
        else 0 
    end as drawdown_pct,
    
    -- Flags
    is_system,
    is_deleted

from with_peaks

{% if is_incremental() %}
where snapshot_date > (select max(snapshot_date) from {{ this }})
{% endif %}
