-- =====================================================================
-- DIM_CARDS - Card Dimension Table
-- =====================================================================
-- Purpose: Payment card operational details and security attributes
-- Grain: One row per physical/virtual card
-- =====================================================================

CREATE TABLE dim.dim_cards (
    -- Primary Key
    card_id VARCHAR(50) PRIMARY KEY,

    -- Secure Identification (PCI Compliance)
    cardnumberhash VARCHAR(128) NOT NULL UNIQUE,
    cardlast4_digits VARCHAR(4) NOT NULL,

    -- Card Classification
    card_brand VARCHAR(50) NOT NULL,
    card_type VARCHAR(50) NOT NULL,
    card_level VARCHAR(50),
    issuing_bank VARCHAR(200),

    -- Lifecycle Dates
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    activation_date DATE,
    lastpinchange_date DATE,

    -- Status & Security
    card_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    block_reason VARCHAR(100),
    fraud_flag BOOLEAN DEFAULT FALSE,

    -- Capabilities
    chip_enabled BOOLEAN DEFAULT TRUE,
    contactless_enabled BOOLEAN DEFAULT FALSE,
    international_enabled BOOLEAN DEFAULT FALSE,
    online_enabled BOOLEAN DEFAULT TRUE,
    atm_enabled BOOLEAN DEFAULT TRUE,

    -- Transaction Limits
    dailylimitpos NUMERIC(18, 2) CHECK (dailylimitpos >= 0),
    dailylimitatm NUMERIC(18, 2) CHECK (dailylimitatm >= 0),
    monthly_limit NUMERIC(18, 2) CHECK (monthly_limit >= 0),

    -- Security Metrics
    pin_attempts INTEGER DEFAULT 0 CHECK (pin_attempts >= 0),
    replacement_count INTEGER DEFAULT 0 CHECK (replacement_count >= 0),

    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_expiry_date CHECK (expiry_date > issue_date),
    CONSTRAINT chk_activation_date CHECK (activation_date IS NULL OR activation_date >= issue_date),
    CONSTRAINT chk_pin_change CHECK (lastpinchange_date IS NULL OR lastpinchange_date >= activation_date)
);

-- Indexes
CREATE UNIQUE INDEX idx_dim_cards_hash ON dim.dim_cards(cardnumberhash);
CREATE INDEX idx_dim_cards_status ON dim.dim_cards(card_status);
CREATE INDEX idx_dim_cards_fraud ON dim.dim_cards(fraud_flag) WHERE fraud_flag = TRUE;
CREATE INDEX idx_dim_cards_expiry ON dim.dim_cards(expiry_date);
CREATE INDEX idx_dim_cards_brand_type ON dim.dim_cards(card_brand, card_type);
CREATE INDEX idx_dim_cards_last4 ON dim.dim_cards(cardlast4_digits);

-- Comments
COMMENT ON TABLE dim.dim_cards IS 'Card dimension with security attributes, capabilities, and fraud flags for transaction analysis';
COMMENT ON COLUMN dim.dim_cards.cardnumberhash IS 'SHA-256 hash of card number for secure identification (PCI compliance)';
COMMENT ON COLUMN dim.dim_cards.fraud_flag IS 'True if card has been flagged for fraudulent activity';
COMMENT ON COLUMN dim.dim_cards.pin_attempts IS 'Failed PIN attempt counter for security monitoring';
