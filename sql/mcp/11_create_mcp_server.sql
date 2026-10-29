/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  11_create_mcp_server.sql
  
  Creates the Snowflake-managed MCP Server MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_MCP
  that exposes ONLY the governed Cortex Agent (type: CORTEX_AGENT_RUN).
  
  SECURITY & GOVERNANCE DESIGN:
    - Exposes ONLY MOON_VALLEY_AGENT (`CORTEX_AGENT_RUN`).
    - Does NOT expose SYSTEM_EXECUTE_SQL, preventing external MCP clients
      from bypassing Semantic Views, verified queries, or agent orchestration.
    - Enforces caller RBAC, Row Access Policy (AZ store manager vs Executive),
      and Dynamic Data Masking automatically via Snowflake OAuth.
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE DATABASE MVN_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MOON_VALLEY_WH;

-- =============================================================================
-- 1. CREATE SNOWFLAKE-MANAGED MCP SERVER EXPOSING ONLY THE CORTEX AGENT
-- =============================================================================
CREATE OR REPLACE MCP SERVER MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_MCP
  COMMENT = 'Snowflake-managed MCP server for Moon Valley Nursery exposing only MOON_VALLEY_AGENT'
  FROM SPECIFICATION
  $$
  tools:
    - title: "Moon Valley Business Assistant"
      name: "moon_valley_business_agent"
      type: "CORTEX_AGENT_RUN"
      identifier: "MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_AGENT"
      description: "Governed answers about Moon Valley Nursery retail sales, gross margin, planting operations, inventory, palm stockouts, store ramp, and ML forecasts."
      annotations:
        readOnlyHint: true
        openWorldHint: false
  $$;

-- =============================================================================
-- 2. GRANT MCP SERVER ACCESS TO GOVERNED ROLES
-- =============================================================================
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE MVN_EXEC_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE MVN_AZ_STORE_MGR_ROLE;

GRANT USAGE ON MCP SERVER MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_MCP TO ROLE MVN_EXEC_ROLE;
GRANT USAGE ON MCP SERVER MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_MCP TO ROLE MVN_AZ_STORE_MGR_ROLE;

-- Advertise supported primary-role OAuth scopes on the schema
ALTER SCHEMA MVN_INTELLIGENCE.ANALYTICS
  SET OAUTH_SCOPES_SUPPORTED = 'session:role:MVN_EXEC_ROLE,session:role:MVN_AZ_STORE_MGR_ROLE';

-- =============================================================================
-- 3. SNOWFLAKE OAUTH SECURITY INTEGRATION FOR CLAUDE.AI / CLAUDE DESKTOP
-- =============================================================================
CREATE OR REPLACE SECURITY INTEGRATION MVN_CLAUDE_MCP_OAUTH
  TYPE = OAUTH
  OAUTH_CLIENT = CUSTOM
  ENABLED = TRUE
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = 'https://claude.ai/api/mcp/auth_callback'
  OAUTH_USE_SECONDARY_ROLES = NONE
  ALLOWED_ROLES_LIST = ('MVN_EXEC_ROLE', 'MVN_AZ_STORE_MGR_ROLE')
  COMMENT = 'OAuth 2.0 Security Integration for Claude.ai custom MCP connector to MOON_VALLEY_MCP';

-- =============================================================================
-- 4. VERIFY MCP SERVER & GENERATE HYPHENATED ENDPOINT URL
--    (Important: MCP server hostnames must use hyphens '-', never underscores '_')
-- =============================================================================
SHOW MCP SERVERS IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
DESCRIBE MCP SERVER MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_MCP;

SELECT
    'https://' || REPLACE(LOWER(CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME()), '_', '-')
    || '.snowflakecomputing.com/api/v2/databases/MVN_INTELLIGENCE/schemas/ANALYTICS/mcp-servers/MOON_VALLEY_MCP'
    AS claude_mcp_server_endpoint_url;
