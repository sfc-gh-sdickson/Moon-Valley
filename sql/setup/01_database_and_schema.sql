/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  01_database_and_schema.sql
  
  Creates the MVN_INTELLIGENCE database, RAW / ANALYTICS / REFERENCE schemas,
  and the MOON_VALLEY_WH compute warehouse.
=============================================================================*/

USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS MVN_INTELLIGENCE
    COMMENT = 'Moon Valley Nursery Sales, Inventory & Planting-Operations Intelligence Platform';

USE DATABASE MVN_INTELLIGENCE;

CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = 'Raw Kimball star schema dimensions, three-fact sales constellation, operational facts, and unstructured documents';

CREATE SCHEMA IF NOT EXISTS ANALYTICS
    COMMENT = 'Curated analytical views, ML feature views, Semantic Views, Cortex Search services, ML UDFs, Cortex Agent, and Managed MCP Server';

CREATE SCHEMA IF NOT EXISTS REFERENCE
    COMMENT = 'Public agronomic and supply-chain standards: USDA Hardiness Zones, USDA PLANTS Taxonomy, Water-Use Classes, GS1 GTIN/GLN, and SKU Crosswalk';

CREATE OR REPLACE WAREHOUSE MOON_VALLEY_WH WITH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for Moon Valley Nursery Intelligence Agent, Cortex Analyst, Cortex Search, and ML Inference';

USE WAREHOUSE MOON_VALLEY_WH;
USE SCHEMA MVN_INTELLIGENCE.RAW;

SHOW SCHEMAS IN DATABASE MVN_INTELLIGENCE;
