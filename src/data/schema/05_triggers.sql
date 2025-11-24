-- =====================================================================
-- FRIS 2.0 - Triggers for Automated Data Management
-- =====================================================================
-- Purpose: Triggers for timestamp updates, data validation, and audit
-- =====================================================================

-- =====================================================================
-- TRIGGER FUNCTION: Update Timestamp
-- =====================================================================

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_timestamp() IS 'Automatically updates the updated_at timestamp on row modification';

-- =====================================================================
-- DIMENSION TABLE TRIGGERS: Updated Timestamp
-- =====================================================================

-- DIM_TIME
CREATE TRIGGER trg_dim_time_update_timestamp
    BEFORE UPDATE ON dim.dim_time
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- DIM_LOCATIONS
CREATE TRIGGER trg_dim_locations_update_timestamp
    BEFORE UPDATE ON dim.dim_locations
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- DIM_CUSTOMERS
CREATE TRIGGER trg_dim_customers_update_timestamp
    BEFORE UPDATE ON dim.dim_customers
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- DIM_ACCOUNTS
CREATE TRIGGER trg_dim_accounts_update_timestamp
    BEFORE UPDATE ON dim.dim_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- DIM_CARDS
CREATE TRIGGER trg_dim_cards_update_timestamp
    BEFORE UPDATE ON dim.dim_cards
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- DIM_MERCHANTS
CREATE TRIGGER trg_dim_merchants_update_timestamp
    BEFORE UPDATE ON dim.dim_merchants
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- DIM_PRODUCTS
CREATE TRIGGER trg_dim_products_update_timestamp
    BEFORE UPDATE ON dim.dim_products
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- DIM_DEVICES
CREATE TRIGGER trg_dim_devices_update_timestamp
    BEFORE UPDATE ON dim.dim_devices
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- =====================================================================
-- FACT TABLE TRIGGERS: Updated Timestamp
-- =====================================================================

-- FACT_TRANSACTIONS
CREATE TRIGGER trg_fact_transactions_update_timestamp
    BEFORE UPDATE ON fact.fact_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- =====================================================================
-- TRIGGER FUNCTION: Auto-calculate Utilization Rate
-- =====================================================================

CREATE OR REPLACE FUNCTION calculate_utilization_rate()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.credit_limit IS NOT NULL AND NEW.credit_limit > 0 THEN
        NEW.utilization_rate = LEAST(NEW.current_balance / NEW.credit_limit, 1.0);
    ELSE
        NEW.utilization_rate = NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_utilization_rate() IS 'Automatically calculates credit utilization rate when balance or limit changes';

-- Apply to DIM_ACCOUNTS
CREATE TRIGGER trg_dim_accounts_utilization
    BEFORE INSERT OR UPDATE OF current_balance, credit_limit ON dim.dim_accounts
    FOR EACH ROW
    EXECUTE FUNCTION calculate_utilization_rate();

-- =====================================================================
-- TRIGGER FUNCTION: Auto-update Device Last Seen Date
-- =====================================================================

CREATE OR REPLACE FUNCTION update_device_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    -- When a transaction uses a device, update last seen date in dim_devices
    UPDATE dim.dim_devices
    SET lastseendate = CURRENT_DATE,
        updated_at = CURRENT_TIMESTAMP
    WHERE device_id = NEW.device_id
      AND lastseendate < CURRENT_DATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_device_last_seen() IS 'Updates device last seen date when transaction occurs';

-- Apply to FACT_TRANSACTIONS
CREATE TRIGGER trg_transactions_device_seen
    AFTER INSERT ON fact.fact_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_device_last_seen();

-- =====================================================================
-- TRIGGER FUNCTION: Auto-update Customer Last Activity Date
-- =====================================================================

CREATE OR REPLACE FUNCTION update_customer_last_activity()
RETURNS TRIGGER AS $$
BEGIN
    -- When a transaction occurs, update customer last activity date
    UPDATE dim.dim_customers
    SET lastactivitydate = CURRENT_DATE,
        updated_at = CURRENT_TIMESTAMP
    WHERE customer_id = NEW.customer_id
      AND (lastactivitydate IS NULL OR lastactivitydate < CURRENT_DATE);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_customer_last_activity() IS 'Updates customer last activity date when transaction occurs';

-- Apply to FACT_TRANSACTIONS
CREATE TRIGGER trg_transactions_customer_activity
    AFTER INSERT ON fact.fact_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_last_activity();

-- =====================================================================
-- TRIGGER FUNCTION: Validate Transaction Amount Consistency
-- =====================================================================

CREATE OR REPLACE FUNCTION validate_transaction_amount()
RETURNS TRIGGER AS $$
BEGIN
    -- If currency is not USD, ensure exchange rate and USD amount are present
    IF NEW.currency_code != 'USD' THEN
        IF NEW.exchange_rate IS NULL OR NEW.transactionamountusd IS NULL THEN
            RAISE EXCEPTION 'Non-USD transactions require exchange_rate and transactionamountusd';
        END IF;

        -- Validate USD amount calculation (with 1% tolerance for rounding)
        IF ABS(NEW.transactionamountusd - (NEW.transaction_amount * NEW.exchange_rate)) > (NEW.transaction_amount * 0.01) THEN
            RAISE EXCEPTION 'Inconsistent USD amount calculation: % != % * %',
                NEW.transactionamountusd, NEW.transaction_amount, NEW.exchange_rate;
        END IF;
    ELSE
        -- For USD transactions, USD amount should match transaction amount
        NEW.transactionamountusd = NEW.transaction_amount;
        NEW.exchange_rate = 1.0;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_transaction_amount() IS 'Validates transaction amount consistency with exchange rates';

-- Apply to FACT_TRANSACTIONS
CREATE TRIGGER trg_transactions_validate_amount
    BEFORE INSERT OR UPDATE ON fact.fact_transactions
    FOR EACH ROW
    EXECUTE FUNCTION validate_transaction_amount();

-- =====================================================================
-- TRIGGER FUNCTION: Auto-flag High-Risk Transactions
-- =====================================================================

CREATE OR REPLACE FUNCTION flag_high_risk_transactions()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-calculate risk_score if not provided
    IF NEW.risk_score IS NULL AND NEW.fraud_score IS NOT NULL THEN
        NEW.risk_score = NEW.fraud_score;
    END IF;

    -- Flag suspicious patterns
    IF NEW.fraud_score > 0.8 OR NEW.transaction_amount > 50000 THEN
        -- Could trigger notification to fraud team
        -- For now, just ensure is_fraud consideration
        IF NEW.fraud_score > 0.9 AND NEW.is_fraud IS NULL THEN
            NEW.is_fraud = TRUE;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION flag_high_risk_transactions() IS 'Auto-calculates risk score and flags suspicious transactions';

-- Apply to FACT_TRANSACTIONS
CREATE TRIGGER trg_transactions_risk_flag
    BEFORE INSERT ON fact.fact_transactions
    FOR EACH ROW
    EXECUTE FUNCTION flag_high_risk_transactions();

-- =====================================================================
-- TRIGGER FUNCTION: Prevent Modification of Historical Fact Records
-- =====================================================================

CREATE OR REPLACE FUNCTION prevent_fact_modification()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent updates to transactions older than 90 days (configurable)
    IF OLD.created_at < CURRENT_TIMESTAMP - INTERVAL '90 days' THEN
        RAISE EXCEPTION 'Cannot modify historical fact records older than 90 days';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION prevent_fact_modification() IS 'Prevents modification of historical fact records for data integrity';

-- Apply to FACT_TRANSACTIONS (commented out by default - enable if needed)
-- CREATE TRIGGER trg_transactions_prevent_historical_update
--     BEFORE UPDATE ON fact.fact_transactions
--     FOR EACH ROW
--     EXECUTE FUNCTION prevent_fact_modification();

-- =====================================================================
-- TRIGGER FUNCTION: Audit Trail (Optional - for sensitive tables)
-- =====================================================================

-- Create audit log table first
CREATE TABLE IF NOT EXISTS audit.audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    row_id TEXT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_by TEXT DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_audit_trail()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit.audit_log(table_name, operation, row_id, old_data)
        VALUES (TG_TABLE_NAME, TG_OP, OLD.customer_id::TEXT, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit.audit_log(table_name, operation, row_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.customer_id::TEXT, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit.audit_log(table_name, operation, row_id, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.customer_id::TEXT, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION log_audit_trail() IS 'Logs all changes to sensitive tables for audit compliance';

-- Apply to sensitive dimension tables (commented out - enable as needed)
-- CREATE TRIGGER trg_dim_customers_audit
--     AFTER INSERT OR UPDATE OR DELETE ON dim.dim_customers
--     FOR EACH ROW
--     EXECUTE FUNCTION log_audit_trail();

-- =====================================================================
-- TRIGGER MANAGEMENT QUERIES
-- =====================================================================

-- View all triggers in database:
-- SELECT
--     schemaname,
--     tablename,
--     triggername,
--     proname as function_name
-- FROM pg_trigger t
-- JOIN pg_class c ON t.tgrelid = c.oid
-- JOIN pg_namespace n ON c.relnamespace = n.oid
-- JOIN pg_proc p ON t.tgfoid = p.oid
-- WHERE n.nspname IN ('dim', 'fact')
-- ORDER BY schemaname, tablename, triggername;

-- Disable all triggers on a table:
-- ALTER TABLE dim.dim_customers DISABLE TRIGGER ALL;

-- Enable all triggers on a table:
-- ALTER TABLE dim.dim_customers ENABLE TRIGGER ALL;

-- Drop a specific trigger:
-- DROP TRIGGER IF EXISTS trg_dim_customers_update_timestamp ON dim.dim_customers;

-- =====================================================================
