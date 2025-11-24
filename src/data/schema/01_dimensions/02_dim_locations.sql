-- =====================================================================
-- DIM_LOCATIONS - Location Dimension Table
-- =====================================================================
-- Purpose: Geographic dimension for location-based analysis
-- Grain: One row per unique location (country/state/city)
-- =====================================================================

CREATE TABLE dim.dim_locations (
    -- Primary Key
    location_id SERIAL PRIMARY KEY,

    -- Geographic Hierarchy
    country_code VARCHAR(3) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    state_code VARCHAR(10),
    state_name VARCHAR(100),
    city_code VARCHAR(10),
    city_name VARCHAR(100),
    postal_code VARCHAR(20),

    -- Coordinates
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    timezone VARCHAR(50),

    -- Classification
    region VARCHAR(50),
    metro_area VARCHAR(100),
    urban_rural VARCHAR(20),
    risk_zone VARCHAR(50),

    -- Market Metrics
    population INTEGER CHECK (population >= 0),
    gdppercapita NUMERIC(18, 2),
    branch_count INTEGER DEFAULT 0 CHECK (branch_count >= 0),
    atm_count INTEGER DEFAULT 0 CHECK (atm_count >= 0),
    competitor_density VARCHAR(20),

    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_dim_locations_country ON dim.dim_locations(country_code);
CREATE INDEX idx_dim_locations_city ON dim.dim_locations(country_code, state_code, city_code);
CREATE INDEX idx_dim_locations_risk_zone ON dim.dim_locations(risk_zone);
CREATE INDEX idx_dim_locations_postal ON dim.dim_locations(postal_code);

-- Comments
COMMENT ON TABLE dim.dim_locations IS 'Geographic dimension for location-based risk analysis and market coverage metrics';
COMMENT ON COLUMN dim.dim_locations.risk_zone IS 'Geographic risk classification for fraud and credit risk analysis';
COMMENT ON COLUMN dim.dim_locations.competitor_density IS 'Market competition level: low, medium, high';
