-- =====================================================================
-- FRIS 2.0 - Additional Performance Indexes
-- =====================================================================
-- Purpose: Additional indexes beyond those already created in table DDL
-- Note: Most indexes are already created in individual table files
--       This file contains composite and specialized indexes
-- =====================================================================

-- =====================================================================
-- DIMENSION TABLE INDEXES (Additional Composite Indexes)
-- =====================================================================

-- DIM_CUSTOMERS: Customer risk analysis composite index
CREATE INDEX idx_dim_customers_risk_composite
    ON dim.dim_customers(customer_status, risk_profile, credit_score)
    WHERE customer_status = 'ACTIVE';

-- DIM_CUSTOMERS: High-risk customer identification
CREATE INDEX idx_dim_customers_high_risk
    ON dim.dim_customers(amlrisklevel, pep_flag, blacklist_flag)
    WHERE amlrisklevel IN ('high', 'critical') OR pep_flag = TRUE OR blacklist_flag = TRUE;

-- DIM_ACCOUNTS: Delinquent accounts analysis
CREATE INDEX idx_dim_accounts_delinquent
    ON dim.dim_accounts(account_status, delinquency_days, current_balance)
    WHERE delinquency_days > 0;

-- DIM_ACCOUNTS: Credit utilization monitoring
CREATE INDEX idx_dim_accounts_utilization
    ON dim.dim_accounts(utilization_rate, credit_limit)
    WHERE utilization_rate > 0.8;

-- DIM_CARDS: Expiring cards monitoring
CREATE INDEX idx_dim_cards_expiring
    ON dim.dim_cards(expiry_date, card_status)
    WHERE card_status = 'ACTIVE' AND expiry_date <= CURRENT_DATE + INTERVAL '90 days';

-- DIM_MERCHANTS: High-risk merchant monitoring
CREATE INDEX idx_dim_merchants_high_risk_composite
    ON dim.dim_merchants(risk_level, fraud_rate, chargeback_rate)
    WHERE highriskflag = TRUE;

-- DIM_PRODUCTS: Active product portfolio
CREATE INDEX idx_dim_products_active_portfolio
    ON dim.dim_products(product_status, product_category, risk_weight)
    WHERE product_status = 'ACTIVE';

-- DIM_DEVICES: Suspicious devices
CREATE INDEX idx_dim_devices_suspicious
    ON dim.dim_devices(fraud_flag, blacklist_flag, is_rooted, is_emulator, trust_score)
    WHERE fraud_flag = TRUE OR blacklist_flag = TRUE OR is_rooted = TRUE OR is_emulator = TRUE;

-- =====================================================================
-- FACT TABLE INDEXES (Additional Composite & Specialized)
-- =====================================================================

-- FACT_TRANSACTIONS: Fraud investigation composite
CREATE INDEX idx_fact_transactions_fraud_investigation
    ON fact.fact_transactions(is_fraud, fraud_score, transaction_datetime, customer_id)
    WHERE is_fraud = TRUE OR fraud_score > 0.7;

-- FACT_TRANSACTIONS: High-value transaction monitoring
CREATE INDEX idx_fact_transactions_high_value
    ON fact.fact_transactions(transaction_amount, transaction_datetime, customer_id, merchant_id)
    WHERE transaction_amount > 10000;

-- FACT_TRANSACTIONS: Declined transactions analysis
CREATE INDEX idx_fact_transactions_declined
    ON fact.fact_transactions(response_code, declinereasoncode, transaction_datetime)
    WHERE response_code != '00';

-- FACT_TRANSACTIONS: Customer transaction history
CREATE INDEX idx_fact_transactions_customer_history
    ON fact.fact_transactions(customer_id, transaction_datetime DESC, transaction_amount);

-- FACT_TRANSACTIONS: Merchant transaction volume
CREATE INDEX idx_fact_transactions_merchant_volume
    ON fact.fact_transactions(merchant_id, transaction_datetime, transaction_amount);

-- FACT_TRANSACTIONS: Card usage patterns
CREATE INDEX idx_fact_transactions_card_usage
    ON fact.fact_transactions(card_id, transaction_datetime, channel_code);

-- FACT_TRANSACTIONS: Geographic transaction analysis
CREATE INDEX idx_fact_transactions_location_analysis
    ON fact.fact_transactions(location_id, transaction_datetime, transaction_amount);

-- FACT_TRANSACTIONS: Device transaction patterns
CREATE INDEX idx_fact_transactions_device_patterns
    ON fact.fact_transactions(device_id, transaction_datetime, is_fraud);

-- FACT_AGENT_DECISIONS: Agent performance analysis
CREATE INDEX idx_fact_agent_decisions_performance
    ON fact.fact_agent_decisions(agent_name, model_version, execution_time_ms, token_cost_usd);

-- FACT_AGENT_DECISIONS: Low confidence decisions
CREATE INDEX idx_fact_agent_decisions_low_confidence
    ON fact.fact_agent_decisions(confidence_score, agent_name, created_at)
    WHERE confidence_score < 0.7;

-- FACT_AGENT_DECISIONS: High-cost decisions monitoring
CREATE INDEX idx_fact_agent_decisions_high_cost
    ON fact.fact_agent_decisions(token_cost_usd, tokens_used, agent_name)
    WHERE token_cost_usd > 0.1;

-- FACT_AGENT_DECISION_DOCS: Document usage frequency
CREATE INDEX idx_fact_decision_docs_usage
    ON fact.fact_agent_decision_docs(doc_id, created_at, relevance_score);

-- FACT_AGENT_DECISION_DOCS: High-relevance evidence
CREATE INDEX idx_fact_decision_docs_high_relevance
    ON fact.fact_agent_decision_docs(relevance_score DESC, retrieval_rank, doc_id)
    WHERE relevance_score > 0.8;

-- =====================================================================
-- FULL-TEXT SEARCH INDEXES (Optional - for text search capabilities)
-- =====================================================================

-- Enable pg_trgm extension for similarity search
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Full-text search on customer names
-- CREATE INDEX idx_dim_customers_name_trgm
--     ON dim.dim_customers USING GIN (full_name gin_trgm_ops);

-- Full-text search on merchant names
-- CREATE INDEX idx_dim_merchants_name_trgm
--     ON dim.dim_merchants USING GIN (merchant_name gin_trgm_ops);

-- Full-text search on regulatory document titles
-- CREATE INDEX idx_dim_regulatory_docs_title_trgm
--     ON dim.dim_regulatory_docs USING GIN (doc_title gin_trgm_ops);

-- Full-text search on agent reasoning traces
-- CREATE INDEX idx_fact_agent_decisions_reasoning_fts
--     ON fact.fact_agent_decisions USING GIN (to_tsvector('english', reasoning_trace));

-- =====================================================================
-- MATERIALIZED VIEW INDEXES (For Common Aggregations)
-- =====================================================================

-- Note: Create materialized views first, then add indexes
-- Example materialized view for daily fraud statistics:
-- CREATE MATERIALIZED VIEW mv_daily_fraud_stats AS
-- SELECT
--     DATE(transaction_datetime) as transaction_date,
--     COUNT(*) as total_transactions,
--     SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) as fraud_count,
--     AVG(fraud_score) as avg_fraud_score,
--     SUM(transaction_amount) as total_amount
-- FROM fact.fact_transactions
-- GROUP BY DATE(transaction_datetime);
--
-- CREATE UNIQUE INDEX idx_mv_daily_fraud_stats_date
--     ON mv_daily_fraud_stats(transaction_date);

-- =====================================================================
-- INDEX MAINTENANCE NOTES
-- =====================================================================
-- 1. Monitor index bloat: SELECT * FROM pgstattuple('index_name');
-- 2. Rebuild bloated indexes: REINDEX INDEX CONCURRENTLY index_name;
-- 3. Update statistics: ANALYZE table_name;
-- 4. Review unused indexes: pg_stat_user_indexes
-- 5. Consider partial indexes for filtered queries
-- 6. Use EXPLAIN ANALYZE to verify index usage
-- =====================================================================
