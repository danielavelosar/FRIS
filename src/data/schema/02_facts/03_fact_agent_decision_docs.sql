-- =====================================================================
-- FACT_AGENT_DECISION_DOCS - Agent Decision Documentation Fact Table
-- =====================================================================
-- Purpose: Links agent decisions to regulatory documents used as evidence (RAG)
-- Grain: One row per document chunk used in an agent decision
-- Type: Factless fact table (tracks relationships with metrics)
-- =====================================================================

CREATE TABLE fact.fact_agent_decision_docs (
    -- Primary Key
    evidence_id VARCHAR(50) PRIMARY KEY,

    -- Foreign Keys
    decision_id VARCHAR(50) NOT NULL,
    doc_id VARCHAR(50) NOT NULL,

    -- Document Chunk Reference
    chunk_id VARCHAR(100) NOT NULL,

    -- Relevance Metrics
    relevance_score NUMERIC(7, 6) NOT NULL CHECK (relevance_score BETWEEN 0 AND 1),
    retrieval_rank INTEGER NOT NULL CHECK (retrieval_rank > 0),

    -- Citation Content
    citation_snippet TEXT,

    -- Timestamp
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Key Constraints
    CONSTRAINT fk_decision_docs_decision FOREIGN KEY (decision_id)
        REFERENCES fact.fact_agent_decisions(decision_id) ON DELETE CASCADE,
    CONSTRAINT fk_decision_docs_document FOREIGN KEY (doc_id)
        REFERENCES dim.dim_regulatory_docs(doc_id) ON DELETE RESTRICT
);

-- Indexes
CREATE INDEX idx_fact_decision_docs_decision ON fact.fact_agent_decision_docs(decision_id);
CREATE INDEX idx_fact_decision_docs_document ON fact.fact_agent_decision_docs(doc_id);
CREATE INDEX idx_fact_decision_docs_relevance ON fact.fact_agent_decision_docs(relevance_score DESC);
CREATE INDEX idx_fact_decision_docs_rank ON fact.fact_agent_decision_docs(retrieval_rank);
CREATE INDEX idx_fact_decision_docs_composite ON fact.fact_agent_decision_docs(decision_id, doc_id, relevance_score);

-- Comments
COMMENT ON TABLE fact.fact_agent_decision_docs IS 'Factless fact table linking agent decisions to regulatory document chunks with RAG relevance metrics for compliance audit trails';
COMMENT ON COLUMN fact.fact_agent_decision_docs.chunk_id IS 'Identifier of specific document chunk/segment retrieved from vector database';
COMMENT ON COLUMN fact.fact_agent_decision_docs.relevance_score IS 'Vector similarity score indicating relevance of document chunk to query (0-1)';
COMMENT ON COLUMN fact.fact_agent_decision_docs.retrieval_rank IS 'Rank of this document in RAG retrieval results (1 = most relevant)';
COMMENT ON COLUMN fact.fact_agent_decision_docs.citation_snippet IS 'Excerpt from document used as evidence in agent reasoning';
