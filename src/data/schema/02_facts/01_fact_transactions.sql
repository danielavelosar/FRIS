-- =====================================================================
-- FACT_TRANSACTIONS - Transaction Fact Table
-- =====================================================================
-- Purpose: Financial transaction events at the most granular level
-- Grain: One row per transaction
-- Partitioning: By month using transaction_datetime
-- =====================================================================

CREATE TABLE fact.fact_transactions (
    -- Primary Key
    transaction_id VARCHAR(50) PRIMARY KEY,

    -- Transaction Timestamp
    transaction_datetime TIMESTAMP NOT NULL,

    -- Transaction Amounts
    transaction_amount NUMERIC(18, 4) NOT NULL CHECK (transaction_amount > 0),
    transactionamountusd NUMERIC(18, 4) CHECK (transactionamountusd > 0),
    currency_code VARCHAR(3) NOT NULL,
    exchange_rate NUMERIC(12, 6) CHECK (exchange_rate > 0),

    -- Transaction Classification
    transaction_type VARCHAR(50) NOT NULL,
    channel_code VARCHAR(50) NOT NULL,
    network_code VARCHAR(20),

    -- Fraud & Risk Scores
    is_fraud BOOLEAN DEFAULT FALSE,
    fraud_score NUMERIC(7, 6) CHECK (fraud_score BETWEEN 0 AND 1),
    risk_score NUMERIC(7, 6) CHECK (risk_score BETWEEN 0 AND 1),
    mlmodelversion VARCHAR(50),

    -- Authorization & Response
    authorization_code VARCHAR(50),
    response_code VARCHAR(10) NOT NULL,
    declinereasoncode VARCHAR(50),

    -- Performance Metrics
    processingtimems INTEGER CHECK (processingtimems >= 0),

    -- Network & Parties
    acquirer_id VARCHAR(50),
    issuer_id VARCHAR(50),

    -- Session Information
    ip_address VARCHAR(45),
    session_id VARCHAR(100),

    -- Foreign Keys to Dimensions
    customer_id VARCHAR(50) NOT NULL,
    account_id VARCHAR(50) NOT NULL,
    card_id VARCHAR(50) NOT NULL,
    merchant_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    location_id INTEGER NOT NULL,
    time_id INTEGER NOT NULL,
    device_id VARCHAR(50) NOT NULL,

    -- ETL Audit
    etlbatchid VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Key Constraints
    CONSTRAINT fk_transactions_customer FOREIGN KEY (customer_id) REFERENCES dim.dim_customers(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_account FOREIGN KEY (account_id) REFERENCES dim.dim_accounts(account_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_card FOREIGN KEY (card_id) REFERENCES dim.dim_cards(card_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_merchant FOREIGN KEY (merchant_id) REFERENCES dim.dim_merchants(merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_product FOREIGN KEY (product_id) REFERENCES dim.dim_products(product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_location FOREIGN KEY (location_id) REFERENCES dim.dim_locations(location_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_time FOREIGN KEY (time_id) REFERENCES dim.dim_time(time_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_device FOREIGN KEY (device_id) REFERENCES dim.dim_devices(device_id) ON DELETE RESTRICT
) PARTITION BY RANGE (DATE_TRUNC('month', transaction_datetime));

-- Indexes on Fact Table
CREATE INDEX idx_fact_transactions_datetime ON fact.fact_transactions(transaction_datetime);
CREATE INDEX idx_fact_transactions_customer ON fact.fact_transactions(customer_id);
CREATE INDEX idx_fact_transactions_merchant ON fact.fact_transactions(merchant_id);
CREATE INDEX idx_fact_transactions_card ON fact.fact_transactions(card_id);
CREATE INDEX idx_fact_transactions_fraud ON fact.fact_transactions(is_fraud) WHERE is_fraud = TRUE;
CREATE INDEX idx_fact_transactions_channel ON fact.fact_transactions(channel_code);
CREATE INDEX idx_fact_transactions_response ON fact.fact_transactions(response_code);
CREATE INDEX idx_fact_transactions_amount ON fact.fact_transactions(transaction_amount);
CREATE INDEX idx_fact_transactions_composite ON fact.fact_transactions(transaction_datetime, customer_id, is_fraud);

-- Comments
COMMENT ON TABLE fact.fact_transactions IS 'Transaction fact table with fraud scores, risk metrics, and dimensional relationships for financial risk analysis';
COMMENT ON COLUMN fact.fact_transactions.transaction_datetime IS 'Transaction timestamp (UTC)';
COMMENT ON COLUMN fact.fact_transactions.is_fraud IS 'True if transaction confirmed as fraudulent';
COMMENT ON COLUMN fact.fact_transactions.fraud_score IS 'ML model fraud probability score (0-1)';
COMMENT ON COLUMN fact.fact_transactions.risk_score IS 'Overall risk score for transaction (0-1)';
COMMENT ON COLUMN fact.fact_transactions.mlmodelversion IS 'Version identifier of ML model used for scoring';
COMMENT ON COLUMN fact.fact_transactions.processingtimems IS 'Transaction processing time in milliseconds';

-- Create partitions for current and future months
-- Example: Create partitions dynamically based on data load dates
-- Partition creation script should be run monthly or automated via pg_cron

-- CREATE TABLE fact.fact_transactions_2024_01 PARTITION OF fact.fact_transactions
--     FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
-- CREATE TABLE fact.fact_transactions_2024_02 PARTITION OF fact.fact_transactions
--     FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
-- ... and so on
