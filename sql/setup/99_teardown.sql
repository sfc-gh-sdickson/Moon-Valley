/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  99_teardown.sql
  
  Cleanly removes all Moon Valley Nursery demo objects (MCP server, OAuth
  security integration, Cortex Agent, database, warehouse, and demo roles).
=============================================================================*/

USE ROLE ACCOUNTADMIN;

DROP SECURITY INTEGRATION IF EXISTS MVN_CLAUDE_MCP_OAUTH;
DROP MCP SERVER IF EXISTS MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_MCP;
DROP AGENT IF EXISTS MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_AGENT;

DROP DATABASE IF EXISTS MVN_INTELLIGENCE;
DROP WAREHOUSE IF EXISTS MOON_VALLEY_WH;

DROP ROLE IF EXISTS MVN_EXEC_ROLE;
DROP ROLE IF EXISTS MVN_AZ_STORE_MGR_ROLE;
