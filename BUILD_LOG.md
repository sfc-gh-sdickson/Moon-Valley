<img src="Snowflake_Logo.svg" width="200">

# Moon Valley Nursery Intelligence Agent — Build Log

## Build Status: Complete (Review Mode — Awaiting Approval Before Deployment)

### Timestamped Log
- **[2026-10-29 11:40]** Initialized directory hierarchy (`docs/images`, `notebooks`, `sql/{setup,data,views,search,models,agent,governance,mcp}`).
- **[2026-10-29 11:40]** Copied `Snowflake_Logo.svg` (15,048 bytes) to project root, `docs/`, and `docs/images/`.
- **[2026-10-29 11:40]** Confirmed build scope with user:
  - **3 Semantic Views:** `SV_MOON_VALLEY_SALES`, `SV_MOON_VALLEY_PLANTING_OPS`, `SV_MOON_VALLEY_INVENTORY_SUPPLY`
  - **3 Cortex Search Services:** `MVN_PLANTING_NOTES_SEARCH`, `MVN_PLANT_CARE_SEARCH`, `MVN_WARRANTY_POLICY_SEARCH`
  - **4 ML Models:** `WEEKLY_SALES_FORECAST_MODEL`, `STOCKOUT_RISK_MODEL`, `PLANTING_ATTACH_MODEL`, `PLANTING_DELAY_RISK_MODEL`
  - **Governance Roles:** `MVN_EXEC_ROLE` (full access) & `MVN_AZ_STORE_MGR_ROLE` (AZ row access + customer email/phone masking)
  - **Snowflake-Managed MCP Server:** `MOON_VALLEY_MCP` exposing ONLY `MOON_VALLEY_AGENT` (`CORTEX_AGENT_RUN`)
- **[2026-10-29 11:42]** Inspected Foster Farms reference templates (`README.md`, `architecture.svg`, `deployment_flow.svg`, `ml_models.svg`, `agent_tool_decision.svg`, `05_create_semantic_views.sql`, `08_ml_model_functions.sql`, `09_create_agent.sql`, `07_ml_models.ipynb`).
- **[2026-10-29 11:44]** Verified Snowflake syntax via `snowflake_product_docs` (`CREATE SEMANTIC VIEW`, `CREATE MCP SERVER`, `CREATE ROW ACCESS POLICY`, `CREATE MASKING POLICY`).
- **[2026-10-29 11:45]** Wrote `sql/setup/01_database_and_schema.sql` (36 lines).
- **[2026-10-29 11:46]** Wrote `sql/setup/02_create_tables.sql` (325 lines — 23 tables across `RAW` and `REFERENCE`).
- **[2026-10-29 11:48]** Wrote `sql/data/03_generate_synthetic_data.sql` (reconciled 2015–2026 synthetic data across 8 dimensions, 3 Kimball sales facts, and 4 operational facts).
- **[2026-10-29 11:50]** Wrote `sql/data/03b_seed_reference_data.sql` (374 lines — USDA Hardiness Zones, USDA PLANTS Taxonomy, Water-Use Classes, 512 GS1 GTIN/GLNs, SKU Crosswalk, and 330 Unstructured Search Docs).
- **[2026-10-29 11:52]** Wrote `sql/views/04_create_views.sql` (518 lines — 7 Business Views + 4 ML Feature Views).
- **[2026-10-29 11:54]** Wrote `sql/views/05_create_semantic_views.sql` (808 lines — 3 Semantic Views with synonyms, relationships, facts, dimensions, metrics, `AI_SQL_GENERATION`, and `AI_VERIFIED_QUERIES`).
- **[2026-10-29 11:55]** Wrote `sql/search/06_create_cortex_search.sql` (88 lines — 3 Cortex Search services).
- **[2026-10-29 11:57]** Authored `notebooks/07_ml_models.ipynb` (13 cells — `get_active_session()`, 4 SQL cells, training & Model Registry logging for all 4 ML models).
- **[2026-10-29 11:58]** Wrote `sql/models/08_ml_model_functions.sql` (227 lines — 4 SQL UDFs using `RETURNS ARRAY` and `MODEL()!PREDICT()`).
- **[2026-10-29 11:59]** Wrote `sql/agent/09_create_agent.sql` (172 lines — `MOON_VALLEY_AGENT` YAML spec with 11 tools).
- **[2026-10-29 12:00]** Wrote `sql/governance/10_roles_and_policies.sql` (198 lines — `MVN_EXEC_ROLE`, `MVN_AZ_STORE_MGR_ROLE`, `MVN_STATE_ROW_ACCESS_POLICY`, `MVN_EMAIL_MASKING_POLICY`, `MVN_PHONE_MASKING_POLICY`).
- **[2026-10-29 12:01]** Wrote `sql/mcp/11_create_mcp_server.sql` (76 lines — `MOON_VALLEY_MCP` exposing ONLY `MOON_VALLEY_AGENT` + OAuth security integration) and `sql/setup/99_teardown.sql` (20 lines).
- **[2026-10-29 12:03]** Created 6 SVG diagrams in `docs/images/` (`architecture.svg`, `deployment_flow.svg`, `kimball_model.svg`, `agent_tool_decision.svg`, `governance_roles.svg`, `ml_models.svg`) with white backgrounds, drop shadows on all boxes, and verified text fit.
- **[2026-10-29 12:05]** Authored `README.md`, `docs/AGENT_SETUP.md`, `docs/MCP_CLAUDE_SETUP.md`, `docs/POWER_BI_SETUP.md`, `docs/DEMO_SCRIPT.md`, `docs/DEPLOYMENT_SUMMARY.md`, and `docs/questions.md` (all starting with `<img src="Snowflake_Logo.svg" width="200">`).
- **[2026-10-29 12:06]** Verified zero merge conflicts and complete compliance with all DO / DO NOT project rules. Ready for user review before deployment.
