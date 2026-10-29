/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  02_create_tables.sql
  
  Creates the complete Kimball star schema in MVN_INTELLIGENCE.RAW and
  public standard reference tables in MVN_INTELLIGENCE.REFERENCE:
    - 8 Conformed Dimensions (DIM_DATE, DIM_LOCATION, DIM_FARM, DIM_PRODUCT,
      DIM_CUSTOMER, DIM_SALESPERSON, DIM_CREW, DIM_CAMPAIGN)
    - 3 Sales Fact Constellation Tables (FACT_SALES_DAILY_LOCATION,
      FACT_SALES_TRANSACTION, FACT_SALES_LINE)
    - 4 Supporting Fact Tables (FACT_PLANTED_JOBS, FACT_INVENTORY_DAILY,
      FACT_FARM_TRANSFERS, FACT_MARKETING_LEADS)
    - 3 Unstructured Document Tables (PLANTING_FIELD_NOTES, PLANT_CARE_GUIDES,
      WARRANTY_POLICIES)
    - 5 Reference / Standards Tables (HARDINESS_ZONE_DIM, PLANT_TAXONOMY_DIM,
      WATER_USE_DIM, GS1_IDENTIFIERS, PRODUCT_TAXONOMY_MAP)
=============================================================================*/

USE DATABASE MVN_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE MOON_VALLEY_WH;

-- =============================================================================
-- 1. CONFORMED DIMENSIONS (RAW SCHEMA)
-- =============================================================================

CREATE OR REPLACE TABLE RAW.DIM_DATE (
    date_key            NUMBER(8,0)     NOT NULL PRIMARY KEY COMMENT 'YYYYMMDD integer date key',
    calendar_date       DATE            NOT NULL COMMENT 'Calendar date (2015-01-01 through 2026-12-31)',
    week                NUMBER(2,0)     NOT NULL COMMENT 'ISO week number of year (1-53)',
    month               NUMBER(2,0)     NOT NULL COMMENT 'Calendar month number (1-12)',
    month_name          VARCHAR(20)     NOT NULL COMMENT 'Month name (January-December)',
    quarter             NUMBER(1,0)     NOT NULL COMMENT 'Calendar/Fiscal quarter (1-4)',
    quarter_name        VARCHAR(10)     NOT NULL COMMENT 'Quarter label (Q1-Q4)',
    year                NUMBER(4,0)     NOT NULL COMMENT 'Fiscal and calendar year (fiscal = calendar)',
    season              VARCHAR(20)     NOT NULL COMMENT 'Nursery season: Spring, Summer, Fall, Winter',
    is_holiday          BOOLEAN         NOT NULL COMMENT 'TRUE on major retail nursery promotion holidays',
    is_peak_season      BOOLEAN         NOT NULL COMMENT 'TRUE during Spring (Mar-May) and Fall (Oct-Nov) planting peaks'
) COMMENT = 'Conformed date dimension (one row per day from 2015-01-01 through 2026-12-31)';

CREATE OR REPLACE TABLE RAW.DIM_LOCATION (
    location_id         VARCHAR(20)     NOT NULL PRIMARY KEY COMMENT 'Unique retail nursery store identifier (e.g., LOC-AZ-001)',
    location_name       VARCHAR(120)    NOT NULL COMMENT 'Retail nursery store name',
    city                VARCHAR(80)     NOT NULL COMMENT 'City name',
    state               VARCHAR(10)     NOT NULL COMMENT 'Two-letter state code (AZ, CA, NV, TX, FL)',
    region              VARCHAR(40)     NOT NULL COMMENT 'Operating region (Desert Southwest, Southern California, Texas, Florida)',
    market              VARCHAR(60)     NOT NULL COMMENT 'Metro market area (Phoenix Metro, Tucson, Las Vegas, SoCal Inland, Houston, Dallas-Fort Worth, Austin/San Antonio, Tampa/Orlando, South Florida)',
    open_date           DATE            NOT NULL COMMENT 'Store grand opening date',
    sq_ft               NUMBER(10,0)    NOT NULL COMMENT 'Nursery yard square footage',
    hardiness_zone      VARCHAR(10)     NOT NULL COMMENT 'USDA Plant Hardiness Zone (e.g., 9b, 10a)',
    is_new_market       BOOLEAN         NOT NULL COMMENT 'TRUE for stores opened in 2024+ expansion markets (FL and new TX stores)'
) COMMENT = 'Conformed location dimension (~100 retail nursery locations across AZ, CA, NV, TX, FL)';

CREATE OR REPLACE TABLE RAW.DIM_FARM (
    farm_id             VARCHAR(20)     NOT NULL PRIMARY KEY COMMENT 'Unique growing farm identifier',
    farm_name           VARCHAR(120)    NOT NULL COMMENT 'Growing farm name',
    state               VARCHAR(10)     NOT NULL COMMENT 'Two-letter state code where farm operates',
    acres               NUMBER(10,0)    NOT NULL COMMENT 'Total growing acreage',
    primary_specialty   VARCHAR(60)     NOT NULL COMMENT 'Primary crop specialty (Specimen Box Trees, Desert & Shade Trees, Palms & Subtropical, Citrus & Stone Fruit)'
) COMMENT = 'Conformed growing farm dimension for vertically integrated farm-to-yard supply';

CREATE OR REPLACE TABLE RAW.DIM_PRODUCT (
    product_id          VARCHAR(20)     NOT NULL PRIMARY KEY COMMENT 'Unique internal product identifier',
    sku                 VARCHAR(40)     NOT NULL COMMENT 'POS stock keeping unit code',
    product_name        VARCHAR(150)    NOT NULL COMMENT 'Retail product name',
    category            VARCHAR(50)     NOT NULL COMMENT 'Product category: Shade Trees, Palms, Fruit Trees, Flowering Trees, Shrubs, Groundcover, Fertilizer & Soil, Services',
    container_size      VARCHAR(30)     NOT NULL COMMENT 'Container / specimen size: 15 gal, 24in box, 36in box, 48in box+, Bag/Bottle, Service',
    unit_price          NUMBER(12,2)    NOT NULL COMMENT 'Standard retail list price in USD',
    unit_cost           NUMBER(12,2)    NOT NULL COMMENT 'Standard landed/farm cost in USD',
    water_use           VARCHAR(20)     NOT NULL COMMENT 'Water use classification (Very Low, Low, Moderate, High, N/A)',
    plant_symbol        VARCHAR(20)     NOT NULL COMMENT 'USDA PLANTS Database symbol (or SVC/FERT for non-plant SKUs)',
    is_tree             BOOLEAN         NOT NULL COMMENT 'TRUE for Shade Trees, Palms, Fruit Trees, Flowering Trees',
    is_box_tree         BOOLEAN         NOT NULL COMMENT 'TRUE for 24in box, 36in box, and 48in box+ specimen trees'
) COMMENT = 'Conformed product dimension (~400 SKUs across trees, palms, shrubs, fertilizers, and planting services)';

CREATE OR REPLACE TABLE RAW.DIM_CUSTOMER (
    customer_id         VARCHAR(25)     NOT NULL PRIMARY KEY COMMENT 'Unique customer identifier',
    customer_name       VARCHAR(120)    NOT NULL COMMENT 'Customer or business account name',
    customer_type       VARCHAR(30)     NOT NULL COMMENT 'Segment: Homeowner, Landscaper, Builder/Commercial',
    zip                 VARCHAR(10)     NOT NULL COMMENT 'Customer 5-digit postal code',
    state               VARCHAR(10)     NOT NULL COMMENT 'Customer state (AZ, CA, NV, TX, FL)',
    first_purchase_date DATE            NOT NULL COMMENT 'Date of first purchase at Moon Valley Nursery',
    email               VARCHAR(150)    NOT NULL COMMENT 'Customer email address (protected by column masking policy)',
    phone               VARCHAR(30)     NOT NULL COMMENT 'Customer phone number (protected by column masking policy)'
) COMMENT = 'Conformed customer dimension (~50,000 customers across Homeowner, Landscaper, and Builder/Commercial segments)';

CREATE OR REPLACE TABLE RAW.DIM_SALESPERSON (
    salesperson_id      VARCHAR(20)     NOT NULL PRIMARY KEY COMMENT 'Unique nursery design consultant / salesperson ID',
    name                VARCHAR(100)    NOT NULL COMMENT 'Salesperson full name',
    location_id         VARCHAR(20)     NOT NULL COMMENT 'Assigned home nursery location ID',
    hire_date           DATE            NOT NULL COMMENT 'Date hired',
    role_title          VARCHAR(60)     NOT NULL COMMENT 'Role title (Nursery Pros, Senior Tree Designer, Commercial Account Rep)'
) COMMENT = 'Conformed salesperson dimension (~400 nursery design consultants across 100 locations)';

CREATE OR REPLACE TABLE RAW.DIM_CREW (
    crew_id             VARCHAR(20)     NOT NULL PRIMARY KEY COMMENT 'Unique professional planting crew ID',
    crew_name           VARCHAR(80)     NOT NULL COMMENT 'Planting crew callsign / identifier',
    location_id         VARCHAR(20)     NOT NULL COMMENT 'Home dispatch nursery location ID',
    crew_size           NUMBER(3,0)     NOT NULL COMMENT 'Number of field technicians on crew (3-8)',
    crane_certified     BOOLEAN         NOT NULL COMMENT 'TRUE if crew is certified for 36in/48in+ crane box-tree installations'
) COMMENT = 'Conformed field planting crew dimension';

CREATE OR REPLACE TABLE RAW.DIM_CAMPAIGN (
    campaign_id         VARCHAR(20)     NOT NULL PRIMARY KEY COMMENT 'Unique marketing campaign identifier',
    campaign_name       VARCHAR(120)    NOT NULL COMMENT 'Marketing campaign name',
    channel             VARCHAR(40)     NOT NULL COMMENT 'Marketing channel (Paid Search, Direct Mail, Billboard/OOH, Local TV & Radio, Social Media, HOA/Builder Events)',
    start_date          DATE            NOT NULL COMMENT 'Campaign launch date',
    end_date            DATE            NOT NULL COMMENT 'Campaign end date',
    region              VARCHAR(40)     NOT NULL COMMENT 'Targeted region',
    budget_usd          NUMBER(12,2)    NOT NULL COMMENT 'Campaign spend budget in USD'
) COMMENT = 'Conformed marketing campaign dimension';


-- =============================================================================
-- 2. KIMBALL THREE-FACT SALES CONSTELLATION (RAW SCHEMA)
--    Reconciled across all three grains: Line -> Transaction -> Daily Location
-- =============================================================================

CREATE OR REPLACE TABLE RAW.FACT_SALES_LINE (
    transaction_id      VARCHAR(30)     NOT NULL COMMENT 'Parent POS transaction identifier',
    line_no             NUMBER(4,0)     NOT NULL COMMENT 'Line item number within transaction',
    date_key            NUMBER(8,0)     NOT NULL COMMENT 'Transaction date key (YYYYMMDD)',
    location_id         VARCHAR(20)     NOT NULL COMMENT 'Store location ID (denormalized for governance & fast joins)',
    state               VARCHAR(10)     NOT NULL COMMENT 'Store state code (AZ, CA, NV, TX, FL) for row-access governance',
    product_id          VARCHAR(20)     NOT NULL COMMENT 'Purchased product SKU ID',
    qty                 NUMBER(8,0)     NOT NULL COMMENT 'Units sold on line',
    unit_price          NUMBER(12,2)    NOT NULL COMMENT 'List unit price at time of sale',
    discount            NUMBER(12,2)    NOT NULL COMMENT 'Total dollar discount applied to this line',
    discount_promo_type VARCHAR(50)     NOT NULL COMMENT 'Promotion / discount reason (None, Multi-Tree Bundle, Summer Heat Clearance, Builder Volume, VIP Landscape Pass, Manager Price Match)',
    extended_price      NUMBER(14,2)    NOT NULL COMMENT 'Net line revenue = (qty * unit_price) - discount',
    unit_cost           NUMBER(12,2)    NOT NULL COMMENT 'Unit cost at time of sale',
    extended_cost       NUMBER(14,2)    NOT NULL COMMENT 'Total line cost = qty * unit_cost',
    line_margin         NUMBER(14,2)    NOT NULL COMMENT 'Gross margin dollars = extended_price - extended_cost',
    PRIMARY KEY (transaction_id, line_no)
) COMMENT = 'Granular POS sales line fact table (transaction x line grain)';

CREATE OR REPLACE TABLE RAW.FACT_SALES_TRANSACTION (
    transaction_id          VARCHAR(30)     NOT NULL PRIMARY KEY COMMENT 'Unique POS transaction identifier',
    date_key                NUMBER(8,0)     NOT NULL COMMENT 'Transaction date key (YYYYMMDD)',
    location_id             VARCHAR(20)     NOT NULL COMMENT 'Store location ID',
    state                   VARCHAR(10)     NOT NULL COMMENT 'Store state code (AZ, CA, NV, TX, FL) for row-access governance',
    customer_id             VARCHAR(25)     NOT NULL COMMENT 'Customer ID',
    salesperson_id          VARCHAR(20)     NOT NULL COMMENT 'Salesperson ID',
    campaign_id             VARCHAR(20)     COMMENT 'Attributed marketing campaign ID (NULL if organic walk-in)',
    gross_sales             NUMBER(14,2)    NOT NULL COMMENT 'Sum of (qty * unit_price) across transaction lines',
    discounts               NUMBER(14,2)    NOT NULL COMMENT 'Sum of line discounts across transaction',
    net_sales               NUMBER(14,2)    NOT NULL COMMENT 'Sum of extended_price across transaction lines',
    gross_margin            NUMBER(14,2)    NOT NULL COMMENT 'Sum of line_margin across transaction lines',
    units                   NUMBER(10,0)    NOT NULL COMMENT 'Total units purchased in transaction',
    tree_units              NUMBER(10,0)    NOT NULL COMMENT 'Total tree units in transaction',
    box_tree_units          NUMBER(10,0)    NOT NULL COMMENT 'Total 24in/36in/48in+ box tree units in transaction',
    includes_planting_flag  BOOLEAN         NOT NULL COMMENT 'TRUE if transaction includes professional planting service'
) COMMENT = 'POS sales transaction header fact table (date x location x transaction grain, reconciled to FACT_SALES_LINE)';

CREATE OR REPLACE TABLE RAW.FACT_SALES_DAILY_LOCATION (
    date_key            NUMBER(8,0)     NOT NULL COMMENT 'Date key (YYYYMMDD)',
    location_id         VARCHAR(20)     NOT NULL COMMENT 'Store location ID',
    state               VARCHAR(10)     NOT NULL COMMENT 'Store state code (AZ, CA, NV, TX, FL) for row-access governance',
    gross_sales         NUMBER(14,2)    NOT NULL COMMENT 'Daily store gross sales (exact sum of FACT_SALES_LINE)',
    net_sales           NUMBER(14,2)    NOT NULL COMMENT 'Daily store net sales after discounts (exact sum of FACT_SALES_LINE)',
    discounts           NUMBER(14,2)    NOT NULL COMMENT 'Daily store discounts (exact sum of FACT_SALES_LINE)',
    units               NUMBER(10,0)    NOT NULL COMMENT 'Daily store units sold (exact sum of FACT_SALES_LINE)',
    transactions        NUMBER(10,0)    NOT NULL COMMENT 'Daily store transaction count',
    gross_margin        NUMBER(14,2)    NOT NULL COMMENT 'Daily store gross margin dollars (exact sum of FACT_SALES_LINE)',
    planting_transactions NUMBER(10,0)  NOT NULL COMMENT 'Daily transactions with professional planting attached',
    tree_transactions   NUMBER(10,0)    NOT NULL COMMENT 'Daily transactions containing at least one tree',
    PRIMARY KEY (date_key, location_id)
) COMMENT = 'Daily store summary sales fact table (date x location grain, 100% reconciled to FACT_SALES_LINE and FACT_SALES_TRANSACTION)';


-- =============================================================================
-- 3. SUPPORTING OPERATIONAL & MARKETING FACTS (RAW SCHEMA)
-- =============================================================================

CREATE OR REPLACE TABLE RAW.FACT_PLANTED_JOBS (
    job_id                  VARCHAR(30)     NOT NULL PRIMARY KEY COMMENT 'Unique field services planting job ID',
    transaction_id          VARCHAR(30)     NOT NULL COMMENT 'Originating POS sales transaction ID',
    location_id             VARCHAR(20)     NOT NULL COMMENT 'Dispatching nursery store ID',
    state                   VARCHAR(10)     NOT NULL COMMENT 'Store state code (AZ, CA, NV, TX, FL) for row-access governance',
    crew_id                 VARCHAR(20)     NOT NULL COMMENT 'Assigned planting crew ID',
    sold_date               DATE            NOT NULL COMMENT 'Date tree and planting service were sold',
    scheduled_date          DATE            NOT NULL COMMENT 'Scheduled planting installation date',
    completed_date          DATE            COMMENT 'Actual completion date (NULL if Scheduled or Cancelled)',
    days_to_schedule        NUMBER(5,0)     NOT NULL COMMENT 'Lead days from sold_date to scheduled_date',
    days_sold_to_completed  NUMBER(5,0)     COMMENT 'Total days from sold_date to completed_date',
    status                  VARCHAR(25)     NOT NULL COMMENT 'Job status: Scheduled, Completed, Rescheduled, Cancelled',
    reschedule_count        NUMBER(3,0)     NOT NULL COMMENT 'Number of times job was rescheduled',
    reschedule_reason       VARCHAR(60)     COMMENT 'Primary reason if rescheduled (Caliche/Hard Dig, Blue Stake Utility Delay, Crane Access/HOA Gate, Extreme Heat Advisory, Customer Request, Crew Overtime)',
    tree_count              NUMBER(5,0)     NOT NULL COMMENT 'Number of trees to plant on job',
    max_container_code      NUMBER(3,0)     NOT NULL COMMENT 'Largest container code on job (1=15gal, 2=24in, 3=36in, 4=48in+)',
    warranty_flag           BOOLEAN         NOT NULL COMMENT 'TRUE if customer purchased extended tree care warranty',
    delayed_flag            NUMBER(1,0)     NOT NULL COMMENT '1 if job missed original scheduled date or was rescheduled, else 0',
    notes_id                VARCHAR(30)     COMMENT 'Reference to field crew note in PLANTING_FIELD_NOTES'
) COMMENT = 'Professional planting jobs tracked in field services application';

CREATE OR REPLACE TABLE RAW.FACT_INVENTORY_DAILY (
    date_key                NUMBER(8,0)     NOT NULL COMMENT 'Snapshot date key (YYYYMMDD)',
    location_id             VARCHAR(20)     NOT NULL COMMENT 'Retail nursery location ID',
    state                   VARCHAR(10)     NOT NULL COMMENT 'Store state code (AZ, CA, NV, TX, FL) for row-access governance',
    product_id              VARCHAR(20)     NOT NULL COMMENT 'Product ID',
    on_hand_units           NUMBER(8,0)     NOT NULL COMMENT 'Physical salable units on hand at store close',
    on_order_units          NUMBER(8,0)     NOT NULL COMMENT 'Units in transit or scheduled from Moon Valley farms',
    daily_sell_rate         NUMBER(8,2)     NOT NULL COMMENT 'Trailing 14-day average daily unit sales velocity',
    days_of_supply          NUMBER(8,2)     NOT NULL COMMENT 'On-hand units divided by daily sell rate',
    lead_time_days          NUMBER(5,0)     NOT NULL COMMENT 'Farm replenishment lead time in days',
    stockout_flag           BOOLEAN         NOT NULL COMMENT 'TRUE when on_hand_units = 0 during active selling season',
    stockout_next_14d_flag  NUMBER(1,0)     NOT NULL COMMENT '1 if SKU stocked out within the next 14 days (ML target), else 0',
    estimated_lost_sales    NUMBER(12,2)    NOT NULL COMMENT 'Estimated lost revenue in USD on stockout days',
    PRIMARY KEY (date_key, location_id, product_id)
) COMMENT = 'Daily store x SKU inventory position and stockout impact fact table';

CREATE OR REPLACE TABLE RAW.FACT_FARM_TRANSFERS (
    transfer_id         VARCHAR(30)     NOT NULL PRIMARY KEY COMMENT 'Unique farm-to-store transfer shipment ID',
    farm_id             VARCHAR(20)     NOT NULL COMMENT 'Source growing farm ID',
    location_id         VARCHAR(20)     NOT NULL COMMENT 'Destination retail nursery store ID',
    state               VARCHAR(10)     NOT NULL COMMENT 'Destination store state code (AZ, CA, NV, TX, FL)',
    product_id          VARCHAR(20)     NOT NULL COMMENT 'Transferred product SKU ID',
    ship_date           DATE            NOT NULL COMMENT 'Date truck departed farm',
    arrival_date        DATE            NOT NULL COMMENT 'Date shipment received at nursery yard',
    units               NUMBER(8,0)     NOT NULL COMMENT 'Number of trees/plants transferred',
    freight_cost_usd    NUMBER(10,2)    NOT NULL COMMENT 'Internal fleet freight cost in USD'
) COMMENT = 'Farm-to-nursery inventory transfer shipments';

CREATE OR REPLACE TABLE RAW.FACT_MARKETING_LEADS (
    lead_id                     VARCHAR(30)     NOT NULL PRIMARY KEY COMMENT 'Unique marketing lead identifier',
    campaign_id                 VARCHAR(20)     NOT NULL COMMENT 'Originating campaign ID',
    location_id                 VARCHAR(20)     NOT NULL COMMENT 'Assigned nursery store location ID',
    state                       VARCHAR(10)     NOT NULL COMMENT 'Store state code (AZ, CA, NV, TX, FL)',
    lead_date                   DATE            NOT NULL COMMENT 'Date lead was captured (yard design consult, web form, call)',
    customer_type               VARCHAR(30)     NOT NULL COMMENT 'Customer segment (Homeowner, Landscaper, Builder/Commercial)',
    converted_flag              BOOLEAN         NOT NULL COMMENT 'TRUE if lead converted to a POS sale',
    converted_transaction_id    VARCHAR(30)     COMMENT 'Converted POS transaction ID (NULL if unconverted)'
) COMMENT = 'Marketing lead capture and POS conversion tracking fact table';


-- =============================================================================
-- 4. UNSTRUCTURED DOCUMENT TABLES FOR CORTEX SEARCH (RAW SCHEMA)
-- =============================================================================

CREATE OR REPLACE TABLE RAW.PLANTING_FIELD_NOTES (
    note_id             VARCHAR(30)     NOT NULL PRIMARY KEY COMMENT 'Unique field note ID',
    job_id              VARCHAR(30)     NOT NULL COMMENT 'Associated planting job ID',
    location_id         VARCHAR(20)     NOT NULL COMMENT 'Nursery store location ID',
    state               VARCHAR(10)     NOT NULL COMMENT 'Store state (AZ, CA, NV, TX, FL)',
    crew_id             VARCHAR(20)     NOT NULL COMMENT 'Planting crew ID',
    note_date           DATE            NOT NULL COMMENT 'Date note was logged',
    note_category       VARCHAR(50)     NOT NULL COMMENT 'Note category: Reschedule Reason, Access/Crane Issue, Soil & Caliche, Irrigation Check, Post-Planting Inspection',
    title               VARCHAR(200)    NOT NULL COMMENT 'Short summary title of field observation',
    content             VARCHAR(8000)   NOT NULL COMMENT 'Full field technician note text'
) COMMENT = 'Unstructured field crew planting notes for MVN_PLANTING_NOTES_SEARCH';

CREATE OR REPLACE TABLE RAW.PLANT_CARE_GUIDES (
    guide_id            VARCHAR(30)     NOT NULL PRIMARY KEY COMMENT 'Unique plant care guide ID',
    category            VARCHAR(50)     NOT NULL COMMENT 'Product category (Palms, Shade Trees, Fruit Trees, Flowering Trees, Shrubs, Fertilizer & Soil)',
    plant_symbol        VARCHAR(20)     NOT NULL COMMENT 'USDA plant symbol',
    hardiness_zone      VARCHAR(20)     NOT NULL COMMENT 'Applicable USDA hardiness zones',
    water_use_class     VARCHAR(20)     NOT NULL COMMENT 'Water use classification (Very Low, Low, Moderate, High)',
    region              VARCHAR(40)     NOT NULL COMMENT 'Target climate region',
    title               VARCHAR(200)    NOT NULL COMMENT 'Care guide title',
    content             VARCHAR(8000)   NOT NULL COMMENT 'Detailed agronomic care, watering schedule, Moon Juice fertilizer protocol, and seasonal heat/frost protection guide'
) COMMENT = 'Unstructured agronomic plant care guides for MVN_PLANT_CARE_SEARCH';

CREATE OR REPLACE TABLE RAW.WARRANTY_POLICIES (
    policy_id               VARCHAR(30)     NOT NULL PRIMARY KEY COMMENT 'Unique warranty policy document ID',
    policy_category         VARCHAR(60)     NOT NULL COMMENT 'Policy category (Palm Replacement, Box Tree Guarantee, Extended Care Plan, Commercial/Builder Terms, Weather & Freeze Exclusions)',
    applicable_categories   VARCHAR(100)    NOT NULL COMMENT 'Covered product categories',
    customer_type           VARCHAR(40)     NOT NULL COMMENT 'Applicable customer segment (All, Homeowner, Landscaper, Builder/Commercial)',
    effective_date          DATE            NOT NULL COMMENT 'Policy effective date',
    title                   VARCHAR(200)    NOT NULL COMMENT 'Policy section title',
    content                 VARCHAR(8000)   NOT NULL COMMENT 'Full synthetic warranty policy and replacement procedure text'
) COMMENT = 'Unstructured warranty and replacement policy documents for MVN_WARRANTY_POLICY_SEARCH';


-- =============================================================================
-- 5. PUBLIC STANDARDS & REFERENCE TABLES (REFERENCE SCHEMA)
-- =============================================================================

CREATE OR REPLACE TABLE REFERENCE.HARDINESS_ZONE_DIM (
    zone                VARCHAR(10)     NOT NULL PRIMARY KEY COMMENT 'USDA Plant Hardiness Zone code (e.g., 8a, 8b, 9a, 9b, 10a, 10b, 11a)',
    min_temp_f_low      NUMBER(5,0)     NOT NULL COMMENT 'Average annual extreme minimum temperature lower bound (F)',
    min_temp_f_high     NUMBER(5,0)     NOT NULL COMMENT 'Average annual extreme minimum temperature upper bound (F)',
    zone_description    VARCHAR(200)    NOT NULL COMMENT 'Climate description and frost profile',
    typical_markets     VARCHAR(200)    NOT NULL COMMENT 'Moon Valley Nursery markets located in this zone'
) COMMENT = 'USDA Plant Hardiness Zone standard reference table';

CREATE OR REPLACE TABLE REFERENCE.PLANT_TAXONOMY_DIM (
    plant_symbol        VARCHAR(20)     NOT NULL PRIMARY KEY COMMENT 'USDA PLANTS Database symbol (e.g., PAFL6, QUVI, PHDA4)',
    scientific_name     VARCHAR(120)    NOT NULL COMMENT 'Botanical Latin binomial name',
    common_name         VARCHAR(120)    NOT NULL COMMENT 'Standard commercial common name',
    family              VARCHAR(80)     NOT NULL COMMENT 'Botanical family (e.g., Fabaceae, Arecaceae, Fagaceae)',
    growth_habit        VARCHAR(60)     NOT NULL COMMENT 'USDA growth habit (Tree, Shrub, Palm, Subshrub)',
    canopy_spread_ft    NUMBER(5,0)     NOT NULL COMMENT 'Mature canopy spread in feet',
    mature_height_ft    NUMBER(5,0)     NOT NULL COMMENT 'Mature height in feet'
) COMMENT = 'USDA PLANTS Database botanical taxonomy reference table';

CREATE OR REPLACE TABLE REFERENCE.WATER_USE_DIM (
    water_use_class             VARCHAR(20)     NOT NULL PRIMARY KEY COMMENT 'Water use class (Very Low, Low, Moderate, High)',
    description                 VARCHAR(300)    NOT NULL COMMENT 'Regional WUCOLS / desert water conservation definition',
    summer_drip_freq_days       NUMBER(4,0)     NOT NULL COMMENT 'Recommended summer deep-watering interval in days once established',
    desert_hoa_approved_flag    BOOLEAN         NOT NULL COMMENT 'TRUE if approved for desert low-water HOA / municipal xeriscape rebates'
) COMMENT = 'Regional low-water-use plant classification reference table';

CREATE OR REPLACE TABLE REFERENCE.GS1_IDENTIFIERS (
    gs1_id              VARCHAR(30)     NOT NULL PRIMARY KEY COMMENT 'Internal GS1 registry row ID',
    identifier_type     VARCHAR(15)     NOT NULL COMMENT 'GTIN (Product) or GLN (Location/Farm)',
    gtin                VARCHAR(20)     COMMENT '14-digit GS1 Global Trade Item Number for retail SKUs',
    gln                 VARCHAR(20)     COMMENT '13-digit GS1 Global Location Number for stores and farms',
    product_id          VARCHAR(20)     COMMENT 'Mapped DIM_PRODUCT.product_id (for GTIN rows)',
    location_id         VARCHAR(20)     COMMENT 'Mapped DIM_LOCATION.location_id or DIM_FARM.farm_id (for GLN rows)',
    registered_name     VARCHAR(150)    NOT NULL COMMENT 'Standardized GS1 description'
) COMMENT = 'GS1 GTIN (product) and GLN (location) supply-chain identifier reference table';

CREATE OR REPLACE TABLE REFERENCE.PRODUCT_TAXONOMY_MAP (
    product_id          VARCHAR(20)     NOT NULL PRIMARY KEY COMMENT 'FK to RAW.DIM_PRODUCT.product_id',
    plant_symbol        VARCHAR(20)     NOT NULL COMMENT 'FK to REFERENCE.PLANT_TAXONOMY_DIM.plant_symbol',
    hardiness_min_zone  VARCHAR(10)     NOT NULL COMMENT 'Minimum survivable USDA zone (e.g., 8a)',
    hardiness_max_zone  VARCHAR(10)     NOT NULL COMMENT 'Maximum recommended USDA zone (e.g., 11a)',
    water_use_class     VARCHAR(20)     NOT NULL COMMENT 'FK to REFERENCE.WATER_USE_DIM.water_use_class',
    full_sun_desert_ok  BOOLEAN         NOT NULL COMMENT 'TRUE if rated for 115F+ direct western desert sun in AZ/NV',
    suitability_notes   VARCHAR(300)    NOT NULL COMMENT 'Agronomic suitability notes for nursery designers'
) COMMENT = 'Crosswalk mapping Moon Valley POS SKUs to USDA taxonomy, hardiness zones, and water-use standards';

SHOW TABLES IN SCHEMA MVN_INTELLIGENCE.RAW;
SHOW TABLES IN SCHEMA MVN_INTELLIGENCE.REFERENCE;
