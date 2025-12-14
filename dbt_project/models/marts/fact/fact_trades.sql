-- fact_trades.sql
-- Gold layer: Trade fact table

{{
    config(
        materialized='incremental',
        unique_key='trade_id',
        partition_by={'field': 'trade_date', 'data_type': 'date'}
    )
}}

with trades as (
    select * from {{ ref('int_trades_enriched') }}
    {% if var('exclude_cancelled_trades', true) %}
    where not is_cancelled
    {% endif %}
)

select
    trade_id,
    
    -- Foreign keys
    {{ dbt_utils.generate_surrogate_key(['account_id', 'platform']) }} as account_key,
    {{ dbt_utils.generate_surrogate_key(['client_id']) }} as client_key,
    {{ dbt_utils.generate_surrogate_key(['platform', 'platform_symbol']) }} as symbol_key,
    
    -- Degenerate dimensions
    account_id,
    client_id,
    platform,
    platform_symbol,
    std_symbol,
    asset_class,
    side,
    status,
    book_flag,
    counterparty,
    quote_currency,
    segment,
    jurisdiction,
    
    -- Measures
    volume,
    open_price,
    close_price,
    commission,
    realized_pnl,
    net_pnl,
    
    -- Time dimensions
    trade_date,
    trade_week,
    open_time,
    close_time,
    
    -- Flags
    is_system,
    is_deleted_account_trade,
    is_closed_account_trade,
    is_orphan_trade

from trades

{% if is_incremental() %}
where trade_date > (select max(trade_date) from {{ this }})
{% endif %}
