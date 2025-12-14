# Key Insights & Findings

## Executive Summary

Analysis of **1,336 trades** from **40 clients** across **69 accounts** over a 31-day period (July 15 - August 14, 2025).

| Metric | Value |
|--------|-------|
| Total Net PnL | $302,278 |
| Win Rate | 45.9% |
| Avg PnL/Trade | $226 |
| Total Volume | 63,017 lots |

---

## 1. Performance Insights

### Top Performers
| Rank | Client | Segment | Net PnL | Trades |
|------|--------|---------|---------|--------|
| 1 | C0038 | retail | $251,400 | 31 |
| 2 | C0032 | retail | $211,269 | 62 |
| 3 | C0034 | pro | $151,426 | 34 |

**Key Insight**: VIP segment has highest average PnL ($992/trade) despite fewer total trades.

### Underperformers
| Rank | Client | Segment | Net PnL | Trades |
|------|--------|---------|---------|--------|
| 1 | C0025 | retail | -$256,938 | 20 |
| 2 | C0033 | pro | -$161,314 | 52 |
| 3 | C0020 | retail | -$101,930 | 20 |

**Key Insight**: C0025 and C0033 account for 53% of total client losses.

### Loss-Driving Symbols
| Symbol | Net PnL | Trades |
|--------|---------|--------|
| US500 | -$179,451 | 62 |
| WTI | -$175,734 | 69 |
| ETHUSD | -$78,787 | 91 |

**Action**: Consider tightening risk limits on US500 and WTI positions.

---

## 2. Activity Insights

### Daily Activity
- **Average daily active clients**: 22
- **Peak day**: August 10 (23 clients, 53 trades)
- **Quietest day**: August 12 (16 clients, 33 trades)

### Trade Size by Segment
| Segment | Avg Volume | Median Volume |
|---------|------------|---------------|
| VIP | 52.7 lots | 5.0 lots |
| Retail | 50.1 lots | 5.0 lots |
| Pro | 41.1 lots | 5.0 lots |

**Key Insight**: VIP clients trade larger average sizes but similar median (driven by outliers).

---

## 3. Risk Alerts

### Severe Drawdowns
| Account | Client | Drawdown | Current Equity |
|---------|--------|----------|----------------|
| A12VJ99T2D | C0033 | -99.6% | $395 |
| A2DHYLURTP | C0018 | -94.4% | $1,912 |

**Critical**: A12VJ99T2D has essentially blown up (-99.6% drawdown).

### Deleted Accounts Still Trading ⚠️
**9 accounts** marked as `is_deleted=true` have recent trades:

| Account | Client | Trades | Net PnL |
|---------|--------|--------|---------|
| AZSJ49ITN7 | C0025 | 20 | -$256,938 |
| AC89K8YQK9 | C0029 | 23 | $141,880 |
| ANFHOLQC3O | C0013 | 24 | -$94,410 |

**Action Required**: Investigate data sync between trading platform and account registry.

---

## 4. Segment Analysis

| Segment | Clients | Trades | Total PnL | Avg PnL | Win Rate |
|---------|---------|--------|-----------|---------|----------|
| VIP | 7 | 206 | $204,308 | $992 | - |
| Pro | 12 | 499 | $70,928 | $142 | - |
| Retail | 21 | 631 | $27,042 | $43 | - |

**Key Insight**: VIP clients (18% of clients) generate 68% of total profits.

---

## Recommendations

1. **Immediate**: Audit deleted accounts with active trades - data integrity issue
2. **Short-term**: Implement position limits for US500 and WTI
3. **Medium-term**: Review risk parameters for accounts with >50% drawdown
4. **Strategic**: Analyze VIP segment success factors for retail client education
