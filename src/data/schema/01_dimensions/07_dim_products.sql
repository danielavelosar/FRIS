-- =====================================================================
-- DIM_PRODUCTS - Product Dimension Table
-- =====================================================================
-- Purpose: Financial product catalog with risk and profitability metrics
-- Grain: One row per unique product offering
-- =====================================================================

CREATE TABLE dim.dim_products (
    -- Primary Key
    product_id VARCHAR(50) PRIMARY KEY,

    -- Business Key & Naming
    product_code VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,

    -- Product Classification
    product_category VARCHAR(100) NOT NULL,
    product_type VARCHAR(100),
    product_family VARCHAR(100),
    target_segment VARCHAR(50),

    -- Lifecycle
    launch_date DATE NOT NULL,
    discontinue_date DATE,
    product_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Financial Terms
    minimum_amount NUMERIC(18, 2) CHECK (minimum_amount >= 0),
    maximum_amount NUMERIC(18, 2) CHECK (maximum_amount >= 0),
    baseinterestrate NUMERIC(7, 4) CHECK (baseinterestrate >= 0),
    annual_fee NUMERIC(18, 2) CHECK (annual_fee >= 0),
    penalty_rate NUMERIC(7, 4) CHECK (penalty_rate >= 0),

    -- Product Terms
    terms_months INTEGER CHECK (terms_months > 0),
    graceperioddays INTEGER CHECK (graceperioddays >= 0),

    -- Features & Benefits
    features TEXT,
    rewards_program VARCHAR(200),

    -- Business Metrics
    profitability_score NUMERIC(5, 4) CHECK (profitability_score BETWEEN 0 AND 1),
    risk_weight NUMERIC(5, 4) CHECK (risk_weight BETWEEN 0 AND 1),

    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_amount_range CHECK (maximum_amount IS NULL OR minimum_amount IS NULL OR maximum_amount >= minimum_amount),
    CONSTRAINT chk_discontinue_date CHECK (discontinue_date IS NULL OR discontinue_date >= launch_date)
);

-- Indexes
CREATE UNIQUE INDEX idx_dim_products_code ON dim.dim_products(product_code);
CREATE INDEX idx_dim_products_name ON dim.dim_products(product_name);
CREATE INDEX idx_dim_products_status ON dim.dim_products(product_status);
CREATE INDEX idx_dim_products_category ON dim.dim_products(product_category, product_type);
CREATE INDEX idx_dim_products_launch ON dim.dim_products(launch_date);
CREATE INDEX idx_dim_products_segment ON dim.dim_products(target_segment);
CREATE INDEX idx_dim_products_risk ON dim.dim_products(risk_weight);

-- Comments
COMMENT ON TABLE dim.dim_products IS 'Product dimension with financial terms, risk weights, and profitability for product portfolio analysis';
COMMENT ON COLUMN dim.dim_products.risk_weight IS 'Risk weighting factor for capital adequacy calculations (Basel III)';
COMMENT ON COLUMN dim.dim_products.profitability_score IS 'Product profitability index from 0 (unprofitable) to 1 (highly profitable)';
COMMENT ON COLUMN dim.dim_products.target_segment IS 'Target customer segment: mass, affluent, premium, corporate';
