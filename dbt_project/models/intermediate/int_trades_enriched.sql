-- int_trades_enriched.sql
-- Silver layer: Core trade enrichment with all business logic

with trades as (
    select * from {{ ref('stg_trades') }}
),

spine as (
    select * from {{ ref('int_client_spine') }}
),

symbols as (
    select * from {{ ref('stg_symbols') }}
),

enriched as (
    select
        -- Trade identifiers
        t.trade_id,
        t.account_id,
        
        -- Client resolution (via account)
        s.client_id,
        s.client_external_id,
        s.segment,
        s.jurisdiction,
        
        -- Symbol standardization
        t.platform,
        t.symbol as platform_symbol,
        coalesce(sym.std_symbol, t.symbol) as std_symbol,
        coalesce(sym.asset_class, 'UNKNOWN') as asset_class,
        
        -- Trade details
        t.side,
        t.status,
        t.book_flag,
        t.counterparty,
        t.quote_currency,
        
        -- Measures
        t.volume,
        t.open_price,
        t.close_price,
        t.commission,
        t.realized_pnl,
        t.realized_pnl + t.commission as net_pnl,
        
        -- Time dimensions
        t.open_time,
        t.close_time,
        t.trade_date,
        date_trunc('week', t.trade_date) as trade_week,
        
        -- Data quality & risk flags
        s.is_system,
        s.is_deleted as is_deleted_account_trade,
        s.is_closed as is_closed_account_trade,
        case when t.status = 'CANCELLED' then true else false end as is_cancelled,
        case when s.client_id is null then true else false end as is_orphan_trade
        
    from trades t
    left join spine s on t.account_id = s.account_id and t.platform = s.platform
    left join symbols sym on t.platform = sym.platform and t.symbol = sym.platform_symbol
)

select * from enriched
