-- =====================================================================
-- FRIS 2.0 - Additional Constraints and Data Validation
-- =====================================================================
-- Purpose: Additional check constraints and validation rules
-- Note: Most constraints are already defined in table DDL files
--       This file contains business logic constraints
-- =====================================================================

-- =====================================================================
-- DIM_CUSTOMERS - Customer Data Validation
-- =====================================================================

-- Ensure customer has basic identification
ALTER TABLE dim.dim_customers
ADD CONSTRAINT chk_customer_identification
CHECK (
    (document_type IS NOT NULL AND document_number IS NOT NULL)
    OR customer_number IS NOT NULL
);

-- Validate age group against birth_date
-- Note: This would typically be handled in application logic or triggers
-- Age group should be: '<18', '18-25', '26-35', '36-45', '46-55', '56-65', '66+'

-- Ensure VIP customers have positive lifetime value
ALTER TABLE dim.dim_customers
ADD CONSTRAINT chk_vip_lifetime_value
CHECK (
    vip_flag = FALSE
    OR (vip_flag = TRUE AND lifetime_value > 0)
);

-- =====================================================================
-- DIM_ACCOUNTS - Account Business Rules
-- =====================================================================

-- Closed accounts should have closing date
ALTER TABLE dim.dim_accounts
ADD CONSTRAINT chk_closed_account_date
CHECK (
    account_status != 'CLOSED'
    OR (account_status = 'CLOSED' AND closing_date IS NOT NULL)
);

-- Delinquent accounts should have delinquency status
ALTER TABLE dim.dim_accounts
ADD CONSTRAINT chk_delinquency_consistency
CHECK (
    (delinquency_days = 0 AND delinquency_status IS NULL)
    OR (delinquency_days > 0 AND delinquency_status IS NOT NULL)
);

-- Write-off consistency
ALTER TABLE dim.dim_accounts
ADD CONSTRAINT chk_writeoff_consistency
CHECK (
    writeoffflag = FALSE
    OR (writeoffflag = TRUE AND writeoffdate IS NOT NULL AND closing_date IS NOT NULL)
);

-- Collection status only for delinquent accounts
ALTER TABLE dim.dim_accounts
ADD CONSTRAINT chk_collection_status
CHECK (
    collection_status IS NULL
    OR delinquency_days > 0
);

-- =====================================================================
-- DIM_CARDS - Card Business Rules
-- =====================================================================

-- Blocked cards must have block reason
ALTER TABLE dim.dim_cards
ADD CONSTRAINT chk_blocked_card_reason
CHECK (
    card_status != 'BLOCKED'
    OR (card_status = 'BLOCKED' AND block_reason IS NOT NULL)
);

-- Fraud-flagged cards should be blocked
ALTER TABLE dim.dim_cards
ADD CONSTRAINT chk_fraud_card_blocked
CHECK (
    fraud_flag = FALSE
    OR (fraud_flag = TRUE AND card_status IN ('BLOCKED', 'CANCELLED'))
);

-- Expired cards
ALTER TABLE dim.dim_cards
ADD CONSTRAINT chk_expired_card_status
CHECK (
    expiry_date > CURRENT_DATE
    OR card_status IN ('EXPIRED', 'CANCELLED')
);

-- =====================================================================
-- DIM_MERCHANTS - Merchant Business Rules
-- =====================================================================

-- High-risk merchants should have risk level specified
ALTER TABLE dim.dim_merchants
ADD CONSTRAINT chk_highrisk_merchant_level
CHECK (
    highriskflag = FALSE
    OR (highriskflag = TRUE AND risk_level IS NOT NULL)
);

-- Fraud/chargeback rates validation
ALTER TABLE dim.dim_merchants
ADD CONSTRAINT chk_merchant_rates_consistency
CHECK (
    (fraud_rate IS NULL OR transaction_count IS NULL OR transaction_count = 0)
    OR (fraud_rate <= 1.0 AND chargeback_rate <= 1.0)
);

-- =====================================================================
-- DIM_PRODUCTS - Product Business Rules
-- =====================================================================

-- Discontinued products should have discontinue date
ALTER TABLE dim.dim_products
ADD CONSTRAINT chk_discontinued_product_date
CHECK (
    product_status != 'DISCONTINUED'
    OR (product_status = 'DISCONTINUED' AND discontinue_date IS NOT NULL)
);

-- Products with fees should have positive amounts
ALTER TABLE dim.dim_products
ADD CONSTRAINT chk_product_fees
CHECK (
    annual_fee IS NULL
    OR annual_fee >= 0
);

-- =====================================================================
-- DIM_DEVICES - Device Security Rules
-- =====================================================================

-- Blacklisted devices should be fraud-flagged
ALTER TABLE dim.dim_devices
ADD CONSTRAINT chk_blacklist_fraud_consistency
CHECK (
    blacklist_flag = FALSE
    OR (blacklist_flag = TRUE AND fraud_flag = TRUE)
);

-- Rooted/emulated devices should have low trust score
ALTER TABLE dim.dim_devices
ADD CONSTRAINT chk_compromised_device_trust
CHECK (
    (is_rooted = FALSE AND is_emulator = FALSE)
    OR trust_score <= 0.5
);

-- =====================================================================
-- DIM_REGULATORY_DOCS - Document Validity Rules
-- =====================================================================

-- Active documents should not be expired
ALTER TABLE dim.dim_regulatory_docs
ADD CONSTRAINT chk_active_doc_not_expired
CHECK (
    status != 'ACTIVE'
    OR expiration_date IS NULL
    OR expiration_date > CURRENT_DATE
);

-- Vectorized documents should have chunk count
ALTER TABLE dim.dim_regulatory_docs
ADD CONSTRAINT chk_vectorized_doc_chunks
CHECK (
    vector_collection_id IS NULL
    OR (vector_collection_id IS NOT NULL AND chunk_count > 0 AND last_embedded_at IS NOT NULL)
);

-- =====================================================================
-- FACT_TRANSACTIONS - Transaction Business Rules
-- =====================================================================

-- Currency consistency
ALTER TABLE fact.fact_transactions
ADD CONSTRAINT chk_currency_consistency
CHECK (
    currency_code = 'USD'
    OR (currency_code != 'USD' AND exchange_rate IS NOT NULL AND transactionamountusd IS NOT NULL)
);

-- Declined transactions should have decline reason
ALTER TABLE fact.fact_transactions
ADD CONSTRAINT chk_declined_transaction_reason
CHECK (
    response_code = '00'
    OR (response_code != '00' AND declinereasoncode IS NOT NULL)
);

-- Fraud flagged transactions should have fraud score
ALTER TABLE fact.fact_transactions
ADD CONSTRAINT chk_fraud_transaction_score
CHECK (
    is_fraud = FALSE
    OR (is_fraud = TRUE AND fraud_score IS NOT NULL AND fraud_score > 0.5)
);

-- =====================================================================
-- FACT_AGENT_DECISIONS - Agent Decision Rules
-- =====================================================================

-- Decision output must be valid JSON
-- Note: JSONB type already enforces JSON validity

-- Low confidence decisions should have reasoning trace
ALTER TABLE fact.fact_agent_decisions
ADD CONSTRAINT chk_low_confidence_reasoning
CHECK (
    confidence_score >= 0.7
    OR (confidence_score < 0.7 AND reasoning_trace IS NOT NULL)
);

-- Token usage and cost consistency
ALTER TABLE fact.fact_agent_decisions
ADD CONSTRAINT chk_token_cost_consistency
CHECK (
    (tokens_used IS NULL AND token_cost_usd IS NULL)
    OR (tokens_used > 0 AND token_cost_usd >= 0)
);

-- =====================================================================
-- FACT_AGENT_DECISION_DOCS - Evidence Quality Rules
-- =====================================================================

-- Top-ranked evidence should have high relevance
ALTER TABLE fact.fact_agent_decision_docs
ADD CONSTRAINT chk_top_rank_relevance
CHECK (
    retrieval_rank > 1
    OR (retrieval_rank = 1 AND relevance_score >= 0.5)
);

-- Citation snippet should exist for high-relevance documents
ALTER TABLE fact.fact_agent_decision_docs
ADD CONSTRAINT chk_high_relevance_citation
CHECK (
    relevance_score < 0.8
    OR (relevance_score >= 0.8 AND citation_snippet IS NOT NULL)
);

-- =====================================================================
-- CROSS-TABLE BUSINESS RULES (Informational - enforced at app level)
-- =====================================================================

-- Note: The following rules are typically enforced in application logic
-- but are documented here for reference:

-- 1. Customer must have at least one active account to perform transactions
-- 2. Card must belong to an account owned by the transaction customer
-- 3. Transaction location should match card international_enabled flag
-- 4. Merchant MCC should be valid according to ISO 18245:2023
-- 5. Transaction amount should respect card daily/monthly limits
-- 6. Agent decisions should reference existing transactions
-- 7. Regulatory documents cited should be active at decision time

-- =====================================================================
-- CONSTRAINT MONITORING
-- =====================================================================

-- Query to check constraint violations:
-- SELECT conrelid::regclass AS table_name,
--        conname AS constraint_name,
--        pg_get_constraintdef(oid) AS constraint_definition
-- FROM pg_constraint
-- WHERE contype = 'c'
--   AND connamespace = 'dim'::regnamespace
-- ORDER BY conrelid::regclass::text, conname;

-- =====================================================================
