-- =====================================================================
-- DIM_REGULATORY_DOCS - Regulatory Documents Dimension Table
-- =====================================================================
-- Purpose: Regulatory documents and policies for RAG (Retrieval-Augmented Generation)
-- Grain: One row per regulatory document
-- =====================================================================

CREATE TABLE dim.dim_regulatory_docs (
    -- Primary Key
    doc_id VARCHAR(50) PRIMARY KEY,

    -- Document Identification
    doc_title VARCHAR(500) NOT NULL,
    doc_type VARCHAR(100) NOT NULL,
    issuing_body VARCHAR(200) NOT NULL,

    -- Document Validity
    effective_date DATE NOT NULL,
    expiration_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Storage & Vector Embeddings
    s3_path VARCHAR(500),
    vector_collection_id VARCHAR(100),
    chunk_count INTEGER DEFAULT 0 CHECK (chunk_count >= 0),
    last_embedded_at TIMESTAMP,

    -- Content Summary
    summary TEXT,

    -- Constraints
    CONSTRAINT chk_expiration CHECK (expiration_date IS NULL OR expiration_date >= effective_date),
    CONSTRAINT chk_vector_embedding CHECK (
        (vector_collection_id IS NULL AND chunk_count = 0) OR
        (vector_collection_id IS NOT NULL AND chunk_count > 0)
    )
);

-- Indexes
CREATE INDEX idx_dim_regulatory_docs_title ON dim.dim_regulatory_docs(doc_title);
CREATE INDEX idx_dim_regulatory_docs_type ON dim.dim_regulatory_docs(doc_type);
CREATE INDEX idx_dim_regulatory_docs_status ON dim.dim_regulatory_docs(status);
CREATE INDEX idx_dim_regulatory_docs_issuer ON dim.dim_regulatory_docs(issuing_body);
CREATE INDEX idx_dim_regulatory_docs_effective ON dim.dim_regulatory_docs(effective_date);
CREATE INDEX idx_dim_regulatory_docs_vector ON dim.dim_regulatory_docs(vector_collection_id) WHERE vector_collection_id IS NOT NULL;
CREATE INDEX idx_dim_regulatory_docs_embedded ON dim.dim_regulatory_docs(last_embedded_at);

-- Comments
COMMENT ON TABLE dim.dim_regulatory_docs IS 'Regulatory documents dimension for RAG-based compliance decisions, linking to vector embeddings for AI agent retrieval';
COMMENT ON COLUMN dim.dim_regulatory_docs.doc_type IS 'Document type: regulation, policy, circular, guideline, standard, law';
COMMENT ON COLUMN dim.dim_regulatory_docs.status IS 'Document status: active, expired, draft, superseded';
COMMENT ON COLUMN dim.dim_regulatory_docs.vector_collection_id IS 'Reference to vector database collection ID for RAG retrieval';
COMMENT ON COLUMN dim.dim_regulatory_docs.chunk_count IS 'Number of text chunks embedded in vector database';
COMMENT ON COLUMN dim.dim_regulatory_docs.s3_path IS 'S3 path to original document file (PDF, DOCX, etc.)';
