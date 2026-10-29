<img src="Snowflake_Logo.svg" width="200">

# Moon Valley Nursery — Step-by-Step Agent Setup Guide

This guide walks through deploying the complete **Moon Valley Nursery Intelligence Agent (`MOON_VALLEY_AGENT`)**, its Kimball star schema, 3 Semantic Views, 3 Cortex Search services, 4 registered ML models, RBAC governance policies, and Snowflake-managed MCP server.

---

## Prerequisites

- **Snowflake Account**: Enterprise Edition or higher (required for Row Access Policies and Dynamic Data Masking).
- **Role**: `ACCOUNTADMIN` (for initial setup of roles, row access policies, masking policies, and OAuth security integration).
- **Cortex Enabled**: Cortex Analyst, Cortex Search, and Snowflake Intelligence / CoWork enabled on the account.

---

## Deployment Flow

<img src="images/deployment_flow.svg" width="850">

Execute the project files in the exact sequence below:

### Step 1: Database, Schemas & Warehouse (`sql/setup/01_database_and_schema.sql`)
Creates:
- Database: `MVN_INTELLIGENCE`
- Schemas: `RAW`, `ANALYTICS`, `REFERENCE`
- Warehouse: `MOON_VALLEY_WH` (`X-SMALL`, auto-suspend 300s, auto-resume)

### Step 2: Create Kimball & Reference Tables (`sql/setup/02_create_tables.sql`)
Creates 23 tables across `RAW` and `REFERENCE`:
- **8 Conformed Dimensions**: `DIM_DATE`, `DIM_LOCATION`, `DIM_FARM`, `DIM_PRODUCT`, `DIM_CUSTOMER`, `DIM_SALESPERSON`, `DIM_CREW`, `DIM_CAMPAIGN`
- **3 Kimball Sales Facts**: `FACT_SALES_DAILY_LOCATION`, `FACT_SALES_TRANSACTION`, `FACT_SALES_LINE`
- **4 Supporting Facts**: `FACT_PLANTED_JOBS`, `FACT_INVENTORY_DAILY`, `FACT_FARM_TRANSFERS`, `FACT_MARKETING_LEADS`
- **3 Unstructured Search Tables**: `PLANTING_FIELD_NOTES`, `PLANT_CARE_GUIDES`, `WARRANTY_POLICIES`
- **5 Reference Standard Tables**: `HARDINESS_ZONE_DIM`, `PLANT_TAXONOMY_DIM`, `WATER_USE_DIM`, `GS1_IDENTIFIERS`, `PRODUCT_TAXONOMY_MAP`

### Step 3: Generate Synthetic Nursery Data (`sql/data/03_generate_synthetic_data.sql`)
Populates all dimensions and facts (2015–2026) and executes an automated reconciliation check confirming `$0.00` variance between `FACT_SALES_DAILY_LOCATION`, `FACT_SALES_TRANSACTION`, and `FACT_SALES_LINE`.

### Step 3b: Seed Reference Standards & Unstructured Docs (`sql/data/03b_seed_reference_data.sql`)
Seeds USDA Plant Hardiness Zones (`8a`–`11a`), USDA PLANTS Database symbols, regional water-use classes, 512 GS1 GTIN/GLN identifiers, product taxonomy mappings, 240 planting crew notes, 60 plant care guides, and 30 synthetic warranty policy documents.

### Step 4: Create Analytical & ML Feature Views (`sql/views/04_create_views.sql`)
Creates 7 business analytical views (`V_SALES_DAILY_ENRICHED`, `V_SALES_LINE_ENRICHED`, `V_STORE_RAMP_COHORT`, `V_PLANTING_OPERATIONS`, `V_INVENTORY_AND_STOCKOUTS`, `V_FARM_TO_STORE_SUPPLY`, `V_CAMPAIGN_CONVERSION`) and 4 ML feature views (`V_WEEKLY_SALES_STORE_CATEGORY`, `V_ML_STOCKOUT_FEATURES`, `V_ML_PLANTING_ATTACH_FEATURES`, `V_ML_PLANTING_DELAY_FEATURES`).

### Step 5: Create Governed Semantic Views (`sql/views/05_create_semantic_views.sql`)
Creates the 3 Semantic Views in `MVN_INTELLIGENCE.ANALYTICS`:
1. `SV_MOON_VALLEY_SALES`
2. `SV_MOON_VALLEY_PLANTING_OPS`
3. `SV_MOON_VALLEY_INVENTORY_SUPPLY`

### Step 6: Create Cortex Search Services (`sql/search/06_create_cortex_search.sql`)
Creates the 3 Cortex Search services in `MVN_INTELLIGENCE.ANALYTICS`:
1. `MVN_PLANTING_NOTES_SEARCH`
2. `MVN_PLANT_CARE_SEARCH`
3. `MVN_WARRANTY_POLICY_SEARCH`

### Step 7: Train & Register ML Models (`notebooks/07_ml_models.ipynb`)
Upload and run `notebooks/07_ml_models.ipynb` in Snowflake Workspaces / Notebooks to train, evaluate, log metrics (`mv.set_metric()`), and register all 4 models in `MVN_INTELLIGENCE.ANALYTICS`:
1. `WEEKLY_SALES_FORECAST_MODEL` (`V1`)
2. `STOCKOUT_RISK_MODEL` (`V1`)
3. `PLANTING_ATTACH_MODEL` (`V1`)
4. `PLANTING_DELAY_RISK_MODEL` (`V1`)

### Step 8: Create ML Prediction UDFs (`sql/models/08_ml_model_functions.sql`)
Creates the 4 SQL UDFs (`RETURNS ARRAY`, calling `MODEL()!PREDICT()`):
1. `AGENT_FORECAST_WEEKLY_SALES()`
2. `AGENT_STOCKOUT_RISK()`
3. `AGENT_PLANTING_ATTACH_PROPENSITY()`
4. `AGENT_PLANTING_DELAY_RISK()`

### Step 9: Create Cortex Agent (`sql/agent/09_create_agent.sql`)
Creates `MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_AGENT` wiring all 3 Cortex Analyst tools, 3 Cortex Search tools, 4 ML UDF tools, and `data_to_chart`.

### Step 10: Apply Governance Roles & Policies (`sql/governance/10_roles_and_policies.sql`)
Creates `MVN_EXEC_ROLE` and `MVN_AZ_STORE_MGR_ROLE`, attaches `MVN_STATE_ROW_ACCESS_POLICY` to all location-keyed tables, attaches `MVN_EMAIL_MASKING_POLICY` and `MVN_PHONE_MASKING_POLICY` to `DIM_CUSTOMER`, and grants privileges on all underlying objects.

### Step 11: Create Snowflake-Managed MCP Server (`sql/mcp/11_create_mcp_server.sql`)
Creates `MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_MCP` exposing **only** `MOON_VALLEY_AGENT` (`type: "CORTEX_AGENT_RUN"`) and configures `MVN_CLAUDE_MCP_OAUTH`.

---

## Post-Deployment Verification Queries

```sql
-- 1. Verify zero empty tables
SELECT TABLE_SCHEMA, TABLE_NAME, ROW_COUNT
FROM MVN_INTELLIGENCE.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- 2. Verify Semantic Views, Search Services, Models, Functions, Agent, and MCP Server
SHOW SEMANTIC VIEWS IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
SHOW CORTEX SEARCH SERVICES IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
SHOW MODELS IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
SHOW USER FUNCTIONS IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
SHOW AGENTS IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
SHOW MCP SERVERS IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
```
