-- tests/assert_no_orphan_trades.sql
-- Custom test: All trades should link to a client

with orphan_trades as (
    select
        trade_id,
        account_id,
        platform,
        trade_date
    from {{ ref('int_trades_enriched') }}
    where is_orphan_trade = true
)

-- Test fails if any rows returned
select * from orphan_trades
