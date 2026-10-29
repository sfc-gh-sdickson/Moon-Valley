<img src="Snowflake_Logo.svg" width="200">

# Connecting Claude.ai to Moon Valley Nursery via Snowflake-Managed MCP Server

This guide explains how Moon Valley Nursery executives (**Bill Serva, CTO** and **Catherine Digua, Data Lead**) and store managers connect **Claude.ai** (or Claude Desktop) directly to Snowflake using the **Snowflake-managed MCP Server (`MOON_VALLEY_MCP`)** with zero self-hosted servers and zero raw SQL exposure.

---

## Why Snowflake-Managed MCP for Moon Valley?

1. **Zero Infrastructure to Host**: Catherine's data team does not need to deploy, patch, or monitor a container or custom MCP proxy server. Snowflake hosts the HTTPS MCP endpoint natively.
2. **One Governed Tool (`CORTEX_AGENT_RUN`)**: `MOON_VALLEY_MCP` exposes **only** `MOON_VALLEY_AGENT` (`moon_valley_business_agent`). It deliberately **does not expose `SYSTEM_EXECUTE_SQL`**, ensuring Claude cannot bypass Semantic Views, verified queries, or business definitions.
3. **Caller RBAC & Row-Level Security via OAuth**: Each user authenticates individually through Snowflake OAuth 2.0. When an executive signs in with `MVN_EXEC_ROLE`, Claude returns enterprise-wide numbers across `AZ`, `CA`, `NV`, `TX`, and `FL`. When an Arizona Store Manager signs in with `MVN_AZ_STORE_MGR_ROLE`, Snowflake automatically filters every underlying table to `state = 'AZ'` and masks customer email and phone numbers.

---

## Step 1: Run `sql/mcp/11_create_mcp_server.sql`

Executing `sql/mcp/11_create_mcp_server.sql` creates both the managed MCP server object and the Snowflake OAuth security integration:

```sql
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
```

---

## Step 2: Retrieve the Hyphenated MCP Endpoint URL & OAuth Client Credentials

**Important Hostname Rule**: Snowflake MCP server connections require **hyphens (`-`) instead of underscores (`_`)** in the account hostname.

Run the following SQL as `ACCOUNTADMIN` to retrieve your exact MCP Server URL and OAuth client credentials:

```sql
-- 1. Get the hyphenated MCP Server Endpoint URL
SELECT
    'https://' || REPLACE(LOWER(CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME()), '_', '-')
    || '.snowflakecomputing.com/api/v2/databases/MVN_INTELLIGENCE/schemas/ANALYTICS/mcp-servers/MOON_VALLEY_MCP'
    AS claude_mcp_server_endpoint_url;

-- 2. Retrieve OAuth Client ID and Client Secret (Integration name MUST be uppercase)
SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('MVN_CLAUDE_MCP_OAUTH');
```

---

## Step 3: Set User Default Role & Warehouse for MCP Sessions

When Claude connects via Snowflake OAuth, the session uses the authenticating user's `DEFAULT_ROLE` and `DEFAULT_WAREHOUSE` (with `OAUTH_USE_SECONDARY_ROLES = NONE` so secondary roles do not widen access):

```sql
-- For Executive Demo (sees all 5 states + unmasked customer PII):
ALTER USER <username> SET DEFAULT_ROLE = 'MVN_EXEC_ROLE' DEFAULT_WAREHOUSE = 'MOON_VALLEY_WH';

-- To switch to Arizona Store Manager Demo (sees AZ only + masked customer PII):
ALTER USER <username> SET DEFAULT_ROLE = 'MVN_AZ_STORE_MGR_ROLE' DEFAULT_WAREHOUSE = 'MOON_VALLEY_WH';
```

---

## Step 4: Add the Custom Connector in Claude.ai

1. In **Claude.ai**, open **Settings → Connectors** (or **Organization Settings → Connectors** for workspace-wide deployment).
2. Click **Add custom connector**.
3. Enter the connector details:
   - **Name**: `Moon Valley Nursery Intelligence (Snowflake)`
   - **Remote MCP Server URL**:
     ```text
     https://<org-name>-<account-name>.snowflakecomputing.com/api/v2/databases/MVN_INTELLIGENCE/schemas/ANALYTICS/mcp-servers/MOON_VALLEY_MCP
     ```
     *(Ensure all underscores `_` in `<org-name>-<account-name>` are replaced with hyphens `-`.)*
   - **OAuth Client ID**: Paste `OAUTH_CLIENT_ID` from `SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('MVN_CLAUDE_MCP_OAUTH')`.
   - **OAuth Client Secret**: Paste `OAUTH_CLIENT_SECRET` from `SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('MVN_CLAUDE_MCP_OAUTH')`.
4. Click **Add / Connect**. Claude will redirect to the Snowflake OAuth login screen (`https://claude.ai/api/mcp/auth_callback`).
5. Sign in with your Snowflake credentials and approve the consent prompt.
6. Confirm that **`moon_valley_business_agent`** ("Moon Valley Business Assistant") is the **only** exposed tool—no raw SQL execution tool is listed.

---

## Troubleshooting Checklist

| Symptom | Cause | Fix |
|---------|-------|-----|
| Connection fails immediately when adding URL | Underscores (`_`) in Snowflake account hostname | Replace all `_` with `-` in the `<org>-<account>.snowflakecomputing.com` hostname. |
| OAuth callback error on login | Redirect URI mismatch | Verify `OAUTH_REDIRECT_URI = 'https://claude.ai/api/mcp/auth_callback'` on `MVN_CLAUDE_MCP_OAUTH`. |
| Session fails to initialize after OAuth approval | User has no `DEFAULT_WAREHOUSE` | Run `ALTER USER <user> SET DEFAULT_WAREHOUSE = 'MOON_VALLEY_WH';`. |
| Tool returns unauthorized error | Active default role lacks `USAGE` on MCP server, Agent, or underlying objects | Re-run `sql/governance/10_roles_and_policies.sql` and `sql/mcp/11_create_mcp_server.sql`. |
