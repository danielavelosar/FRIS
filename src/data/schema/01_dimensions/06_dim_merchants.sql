-- =====================================================================
-- DIM_MERCHANTS - Merchant Dimension Table
-- =====================================================================
-- Purpose: Merchant profiles with risk metrics and MCC classification
-- Grain: One row per unique merchant
-- =====================================================================

CREATE TABLE dim.dim_merchants (
    -- Primary Key
    merchant_id VARCHAR(50) PRIMARY KEY,

    -- Business Identification
    merchant_name VARCHAR(200) NOT NULL,
    legal_name VARCHAR(200),
    tax_id VARCHAR(50),

    -- MCC Classification (ISO 18245)
    merchantcategorycode VARCHAR(4) NOT NULL,
    mcc_description VARCHAR(200),
    industry_category VARCHAR(100),
    business_type VARCHAR(50),

    -- Lifecycle
    registration_date DATE NOT NULL,
    merchant_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Risk Metrics
    risk_level VARCHAR(20),
    fraud_rate NUMERIC(7, 6) CHECK (fraud_rate BETWEEN 0 AND 1),
    chargeback_rate NUMERIC(7, 6) CHECK (chargeback_rate BETWEEN 0 AND 1),
    highriskflag BOOLEAN DEFAULT FALSE,

    -- Business Metrics
    average_ticket NUMERIC(18, 2) CHECK (average_ticket >= 0),
    monthly_volume NUMERIC(18, 2) CHECK (monthly_volume >= 0),
    transaction_count INTEGER DEFAULT 0 CHECK (transaction_count >= 0),
    terminal_count INTEGER DEFAULT 0 CHECK (terminal_count >= 0),

    -- Contact Information
    website_url VARCHAR(255),
    email_domain VARCHAR(100),
    phone_number VARCHAR(50),

    -- Acquiring & Capabilities
    acquirer_name VARCHAR(200),
    ecommerceenabled BOOLEAN DEFAULT FALSE,
    recurring_billing BOOLEAN DEFAULT FALSE,

    -- Compliance
    pci_compliant BOOLEAN DEFAULT FALSE,
    lastreviewdate DATE,

    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_mcc_length CHECK (LENGTH(merchantcategorycode) = 4)
);

-- Indexes
CREATE INDEX idx_dim_merchants_name ON dim.dim_merchants(merchant_name);
CREATE INDEX idx_dim_merchants_status ON dim.dim_merchants(merchant_status);
CREATE INDEX idx_dim_merchants_mcc ON dim.dim_merchants(merchantcategorycode);
CREATE INDEX idx_dim_merchants_risk ON dim.dim_merchants(risk_level, highriskflag);
CREATE INDEX idx_dim_merchants_fraud_rate ON dim.dim_merchants(fraud_rate) WHERE fraud_rate > 0.01;
CREATE INDEX idx_dim_merchants_chargeback ON dim.dim_merchants(chargeback_rate) WHERE chargeback_rate > 0.01;
CREATE INDEX idx_dim_merchants_industry ON dim.dim_merchants(industry_category);

-- Comments
COMMENT ON TABLE dim.dim_merchants IS 'Merchant dimension with MCC classification, risk metrics, and fraud/chargeback rates for merchant risk analysis';
COMMENT ON COLUMN dim.dim_merchants.merchantcategorycode IS 'ISO 18245 Merchant Category Code (4-digit): 0001-9999';
COMMENT ON COLUMN dim.dim_merchants.fraud_rate IS 'Ratio of fraudulent transactions to total transactions';
COMMENT ON COLUMN dim.dim_merchants.chargeback_rate IS 'Ratio of chargebacks to total transactions';
COMMENT ON COLUMN dim.dim_merchants.highriskflag IS 'True if merchant operates in high-risk industry or has elevated risk metrics';
