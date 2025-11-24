-- =====================================================================
-- FACT_AGENT_DECISIONS - Agent Decision Fact Table
-- =====================================================================
-- Purpose: AI agent decision events with full audit trail
-- Grain: One row per agent decision on a transaction
-- =====================================================================

CREATE TABLE fact.fact_agent_decisions (
    -- Primary Key
    decision_id VARCHAR(50) PRIMARY KEY,

    -- Foreign Key to Transaction
    transaction_id VARCHAR(50) NOT NULL,

    -- Agent Identification
    agent_name VARCHAR(100) NOT NULL,

    -- Decision Output
    decision_output JSONB NOT NULL,
    reasoning_trace TEXT,

    -- Model Information
    model_version VARCHAR(50) NOT NULL,

    -- Performance Metrics
    execution_time_ms INTEGER NOT NULL CHECK (execution_time_ms >= 0),
    tokens_used INTEGER CHECK (tokens_used >= 0),
    token_cost_usd NUMERIC(12, 6) CHECK (token_cost_usd >= 0),

    -- Decision Quality
    confidence_score NUMERIC(5, 4) CHECK (confidence_score BETWEEN 0 AND 1),

    -- Timestamp
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Key Constraint
    CONSTRAINT fk_agent_decisions_transaction FOREIGN KEY (transaction_id)
        REFERENCES fact.fact_transactions(transaction_id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_fact_agent_decisions_transaction ON fact.fact_agent_decisions(transaction_id);
CREATE INDEX idx_fact_agent_decisions_agent ON fact.fact_agent_decisions(agent_name);
CREATE INDEX idx_fact_agent_decisions_created ON fact.fact_agent_decisions(created_at);
CREATE INDEX idx_fact_agent_decisions_model ON fact.fact_agent_decisions(model_version);
CREATE INDEX idx_fact_agent_decisions_confidence ON fact.fact_agent_decisions(confidence_score);

-- GIN index for JSONB decision_output queries
CREATE INDEX idx_fact_agent_decisions_output_gin ON fact.fact_agent_decisions USING GIN (decision_output);

-- Comments
COMMENT ON TABLE fact.fact_agent_decisions IS 'Agent decision fact table with reasoning traces, token costs, and confidence scores for AI decision audit and analysis';
COMMENT ON COLUMN fact.fact_agent_decisions.agent_name IS 'Name/identifier of the AI agent making the decision (e.g., FraudDetectionAgent, ComplianceAgent)';
COMMENT ON COLUMN fact.fact_agent_decisions.decision_output IS 'Structured JSON output from agent decision (approve/decline, risk level, recommended actions)';
COMMENT ON COLUMN fact.fact_agent_decisions.reasoning_trace IS 'Full reasoning chain from agent explaining decision rationale';
COMMENT ON COLUMN fact.fact_agent_decisions.model_version IS 'LLM model version identifier (e.g., gpt-4-turbo, claude-3-opus)';
COMMENT ON COLUMN fact.fact_agent_decisions.tokens_used IS 'Total tokens consumed in LLM call (input + output)';
COMMENT ON COLUMN fact.fact_agent_decisions.token_cost_usd IS 'Cost in USD for LLM API call based on token usage';
COMMENT ON COLUMN fact.fact_agent_decisions.confidence_score IS 'Agent confidence in decision from 0 (uncertain) to 1 (highly confident)';
