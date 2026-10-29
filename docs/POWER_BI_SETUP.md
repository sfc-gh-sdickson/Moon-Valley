<img src="Snowflake_Logo.svg" width="200">

# Connecting Power BI to Moon Valley Nursery Semantic Views

This guide explains how Moon Valley Nursery connects **Power BI** directly to Snowflake's governed **Semantic Views** (`SV_MOON_VALLEY_SALES`, `SV_MOON_VALLEY_PLANTING_OPS`, `SV_MOON_VALLEY_INVENTORY_SUPPLY`) and analytical views—eliminating the need to build and maintain a separate semantic-layer database and SSAS cube in 2027.

---

## Architectural Note: Why One Snowflake Semantic View Replaces the "SSIS/SSAS Cube"

During the October 2026 discovery session with **Catherine Digua (Data Lead)** and **Bill Serva (CTO)**, the team described a 2027 target architecture featuring:
1. A separate semantic-layer database in front of the Kimball warehouse.
2. An interactive cube (referred to in the meeting as an *"SSIS cube"*—technically **SSAS / SQL Server Analysis Services** tabular/multidimensional cube, while SSIS is SQL Server Integration Services ETL).
3. Power BI dashboards for field users and SSRS for standard reports.
4. A separate MCP integration so executives can ask questions in Claude.

With **Snowflake Semantic Views**:
- **Single Source of Metric Truth**: Metrics such as `net_sales`, `gross_margin_pct`, `planting_attach_rate`, `same_store_sales`, `avg_days_sold_to_planted`, and `lost_sales_estimate` are defined **once** in `SV_MOON_VALLEY_SALES`, `SV_MOON_VALLEY_PLANTING_OPS`, and `SV_MOON_VALLEY_INVENTORY_SUPPLY`.
- **100% Reconciliation Across Grains**: Because `FACT_SALES_DAILY_LOCATION`, `FACT_SALES_TRANSACTION`, and `FACT_SALES_LINE` are mathematically reconciled in `MVN_INTELLIGENCE.RAW`, a Power BI executive scorecard querying daily store sales and a Claude / Cortex Agent query analyzing line-level tree sales return the **exact same dollar total to the penny**.
- **Shared Row-Level Security**: Power BI DirectQuery with SSO/OAuth passes the signed-in user's Snowflake role (`MVN_EXEC_ROLE` or `MVN_AZ_STORE_MGR_ROLE`), so `MVN_STATE_ROW_ACCESS_POLICY` and customer PII masking apply identically in Power BI, Snowflake Intelligence, and Claude.

---

## Step 1: Connect Power BI Desktop to Snowflake

1. Open **Power BI Desktop** and select **Get Data → Database → Snowflake**.
2. Enter your Snowflake connection settings:
   - **Server**: `<org-name>-<account-name>.snowflakecomputing.com`
   - **Warehouse**: `MOON_VALLEY_WH`
   - **Role** *(Advanced Options)*: `MVN_EXEC_ROLE` (or `MVN_AZ_STORE_MGR_ROLE` to test Arizona store-manager filtering)
3. Select **Microsoft Account / Snowflake OAuth** (or Username/Password for testing) and click **Connect**.
4. In the Navigator pane, expand **`MVN_INTELLIGENCE` → `ANALYTICS`**.
5. Select **DirectQuery** mode so Snowflake enforces Row Access Policies and Dynamic Data Masking in real time for each viewer.

---

## Step 2: Querying the Semantic Views Directly (`SEMANTIC_VIEW` SQL Syntax)

Power BI can either import/DirectQuery the curated analytical views (`V_SALES_DAILY_ENRICHED`, `V_SALES_LINE_ENRICHED`, `V_STORE_RAMP_COHORT`, `V_PLANTING_OPERATIONS`, `V_INVENTORY_AND_STOCKOUTS`) or query the governed **Semantic Views** directly using Snowflake's `SEMANTIC_VIEW(...)` table construct so metric formulas are never duplicated in DAX:

### Example 1: Q4 2026 Net Sales & Gross Margin % by State (Matches Claude & Cortex Agent)
```sql
SELECT *
FROM SEMANTIC_VIEW(
    MVN_INTELLIGENCE.ANALYTICS.SV_MOON_VALLEY_SALES
    DIMENSIONS locations.state
    METRICS
        daily_sales.daily_net_sales,
        sales_lines.gross_margin,
        sales_lines.gross_margin_pct,
        transactions.transaction_count,
        transactions.planting_attach_rate
)
ORDER BY daily_net_sales DESC;
```

### Example 2: Gross Margin % by Box-Tree Container Size (24in vs. 36in vs. 48in+)
```sql
SELECT *
FROM SEMANTIC_VIEW(
    MVN_INTELLIGENCE.ANALYTICS.SV_MOON_VALLEY_SALES
    DIMENSIONS products.container_size
    METRICS
        sales_lines.total_units,
        sales_lines.net_sales,
        sales_lines.gross_margin,
        sales_lines.gross_margin_pct
)
WHERE container_size IN ('24in box', '36in box', '48in box+')
ORDER BY gross_margin_pct DESC;
```

### Example 3: Palm Stockouts & Estimated Lost Sales by Store
```sql
SELECT *
FROM SEMANTIC_VIEW(
    MVN_INTELLIGENCE.ANALYTICS.SV_MOON_VALLEY_INVENTORY_SUPPLY
    DIMENSIONS
        locations.location_id,
        locations.location_name,
        locations.state,
        products.category
    METRICS
        inventory.stockout_days,
        inventory.stockout_rate_pct,
        inventory.lost_sales_estimate
)
WHERE category = 'Palms'
  AND stockout_days > 0
ORDER BY lost_sales_estimate DESC;
```

---

## Step 3: Side-by-Side Reconciliation Check (Power BI vs. Claude / Cortex Agent)

Run this query in Power BI or Snowsight to prove that `FACT_SALES_DAILY_LOCATION`, `FACT_SALES_TRANSACTION`, and `FACT_SALES_LINE` reconcile with `$0.00` variance:

```sql
SELECT
    l.state,
    ROUND(SUM(ds.net_sales), 2) AS daily_fact_net_sales,
    ROUND((
        SELECT SUM(t.net_sales)
        FROM MVN_INTELLIGENCE.RAW.FACT_SALES_TRANSACTION t
        JOIN MVN_INTELLIGENCE.RAW.DIM_DATE d2 ON t.date_key = d2.date_key
        WHERE t.state = l.state AND d2.year = 2026 AND d2.quarter = 4
    ), 2) AS txn_fact_net_sales,
    ROUND((
        SELECT SUM(sl.extended_price)
        FROM MVN_INTELLIGENCE.RAW.FACT_SALES_LINE sl
        JOIN MVN_INTELLIGENCE.RAW.DIM_DATE d3 ON sl.date_key = d3.date_key
        WHERE sl.state = l.state AND d3.year = 2026 AND d3.quarter = 4
    ), 2) AS line_fact_net_sales
FROM MVN_INTELLIGENCE.RAW.FACT_SALES_DAILY_LOCATION ds
JOIN MVN_INTELLIGENCE.RAW.DIM_DATE d ON ds.date_key = d.date_key
JOIN MVN_INTELLIGENCE.RAW.DIM_LOCATION l ON ds.location_id = l.location_id
WHERE d.year = 2026 AND d.quarter = 4
GROUP BY l.state
ORDER BY daily_fact_net_sales DESC;
```
