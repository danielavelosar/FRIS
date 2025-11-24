# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FRIS 2.0 (Financial Risk Intelligence System) is a financial risk analysis platform that combines AI agents, ETL pipelines, and dimensional data modeling to detect fraud, evaluate credit risk, and ensure regulatory compliance.

The system uses a multi-agent architecture with LangGraph orchestration to analyze financial transactions and provide audit trails for AI-driven decisions.

## Architecture

### Core Design Principles

**Star Schema Data Model**: The system is built around a constellation schema with two primary fact tables:
- `fact_transactions`: Financial transaction events at the most granular level
- `fact_agent_decisions`: AI agent decision events with full audit trails
- `fact_agent_decision_docs`: Factless fact table linking agent decisions to regulatory documents (RAG evidence)

Both fact tables share common dimensions (customers, time, locations, etc.), creating a constellation pattern that maintains the benefits of star schema design while supporting multiple analytical perspectives.

**Clean Architecture**: Follow SOLID principles throughout the codebase. The architecture separates concerns into distinct layers:
- `src/data/`: ETL pipelines and data modeling
- `src/agents/`: AI agent implementations
- `src/orchestration/`: LangGraph-based workflow coordination
- `src/infrastructure/`: Docker, Kubernetes, and observability tools

### Data Model Philosophy

**Why Star Schema Over Snowflake**:
- Simpler queries with fewer joins for AI agents to consume
- Standard pattern in risk data marts (aligned with Basel Committee principles)
- Optimized for analytical workloads and aggregations
- Better performance for LLM-based analysis

**Factless Fact Tables vs Bridge Tables**:
`fact_agent_decision_docs` is implemented as a factless fact table rather than a simple bridge table because:
- It represents an auditable event ("a regulatory document was used in an agent decision")
- Contains business metrics (`relevance_score`, `retrieval_rank`, `citation_snippet`)
- Supports analytical queries like "Which regulation is most frequently cited?" or "What documents does the Compliance Agent use most?"

**Dimension Design Pattern**: Some dimensions contain denormalized attributes for performance:
- `dim_accounts` includes key product attributes (product_name, product_family) cached from `dim_products`
- This reduces joins in frequent queries while maintaining `dim_products` as the canonical source
- ETL refreshes these cached attributes using Type 1 SCD (overwrite) or snapshot patterns

### Key Dimensional Components

**Fact Tables**:
1. **fact_transactions**: Transaction-level metrics including fraud scores, risk scores, processing times, and ML model versions
2. **fact_agent_decisions**: Agent decision audit trail with reasoning traces, token costs, execution times, and confidence scores
3. **fact_agent_decision_docs**: RAG evidence linking decisions to specific regulatory document chunks with relevance scoring

**Core Dimensions**:
- `dim_customers`: Customer profiles with KYC/AML risk levels, credit scores, PEP flags, and customer segmentation
- `dim_accounts`: Account lifecycle, credit limits, delinquency status, and product relationship
- `dim_cards`: Card operational details, capabilities, limits, and fraud flags
- `dim_merchants`: Merchant risk profiles with MCC codes (ISO 18245), fraud rates, and chargeback metrics
- `dim_products`: Financial product catalog with risk weights and profitability scores
- `dim_locations`: Geographic hierarchy with risk zones and market density metrics
- `dim_time`: Calendar dimension with fiscal periods, holidays, and business day flags
- `dim_devices`: Device fingerprinting for fraud detection with trust scores
- `dim_regulatory_docs`: Regulatory document metadata for RAG retrieval with vector embeddings

### Industry Standards Alignment

**MCC Codes (ISO 18245:2023)**: Merchant categorization using 4-digit codes ranging 0001-9999:
- 0001-1499: Agricultural services
- 1500-2999: Contracted services
- 4000-4799: Transportation services
- 5000-7299: Retail and clothing
- 7300-7999: Business services
- 8000-8999: Professional services
- 9000-9999: Government services

**Credit Risk Metrics (Freddie Mac Standards)**:
- LTV (Loan-to-Value): Loan amount / Asset value
- DTI (Debt-to-Income): Monthly debt payments / Gross monthly income
- Credit Score: Standard bureau scores with range categorization

**Risk Data Aggregation (Basel Committee BCBS 239)**:
- 14 fundamental principles covering governance, architecture, and data capabilities
- Focus on accuracy, completeness, timeliness, and adaptability
- Crisis response capability with full audit trails

## Development Workflow

### Directory Structure
```
FRIS-2.0/
├── docs/
│   ├── daily-learning/     # Daily learning summaries
│   ├── architecture/       # ER diagrams and technical decisions
│   ├── api/                # API documentation
│   └── business/           # Business rules and KPIs
├── src/
│   ├── data/              # ETL and data modeling
│   ├── agents/            # System agents
│   ├── orchestration/     # LangGraph orchestration
│   └── infrastructure/    # Docker, K8s, observability
├── notebooks/             # Jupyter exploration notebooks
└── tests/                # Unit and integration tests
```

### Data Modeling Guidelines

**When Creating/Modifying Tables**:
1. Maintain grain consistency: one row = one event/entity
2. Include audit fields: `created_at`, `updated_at`, `etlbatchid`
3. Apply appropriate constraints and foreign keys
4. Consider partitioning strategies for fact tables (typically by date)
5. Index all foreign keys and frequently filtered columns

**Security and Compliance**:
- Implement encryption at rest and in transit
- Apply masking and tokenization for PII
- Hash sensitive identifiers (e.g., `cardnumberhash`)
- Comply with GDPR, PCI-DSS, SOX requirements
- Maintain 7-year data retention with archival strategy

**Performance Optimization**:
- Partition `fact_transactions` by date
- Create materialized views for frequent reports
- Apply compression to historical data
- Monitor query patterns and add indexes accordingly

## AI Agent Integration

**RAG (Retrieval-Augmented Generation) Pattern**:
- Regulatory documents stored in `dim_regulatory_docs` with S3 paths
- Vector embeddings maintained in separate collection
- Agent decisions link to specific document chunks via `fact_agent_decision_docs`
- Track relevance scores and retrieval ranks for quality assessment

**Decision Audit Trail Requirements**:
Each agent decision must capture:
- `reasoning_trace`: Full explanation of the decision logic
- `decision_output`: Structured JSON result
- `model_version`: LLM model identifier
- Cost metrics: `tokens_used`, `token_cost_usd`
- Performance: `execution_time_ms`
- Confidence: `confidence_score`

**Agent Design Principles**:
- Agents consume data from the star schema with minimal joins
- Provide structured, analyzable outputs in JSON format
- Include confidence scores for all probabilistic decisions
- Reference regulatory evidence when making compliance decisions
- Log all decisions for reproducibility and audit

## Code Style Guidelines

- Follow SOLID principles in all implementations
- Use clean architecture patterns with clear separation of concerns
- **NEVER use `!important` declarations in CSS/styling**
- Prefer composition over inheritance
- Write self-documenting code with clear naming conventions
- Keep functions focused on single responsibilities
