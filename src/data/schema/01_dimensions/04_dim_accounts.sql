-- =====================================================================
-- DIM_ACCOUNTS - Account Dimension Table
-- =====================================================================
-- Purpose: Financial account/contract lifecycle and credit exposure
-- Grain: One row per unique account
-- =====================================================================

CREATE TABLE dim.dim_accounts (
    -- Primary Key
    account_id VARCHAR(50) PRIMARY KEY,

    -- Business Key & Classification
    account_number VARCHAR(50) NOT NULL UNIQUE,
    account_type VARCHAR(50) NOT NULL,
    account_subtype VARCHAR(50),
    product_name VARCHAR(200),

    -- Lifecycle
    opening_date DATE NOT NULL,
    closing_date DATE,
    account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Credit & Financial Position
    credit_limit NUMERIC(18, 2) CHECK (credit_limit >= 0),
    available_credit NUMERIC(18, 2) CHECK (available_credit >= 0),
    current_balance NUMERIC(18, 2),
    interest_rate NUMERIC(7, 4) CHECK (interest_rate >= 0),

    -- Payment Terms
    paymentduedate INTEGER CHECK (paymentduedate BETWEEN 1 AND 31),
    minimum_payment NUMERIC(18, 2) CHECK (minimum_payment >= 0),

    -- Delinquency & Collections
    delinquency_days INTEGER DEFAULT 0 CHECK (delinquency_days >= 0),
    delinquency_status VARCHAR(50),
    lastpaymentdate DATE,
    lastpaymentamount NUMERIC(18, 2),
    collection_status VARCHAR(50),

    -- Risk Metrics
    utilization_rate NUMERIC(5, 4) CHECK (utilization_rate BETWEEN 0 AND 1),
    writeoffflag BOOLEAN DEFAULT FALSE,
    writeoffdate DATE,

    -- Organization
    branch_code VARCHAR(20),
    officer_id VARCHAR(50),

    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_closing_date CHECK (closing_date IS NULL OR closing_date >= opening_date),
    CONSTRAINT chk_writeoff_date CHECK (writeoffdate IS NULL OR writeoffflag = TRUE),
    CONSTRAINT chk_credit_available CHECK (available_credit IS NULL OR available_credit <= credit_limit)
);

-- Indexes
CREATE INDEX idx_dim_accounts_number ON dim.dim_accounts(account_number);
CREATE INDEX idx_dim_accounts_status ON dim.dim_accounts(account_status);
CREATE INDEX idx_dim_accounts_type ON dim.dim_accounts(account_type);
CREATE INDEX idx_dim_accounts_delinquency ON dim.dim_accounts(delinquency_status, delinquency_days);
CREATE INDEX idx_dim_accounts_opening ON dim.dim_accounts(opening_date);
CREATE INDEX idx_dim_accounts_writeoff ON dim.dim_accounts(writeoffflag) WHERE writeoffflag = TRUE;

-- Comments
COMMENT ON TABLE dim.dim_accounts IS 'Account dimension tracking credit exposure, delinquency status, and account lifecycle';
COMMENT ON COLUMN dim.dim_accounts.utilization_rate IS 'Credit utilization ratio: current_balance / credit_limit';
COMMENT ON COLUMN dim.dim_accounts.delinquency_days IS 'Number of days past due on payment';
COMMENT ON COLUMN dim.dim_accounts.writeoffflag IS 'True if account has been written off as uncollectible';
