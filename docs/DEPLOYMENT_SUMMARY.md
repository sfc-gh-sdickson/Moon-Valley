<img src="Snowflake_Logo.svg" width="200">

# Moon Valley Nursery Intelligence Agent — Deployment & Build Summary

## Project Status: Ready for Review (Pre-Deployment)

All SQL scripts, Snowflake Notebook cells, SVG architecture diagrams, and setup/demo documentation have been authored and verified against Snowflake syntax standards. Per instructions, **no objects have been deployed to Snowflake yet** pending your review and approval.

---

## Complete Artifact Inventory

### 1. SQL Scripts (`sql/`)

| Execution Step | File Path | Objects Created |
|----------------|-----------|-----------------|
| **01** | `sql/setup/01_database_and_schema.sql` | Database `MVN_INTELLIGENCE`, Schemas `RAW`, `ANALYTICS`, `REFERENCE`, Warehouse `MOON_VALLEY_WH` |
| **02** | `sql/setup/02_create_tables.sql` | 8 Conformed Dimensions, 3 Kimball Sales Facts, 4 Supporting Facts, 5 Reference Tables, 3 Unstructured Search Tables (23 tables total) |
| **03** | `sql/data/03_generate_synthetic_data.sql` | Synthetic data (2015–2026) with automated 3-fact reconciliation check (`$0.00` variance) |
| **03b** | `sql/data/03b_seed_reference_data.sql` | USDA Hardiness Zones (`8a`–`11a`), USDA PLANTS Taxonomy (38 symbols), Water-Use Classes, 512 GS1 GTIN/GLN IDs, SKU Crosswalk, 330 Unstructured Search Docs |
| **04** | `sql/views/04_create_views.sql` | 7 Business Analytical Views + 4 ML Feature Engineering Views |
| **05** | `sql/views/05_create_semantic_views.sql` | 3 Semantic Views: `SV_MOON_VALLEY_SALES`, `SV_MOON_VALLEY_PLANTING_OPS`, `SV_MOON_VALLEY_INVENTORY_SUPPLY` (with `TABLES`, `RELATIONSHIPS`, `FACTS`, `DIMENSIONS`, `METRICS`, `AI_SQL_GENERATION`, `AI_VERIFIED_QUERIES`) |
| **06** | `sql/search/06_create_cortex_search.sql` | 3 Cortex Search Services: `MVN_PLANTING_NOTES_SEARCH`, `MVN_PLANT_CARE_SEARCH`, `MVN_WARRANTY_POLICY_SEARCH` |
| **07** | `notebooks/07_ml_models.ipynb` | Snowflake Notebook training, evaluating, logging metrics (`mv.set_metric()`), and registering 4 ML models in `MVN_INTELLIGENCE.ANALYTICS` |
| **08** | `sql/models/08_ml_model_functions.sql` | 4 SQL UDFs (`RETURNS ARRAY`, calling `MODEL()!PREDICT()`): `AGENT_FORECAST_WEEKLY_SALES`, `AGENT_STOCKOUT_RISK`, `AGENT_PLANTING_ATTACH_PROPENSITY`, `AGENT_PLANTING_DELAY_RISK` |
| **09** | `sql/agent/09_create_agent.sql` | Cortex Agent `MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_AGENT` (YAML spec with 11 tools) |
| **10** | `sql/governance/10_roles_and_policies.sql` | Roles `MVN_EXEC_ROLE` & `MVN_AZ_STORE_MGR_ROLE`, `MVN_STATE_ROW_ACCESS_POLICY`, `MVN_EMAIL_MASKING_POLICY`, `MVN_PHONE_MASKING_POLICY`, and full grants |
| **11** | `sql/mcp/11_create_mcp_server.sql` | Snowflake-managed MCP server `MOON_VALLEY_MCP` (exposing **only** `MOON_VALLEY_AGENT` via `CORTEX_AGENT_RUN`) + OAuth Security Integration `MVN_CLAUDE_MCP_OAUTH` |
| **99** | `sql/setup/99_teardown.sql` | Clean teardown script |

---

### 2. SVG Graphics (`docs/images/`)

| File | Dimensions | Description |
|------|------------|-------------|
| `Snowflake_Logo.svg` | Vector | Official Snowflake logo (included in root, `docs/`, and `docs/images/`) |
| `docs/images/architecture.svg` | `1200 × 880` | End-to-end system architecture diagram |
| `docs/images/deployment_flow.svg` | `1000 × 700` | Sequential deployment flow (`01` → `11`) with L-shaped row connectors |
| `docs/images/kimball_model.svg` | `1200 × 840` | 3-fact Kimball sales constellation, 4 supporting facts, 8 conformed dimensions, and 5 reference tables |
| `docs/images/agent_tool_decision.svg` | `1200 × 1050` | Agent orchestration decision tree and multi-tool chaining flows |
| `docs/images/governance_roles.svg` | `1100 × 680` | Side-by-side `MVN_EXEC_ROLE` vs. `MVN_AZ_STORE_MGR_ROLE` query & PII masking comparison |
| `docs/images/ml_models.svg` | `1100 × 540` | 4-model Snowpark ML training, Model Registry, and `MODEL()!PREDICT()` UDF pipeline |

---

### 3. Documentation (`docs/`)

- `README.md` — Project overview, architecture, Kimball model, ML models, and execution order
- `docs/AGENT_SETUP.md` — Step-by-step deployment and verification guide
- `docs/MCP_CLAUDE_SETUP.md` — Managed MCP server + Claude.ai OAuth custom connector guide
- `docs/POWER_BI_SETUP.md` — Connecting Power BI to Semantic Views (including SSAS vs. SSIS cube architectural note)
- `docs/DEMO_SCRIPT.md` — 7–10 minute live demo script for Catherine Digua & Bill Serva
- `docs/DEPLOYMENT_SUMMARY.md` — Complete artifact inventory and compliance checklist
- `docs/questions.md` — 32 complex test questions across all tools and roles
