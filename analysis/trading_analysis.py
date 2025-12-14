"""
Trading Analytics - Performance Analysis
=========================================
Answers all business questions from the brief with visualizations.
"""

import pandas as pd
import numpy as np
from pathlib import Path

# ============================================================================
# DATA LOADING (simulates reading from dbt marts)
# ============================================================================

DATA_PATH = Path(__file__).parent.parent / 'data'

def load_and_transform():
    """Load raw data and apply transformations (mirrors dbt logic)."""
    
    # Load raw data
    trades = pd.read_csv(DATA_PATH / 'trades_raw.csv', parse_dates=['open_time', 'close_time'])
    accounts = pd.read_csv(DATA_PATH / 'accounts_raw.csv', parse_dates=['created_at', 'closed_at'])
    clients = pd.read_csv(DATA_PATH / 'clients_raw.csv', parse_dates=['created_at'])
    balances = pd.read_csv(DATA_PATH / 'balances_eod_raw.csv', parse_dates=['date'])
    symbols = pd.read_csv(DATA_PATH / 'symbols_ref.csv')
    
    # === STAGING TRANSFORMATIONS ===
    
    # Normalize side
    trades['side'] = trades['side'].str.upper().replace({'B': 'BUY', 'S': 'SELL'})
    
    # Normalize segment
    clients['segment'] = clients['segment'].str.lower().str.strip()
    
    # Add trade date
    trades['trade_date'] = trades['open_time'].dt.date
    trades['trade_week'] = pd.to_datetime(trades['trade_date']).dt.to_period('W').dt.start_time
    
    # === INTERMEDIATE TRANSFORMATIONS ===
    
    # Build client-account spine
    spine = accounts.merge(clients, on='client_id', how='left', suffixes=('_acct', '_client'))
    
    # Enrich trades with client info
    trades_enriched = trades.merge(
        spine[['account_id', 'platform', 'client_id', 'segment', 'jurisdiction', 'is_system', 'is_deleted']],
        on=['account_id', 'platform'],
        how='left'
    )
    
    # Standardize symbols
    trades_enriched = trades_enriched.merge(
        symbols[['platform', 'platform_symbol', 'std_symbol', 'asset_class']],
        left_on=['platform', 'symbol'],
        right_on=['platform', 'platform_symbol'],
        how='left'
    )
    trades_enriched['std_symbol'] = trades_enriched['std_symbol'].fillna(trades_enriched['symbol'])
    trades_enriched['asset_class'] = trades_enriched['asset_class'].fillna('UNKNOWN')
    
    # Calculate net PnL
    trades_enriched['net_pnl'] = trades_enriched['realized_pnl'] + trades_enriched['commission']
    
    # Flags
    trades_enriched['is_cancelled'] = trades_enriched['status'] == 'CANCELLED'
    
    # Filter for analysis (exclude cancelled, system accounts)
    analysis_trades = trades_enriched[
        (~trades_enriched['is_cancelled']) & 
        (trades_enriched['is_system'] != True)
    ].copy()
    
    # === EOD BALANCES WITH DRAWDOWN ===
    balances = balances.sort_values(['account_id', 'platform', 'date'])
    balances['peak_equity'] = balances.groupby(['account_id', 'platform'])['equity'].cummax()
    balances['drawdown_pct'] = (balances['equity'] - balances['peak_equity']) / balances['peak_equity']
    
    return {
        'trades': analysis_trades,
        'trades_all': trades_enriched,
        'accounts': accounts,
        'clients': clients,
        'balances': balances,
        'symbols': symbols,
        'spine': spine
    }


# ============================================================================
# ANALYSIS FUNCTIONS
# ============================================================================

def performance_analysis(trades):
    """Top/Bottom performers by client and symbol."""
    
    # Client performance
    client_perf = trades.groupby(['client_id', 'segment']).agg(
        trade_count=('trade_id', 'count'),
        total_volume=('volume', 'sum'),
        gross_pnl=('realized_pnl', 'sum'),
        commission=('commission', 'sum'),
        net_pnl=('net_pnl', 'sum')
    ).reset_index()
    
    top_10 = client_perf.nlargest(10, 'net_pnl')[['client_id', 'segment', 'net_pnl', 'trade_count']]
    bottom_10 = client_perf.nsmallest(10, 'net_pnl')[['client_id', 'segment', 'net_pnl', 'trade_count']]
    
    # Symbol performance
    symbol_perf = trades.groupby('std_symbol').agg(
        trade_count=('trade_id', 'count'),
        net_pnl=('net_pnl', 'sum'),
        avg_pnl=('net_pnl', 'mean')
    ).reset_index()
    
    loss_symbols = symbol_perf[symbol_perf['net_pnl'] < 0].nsmallest(10, 'net_pnl')
    
    return {
        'top_10_clients': top_10,
        'bottom_10_clients': bottom_10,
        'loss_symbols': loss_symbols,
        'client_perf': client_perf
    }


def activity_analysis(trades, spine):
    """Active traders and trade size analysis."""
    
    # Daily active traders
    daily_active = trades.groupby('trade_date').agg(
        active_clients=('client_id', 'nunique'),
        active_accounts=('account_id', 'nunique'),
        trade_count=('trade_id', 'count')
    ).reset_index()
    
    # Weekly active traders
    weekly_active = trades.groupby('trade_week').agg(
        active_clients=('client_id', 'nunique'),
        active_accounts=('account_id', 'nunique'),
        trade_count=('trade_id', 'count')
    ).reset_index()
    
    # Avg trade size by symbol
    size_by_symbol = trades.groupby('std_symbol')['volume'].agg(['mean', 'median', 'count']).reset_index()
    size_by_symbol.columns = ['symbol', 'avg_volume', 'median_volume', 'trade_count']
    
    # Avg trade size by segment
    size_by_segment = trades.groupby('segment')['volume'].agg(['mean', 'median', 'count']).reset_index()
    size_by_segment.columns = ['segment', 'avg_volume', 'median_volume', 'trade_count']
    
    return {
        'daily_active': daily_active,
        'weekly_active': weekly_active,
        'size_by_symbol': size_by_symbol.sort_values('avg_volume', ascending=False),
        'size_by_segment': size_by_segment.sort_values('avg_volume', ascending=False)
    }


def risk_analysis(trades_all, balances, spine):
    """Risk metrics: drawdowns, deleted account trading."""
    
    # Largest drawdowns by account
    worst_drawdowns = balances.groupby(['account_id', 'platform']).agg(
        min_drawdown_pct=('drawdown_pct', 'min'),
        current_equity=('equity', 'last'),
        peak_equity=('peak_equity', 'max')
    ).reset_index()
    worst_drawdowns = worst_drawdowns.nsmallest(10, 'min_drawdown_pct')
    
    # Add client info
    worst_drawdowns = worst_drawdowns.merge(
        spine[['account_id', 'platform', 'client_id']].drop_duplicates(),
        on=['account_id', 'platform'],
        how='left'
    )
    
    # Deleted accounts still trading
    deleted_trading = trades_all[
        (trades_all['is_deleted'] == True) & 
        (~trades_all['is_cancelled'])
    ].groupby(['account_id', 'client_id']).agg(
        trade_count=('trade_id', 'count'),
        last_trade=('trade_date', 'max'),
        net_pnl=('net_pnl', 'sum')
    ).reset_index()
    
    return {
        'worst_drawdowns': worst_drawdowns,
        'deleted_trading': deleted_trading
    }


# ============================================================================
# MAIN EXECUTION
# ============================================================================

def main():
    """Run all analyses and generate summary."""
    
    print("=" * 60)
    print("TRADING ANALYTICS - PERFORMANCE ANALYSIS")
    print("=" * 60)
    
    # Load data
    data = load_and_transform()
    trades = data['trades']
    
    print(f"\nData loaded: {len(trades):,} trades (excl. cancelled/system)")
    print(f"Date range: {trades['trade_date'].min()} to {trades['trade_date'].max()}")
    print(f"Unique clients: {trades['client_id'].nunique()}")
    print(f"Unique accounts: {trades['account_id'].nunique()}")
    
    # === PERFORMANCE ===
    print("\n" + "=" * 60)
    print("1. PERFORMANCE ANALYSIS")
    print("=" * 60)
    
    perf = performance_analysis(trades)
    
    print("\n🏆 TOP 10 PERFORMERS (by Net PnL):")
    print(perf['top_10_clients'].to_string(index=False))
    
    print("\n⚠️ BOTTOM 10 PERFORMERS (by Net PnL):")
    print(perf['bottom_10_clients'].to_string(index=False))
    
    print("\n📉 SYMBOLS CONTRIBUTING MOST TO LOSSES:")
    print(perf['loss_symbols'].to_string(index=False))
    
    # === ACTIVITY ===
    print("\n" + "=" * 60)
    print("2. ACTIVITY ANALYSIS")
    print("=" * 60)
    
    activity = activity_analysis(trades, data['spine'])
    
    print("\n📅 DAILY ACTIVE TRADERS (sample):")
    print(activity['daily_active'].tail(10).to_string(index=False))
    
    print("\n📊 AVG TRADE SIZE BY SEGMENT:")
    print(activity['size_by_segment'].to_string(index=False))
    
    print("\n📊 AVG TRADE SIZE BY SYMBOL (Top 10):")
    print(activity['size_by_symbol'].head(10).to_string(index=False))
    
    # === RISK ===
    print("\n" + "=" * 60)
    print("3. RISK ANALYSIS")
    print("=" * 60)
    
    risk = risk_analysis(data['trades_all'], data['balances'], data['spine'])
    
    print("\n🔴 LARGEST EQUITY DRAWDOWNS:")
    print(risk['worst_drawdowns'][['account_id', 'client_id', 'min_drawdown_pct', 'current_equity']].to_string(index=False))
    
    print("\n⚠️ DELETED ACCOUNTS STILL TRADING:")
    if len(risk['deleted_trading']) > 0:
        print(risk['deleted_trading'].to_string(index=False))
    else:
        print("None found.")
    
    # === SUMMARY STATS ===
    print("\n" + "=" * 60)
    print("4. SUMMARY STATISTICS")
    print("=" * 60)
    
    total_pnl = trades['net_pnl'].sum()
    total_volume = trades['volume'].sum()
    avg_pnl_per_trade = trades['net_pnl'].mean()
    win_rate = (trades['net_pnl'] > 0).mean()
    
    print(f"\nTotal Net PnL: ${total_pnl:,.2f}")
    print(f"Total Volume: {total_volume:,.2f} lots")
    print(f"Avg PnL per Trade: ${avg_pnl_per_trade:,.2f}")
    print(f"Win Rate: {win_rate:.1%}")
    print(f"Total Trades: {len(trades):,}")
    
    # By segment
    print("\n📊 BY SEGMENT:")
    seg_summary = trades.groupby('segment').agg(
        clients=('client_id', 'nunique'),
        trades=('trade_id', 'count'),
        net_pnl=('net_pnl', 'sum'),
        avg_pnl=('net_pnl', 'mean')
    ).reset_index()
    print(seg_summary.to_string(index=False))
    
    return {
        'data': data,
        'performance': perf,
        'activity': activity,
        'risk': risk
    }


if __name__ == '__main__':
    results = main()
