-- tests/assert_no_deleted_accounts_trading.sql
-- Custom test: Alert if deleted accounts have recent trades

with deleted_account_trades as (
    select
        account_id,
        client_id,
        count(*) as trade_count,
        max(trade_date) as last_trade_date
    from {{ ref('int_trades_enriched') }}
    where is_deleted_account_trade = true
      and not is_cancelled
    group by 1, 2
)

-- Test fails if any rows returned
select * from deleted_account_trades
