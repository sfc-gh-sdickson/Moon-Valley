/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  03_generate_synthetic_data.sql
  
  Generates realistic synthetic nursery data across 2015–2026:
    - 8 Conformed Dimensions (DIM_DATE, DIM_LOCATION, DIM_FARM, DIM_PRODUCT,
      DIM_CUSTOMER, DIM_SALESPERSON, DIM_CREW, DIM_CAMPAIGN)
    - 3 Reconciled Kimball Sales Facts (FACT_SALES_LINE -> FACT_SALES_TRANSACTION
      -> FACT_SALES_DAILY_LOCATION)
    - 4 Operational & Marketing Facts (FACT_PLANTED_JOBS, FACT_INVENTORY_DAILY,
      FACT_FARM_TRANSFERS, FACT_MARKETING_LEADS)
  
  Storylines embedded:
    1. Spring (Mar–May) and Fall (Oct–Nov) peaks; Summer heat dip in AZ/NV;
       milder seasonality in FL.
    2. 5 underperforming AZ stores in Fall 2026 vs Fall 2025 (Surprise Bell Rd,
       Chandler Ocotillo, Glendale Arrowhead, Buckeye Verrado, Tucson Ina Rd)
       driven by palm stockouts, lower traffic, and summer clearance discounting.
    3. New FL and TX stores (opened 2024–2025) ramping in their first 12 months.
    4. Large specimen box trees (24in / 36in / 48in+) drive high ticket & margin.
    5. ~35% planting attach rate overall, with store-level variation.
    6. Recurring palm stockouts at specific AZ/NV/TX locations during peak weeks.
=============================================================================*/

USE DATABASE MVN_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE MOON_VALLEY_WH;

-- =============================================================================
-- 1. DIM_DATE (2015-01-01 through 2026-12-31 = 4,383 days)
-- =============================================================================
TRUNCATE TABLE RAW.DIM_DATE;

INSERT INTO RAW.DIM_DATE
WITH date_gen AS (
    SELECT DATEADD('day', SEQ4(), '2015-01-01'::DATE) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 4383))
)
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                               AS date_key,
    d                                                               AS calendar_date,
    WEEKISO(d)                                                      AS week,
    MONTH(d)                                                        AS month,
    MONTHNAME(d)                                                    AS month_name,
    QUARTER(d)                                                      AS quarter,
    'Q' || QUARTER(d)                                               AS quarter_name,
    YEAR(d)                                                         AS year,
    CASE
        WHEN MONTH(d) IN (3, 4, 5)  THEN 'Spring'
        WHEN MONTH(d) IN (6, 7, 8)  THEN 'Summer'
        WHEN MONTH(d) IN (9, 10, 11) THEN 'Fall'
        ELSE 'Winter'
    END                                                             AS season,
    CASE
        WHEN (MONTH(d) = 5 AND DAY(d) BETWEEN 25 AND 31 AND DAYOFWEEKISO(d) = 1) -- Memorial Day
          OR (MONTH(d) = 4 AND DAY(d) = 22)                                      -- Earth Day / Arbor Week
          OR (MONTH(d) = 9 AND DAY(d) BETWEEN 1 AND 7 AND DAYOFWEEKISO(d) = 1)   -- Labor Day
          OR (MONTH(d) = 11 AND DAY(d) BETWEEN 24 AND 30 AND DAYOFWEEKISO(d) = 5)-- Black Friday
          OR (MONTH(d) = 3 AND DAY(d) = 20)                                      -- Spring Equinox Kickoff
        THEN TRUE
        ELSE FALSE
    END                                                             AS is_holiday,
    CASE
        WHEN MONTH(d) IN (3, 4, 5, 10, 11) THEN TRUE
        ELSE FALSE
    END                                                             AS is_peak_season
FROM date_gen;


-- =============================================================================
-- 2. DIM_LOCATION (100 Retail Nursery Locations across AZ, CA, NV, TX, FL)
-- =============================================================================
TRUNCATE TABLE RAW.DIM_LOCATION;

INSERT INTO RAW.DIM_LOCATION
WITH seq AS (
    SELECT SEQ4() + 1 AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 100))
),
loc_base AS (
    SELECT
        n,
        CASE
            WHEN n <= 35 THEN 'AZ'
            WHEN n <= 60 THEN 'CA'
            WHEN n <= 72 THEN 'NV'
            WHEN n <= 88 THEN 'TX'
            ELSE 'FL'
        END AS state,
        CASE
            WHEN n <= 35 THEN n
            WHEN n <= 60 THEN n - 35
            WHEN n <= 72 THEN n - 60
            WHEN n <= 88 THEN n - 72
            ELSE n - 88
        END AS state_idx
    FROM seq
)
SELECT
    'LOC-' || state || '-' || LPAD(state_idx::VARCHAR, 3, '0') AS location_id,
    CASE state
        WHEN 'AZ' THEN
            CASE state_idx
                WHEN 1  THEN 'Moon Valley Cave Creek Flagship'
                WHEN 2  THEN 'Moon Valley Scottsdale Shea'
                WHEN 3  THEN 'Moon Valley Gilbert Val Vista'
                WHEN 4  THEN 'Moon Valley Surprise Bell Rd'
                WHEN 5  THEN 'Moon Valley Queen Creek Rittenhouse'
                WHEN 6  THEN 'Moon Valley Mesa McKellips'
                WHEN 7  THEN 'Moon Valley Chandler Ocotillo'
                WHEN 8  THEN 'Moon Valley Peoria Happy Valley'
                WHEN 9  THEN 'Moon Valley Goodyear Estrella'
                WHEN 10 THEN 'Moon Valley Phoenix Tatum Blvd'
                WHEN 11 THEN 'Moon Valley Glendale Arrowhead'
                WHEN 12 THEN 'Moon Valley North Scottsdale Pima'
                WHEN 13 THEN 'Moon Valley Avondale McDowell'
                WHEN 14 THEN 'Moon Valley Tempe Warner Rd'
                WHEN 15 THEN 'Moon Valley Buckeye Verrado'
                WHEN 16 THEN 'Moon Valley Maricopa John Wayne'
                WHEN 17 THEN 'Moon Valley Casa Grande Florence'
                WHEN 18 THEN 'Moon Valley Prescott Valley Hwy 69'
                WHEN 19 THEN 'Moon Valley Tucson Ina Rd'
                WHEN 20 THEN 'Moon Valley Tucson Tanque Verde'
                WHEN 21 THEN 'Moon Valley Oro Valley Oracle'
                WHEN 22 THEN 'Moon Valley Marana Twin Peaks'
                WHEN 23 THEN 'Moon Valley Sahuarita Duval Mine'
                WHEN 24 THEN 'Moon Valley Yuma Fortuna Rd'
                WHEN 25 THEN 'Moon Valley Lake Havasu Hwy 95'
                WHEN 26 THEN 'Moon Valley Bullhead City Hwy 95'
                WHEN 27 THEN 'Moon Valley Kingman Stockton Hill'
                WHEN 28 THEN 'Moon Valley Flagstaff Butler Ave'
                WHEN 29 THEN 'Moon Valley Sedona Red Rock'
                WHEN 30 THEN 'Moon Valley Payson Beeline Hwy'
                WHEN 31 THEN 'Moon Valley Apache Junction US-60'
                WHEN 32 THEN 'Moon Valley San Tan Valley Hunt Hwy'
                WHEN 33 THEN 'Moon Valley Anthem Gavilan Peak'
                WHEN 34 THEN 'Moon Valley Fountain Hills Shea'
                ELSE         'Moon Valley Litchfield Park Camelback'
            END
        WHEN 'CA' THEN
            CASE state_idx
                WHEN 1  THEN 'Moon Valley Palm Desert Hwy 111'
                WHEN 2  THEN 'Moon Valley Indio Jefferson St'
                WHEN 3  THEN 'Moon Valley Murrieta Hot Springs'
                WHEN 4  THEN 'Moon Valley Temecula Winchester'
                WHEN 5  THEN 'Moon Valley Corona Cajalco'
                WHEN 6  THEN 'Moon Valley Riverside Van Buren'
                WHEN 7  THEN 'Moon Valley San Diego Miramar'
                WHEN 8  THEN 'Moon Valley Escondido Auto Park'
                WHEN 9  THEN 'Moon Valley Chula Vista Otay Lakes'
                WHEN 10 THEN 'Moon Valley Carlsbad Palomar'
                WHEN 11 THEN 'Moon Valley Irvine Sand Canyon'
                WHEN 12 THEN 'Moon Valley Huntington Beach'
                WHEN 13 THEN 'Moon Valley San Juan Capistrano'
                WHEN 14 THEN 'Moon Valley Yorba Linda Imperial'
                WHEN 15 THEN 'Moon Valley Chino Hills Soquel'
                WHEN 16 THEN 'Moon Valley Rancho Cucamonga'
                WHEN 17 THEN 'Moon Valley Redlands Lugonia'
                WHEN 18 THEN 'Moon Valley Beaumont I-10'
                WHEN 19 THEN 'Moon Valley Thousand Oaks'
                WHEN 20 THEN 'Moon Valley Simi Valley Madera'
                WHEN 21 THEN 'Moon Valley Santa Clarita Bouquet'
                WHEN 22 THEN 'Moon Valley Bakersfield Rosedale'
                WHEN 23 THEN 'Moon Valley Fresno Herndon Ave'
                WHEN 24 THEN 'Moon Valley Visalia Mooney Blvd'
                ELSE         'Moon Valley Fallbrook Hwy 76'
            END
        WHEN 'NV' THEN
            CASE state_idx
                WHEN 1  THEN 'Moon Valley Las Vegas Summerlin'
                WHEN 2  THEN 'Moon Valley Henderson St Rose'
                WHEN 3  THEN 'Moon Valley Centennial Hills'
                WHEN 4  THEN 'Moon Valley Southern Highlands'
                WHEN 5  THEN 'Moon Valley North Las Vegas Craig'
                WHEN 6  THEN 'Moon Valley Spring Valley Rainbow'
                WHEN 7  THEN 'Moon Valley Green Valley Sunset'
                WHEN 8  THEN 'Moon Valley Blue Diamond Rd'
                WHEN 9  THEN 'Moon Valley Mesquite Falcon Ridge'
                WHEN 10 THEN 'Moon Valley Pahrump Hwy 160'
                WHEN 11 THEN 'Moon Valley Boulder City Nevada Way'
                ELSE         'Moon Valley Enterprise Durango'
            END
        WHEN 'TX' THEN
            CASE state_idx
                WHEN 1  THEN 'Moon Valley Katy Freeway'
                WHEN 2  THEN 'Moon Valley Spring I-45 North'
                WHEN 3  THEN 'Moon Valley Sugar Land Hwy 59'
                WHEN 4  THEN 'Moon Valley Cypress Hwy 290'
                WHEN 5  THEN 'Moon Valley League City I-45'
                WHEN 6  THEN 'Moon Valley Conroe Loop 336'
                WHEN 7  THEN 'Moon Valley Frisco Preston Rd'
                WHEN 8  THEN 'Moon Valley McKinney US-75'
                WHEN 9  THEN 'Moon Valley Keller Bear Creek'
                WHEN 10 THEN 'Moon Valley Rockwall I-30'
                WHEN 11 THEN 'Moon Valley Mansfield US-287'
                WHEN 12 THEN 'Moon Valley Austin Cedar Park'
                WHEN 13 THEN 'Moon Valley Georgetown I-35'
                WHEN 14 THEN 'Moon Valley Dripping Springs'
                WHEN 15 THEN 'Moon Valley San Antonio Stone Oak'
                ELSE         'Moon Valley New Braunfels I-35'
            END
        ELSE -- FL
            CASE state_idx
                WHEN 1  THEN 'Moon Valley Tampa Citrus Park'
                WHEN 2  THEN 'Moon Valley Brandon Hwy 60'
                WHEN 3  THEN 'Moon Valley Wesley Chapel SR-54'
                WHEN 4  THEN 'Moon Valley Sarasota University Pkwy'
                WHEN 5  THEN 'Moon Valley Orlando Winter Garden'
                WHEN 6  THEN 'Moon Valley Lake Mary I-4'
                WHEN 7  THEN 'Moon Valley Kissimmee Osceola'
                WHEN 8  THEN 'Moon Valley Clermont Hwy 27'
                WHEN 9  THEN 'Moon Valley Fort Myers Daniels Pkwy'
                WHEN 10 THEN 'Moon Valley Naples Pine Ridge'
                WHEN 11 THEN 'Moon Valley West Palm Beach Okeechobee'
                ELSE         'Moon Valley Boca Raton Glades Rd'
            END
    END AS location_name,
    CASE state
        WHEN 'AZ' THEN CASE WHEN state_idx BETWEEN 19 AND 23 THEN 'Tucson' WHEN state_idx = 24 THEN 'Yuma' WHEN state_idx = 28 THEN 'Flagstaff' ELSE 'Phoenix Metro' END
        WHEN 'CA' THEN CASE WHEN state_idx IN (1, 2) THEN 'Palm Desert' WHEN state_idx BETWEEN 7 AND 10 THEN 'San Diego' WHEN state_idx BETWEEN 11 AND 14 THEN 'Orange County' ELSE 'Inland Empire' END
        WHEN 'NV' THEN CASE WHEN state_idx = 2 THEN 'Henderson' ELSE 'Las Vegas' END
        WHEN 'TX' THEN CASE WHEN state_idx <= 6 THEN 'Houston' WHEN state_idx <= 11 THEN 'Dallas-Fort Worth' WHEN state_idx <= 14 THEN 'Austin' ELSE 'San Antonio' END
        ELSE           CASE WHEN state_idx <= 4 THEN 'Tampa' WHEN state_idx <= 8 THEN 'Orlando' WHEN state_idx <= 10 THEN 'Southwest FL' ELSE 'South Florida' END
    END AS city,
    state,
    CASE state
        WHEN 'AZ' THEN 'Desert Southwest'
        WHEN 'NV' THEN 'Desert Southwest'
        WHEN 'CA' THEN 'Southern California'
        WHEN 'TX' THEN 'Texas'
        ELSE 'Florida'
    END AS region,
    CASE state
        WHEN 'AZ' THEN CASE WHEN state_idx BETWEEN 19 AND 23 THEN 'Tucson Metro' ELSE 'Phoenix Metro' END
        WHEN 'CA' THEN CASE WHEN state_idx IN (1, 2) THEN 'Coachella Valley' WHEN state_idx BETWEEN 7 AND 10 THEN 'San Diego Metro' ELSE 'SoCal Inland & OC' END
        WHEN 'NV' THEN 'Las Vegas Valley'
        WHEN 'TX' THEN CASE WHEN state_idx <= 6 THEN 'Greater Houston' WHEN state_idx <= 11 THEN 'DFW Metroplex' ELSE 'Central Texas (Austin/SA)' END
        ELSE           CASE WHEN state_idx <= 4 THEN 'Tampa Bay' WHEN state_idx <= 8 THEN 'Greater Orlando' ELSE 'South Florida' END
    END AS market,
    CASE
        WHEN state = 'AZ' AND state_idx <= 25 THEN DATEADD('day', state_idx * 45, '2014-01-15'::DATE)
        WHEN state = 'AZ' THEN DATEADD('day', (state_idx - 25) * 60, '2018-03-01'::DATE)
        WHEN state = 'CA' AND state_idx <= 18 THEN DATEADD('day', state_idx * 55, '2015-02-01'::DATE)
        WHEN state = 'CA' THEN DATEADD('day', (state_idx - 18) * 70, '2020-04-01'::DATE)
        WHEN state = 'NV' THEN DATEADD('day', state_idx * 65, '2016-01-15'::DATE)
        WHEN state = 'TX' AND state_idx <= 10 THEN DATEADD('day', state_idx * 50, '2021-03-01'::DATE)
        WHEN state = 'TX' THEN DATEADD('day', (state_idx - 10) * 35, '2024-09-01'::DATE) -- New ramping TX stores
        ELSE DATEADD('day', state_idx * 30, '2024-10-01'::DATE)                         -- New ramping FL stores
    END AS open_date,
    120000 + MOD(n * 13700, 180000) AS sq_ft,
    CASE
        WHEN state = 'AZ' AND state_idx = 28 THEN '8a'
        WHEN state = 'AZ' AND state_idx BETWEEN 19 AND 23 THEN '9a'
        WHEN state = 'AZ' THEN '9b'
        WHEN state = 'NV' THEN '9a'
        WHEN state = 'CA' AND state_idx IN (1, 2) THEN '10a'
        WHEN state = 'CA' THEN '10a'
        WHEN state = 'TX' AND state_idx BETWEEN 7 AND 11 THEN '8b'
        WHEN state = 'TX' THEN '9a'
        WHEN state = 'FL' AND state_idx >= 9 THEN '10b'
        ELSE '9b'
    END AS hardiness_zone,
    CASE
        WHEN state = 'FL' OR (state = 'TX' AND state_idx > 10) THEN TRUE
        ELSE FALSE
    END AS is_new_market
FROM loc_base;


-- =============================================================================
-- 3. DIM_FARM (12 Vertically Integrated Growing Farms)
-- =============================================================================
TRUNCATE TABLE RAW.DIM_FARM;

INSERT INTO RAW.DIM_FARM VALUES
    ('FARM-AZ-01', 'Yuma Imperial Specimen Farm',       'AZ', 1450, 'Specimen Box Trees & Desert Shade'),
    ('FARM-AZ-02', 'Gila Bend Desert Grown Farm',       'AZ', 1120, 'Palo Verde, Mesquite & Ironwood'),
    ('FARM-AZ-03', 'Buckeye Hassayampa Tree Farm',      'AZ',  890, 'Ash, Elm & Olive Box Trees'),
    ('FARM-CA-01', 'Coachella Valley Date & Palm Farm', 'CA', 1680, 'Date Palms, Fan Palms & Queen Palms'),
    ('FARM-CA-02', 'Piru Canyon Heritage Farm',         'CA', 1340, 'Live Oak, Sycamore & Magnolia'),
    ('FARM-CA-03', 'Fillmore Citrus & Stone Fruit Farm','CA',  920, 'Citrus, Avocado & Deciduous Fruit'),
    ('FARM-CA-04', 'Hemet Inland Specimen Farm',        'CA', 1050, 'Flowering Trees, Crape Myrtle & Shrubs'),
    ('FARM-TX-01', 'Glen Flora Brazos River Farm',      'TX', 1820, 'Southern Live Oak, Cedar Elm & Red Oak'),
    ('FARM-TX-02', 'Waller County Specimen Farm',       'TX', 1240, 'Cold-Hardy Palms, Magnolia & Pine'),
    ('FARM-TX-03', 'Pleasanton South Texas Farm',       'TX',  960, 'Texas Mountain Laurel & Drought Shrubs'),
    ('FARM-FL-01', 'Homestead Subtropical Palm Farm',   'FL', 1540, 'Royal Palm, Bismarck Palm & Coconut'),
    ('FARM-FL-02', 'Zolfo Springs Peace River Farm',    'FL', 1180, 'Cathedral Live Oak, Sabal Palm & Citrus');


-- =============================================================================
-- 4. DIM_PRODUCT (400 SKUs across 8 Categories & Container Sizes)
-- =============================================================================
TRUNCATE TABLE RAW.DIM_PRODUCT;

INSERT INTO RAW.DIM_PRODUCT
WITH seq AS (
    SELECT SEQ4() + 1 AS p_idx
    FROM TABLE(GENERATOR(ROWCOUNT => 400))
),
prod_meta AS (
    SELECT
        p_idx,
        CASE
            WHEN p_idx <= 90  THEN 'Shade Trees'
            WHEN p_idx <= 160 THEN 'Palms'
            WHEN p_idx <= 215 THEN 'Fruit Trees'
            WHEN p_idx <= 270 THEN 'Flowering Trees'
            WHEN p_idx <= 325 THEN 'Shrubs'
            WHEN p_idx <= 355 THEN 'Groundcover'
            WHEN p_idx <= 380 THEN 'Fertilizer & Soil'
            ELSE 'Services'
        END AS category,
        CASE
            WHEN p_idx <= 270 THEN -- Trees & Palms
                CASE MOD(p_idx, 4)
                    WHEN 1 THEN '15 gal'
                    WHEN 2 THEN '24in box'
                    WHEN 3 THEN '36in box'
                    ELSE        '48in box+'
                END
            WHEN p_idx <= 355 THEN -- Shrubs & Groundcover
                CASE WHEN MOD(p_idx, 3) = 0 THEN '24in box' ELSE '15 gal' END
            WHEN p_idx <= 380 THEN 'Bag/Bottle'
            ELSE 'Service'
        END AS container_size
    FROM seq
)
SELECT
    'PRD-' || LPAD(p_idx::VARCHAR, 4, '0') AS product_id,
    'MVN-' || UPPER(SUBSTR(category, 1, 3)) || '-' || LPAD(p_idx::VARCHAR, 4, '0') AS sku,
    CASE category
        WHEN 'Shade Trees' THEN
            (CASE MOD(p_idx, 8)
                WHEN 0 THEN 'Museum Palo Verde'
                WHEN 1 THEN 'Chilean Mesquite'
                WHEN 2 THEN 'Southern Live Oak'
                WHEN 3 THEN 'arizona Ash (Fan-Tex)'
                WHEN 4 THEN 'Chinese Elm (True Green)'
                WHEN 5 THEN 'Desert Ironwood'
                WHEN 6 THEN 'Swan Hill Fruitless Olive'
                ELSE        'Monterey Oak'
            END) || ' (' || container_size || ')'
        WHEN 'Palms' THEN
            (CASE MOD(p_idx, 7)
                WHEN 0 THEN 'Piru Queen Palm'
                WHEN 1 THEN 'Mediterranean Fan Palm'
                WHEN 2 THEN 'Medjool Date Palm'
                WHEN 3 THEN 'Mule Palm (X Butiagrus)'
                WHEN 4 THEN 'Bismarck Silver Palm'
                WHEN 5 THEN 'Mexican Fan Palm'
                ELSE        'Canary Island Date Palm'
            END) || ' (' || container_size || ')'
        WHEN 'Fruit Trees' THEN
            (CASE MOD(p_idx, 6)
                WHEN 0 THEN 'Meyer Improved Lemon'
                WHEN 1 THEN 'Washington Navel Orange'
                WHEN 2 THEN 'Bearss Seedless Lime'
                WHEN 3 THEN 'Hass Avocado'
                WHEN 4 THEN 'Desert Gold Peach'
                ELSE        'Wonderful Pomegranate'
            END) || ' (' || container_size || ')'
        WHEN 'Flowering Trees' THEN
            (CASE MOD(p_idx, 6)
                WHEN 0 THEN 'Tuscarora Crape Myrtle'
                WHEN 1 THEN 'Texas Mountain Laurel'
                WHEN 2 THEN 'Royal Poinciana'
                WHEN 3 THEN 'Desert Willow (Bubba)'
                WHEN 4 THEN 'Southern Magnolia (Little Gem)'
                ELSE        'Purple Leaf Plum'
            END) || ' (' || container_size || ')'
        WHEN 'Shrubs' THEN
            (CASE MOD(p_idx, 5)
                WHEN 0 THEN 'Texas Ranger (Green Cloud)'
                WHEN 1 THEN 'Red Bird of Paradise'
                WHEN 2 THEN 'Hopseed Bush (Dodonaea)'
                WHEN 3 THEN 'Japanese Boxwood'
                ELSE        'Bougainvillea Torch Glow'
            END) || ' (' || container_size || ')'
        WHEN 'Groundcover' THEN
            (CASE MOD(p_idx, 4)
                WHEN 0 THEN 'Lantana New Gold'
                WHEN 1 THEN 'Trailing Rosemary'
                WHEN 2 THEN 'Star Jasmine'
                ELSE        'Purple Heart Tradescantia'
            END) || ' (' || container_size || ')'
        WHEN 'Fertilizer & Soil' THEN
            CASE MOD(p_idx, 5)
                WHEN 0 THEN 'Moon Juice Root & Bio-Stimulant (1 Gal)'
                WHEN 1 THEN 'Super Charged Moon Green (20 lb)'
                WHEN 2 THEN 'Moon Dust All-Purpose Fertilizer (40 lb)'
                WHEN 3 THEN 'Moon Valley Mulch & Compost Blend (2 cu ft)'
                ELSE        'Super Palm Juice Micronutrient (1 Gal)'
            END
        ELSE
            CASE MOD(p_idx, 4)
                WHEN 0 THEN 'Professional Tree Planting Service - Standard Box'
                WHEN 1 THEN 'ProfessionalCrane & Heavy Box Planting Service'
                WHEN 2 THEN 'VIP Landscape Design Consultation Package'
                ELSE        'Extended 1-Year Tree Replacement Warranty Plan'
            END
    END AS product_name,
    category,
    container_size,
    -- Unit Price: Box trees command significantly higher ticket prices
    CASE
        WHEN container_size = '48in box+'  THEN ROUND(3600 + MOD(p_idx * 97, 1800), 2)
        WHEN container_size = '36in box'   THEN ROUND(1650 + MOD(p_idx * 73, 750), 2)
        WHEN container_size = '24in box'   THEN ROUND(599  + MOD(p_idx * 41, 300), 2)
        WHEN container_size = '15 gal'     THEN ROUND(129  + MOD(p_idx * 19, 90), 2)
        WHEN container_size = 'Bag/Bottle' THEN ROUND(49   + MOD(p_idx * 11, 45), 2)
        ELSE                                    ROUND(225  + MOD(p_idx * 53, 450), 2)
    END AS unit_price,
    -- Unit Cost: Vertically integrated farms yield higher gross margin % on larger box sizes
    -- 24in box (~54% GM), 36in box (~61% GM), 48in box+ (~66% GM)
    CASE
        WHEN container_size = '48in box+'  THEN ROUND((3600 + MOD(p_idx * 97, 1800)) * 0.34, 2)
        WHEN container_size = '36in box'   THEN ROUND((1650 + MOD(p_idx * 73, 750))  * 0.39, 2)
        WHEN container_size = '24in box'   THEN ROUND((599  + MOD(p_idx * 41, 300))  * 0.46, 2)
        WHEN container_size = '15 gal'     THEN ROUND((129  + MOD(p_idx * 19, 90))   * 0.52, 2)
        WHEN container_size = 'Bag/Bottle' THEN ROUND((49   + MOD(p_idx * 11, 45))   * 0.40, 2)
        ELSE                                    ROUND((225  + MOD(p_idx * 53, 450))  * 0.35, 2)
    END AS unit_cost,
    CASE
        WHEN category IN ('Fertilizer & Soil', 'Services') THEN 'N/A'
        WHEN category = 'Shade Trees' AND MOD(p_idx, 8) IN (0, 1, 5, 6) THEN 'Very Low'
        WHEN category = 'Shade Trees' THEN 'Low'
        WHEN category = 'Palms' AND MOD(p_idx, 7) IN (1, 2, 4, 5) THEN 'Low'
        WHEN category = 'Palms' THEN 'Moderate'
        WHEN category = 'Fruit Trees' AND MOD(p_idx, 6) = 5 THEN 'Low'
        WHEN category = 'Fruit Trees' THEN 'Moderate'
        WHEN category = 'Flowering Trees' AND MOD(p_idx, 6) IN (1, 3) THEN 'Very Low'
        WHEN category = 'Flowering Trees' THEN 'Moderate'
        WHEN category = 'Shrubs' AND MOD(p_idx, 5) IN (0, 1, 2) THEN 'Very Low'
        ELSE 'Low'
    END AS water_use,
    CASE category
        WHEN 'Shade Trees' THEN
            CASE MOD(p_idx, 8)
                WHEN 0 THEN 'PAFL6'  -- Parkinsonia florida (Blue/Museum Palo Verde)
                WHEN 1 THEN 'PRCH'   -- Prosopis chilensis (Chilean Mesquite)
                WHEN 2 THEN 'QUVI'   -- Quercus virginiana (Southern Live Oak)
                WHEN 3 THEN 'FRVE2'  -- Fraxinus velutina (Arizona Ash)
                WHEN 4 THEN 'ULPA'   -- Ulmus parvifolia (Chinese Elm)
                WHEN 5 THEN 'OLTE'   -- Olneya tesota (Desert Ironwood)
                WHEN 6 THEN 'OLEU'   -- Olea europaea (Fruitless Olive)
                ELSE        'QUPO2'  -- Quercus polymorpha (Monterey Oak)
            END
        WHEN 'Palms' THEN
            CASE MOD(p_idx, 7)
                WHEN 0 THEN 'SYRO'   -- Syagrus romanzoffiana (Queen Palm)
                WHEN 1 THEN 'CHHU2'  -- Chamaerops humilis (Mediterranean Fan Palm)
                WHEN 2 THEN 'PHDA4'  -- Phoenix dactylifera (Medjool Date Palm)
                WHEN 3 THEN 'BUNA'   -- Butia x Syagrus (Mule Palm)
                WHEN 4 THEN 'BINO'   -- Bismarckia nobilis (Bismarck Palm)
                WHEN 5 THEN 'WARO'   -- Washingtonia robusta (Mexican Fan Palm)
                ELSE        'PHCA13' -- Phoenix canariensis (Canary Island Date Palm)
            END
        WHEN 'Fruit Trees' THEN
            CASE MOD(p_idx, 6)
                WHEN 0 THEN 'CILI5'  -- Citrus x limon
                WHEN 1 THEN 'CISI3'  -- Citrus x sinensis
                WHEN 2 THEN 'CIAU7'  -- Citrus x aurantiifolia
                WHEN 3 THEN 'PEAM3'  -- Persea americana
                WHEN 4 THEN 'PRPE3'  -- Prunus persica
                ELSE        'PUGR2'  -- Punica granatum
            END
        WHEN 'Flowering Trees' THEN
            CASE MOD(p_idx, 6)
                WHEN 0 THEN 'LAIN7'  -- Lagerstroemia indica (Crape Myrtle)
                WHEN 1 THEN 'SOSE3'  -- Sophora secundiflora (Texas Mountain Laurel)
                WHEN 2 THEN 'DERE'   -- Delonix regia (Royal Poinciana)
                WHEN 3 THEN 'CHLI2'  -- Chilopsis linearis (Desert Willow)
                WHEN 4 THEN 'MAGR4'  -- Magnolia grandiflora (Southern Magnolia)
                ELSE        'PRCE2'  -- Prunus cerasifera (Purple Leaf Plum)
            END
        WHEN 'Shrubs' THEN
            CASE MOD(p_idx, 5)
                WHEN 0 THEN 'LEFR3'  -- Leucophyllum frutescens (Texas Ranger)
                WHEN 1 THEN 'CAPU13' -- Caesalpinia pulcherrima (Red Bird of Paradise)
                WHEN 2 THEN 'DOVI'   -- Dodonaea viscosa (Hopseed Bush)
                WHEN 3 THEN 'BUMI'   -- Buxus microphylla (Japanese Boxwood)
                ELSE        'BOGL'   -- Bougainvillea glabra
            END
        WHEN 'Groundcover' THEN
            CASE MOD(p_idx, 4)
                WHEN 0 THEN 'LACA2'  -- Lantana camara
                WHEN 1 THEN 'ROOF'   -- Rosmarinus officinalis
                WHEN 2 THEN 'TRJA'   -- Trachelospermum jasminoides
                ELSE        'TRPA8'  -- Tradescantia pallida
            END
        WHEN 'Fertilizer & Soil' THEN 'FERT'
        ELSE 'SVC'
    END AS plant_symbol,
    CASE WHEN category IN ('Shade Trees', 'Palms', 'Fruit Trees', 'Flowering Trees') THEN TRUE ELSE FALSE END AS is_tree,
    CASE WHEN category IN ('Shade Trees', 'Palms', 'Fruit Trees', 'Flowering Trees')
          AND container_size IN ('24in box', '36in box', '48in box+') THEN TRUE ELSE FALSE END AS is_box_tree
FROM prod_meta;


-- =============================================================================
-- 5. DIM_CUSTOMER (50,000 Customers across Homeowner, Landscaper, Builder)
-- =============================================================================
TRUNCATE TABLE RAW.DIM_CUSTOMER;

INSERT INTO RAW.DIM_CUSTOMER
WITH seq AS (
    SELECT SEQ4() + 1 AS c_idx
    FROM TABLE(GENERATOR(ROWCOUNT => 50000))
),
cust_base AS (
    SELECT
        c_idx,
        CASE
            WHEN MOD(c_idx, 100) < 72 THEN 'Homeowner'
            WHEN MOD(c_idx, 100) < 90 THEN 'Landscaper'
            ELSE 'Builder/Commercial'
        END AS customer_type,
        CASE
            WHEN MOD(c_idx, 100) < 35 THEN 'AZ'
            WHEN MOD(c_idx, 100) < 60 THEN 'CA'
            WHEN MOD(c_idx, 100) < 72 THEN 'NV'
            WHEN MOD(c_idx, 100) < 88 THEN 'TX'
            ELSE 'FL'
        END AS state
    FROM seq
)
SELECT
    'CUST-' || LPAD(c_idx::VARCHAR, 6, '0') AS customer_id,
    CASE customer_type
        WHEN 'Homeowner' THEN
            ARRAY_CONSTRUCT('James','Mary','Robert','Patricia','Michael','Jennifer','William','Linda','David','Elizabeth','Carlos','Elena','Sofia','Marcus','Priya','Devon')[MOD(c_idx, 16)]::VARCHAR
            || ' ' ||
            ARRAY_CONSTRUCT('Anderson','Martinez','Thompson','Garcia','Robinson','Clark','Rodriguez','Lewis','Walker','Hall','Nguyen','Patel','Chen','Reyes','Bennett','Foster')[MOD(FLOOR(c_idx / 16), 16)]::VARCHAR
        WHEN 'Landscaper' THEN
            ARRAY_CONSTRUCT('Desert Bloom','Sunbelt','Oasis','Sonoran','Pacific Crest','Lone Star','Emerald Coast','Canyon View','Premier','Pinnacle')[MOD(c_idx, 10)]::VARCHAR
            || ' Landscape Design #' || MOD(c_idx, 500)::VARCHAR
        ELSE
            ARRAY_CONSTRUCT('Toll Desert','Taylor Morrison','Pulte Southwest','Lennar Sunbelt','Shea Homes','Meritage','DR Horton','Highland','GL Homes','Perry')[MOD(c_idx, 10)]::VARCHAR
            || ' Communities Div-' || MOD(c_idx, 200)::VARCHAR
    END AS customer_name,
    customer_type,
    CASE state
        WHEN 'AZ' THEN (85001 + MOD(c_idx * 7, 280))::VARCHAR
        WHEN 'CA' THEN (92001 + MOD(c_idx * 7, 650))::VARCHAR
        WHEN 'NV' THEN (89001 + MOD(c_idx * 7, 190))::VARCHAR
        WHEN 'TX' THEN (75001 + MOD(c_idx * 7, 2900))::VARCHAR
        ELSE           (32801 + MOD(c_idx * 7, 1400))::VARCHAR
    END AS zip,
    state,
    DATEADD('day', MOD(c_idx * 13, 4000), '2015-01-15'::DATE) AS first_purchase_date,
    'customer.' || c_idx::VARCHAR || '@' ||
    CASE customer_type
        WHEN 'Homeowner' THEN 'gmail.com'
        WHEN 'Landscaper' THEN 'landscapingpros.com'
        ELSE 'builderdevelopments.com'
    END AS email,
    CASE state
        WHEN 'AZ' THEN '(480) 555-' || LPAD(MOD(c_idx * 17, 10000)::VARCHAR, 4, '0')
        WHEN 'CA' THEN '(760) 555-' || LPAD(MOD(c_idx * 17, 10000)::VARCHAR, 4, '0')
        WHEN 'NV' THEN '(702) 555-' || LPAD(MOD(c_idx * 17, 10000)::VARCHAR, 4, '0')
        WHEN 'TX' THEN '(281) 555-' || LPAD(MOD(c_idx * 17, 10000)::VARCHAR, 4, '0')
        ELSE           '(813) 555-' || LPAD(MOD(c_idx * 17, 10000)::VARCHAR, 4, '0')
    END AS phone
FROM cust_base;


-- =============================================================================
-- 6. DIM_SALESPERSON (400 Salespeople — 4 per Nursery Location)
-- =============================================================================
TRUNCATE TABLE RAW.DIM_SALESPERSON;

INSERT INTO RAW.DIM_SALESPERSON
WITH seq AS (
    SELECT SEQ4() + 1 AS s_idx
    FROM TABLE(GENERATOR(ROWCOUNT => 400))
),
locs AS (
    SELECT location_id, open_date, ROW_NUMBER() OVER (ORDER BY location_id) AS loc_num
    FROM RAW.DIM_LOCATION
)
SELECT
    'SLS-' || LPAD(s.s_idx::VARCHAR, 4, '0') AS salesperson_id,
    ARRAY_CONSTRUCT('logan','Chloe','austin','Savannah','Wyatt','brooklyn','Hunter','Sierra','Cole','Autumn','Dylan','morgan','blake','Paige','Garrett','Haley','Grant','Mackenzie','Tanner','Kaitlyn')[MOD(s.s_idx, 20)]::VARCHAR
    || ' ' ||
    ARRAY_CONSTRUCT('mitchell','Caldwell','Reeves','dawson','Vaughn','santiago','Delgado','Keller','strickland','boone','Harmon','fitzgerald','Navarro','benson','manning','hale')[MOD(FLOOR(s.s_idx / 20), 16)]::VARCHAR
    || ' (' || l.location_id || ')' AS name,
    l.location_id,
    GREATEST(l.open_date, DATEADD('day', MOD(s.s_idx * 29, 2500), '2016-01-01'::DATE)) AS hire_date,
    CASE MOD(s.s_idx, 4)
        WHEN 0 THEN 'Senior Specimen Tree Designer'
        WHEN 1 THEN 'Commercial & Builder Account Rep'
        WHEN 2 THEN 'Yard Design Pro'
        ELSE        'Nursery Sales Consultant'
    END AS role_title
FROM seq s
JOIN locs l ON l.loc_num = MOD(s.s_idx - 1, 100) + 1;


-- =============================================================================
-- 7. DIM_CREW (100 Field Planting Crews — 1 per Nursery Location)
-- =============================================================================
TRUNCATE TABLE RAW.DIM_CREW;

INSERT INTO RAW.DIM_CREW
SELECT
    'CREW-' || LPAD(ROW_NUMBER() OVER (ORDER BY location_id)::VARCHAR, 3, '0') AS crew_id,
    location_name || ' Planting Crew #' || ROW_NUMBER() OVER (PARTITION BY state ORDER BY location_id) AS crew_name,
    location_id,
    4 + MOD(ROW_NUMBER() OVER (ORDER BY location_id), 5) AS crew_size,
    CASE WHEN MOD(ROW_NUMBER() OVER (ORDER BY location_id), 3) IN (0, 1) THEN TRUE ELSE FALSE END AS crane_certified
FROM RAW.DIM_LOCATION;


-- =============================================================================
-- 8. DIM_CAMPAIGN (40 Marketing Campaigns across 2022–2026)
-- =============================================================================
TRUNCATE TABLE RAW.DIM_CAMPAIGN;

INSERT INTO RAW.DIM_CAMPAIGN
WITH seq AS (
    SELECT SEQ4() + 1 AS camp_idx
    FROM TABLE(GENERATOR(ROWCOUNT => 40))
)
SELECT
    'CMP-' || LPAD(camp_idx::VARCHAR, 3, '0') AS campaign_id,
    (2022 + FLOOR((camp_idx - 1) / 8))::VARCHAR || ' ' ||
    CASE MOD(camp_idx - 1, 8)
        WHEN 0 THEN 'Spring Monster Tree Sale'
        WHEN 1 THEN 'Instant Shade Box Tree Blitz'
        WHEN 2 THEN 'Resort Backyard Palm Event'
        WHEN 3 THEN 'Summer Heat Relief & Moon Juice Promo'
        WHEN 4 THEN 'Fall Planting Peak Specimen Sale'
        WHEN 5 THEN 'Privacy Hedge & Hollywood Style Promo'
        WHEN 6 THEN 'New Homeowner & HOA Design Showcase'
        ELSE        'Citrus & Fruit Orchard Harvest Event'
    END AS campaign_name,
    CASE MOD(camp_idx, 6)
        WHEN 0 THEN 'Paid Search'
        WHEN 1 THEN 'Direct Mail'
        WHEN 2 THEN 'Billboard/OOH'
        WHEN 3 THEN 'Local TV & Radio'
        WHEN 4 THEN 'Social Media'
        ELSE        'HOA/Builder Events'
    END AS channel,
    DATEADD('day', (camp_idx - 1) * 44, '2022-01-15'::DATE) AS start_date,
    DATEADD('day', (camp_idx - 1) * 44 + 40, '2022-01-15'::DATE) AS end_date,
    CASE MOD(camp_idx, 5)
        WHEN 0 THEN 'Desert Southwest'
        WHEN 1 THEN 'Southern California'
        WHEN 2 THEN 'Texas'
        WHEN 3 THEN 'Florida'
        ELSE        'All Regions'
    END AS region,
    ROUND(35000 + MOD(camp_idx * 8900, 95000), 2) AS budget_usd
FROM seq;


-- =============================================================================
-- 9. SALES FACT CONSTELLATION
--    Step 9A: Generate Transaction Skeleton (2015–2026, ~95,000 transactions)
--             Then expand to FACT_SALES_LINE (~185,000 lines)
--             Then aggregate FACT_SALES_LINE -> FACT_SALES_TRANSACTION
--             Then aggregate FACT_SALES_TRANSACTION -> FACT_SALES_DAILY_LOCATION
--             Guarantees 100.00% mathematical reconciliation across all 3 facts!
-- =============================================================================
TRUNCATE TABLE RAW.FACT_SALES_LINE;
TRUNCATE TABLE RAW.FACT_SALES_TRANSACTION;
TRUNCATE TABLE RAW.FACT_SALES_DAILY_LOCATION;

CREATE OR REPLACE TEMPORARY TABLE TEMP_TXN_HEADER AS
WITH raw_gen AS (
    SELECT SEQ4() + 1 AS t_id
    FROM TABLE(GENERATOR(ROWCOUNT => 95000))
),
txn_dates AS (
    SELECT
        t_id,
        -- Weight denser in 2023–2026 (70% of rows in 2023–2026, 30% across 2015–2022)
        CASE
            WHEN MOD(t_id, 10) < 3 THEN DATEADD('day', MOD(t_id * 17, 2922), '2015-01-01'::DATE)
            ELSE                        DATEADD('day', MOD(t_id * 13, 1397), '2023-01-01'::DATE)
        END AS raw_date,
        MOD(t_id * 31, 100) + 1 AS raw_loc_num
    FROM raw_gen
),
locs_numbered AS (
    SELECT
        location_id,
        state,
        region,
        open_date,
        is_new_market,
        ROW_NUMBER() OVER (ORDER BY location_id) AS loc_num
    FROM RAW.DIM_LOCATION
),
filtered_txns AS (
    SELECT
        td.t_id,
        -- Shift seasonal concentration toward Spring (Mar-May) and Fall (Oct-Nov)
        CASE
            WHEN l.state IN ('AZ', 'NV') AND MONTH(td.raw_date) IN (7, 8) AND MOD(td.t_id, 3) != 0
                THEN DATEADD('month', 3, td.raw_date) -- Move 2/3 of Jul/Aug desert transactions into Oct/Nov Fall peak
            WHEN MONTH(td.raw_date) IN (1, 12) AND MOD(td.t_id, 2) = 0
                THEN DATEADD('month', 3, td.raw_date) -- Shift half of winter into Spring peak
            ELSE td.raw_date
        END AS adj_date,
        l.location_id,
        l.state,
        l.region,
        l.open_date,
        l.is_new_market,
        l.loc_num
    FROM txn_dates td
    JOIN locs_numbered l ON td.raw_loc_num = l.loc_num
),
valid_txns AS (
    SELECT
        t_id,
        LEAST(adj_date, '2026-10-28'::DATE) AS txn_date,
        location_id,
        state,
        region,
        open_date,
        is_new_market,
        loc_num
    FROM filtered_txns
    WHERE adj_date >= open_date
      AND adj_date <= '2026-10-28'::DATE
      -- Storyline: 5 specific AZ stores underperform in Fall 2026 vs Fall 2025
      -- (LOC-AZ-004 Surprise, LOC-AZ-007 Chandler, LOC-AZ-011 Glendale, LOC-AZ-015 Buckeye, LOC-AZ-019 Tucson Ina)
      AND NOT (
          location_id IN ('LOC-AZ-004', 'LOC-AZ-007', 'LOC-AZ-011', 'LOC-AZ-015', 'LOC-AZ-019')
          AND YEAR(adj_date) = 2026
          AND MONTH(adj_date) IN (9, 10, 11)
          AND MOD(t_id, 10) < 4 -- 40% volume drop in Fall 2026 at these 5 AZ stores
      )
)
SELECT
    'TXN-' || LPAD(t_id::VARCHAR, 7, '0') AS transaction_id,
    TO_NUMBER(TO_CHAR(txn_date, 'YYYYMMDD')) AS date_key,
    txn_date,
    location_id,
    state,
    'CUST-' || LPAD((MOD(t_id * 37, 50000) + 1)::VARCHAR, 6, '0') AS customer_id,
    'SLS-'  || LPAD(((loc_num - 1) * 4 + MOD(t_id, 4) + 1)::VARCHAR, 4, '0') AS salesperson_id,
    CASE
        WHEN txn_date >= '2022-01-15'::DATE AND MOD(t_id, 5) IN (0, 1)
        THEN 'CMP-' || LPAD((MOD(t_id, 40) + 1)::VARCHAR, 3, '0')
        ELSE NULL
    END AS campaign_id,
    -- ~36% overall professional planting attach rate, but intentionally lower (~19%) at underperforming stores
    CASE
        WHEN location_id IN ('LOC-AZ-004', 'LOC-AZ-007', 'LOC-AZ-011', 'LOC-AZ-015', 'LOC-AZ-019', 'LOC-TX-014', 'LOC-FL-008')
            THEN (MOD(t_id, 100) < 19)
        WHEN MOD(t_id, 4) = 0 -- Senior Specimen Tree Designer has higher planting attach
            THEN (MOD(t_id, 100) < 48)
        ELSE (MOD(t_id, 100) < 36)
    END AS target_planting_flag
FROM valid_txns;

-- Populate FACT_SALES_LINE (1 to 3 lines per transaction)
INSERT INTO RAW.FACT_SALES_LINE
WITH line_slots AS (
    SELECT 1 AS line_no UNION ALL SELECT 2 UNION ALL SELECT 3
),
expanded_lines AS (
    SELECT
        th.transaction_id,
        ls.line_no,
        th.date_key,
        th.txn_date,
        th.location_id,
        th.state,
        th.target_planting_flag,
        CASE
            -- Line 1: Primary tree or shrub product (1..355)
            WHEN ls.line_no = 1 THEN
                CASE
                    -- Salesperson #1 at each store (Senior Specimen Designer) sells heavy 36in/48in box trees
                    WHEN MOD(TO_NUMBER(SUBSTR(th.salesperson_id, 5)), 4) = 1
                        THEN 'PRD-' || LPAD((MOD(TO_NUMBER(SUBSTR(th.transaction_id, 5)) * 4 + 3, 268) + 1)::VARCHAR, 4, '0')
                    ELSE 'PRD-' || LPAD((MOD(TO_NUMBER(SUBSTR(th.transaction_id, 5)) * 7, 355) + 1)::VARCHAR, 4, '0')
                END
            -- Line 2: If target_planting_flag is TRUE, attach Planting Service SKU (381..400)
            WHEN ls.line_no = 2 AND th.target_planting_flag = TRUE
                THEN 'PRD-' || LPAD((381 + MOD(TO_NUMBER(SUBSTR(th.transaction_id, 5)), 20))::VARCHAR, 4, '0')
            -- Line 2 (non-planting, 40% of txns): Fertilizer / Moon Juice attach (356..380)
            WHEN ls.line_no = 2 AND th.target_planting_flag = FALSE AND MOD(TO_NUMBER(SUBSTR(th.transaction_id, 5)), 5) IN (0, 1)
                THEN 'PRD-' || LPAD((356 + MOD(TO_NUMBER(SUBSTR(th.transaction_id, 5)), 25))::VARCHAR, 4, '0')
            -- Line 3 (25% of txns): Companion shrub/fertilizer/second tree
            WHEN ls.line_no = 3 AND MOD(TO_NUMBER(SUBSTR(th.transaction_id, 5)), 4) = 0
                THEN 'PRD-' || LPAD((MOD(TO_NUMBER(SUBSTR(th.transaction_id, 5)) * 11, 380) + 1)::VARCHAR, 4, '0')
            ELSE NULL
        END AS product_id
    FROM TEMP_TXN_HEADER th
    CROSS JOIN line_slots ls
),
lines_with_prod AS (
    SELECT
        el.transaction_id,
        el.line_no,
        el.date_key,
        el.txn_date,
        el.location_id,
        el.state,
        el.product_id,
        p.unit_price,
        p.unit_cost,
        p.container_size,
        p.category,
        CASE
            WHEN p.container_size IN ('36in box', '48in box+') THEN 1 + MOD(TO_NUMBER(SUBSTR(el.transaction_id, 5)), 2)
            WHEN p.container_size = '24in box'                 THEN 1 + MOD(TO_NUMBER(SUBSTR(el.transaction_id, 5)), 3)
            WHEN p.category = 'Services'                       THEN 1
            ELSE                                                    1 + MOD(TO_NUMBER(SUBSTR(el.transaction_id, 5)), 5)
        END AS qty,
        -- Discount promo logic: heavy discounting at select stores erodes margin
        CASE
            WHEN el.location_id IN ('LOC-AZ-004', 'LOC-AZ-007', 'LOC-AZ-011', 'LOC-NV-005', 'LOC-TX-006')
                 AND MOD(TO_NUMBER(SUBSTR(el.transaction_id, 5)), 3) = 0
                THEN 'Manager Price Match'
            WHEN MONTH(el.txn_date) IN (6, 7, 8) AND el.state IN ('AZ', 'NV')
                 AND MOD(TO_NUMBER(SUBSTR(el.transaction_id, 5)), 2) = 0
                THEN 'Summer Heat Clearance'
            WHEN MOD(TO_NUMBER(SUBSTR(el.transaction_id, 5)), 7) = 0
                THEN 'Multi-Tree Bundle'
            WHEN MOD(TO_NUMBER(SUBSTR(el.transaction_id, 5)), 11) = 0
                THEN 'Builder Volume'
            WHEN MOD(TO_NUMBER(SUBSTR(el.transaction_id, 5)), 13) = 0
                THEN 'VIP Landscape Pass'
            ELSE 'None'
        END AS discount_promo_type
    FROM expanded_lines el
    JOIN RAW.DIM_PRODUCT p ON el.product_id = p.product_id
    WHERE el.product_id IS NOT NULL
)
SELECT
    transaction_id,
    ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY line_no) AS line_no,
    date_key,
    location_id,
    state,
    product_id,
    qty,
    unit_price,
    ROUND(
        (qty * unit_price) *
        CASE discount_promo_type
            WHEN 'Manager Price Match'   THEN 0.18
            WHEN 'Summer Heat Clearance' THEN 0.22
            WHEN 'Builder Volume'        THEN 0.12
            WHEN 'Multi-Tree Bundle'     THEN 0.10
            WHEN 'VIP Landscape Pass'    THEN 0.08
            ELSE 0.00
        END,
        2
    ) AS discount,
    discount_promo_type,
    ROUND((qty * unit_price) - ROUND(
        (qty * unit_price) *
        CASE discount_promo_type
            WHEN 'Manager Price Match'   THEN 0.18
            WHEN 'Summer Heat Clearance' THEN 0.22
            WHEN 'Builder Volume'        THEN 0.12
            WHEN 'Multi-Tree Bundle'     THEN 0.10
            WHEN 'VIP Landscape Pass'    THEN 0.08
            ELSE 0.00
        END,
        2
    ), 2) AS extended_price,
    unit_cost,
    ROUND(qty * unit_cost, 2) AS extended_cost,
    ROUND(
        ROUND((qty * unit_price) - ROUND(
            (qty * unit_price) *
            CASE discount_promo_type
                WHEN 'Manager Price Match'   THEN 0.18
                WHEN 'Summer Heat Clearance' THEN 0.22
                WHEN 'Builder Volume'        THEN 0.12
                WHEN 'Multi-Tree Bundle'     THEN 0.10
                WHEN 'VIP Landscape Pass'    THEN 0.08
                ELSE 0.00
            END,
            2
        ), 2) - ROUND(qty * unit_cost, 2),
        2
    ) AS line_margin
FROM lines_with_prod;


-- Populate FACT_SALES_TRANSACTION as exact roll-up of FACT_SALES_LINE
INSERT INTO RAW.FACT_SALES_TRANSACTION
SELECT
    th.transaction_id,
    th.date_key,
    th.location_id,
    th.state,
    th.customer_id,
    th.salesperson_id,
    th.campaign_id,
    SUM(ROUND(l.qty * l.unit_price, 2))                                         AS gross_sales,
    SUM(l.discount)                                                             AS discounts,
    SUM(l.extended_price)                                                       AS net_sales,
    SUM(l.line_margin)                                                          AS gross_margin,
    SUM(l.qty)                                                                  AS units,
    SUM(CASE WHEN p.is_tree THEN l.qty ELSE 0 END)                              AS tree_units,
    SUM(CASE WHEN p.is_box_tree THEN l.qty ELSE 0 END)                          AS box_tree_units,
    MAX(CASE WHEN p.category = 'Services' THEN TRUE ELSE FALSE END)             AS includes_planting_flag
FROM TEMP_TXN_HEADER th
JOIN RAW.FACT_SALES_LINE l ON th.transaction_id = l.transaction_id
JOIN RAW.DIM_PRODUCT p     ON l.product_id = p.product_id
GROUP BY
    th.transaction_id,
    th.date_key,
    th.location_id,
    th.state,
    th.customer_id,
    th.salesperson_id,
    th.campaign_id;


-- Populate FACT_SALES_DAILY_LOCATION as exact roll-up of FACT_SALES_TRANSACTION (which equals FACT_SALES_LINE)
INSERT INTO RAW.FACT_SALES_DAILY_LOCATION
SELECT
    t.date_key,
    t.location_id,
    t.state,
    SUM(t.gross_sales)                                                          AS gross_sales,
    SUM(t.net_sales)                                                            AS net_sales,
    SUM(t.discounts)                                                            AS discounts,
    SUM(t.units)                                                                AS units,
    COUNT(DISTINCT t.transaction_id)                                            AS transactions,
    SUM(t.gross_margin)                                                         AS gross_margin,
    SUM(CASE WHEN t.includes_planting_flag THEN 1 ELSE 0 END)                   AS planting_transactions,
    SUM(CASE WHEN t.tree_units > 0 THEN 1 ELSE 0 END)                           AS tree_transactions
FROM RAW.FACT_SALES_TRANSACTION t
GROUP BY
    t.date_key,
    t.location_id,
    t.state;


-- =============================================================================
-- 10. FACT_PLANTED_JOBS (Field Services Planting Jobs for Planting Transactions)
-- =============================================================================
TRUNCATE TABLE RAW.FACT_PLANTED_JOBS;

INSERT INTO RAW.FACT_PLANTED_JOBS
WITH planting_txns AS (
    SELECT
        t.transaction_id,
        t.date_key,
        d.calendar_date AS sold_date,
        d.season,
        d.is_peak_season,
        t.location_id,
        t.state,
        GREATEST(t.tree_units, 1) AS tree_count,
        CASE
            WHEN t.box_tree_units >= 3 THEN 4 -- 48in+ crane box
            WHEN t.box_tree_units >= 2 THEN 3 -- 36in box
            WHEN t.box_tree_units >= 1 THEN 2 -- 24in box
            ELSE 1                            -- 15 gal
        END AS max_container_code,
        c.crew_id,
        c.crew_size,
        ROW_NUMBER() OVER (ORDER BY t.date_key, t.transaction_id) AS job_seq
    FROM RAW.FACT_SALES_TRANSACTION t
    JOIN RAW.DIM_DATE d ON t.date_key = d.date_key
    JOIN RAW.DIM_CREW c ON t.location_id = c.location_id
    WHERE t.includes_planting_flag = TRUE
      AND d.year >= 2022
),
job_calc AS (
    SELECT
        pt.*,
        -- Lead time to schedule is longer in Spring/Fall peak and for larger box sizes
        (CASE WHEN pt.is_peak_season THEN 8 ELSE 4 END)
        + pt.max_container_code * 2
        + MOD(pt.job_seq, 5) AS days_to_schedule,
        -- Certain crews (CREW-004, CREW-007, CREW-011, CREW-015, CREW-073) & heavy box jobs in peak season have higher delay/reschedule risk
        CASE
            WHEN pt.crew_id IN ('CREW-004', 'CREW-007', 'CREW-011', 'CREW-015', 'CREW-073')
                 AND MOD(pt.job_seq, 10) < 6 THEN 1
            WHEN pt.max_container_code >= 3 AND pt.is_peak_season AND pt.crew_size <= 5
                 AND MOD(pt.job_seq, 10) < 7 THEN 1
            WHEN pt.days_to_schedule >= 14 AND MOD(pt.job_seq, 10) < 5 THEN 1
            ELSE 0
        END AS delayed_flag
    FROM planting_txns pt
)
SELECT
    'JOB-' || LPAD(job_seq::VARCHAR, 7, '0') AS job_id,
    transaction_id,
    location_id,
    state,
    crew_id,
    sold_date,
    DATEADD('day', days_to_schedule, sold_date) AS scheduled_date,
    CASE
        WHEN sold_date >= '2026-10-15'::DATE AND MOD(job_seq, 3) != 0 THEN NULL -- Upcoming/Active scheduled jobs for ML scoring
        WHEN MOD(job_seq, 40) = 0 THEN NULL                                     -- Cancelled
        ELSE DATEADD('day', days_to_schedule + (CASE WHEN delayed_flag = 1 THEN 4 + MOD(job_seq, 6) ELSE 0 END), sold_date)
    END AS completed_date,
    days_to_schedule,
    CASE
        WHEN sold_date >= '2026-10-15'::DATE AND MOD(job_seq, 3) != 0 THEN NULL
        WHEN MOD(job_seq, 40) = 0 THEN NULL
        ELSE days_to_schedule + (CASE WHEN delayed_flag = 1 THEN 4 + MOD(job_seq, 6) ELSE 0 END)
    END AS days_sold_to_completed,
    CASE
        WHEN sold_date >= '2026-10-15'::DATE AND MOD(job_seq, 3) != 0 THEN
            CASE WHEN delayed_flag = 1 AND MOD(job_seq, 2) = 0 THEN 'Rescheduled' ELSE 'Scheduled' END
        WHEN MOD(job_seq, 40) = 0 THEN 'Cancelled'
        ELSE 'Completed'
    END AS status,
    CASE WHEN delayed_flag = 1 THEN 1 + MOD(job_seq, 2) ELSE 0 END AS reschedule_count,
    CASE
        WHEN delayed_flag = 1 THEN
            CASE MOD(job_seq, 6)
                WHEN 0 THEN 'Caliche/Hard Dig Required Rock Breaker'
                WHEN 1 THEN 'Blue Stake Utility Marking Delay'
                WHEN 2 THEN 'Crane Access / HOA Gate Clearance'
                WHEN 3 THEN 'Extreme Heat Advisory Reschedule'
                WHEN 4 THEN 'Customer Site Readiness Request'
                ELSE        'Prior Job Crew Overtime Spillover'
            END
        ELSE NULL
    END AS reschedule_reason,
    tree_count,
    max_container_code,
    CASE WHEN max_container_code >= 3 OR MOD(job_seq, 3) = 0 THEN TRUE ELSE FALSE END AS warranty_flag,
    delayed_flag,
    'NOTE-' || LPAD((MOD(job_seq, 240) + 1)::VARCHAR, 4, '0') AS notes_id
FROM job_calc;


-- =============================================================================
-- 11. FACT_INVENTORY_DAILY (Store × Product Weekly/Daily Inventory Snapshots)
--     Includes recurring Palm stockouts at AZ/NV/TX stores in peak weeks
-- =============================================================================
TRUNCATE TABLE RAW.FACT_INVENTORY_DAILY;

INSERT INTO RAW.FACT_INVENTORY_DAILY
WITH sample_dates AS (
    -- Weekly snapshots across 2025–2026 plus daily snapshots for last 14 days of Oct 2026
    SELECT date_key, calendar_date, season, is_peak_season
    FROM RAW.DIM_DATE
    WHERE (year IN (2025, 2026) AND DAYOFWEEKISO(calendar_date) = 1 AND calendar_date <= '2026-10-28'::DATE)
       OR (calendar_date BETWEEN '2026-10-15'::DATE AND '2026-10-28'::DATE)
),
top_products AS (
    SELECT product_id, category, container_size, unit_price
    FROM RAW.DIM_PRODUCT
    WHERE MOD(TO_NUMBER(SUBSTR(product_id, 5)), 8) = 1 -- 50 core high-velocity tree/palm/shrub SKUs
      AND category != 'Services'
),
loc_subset AS (
    SELECT location_id, state, open_date
    FROM RAW.DIM_LOCATION
),
inv_grid AS (
    SELECT
        sd.date_key,
        sd.calendar_date,
        sd.is_peak_season,
        l.location_id,
        l.state,
        tp.product_id,
        tp.category,
        tp.unit_price,
        ABS(HASH(sd.date_key, l.location_id, tp.product_id)) AS h
    FROM sample_dates sd
    CROSS JOIN loc_subset l
    CROSS JOIN top_products tp
    WHERE sd.calendar_date >= l.open_date
      AND MOD(ABS(HASH(l.location_id, tp.product_id)), 5) = 0 -- ~10 core SKUs tracked per store per snapshot
),
inv_metrics AS (
    SELECT
        date_key,
        location_id,
        state,
        product_id,
        category,
        unit_price,
        is_peak_season,
        h,
        -- Storyline: Palms at AZ/NV/TX stores (especially Surprise, Chandler, Glendale, Buckeye, Tucson, Scottsdale) experience recurring peak stockouts
        CASE
            WHEN category = 'Palms'
                 AND is_peak_season = TRUE
                 AND location_id IN ('LOC-AZ-002', 'LOC-AZ-004', 'LOC-AZ-007', 'LOC-AZ-011', 'LOC-AZ-015', 'LOC-AZ-019', 'LOC-NV-001', 'LOC-TX-001')
                 AND MOD(h, 10) < 4
                THEN 0
            WHEN is_peak_season = TRUE AND MOD(h, 25) = 0
                THEN 0
            ELSE 2 + MOD(h, 38)
        END AS on_hand_units,
        CASE
            WHEN category = 'Palms' AND is_peak_season = TRUE AND MOD(h, 4) = 0 THEN 0
            ELSE MOD(h, 20)
        END AS on_order_units,
        ROUND(0.6 + (MOD(h, 35) / 10.0) * (CASE WHEN is_peak_season THEN 1.65 ELSE 1.0 END), 2) AS daily_sell_rate,
        CASE
            WHEN category = 'Palms' THEN 12 + MOD(h, 7)
            WHEN category = 'Shade Trees' THEN 9 + MOD(h, 6)
            ELSE 5 + MOD(h, 5)
        END AS lead_time_days
    FROM inv_grid
)
SELECT
    date_key,
    location_id,
    state,
    product_id,
    on_hand_units,
    on_order_units,
    daily_sell_rate,
    ROUND(on_hand_units / NULLIF(daily_sell_rate, 0), 2) AS days_of_supply,
    lead_time_days,
    (on_hand_units = 0) AS stockout_flag,
    -- ML Target: Stockout in next 14 days when days_of_supply < lead_time_days and on_order_units is low
    CASE
        WHEN on_hand_units = 0 THEN 1
        WHEN (on_hand_units / NULLIF(daily_sell_rate, 0)) < (lead_time_days * 0.75)
             AND on_order_units < (daily_sell_rate * 5) THEN 1
        ELSE 0
    END AS stockout_next_14d_flag,
    CASE
        WHEN on_hand_units = 0 THEN ROUND(daily_sell_rate * unit_price * 0.85, 2)
        ELSE 0.00
    END AS estimated_lost_sales
FROM inv_metrics;


-- =============================================================================
-- 12. FACT_FARM_TRANSFERS (6,000 Farm-to-Store Replenishment Transfers)
-- =============================================================================
TRUNCATE TABLE RAW.FACT_FARM_TRANSFERS;

INSERT INTO RAW.FACT_FARM_TRANSFERS
WITH seq AS (
    SELECT SEQ4() + 1 AS tr_idx
    FROM TABLE(GENERATOR(ROWCOUNT => 6000))
)
SELECT
    'TRF-' || LPAD(s.tr_idx::VARCHAR, 6, '0') AS transfer_id,
    CASE l.state
        WHEN 'AZ' THEN ARRAY_CONSTRUCT('FARM-AZ-01', 'FARM-AZ-02', 'FARM-AZ-03', 'FARM-CA-01')[MOD(s.tr_idx, 4)]::VARCHAR
        WHEN 'CA' THEN ARRAY_CONSTRUCT('FARM-CA-01', 'FARM-CA-02', 'FARM-CA-03', 'FARM-CA-04')[MOD(s.tr_idx, 4)]::VARCHAR
        WHEN 'NV' THEN ARRAY_CONSTRUCT('FARM-CA-01', 'FARM-AZ-01', 'FARM-AZ-02')[MOD(s.tr_idx, 3)]::VARCHAR
        WHEN 'TX' THEN ARRAY_CONSTRUCT('FARM-TX-01', 'FARM-TX-02', 'FARM-TX-03')[MOD(s.tr_idx, 3)]::VARCHAR
        ELSE           ARRAY_CONSTRUCT('FARM-FL-01', 'FARM-FL-02')[MOD(s.tr_idx, 2)]::VARCHAR
    END AS farm_id,
    l.location_id,
    l.state,
    'PRD-' || LPAD((MOD(s.tr_idx * 9, 355) + 1)::VARCHAR, 4, '0') AS product_id,
    GREATEST(l.open_date, DATEADD('day', MOD(s.tr_idx * 11, 1400), '2023-01-01'::DATE)) AS ship_date,
    DATEADD('day', 2 + MOD(s.tr_idx, 4), GREATEST(l.open_date, DATEADD('day', MOD(s.tr_idx * 11, 1400), '2023-01-01'::DATE))) AS arrival_date,
    10 + MOD(s.tr_idx * 7, 45) AS units,
    ROUND(450 + MOD(s.tr_idx * 23, 1200), 2) AS freight_cost_usd
FROM seq s
JOIN (
    SELECT location_id, state, open_date, ROW_NUMBER() OVER (ORDER BY location_id) AS loc_num
    FROM RAW.DIM_LOCATION
) l ON l.loc_num = MOD(s.tr_idx - 1, 100) + 1;


-- =============================================================================
-- 13. FACT_MARKETING_LEADS (25,000 Marketing Leads linked to Campaigns & Pos)
-- =============================================================================
TRUNCATE TABLE RAW.FACT_MARKETING_LEADS;

INSERT INTO RAW.FACT_MARKETING_LEADS
WITH camp_txns AS (
    SELECT
        transaction_id,
        campaign_id,
        location_id,
        state,
        TO_DATE(date_key::VARCHAR, 'YYYYMMDD') AS txn_date,
        ROW_NUMBER() OVER (ORDER BY transaction_id) AS rn
    FROM RAW.FACT_SALES_TRANSACTION
    WHERE campaign_id IS NOT NULL
    QUALIFY rn <= 8500
),
unconverted_gen AS (
    SELECT SEQ4() + 8501 AS lead_num
    FROM TABLE(GENERATOR(ROWCOUNT => 16500))
)
-- 8,500 converted leads directly tied to campaign-attributed POS transactions
SELECT
    'LEAD-' || LPAD(ct.rn::VARCHAR, 6, '0') AS lead_id,
    ct.campaign_id,
    ct.location_id,
    ct.state,
    DATEADD('day', -MOD(ct.rn, 10), ct.txn_date) AS lead_date,
    c.customer_type,
    TRUE AS converted_flag,
    ct.transaction_id AS converted_transaction_id
FROM camp_txns ct
JOIN RAW.FACT_SALES_TRANSACTION t ON ct.transaction_id = t.transaction_id
JOIN RAW.DIM_CUSTOMER c           ON t.customer_id = c.customer_id

UNION ALL

-- 16,500 unconverted marketing leads
SELECT
    'LEAD-' || LPAD(ug.lead_num::VARCHAR, 6, '0') AS lead_id,
    'CMP-' || LPAD((MOD(ug.lead_num, 40) + 1)::VARCHAR, 3, '0') AS campaign_id,
    l.location_id,
    l.state,
    GREATEST(l.open_date, DATEADD('day', MOD(ug.lead_num * 7, 1380), '2023-01-01'::DATE)) AS lead_date,
    CASE
        WHEN MOD(ug.lead_num, 10) < 7 THEN 'Homeowner'
        WHEN MOD(ug.lead_num, 10) < 9 THEN 'Landscaper'
        ELSE 'Builder/Commercial'
    END AS customer_type,
    FALSE AS converted_flag,
    NULL AS converted_transaction_id
FROM unconverted_gen ug
JOIN (
    SELECT location_id, state, open_date, ROW_NUMBER() OVER (ORDER BY location_id) AS loc_num
    FROM RAW.DIM_LOCATION
) l ON l.loc_num = MOD(ug.lead_num - 1, 100) + 1;


-- =============================================================================
-- 14. RECONCILIATION & ROW COUNT VERIFICATION
-- =============================================================================
SELECT
    'RECONCILIATION_CHECK' AS check_type,
    (SELECT SUM(net_sales) FROM RAW.FACT_SALES_DAILY_LOCATION)  AS daily_location_net_sales,
    (SELECT SUM(net_sales) FROM RAW.FACT_SALES_TRANSACTION)     AS transaction_net_sales,
    (SELECT SUM(extended_price) FROM RAW.FACT_SALES_LINE)       AS line_net_sales,
    (SELECT SUM(net_sales) FROM RAW.FACT_SALES_DAILY_LOCATION)
      - (SELECT SUM(extended_price) FROM RAW.FACT_SALES_LINE)   AS net_sales_variance,
    (SELECT SUM(gross_margin) FROM RAW.FACT_SALES_DAILY_LOCATION)
      - (SELECT SUM(line_margin) FROM RAW.FACT_SALES_LINE)      AS margin_variance;
