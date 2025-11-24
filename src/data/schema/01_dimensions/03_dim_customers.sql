-- =====================================================================
-- DIM_CUSTOMERS - Customer Dimension Table
-- =====================================================================
-- Purpose: Customer profiles with KYC, AML, and risk attributes
-- Grain: One row per unique customer
-- =====================================================================

CREATE TABLE dim.dim_customers (
    -- Primary Key
    customer_id VARCHAR(50) PRIMARY KEY,

    -- Business Key & Identification
    customer_number VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200),
    document_type VARCHAR(20),
    document_number VARCHAR(50),

    -- Demographics
    birth_date DATE,
    age_group VARCHAR(20),
    gender VARCHAR(20),
    marital_status VARCHAR(20),
    education_level VARCHAR(50),

    -- Employment & Income
    occupation VARCHAR(100),
    employment_type VARCHAR(50),
    employer_name VARCHAR(200),
    monthly_income NUMERIC(18, 2) CHECK (monthly_income >= 0),
    income_bracket VARCHAR(50),

    -- Segmentation
    customer_segment VARCHAR(50),
    risk_profile VARCHAR(50),

    -- Credit & Risk
    credit_score INTEGER CHECK (credit_score BETWEEN 300 AND 850),
    creditscorerange VARCHAR(20),
    amlrisklevel VARCHAR(20),
    pep_flag BOOLEAN DEFAULT FALSE,
    blacklist_flag BOOLEAN DEFAULT FALSE,
    vip_flag BOOLEAN DEFAULT FALSE,

    -- Status & Dates
    registration_date DATE,
    activation_date DATE,
    lastactivitydate DATE,
    customer_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- KYC/AML
    kyc_status VARCHAR(20),
    kycverificationdate DATE,

    -- Contact Preferences
    email_domain VARCHAR(100),
    phonecountrycode VARCHAR(5),
    phoneareacode VARCHAR(10),
    preferred_language VARCHAR(20),
    preferred_channel VARCHAR(50),

    -- Business Metrics
    churn_probability NUMERIC(5, 4) CHECK (churn_probability BETWEEN 0 AND 1),
    lifetime_value NUMERIC(18, 2),
    total_products INTEGER DEFAULT 0 CHECK (total_products >= 0),

    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_dates CHECK (activation_date >= registration_date),
    CONSTRAINT chk_last_activity CHECK (lastactivitydate >= registration_date)
);

-- Indexes
CREATE INDEX idx_dim_customers_number ON dim.dim_customers(customer_number);
CREATE INDEX idx_dim_customers_status ON dim.dim_customers(customer_status);
CREATE INDEX idx_dim_customers_risk ON dim.dim_customers(risk_profile, amlrisklevel);
CREATE INDEX idx_dim_customers_segment ON dim.dim_customers(customer_segment);
CREATE INDEX idx_dim_customers_credit ON dim.dim_customers(credit_score);
CREATE INDEX idx_dim_customers_pep ON dim.dim_customers(pep_flag) WHERE pep_flag = TRUE;
CREATE INDEX idx_dim_customers_blacklist ON dim.dim_customers(blacklist_flag) WHERE blacklist_flag = TRUE;
CREATE INDEX idx_dim_customers_registration ON dim.dim_customers(registration_date);

-- Comments
COMMENT ON TABLE dim.dim_customers IS 'Customer dimension with KYC/AML risk profiles, credit scores, and segmentation for risk analysis';
COMMENT ON COLUMN dim.dim_customers.pep_flag IS 'Politically Exposed Person flag for AML compliance';
COMMENT ON COLUMN dim.dim_customers.amlrisklevel IS 'AML risk classification: low, medium, high';
COMMENT ON COLUMN dim.dim_customers.kyc_status IS 'KYC verification status: pending, verified, expired, rejected';
