-- =====================================================================
-- FRIS 2.0 - Master DDL Script
-- =====================================================================
-- Purpose: Execute all DDL scripts in correct dependency order
-- Usage: psql -U postgres -d fris_warehouse -f master_ddl.sql
-- =====================================================================

\echo '==============================================================='
\echo 'FRIS 2.0 - Financial Risk Intelligence System'
\echo 'PostgreSQL Schema Creation - Master Script'
\echo '==============================================================='
\echo ''

-- =====================================================================
-- Configuration
-- =====================================================================

-- Stop on first error
\set ON_ERROR_STOP on

-- Show execution time
\timing on

-- Set client encoding
SET client_encoding = 'UTF8';

-- =====================================================================
-- STEP 0: Create Audit Schema
-- =====================================================================

\echo 'Step 0: Creating audit schema...'
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS 'Audit and logging tables for FRIS data warehouse';

-- =====================================================================
-- STEP 1: Initialize Schemas
-- =====================================================================

\echo 'Step 1: Initializing schemas (dim, fact)...'
\i 00_init_schemas.sql
\echo 'Schemas created successfully.'
\echo ''

-- =====================================================================
-- STEP 2: Create Dimension Tables
-- =====================================================================

\echo 'Step 2: Creating dimension tables...'
\echo '  2.1 - Creating dim_time...'
\i 01_dimensions/01_dim_time.sql

\echo '  2.2 - Creating dim_locations...'
\i 01_dimensions/02_dim_locations.sql

\echo '  2.3 - Creating dim_customers...'
\i 01_dimensions/03_dim_customers.sql

\echo '  2.4 - Creating dim_accounts...'
\i 01_dimensions/04_dim_accounts.sql

\echo '  2.5 - Creating dim_cards...'
\i 01_dimensions/05_dim_cards.sql

\echo '  2.6 - Creating dim_merchants...'
\i 01_dimensions/06_dim_merchants.sql

\echo '  2.7 - Creating dim_products...'
\i 01_dimensions/07_dim_products.sql

\echo '  2.8 - Creating dim_devices...'
\i 01_dimensions/08_dim_devices.sql

\echo '  2.9 - Creating dim_regulatory_docs...'
\i 01_dimensions/09_dim_regulatory_docs.sql

\echo 'All dimension tables created successfully.'
\echo ''

-- =====================================================================
-- STEP 3: Create Fact Tables
-- =====================================================================

\echo 'Step 3: Creating fact tables...'
\echo '  3.1 - Creating fact_transactions (partitioned)...'
\i 02_facts/01_fact_transactions.sql

\echo '  3.2 - Creating fact_agent_decisions...'
\i 02_facts/02_fact_agent_decisions.sql

\echo '  3.3 - Creating fact_agent_decision_docs...'
\i 02_facts/03_fact_agent_decision_docs.sql

\echo 'All fact tables created successfully.'
\echo ''

-- =====================================================================
-- STEP 4: Create Additional Indexes
-- =====================================================================

\echo 'Step 4: Creating additional performance indexes...'
\i 03_indexes.sql
\echo 'Additional indexes created successfully.'
\echo ''

-- =====================================================================
-- STEP 5: Add Business Constraints
-- =====================================================================

\echo 'Step 5: Adding business logic constraints...'
\i 04_constraints.sql
\echo 'Business constraints added successfully.'
\echo ''

-- =====================================================================
-- STEP 6: Create Triggers
-- =====================================================================

\echo 'Step 6: Creating triggers for automated data management...'
\i 05_triggers.sql
\echo 'Triggers created successfully.'
\echo ''

-- =====================================================================
-- STEP 7: Grant Permissions (Optional - configure as needed)
-- =====================================================================

\echo 'Step 7: Configuring permissions...'

-- Create roles (if they don't exist)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'fris_readonly') THEN
        CREATE ROLE fris_readonly;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'fris_readwrite') THEN
        CREATE ROLE fris_readwrite;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'fris_etl') THEN
        CREATE ROLE fris_etl;
    END IF;
END
$$;

-- Grant schema usage
GRANT USAGE ON SCHEMA dim TO fris_readonly, fris_readwrite, fris_etl;
GRANT USAGE ON SCHEMA fact TO fris_readonly, fris_readwrite, fris_etl;
GRANT USAGE ON SCHEMA audit TO fris_readonly, fris_readwrite, fris_etl;

-- Grant SELECT on all dimension tables to readonly
GRANT SELECT ON ALL TABLES IN SCHEMA dim TO fris_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA fact TO fris_readonly;

-- Grant SELECT, INSERT, UPDATE on dimension tables to readwrite
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA dim TO fris_readwrite;
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA fact TO fris_readwrite;

-- Grant full access to ETL role
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA dim TO fris_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA fact TO fris_etl;

-- Grant sequence usage for auto-increment fields
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA dim TO fris_readwrite, fris_etl;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA fact TO fris_readwrite, fris_etl;

\echo 'Permissions configured successfully.'
\echo ''

-- =====================================================================
-- STEP 8: Create Initial Partitions for fact_transactions
-- =====================================================================

\echo 'Step 8: Creating initial partitions for fact_transactions...'

-- Create partitions for current year and next 12 months
DO $$
DECLARE
    start_date DATE;
    end_date DATE;
    partition_name TEXT;
    counter INTEGER := 0;
BEGIN
    -- Start from current month
    start_date := DATE_TRUNC('month', CURRENT_DATE);

    -- Create 12 monthly partitions
    FOR counter IN 0..11 LOOP
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'fact_transactions_' || TO_CHAR(start_date, 'YYYY_MM');

        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS fact.%I PARTITION OF fact.fact_transactions
             FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            start_date,
            end_date
        );

        RAISE NOTICE 'Created partition: % for range [%, %)', partition_name, start_date, end_date;

        start_date := end_date;
    END LOOP;
END
$$;

\echo 'Initial partitions created successfully.'
\echo ''

-- =====================================================================
-- STEP 9: Analyze Tables for Query Optimization
-- =====================================================================

\echo 'Step 9: Analyzing tables for query optimization...'

ANALYZE dim.dim_time;
ANALYZE dim.dim_locations;
ANALYZE dim.dim_customers;
ANALYZE dim.dim_accounts;
ANALYZE dim.dim_cards;
ANALYZE dim.dim_merchants;
ANALYZE dim.dim_products;
ANALYZE dim.dim_devices;
ANALYZE dim.dim_regulatory_docs;
ANALYZE fact.fact_transactions;
ANALYZE fact.fact_agent_decisions;
ANALYZE fact.fact_agent_decision_docs;

\echo 'Table statistics updated successfully.'
\echo ''

-- =====================================================================
-- STEP 10: Schema Validation and Summary
-- =====================================================================

\echo 'Step 10: Validating schema creation...'
\echo ''

-- Count tables created
\echo 'Tables Created:'
SELECT
    schemaname AS schema,
    COUNT(*) AS table_count
FROM pg_tables
WHERE schemaname IN ('dim', 'fact', 'audit')
GROUP BY schemaname
ORDER BY schemaname;

\echo ''
\echo 'Dimension Tables:'
SELECT tablename FROM pg_tables WHERE schemaname = 'dim' ORDER BY tablename;

\echo ''
\echo 'Fact Tables:'
SELECT tablename FROM pg_tables WHERE schemaname = 'fact' ORDER BY tablename;

\echo ''
\echo 'Indexes Created:'
SELECT
    schemaname AS schema,
    COUNT(*) AS index_count
FROM pg_indexes
WHERE schemaname IN ('dim', 'fact')
GROUP BY schemaname
ORDER BY schemaname;

\echo ''
\echo 'Constraints Summary:'
SELECT
    n.nspname AS schema,
    COUNT(*) AS constraint_count
FROM pg_constraint c
JOIN pg_namespace n ON c.connamespace = n.oid
WHERE n.nspname IN ('dim', 'fact')
GROUP BY n.nspname
ORDER BY n.nspname;

\echo ''
\echo 'Triggers Summary:'
SELECT
    schemaname AS schema,
    COUNT(DISTINCT triggername) AS trigger_count
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname IN ('dim', 'fact')
  AND NOT tgisinternal
GROUP BY schemaname
ORDER BY schemaname;

-- =====================================================================
-- Completion Message
-- =====================================================================

\echo ''
\echo '==============================================================='
\echo 'FRIS 2.0 Schema Creation Completed Successfully!'
\echo '==============================================================='
\echo ''
\echo 'Schema Summary:'
\echo '  - 2 schemas created: dim, fact'
\echo '  - 9 dimension tables created'
\echo '  - 3 fact tables created (1 partitioned)'
\echo '  - Indexes, constraints, and triggers configured'
\echo '  - Initial partitions created for fact_transactions'
\echo '  - Permissions configured for roles'
\echo ''
\echo 'Next Steps:'
\echo '  1. Review table structures: \d+ dim.dim_customers'
\echo '  2. Load dimension data via ETL pipelines'
\echo '  3. Create additional partitions as needed'
\echo '  4. Configure backup and archival strategies'
\echo '  5. Set up monitoring and alerting'
\echo ''
\echo 'Documentation: See docs/architecture/ for data model details'
\echo '==============================================================='
