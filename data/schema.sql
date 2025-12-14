
-- Minimal Postgres DDL for the reduced RAW dataset

CREATE TABLE trades_raw (
    trade_id TEXT,
    platform TEXT,
    account_id TEXT,
    client_external_id TEXT,
    symbol TEXT,
    side TEXT,
    volume NUMERIC,
    open_time TIMESTAMPTZ,
    close_time TIMESTAMPTZ,
    open_price NUMERIC,
    close_price NUMERIC,
    commission NUMERIC,
    realized_pnl NUMERIC,
    book_flag TEXT,
    counterparty TEXT,
    quote_currency TEXT,
    status TEXT
);

CREATE TABLE accounts_raw (
    account_id TEXT,
    platform TEXT,
    client_id TEXT,
    base_currency TEXT,
    created_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    salesforce_account_id TEXT,
    is_system BOOLEAN,
    is_deleted BOOLEAN
);

CREATE TABLE clients_raw (
    client_id TEXT,
    client_external_id TEXT,
    jurisdiction TEXT,
    segment TEXT,
    created_at TIMESTAMPTZ
);

CREATE TABLE balances_eod_raw (
    account_id TEXT,
    platform TEXT,
    date DATE,
    balance NUMERIC,
    equity NUMERIC,
    floating_pnl NUMERIC,
    credit NUMERIC,
    margin_level NUMERIC
);

CREATE TABLE symbols_ref (
    platform TEXT,
    platform_symbol TEXT,
    std_symbol TEXT,
    asset_class TEXT,
    quote_currency TEXT,
    tick_value NUMERIC
);
