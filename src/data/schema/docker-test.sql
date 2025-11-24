-- =====================================================================
-- FRIS 2.0 - Schema Validation Test Script
-- =====================================================================
-- Purpose: Validate that all database objects were created successfully
-- Usage: psql -U fris_user -d fris_warehouse -f docker-test.sql
-- =====================================================================

\echo '==============================================================='
\echo 'FRIS 2.0 - Schema Validation Tests'
\echo '==============================================================='
\echo ''

-- Set output format
\pset border 2
\pset format wrapped

-- =====================================================================
-- Test 1: Verify Schemas Exist
-- =====================================================================
\echo 'Test 1: Checking schemas...'
SELECT
    schema_name,
    CASE
        WHEN schema_name IN ('dim', 'fact', 'audit') THEN '✓ OK'
        ELSE '✗ UNEXPECTED'
    END as status
FROM information_schema.schemata
WHERE schema_name IN ('dim', 'fact', 'audit')
ORDER BY schema_name;

\echo ''

-- =====================================================================
-- Test 2: Count Tables by Schema
-- =====================================================================
\echo 'Test 2: Counting tables...'
SELECT
    schemaname as schema,
    COUNT(*) as table_count,
    CASE
        WHEN schemaname = 'dim' AND COUNT(*) = 9 THEN '✓ Expected: 9'
        WHEN schemaname = 'fact' AND COUNT(*) >= 3 THEN '✓ Expected: 3+'
        ELSE '⚠ Check count'
    END as status
FROM pg_tables
WHERE schemaname IN ('dim', 'fact', 'audit')
GROUP BY schemaname
ORDER BY schemaname;

\echo ''

-- =====================================================================
-- Test 3: List All Dimension Tables
-- =====================================================================
\echo 'Test 3: Dimension tables...'
SELECT
    tablename,
    '✓' as status
FROM pg_tables
WHERE schemaname = 'dim'
ORDER BY tablename;

\echo ''

-- =====================================================================
-- Test 4: List All Fact Tables
-- =====================================================================
\echo 'Test 4: Fact tables...'
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size('fact.'||tablename)) as size,
    '✓' as status
FROM pg_tables
WHERE schemaname = 'fact'
ORDER BY tablename;

\echo ''

-- =====================================================================
-- Test 5: Verify Partitions for fact_transactions
-- =====================================================================
\echo 'Test 5: fact_transactions partitions...'
SELECT
    schemaname,
    tablename as partition_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE tablename LIKE 'fact_transactions%'
ORDER BY tablename;

\echo ''

-- =====================================================================
-- Test 6: Count Indexes
-- =====================================================================
\echo 'Test 6: Counting indexes...'
SELECT
    schemaname as schema,
    COUNT(*) as index_count
FROM pg_indexes
WHERE schemaname IN ('dim', 'fact')
GROUP BY schemaname
ORDER BY schemaname;

\echo ''

-- =====================================================================
-- Test 7: Count Constraints
-- =====================================================================
\echo 'Test 7: Counting constraints...'
SELECT
    n.nspname as schema,
    contype as constraint_type,
    COUNT(*) as count,
    CASE contype
        WHEN 'p' THEN 'Primary Key'
        WHEN 'f' THEN 'Foreign Key'
        WHEN 'c' THEN 'Check'
        WHEN 'u' THEN 'Unique'
        ELSE 'Other'
    END as description
FROM pg_constraint c
JOIN pg_namespace n ON c.connamespace = n.oid
WHERE n.nspname IN ('dim', 'fact')
GROUP BY n.nspname, contype
ORDER BY n.nspname, contype;

\echo ''

-- =====================================================================
-- Test 8: Count Triggers
-- =====================================================================
\echo 'Test 8: Counting triggers...'
SELECT
    schemaname as schema,
    COUNT(DISTINCT triggername) as trigger_count
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname IN ('dim', 'fact')
  AND NOT tgisinternal  -- Exclude internal triggers
GROUP BY schemaname
ORDER BY schemaname;

\echo ''

-- =====================================================================
-- Test 9: Verify Foreign Key Relationships
-- =====================================================================
\echo 'Test 9: Foreign key relationships...'
SELECT
    tc.table_schema as schema,
    tc.table_name as from_table,
    kcu.column_name as from_column,
    ccu.table_name as to_table,
    ccu.column_name as to_column,
    '✓' as status
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema IN ('dim', 'fact')
ORDER BY tc.table_schema, tc.table_name, kcu.column_name;

\echo ''

-- =====================================================================
-- Test 10: Check Table Row Counts (Should be 0 initially)
-- =====================================================================
\echo 'Test 10: Row counts (should be 0 for empty database)...'
SELECT
    schemaname || '.' || tablename as table_name,
    n_live_tup as row_count,
    CASE
        WHEN n_live_tup = 0 THEN '✓ Empty'
        ELSE '⚠ Has data'
    END as status
FROM pg_stat_user_tables
WHERE schemaname IN ('dim', 'fact')
ORDER BY schemaname, tablename;

\echo ''

-- =====================================================================
-- Test 11: Verify Key Columns Exist
-- =====================================================================
\echo 'Test 11: Verifying critical columns...'

-- Check dim_customers has essential fields
SELECT
    'dim_customers' as table_name,
    COUNT(*) FILTER (WHERE column_name IN ('customer_id', 'customer_number', 'risk_profile', 'credit_score')) as critical_columns,
    CASE
        WHEN COUNT(*) FILTER (WHERE column_name IN ('customer_id', 'customer_number', 'risk_profile', 'credit_score')) = 4
        THEN '✓ All critical columns present'
        ELSE '✗ Missing columns'
    END as status
FROM information_schema.columns
WHERE table_schema = 'dim' AND table_name = 'dim_customers';

-- Check fact_transactions has essential fields
SELECT
    'fact_transactions' as table_name,
    COUNT(*) FILTER (WHERE column_name IN ('transaction_id', 'transaction_amount', 'fraud_score', 'customer_id')) as critical_columns,
    CASE
        WHEN COUNT(*) FILTER (WHERE column_name IN ('transaction_id', 'transaction_amount', 'fraud_score', 'customer_id')) = 4
        THEN '✓ All critical columns present'
        ELSE '✗ Missing columns'
    END as status
FROM information_schema.columns
WHERE table_schema = 'fact' AND table_name = 'fact_transactions';

-- Check fact_agent_decisions has essential fields
SELECT
    'fact_agent_decisions' as table_name,
    COUNT(*) FILTER (WHERE column_name IN ('decision_id', 'transaction_id', 'agent_name', 'decision_output')) as critical_columns,
    CASE
        WHEN COUNT(*) FILTER (WHERE column_name IN ('decision_id', 'transaction_id', 'agent_name', 'decision_output')) = 4
        THEN '✓ All critical columns present'
        ELSE '✗ Missing columns'
    END as status
FROM information_schema.columns
WHERE table_schema = 'fact' AND table_name = 'fact_agent_decisions';

\echo ''

-- =====================================================================
-- Test 12: Verify JSONB Column Type
-- =====================================================================
\echo 'Test 12: Verifying JSONB columns...'
SELECT
    table_schema || '.' || table_name as table_name,
    column_name,
    data_type,
    CASE
        WHEN data_type = 'jsonb' THEN '✓ Correct type'
        ELSE '✗ Wrong type'
    END as status
FROM information_schema.columns
WHERE table_schema = 'fact'
  AND column_name = 'decision_output'
ORDER BY table_name;

\echo ''

-- =====================================================================
-- Test 13: Check Functions/Triggers Exist
-- =====================================================================
\echo 'Test 13: Checking trigger functions...'
SELECT
    routine_schema as schema,
    routine_name as function_name,
    '✓' as status
FROM information_schema.routines
WHERE routine_schema IN ('public')
  AND routine_type = 'FUNCTION'
  AND routine_name LIKE '%timestamp%'
     OR routine_name LIKE '%utilization%'
     OR routine_name LIKE '%device%'
     OR routine_name LIKE '%customer%'
ORDER BY routine_name;

\echo ''

-- =====================================================================
-- Summary
-- =====================================================================
\echo '==============================================================='
\echo 'Validation Summary'
\echo '==============================================================='

SELECT
    'Schemas' as object_type,
    (SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('dim', 'fact', 'audit')) as count
UNION ALL
SELECT
    'Dimension Tables',
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'dim')
UNION ALL
SELECT
    'Fact Tables',
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'fact')
UNION ALL
SELECT
    'Total Indexes',
    (SELECT COUNT(*) FROM pg_indexes WHERE schemaname IN ('dim', 'fact'))
UNION ALL
SELECT
    'Foreign Keys',
    (SELECT COUNT(*) FROM information_schema.table_constraints
     WHERE constraint_type = 'FOREIGN KEY' AND table_schema IN ('dim', 'fact'))
UNION ALL
SELECT
    'Triggers',
    (SELECT COUNT(DISTINCT triggername) FROM pg_trigger t
     JOIN pg_class c ON t.tgrelid = c.oid
     JOIN pg_namespace n ON c.relnamespace = n.oid
     WHERE n.nspname IN ('dim', 'fact') AND NOT tgisinternal);

\echo ''
\echo '==============================================================='
\echo 'Validation Complete!'
\echo ''
\echo 'Expected results:'
\echo '  - 3 schemas (dim, fact, audit)'
\echo '  - 9 dimension tables'
\echo '  - 3+ fact tables (including partitions)'
\echo '  - Multiple indexes per table'
\echo '  - Foreign keys linking facts to dimensions'
\echo '  - Triggers for timestamp updates'
\echo '==============================================================='
