-- =====================================================================
-- FRIS 2.0 - Financial Risk Intelligence System
-- Schema Initialization Script
-- =====================================================================
-- Purpose: Create organizational schemas for dimensional data warehouse
-- Schemas:
--   - dim: Dimension tables (customers, products, time, etc.)
--   - fact: Fact tables (transactions, agent decisions)
-- =====================================================================

-- Create dimension schema
CREATE SCHEMA IF NOT EXISTS dim;

COMMENT ON SCHEMA dim IS 'Dimension tables for FRIS data warehouse - contains descriptive attributes for analysis';

-- Create fact schema
CREATE SCHEMA IF NOT EXISTS fact;

COMMENT ON SCHEMA fact IS 'Fact tables for FRIS data warehouse - contains transactional events and metrics';

-- Verify schemas were created
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('dim', 'fact')
ORDER BY schema_name;
