-- f_client_performance_daily.sql
-- Gold layer: Pre-aggregated client performance (OLAP cube pattern)

{{
    config(
        materialized='table'
    )
}}

with trades as (
    select * from {{ ref('fact_trades') }}
    where not is_system
      and client_id is not null
),

daily_agg as (
    select
        client_id,
        segment,
        jurisdiction,
        trade_date,
        
        -- Activity metrics
        count(distinct trade_id) as trade_count,
        count(distinct account_id) as active_accounts,
        count(distinct std_symbol) as symbols_traded,
        
        -- Volume metrics
        sum(volume) as total_volume,
        avg(volume) as avg_trade_size,
        
        -- PnL metrics
        sum(realized_pnl) as gross_pnl,
        sum(commission) as total_commission,
        sum(net_pnl) as net_pnl,
        
        -- Win/loss breakdown
        sum(case when net_pnl > 0 then 1 else 0 end) as winning_trades,
        sum(case when net_pnl < 0 then 1 else 0 end) as losing_trades,
        sum(case when net_pnl > 0 then net_pnl else 0 end) as gross_profit,
        sum(case when net_pnl < 0 then net_pnl else 0 end) as gross_loss
        
    from trades
    group by 1, 2, 3, 4
)

select
    {{ dbt_utils.generate_surrogate_key(['client_id', 'trade_date']) }} as performance_key,
    {{ dbt_utils.generate_surrogate_key(['client_id']) }} as client_key,
    *,
    
    -- Derived metrics
    case when losing_trades > 0 
        then winning_trades::float / (winning_trades + losing_trades) 
        else 1 
    end as win_rate,
    
    case when gross_loss != 0 
        then abs(gross_profit / gross_loss) 
        else null 
    end as profit_factor

from daily_agg
