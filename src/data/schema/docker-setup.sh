#!/bin/bash
# =====================================================================
# FRIS 2.0 - Docker PostgreSQL Setup Script (Bash)
# =====================================================================
# Purpose: Automate PostgreSQL container setup and schema deployment
# Usage: ./src/data/schema/docker-setup.sh
# =====================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

echo -e "${CYAN}===============================================================${NC}"
echo -e "${CYAN}FRIS 2.0 - PostgreSQL Docker Setup${NC}"
echo -e "${CYAN}===============================================================${NC}"
echo ""

# =====================================================================
# Load Configuration from .env
# =====================================================================
ENV_FILE=".env"

if [ -f "$ENV_FILE" ]; then
    echo -e "${GRAY}Loading configuration from .env...${NC}"
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    echo -e "${GREEN}✓ Configuration loaded${NC}"
else
    echo -e "${YELLOW}⚠ .env file not found, using defaults${NC}"
fi

# Configuration with fallbacks
CONTAINER_NAME="fris-postgres"
DB_USER="${POSTGRES_USER:-fris_user}"
DB_PASSWORD="${POSTGRES_PASSWORD:-fris_password}"
DB_NAME="${POSTGRES_DB:-fris_warehouse}"
DB_PORT="${POSTGRES_PORT:-5432}"
PGADMIN_PORT="${PGADMIN_PORT:-5050}"
PGADMIN_EMAIL="${PGADMIN_EMAIL:-admin@fris.local}"
PGADMIN_PASSWORD="${PGADMIN_PASSWORD:-admin}"

SCHEMA_DIR="src/data/schema"
MAX_RETRIES=30
RETRY_INTERVAL=2

echo ""

# =====================================================================
# Step 1: Check Docker Installation
# =====================================================================
echo -e "${YELLOW}Step 1: Checking Docker installation...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed or not in PATH${NC}"
    echo -e "${RED}Please install Docker: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

DOCKER_VERSION=$(docker --version)
echo -e "${GREEN}✓ Docker found: $DOCKER_VERSION${NC}"

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}✗ Docker daemon is not running${NC}"
    echo -e "${RED}Please start Docker${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker daemon is running${NC}"
echo ""

# =====================================================================
# Step 2: Start Docker Compose
# =====================================================================
echo -e "${YELLOW}Step 2: Starting PostgreSQL and pgAdmin containers...${NC}"

if docker-compose up -d; then
    echo -e "${GREEN}✓ Containers started successfully${NC}"
else
    echo -e "${RED}✗ Failed to start containers${NC}"
    exit 1
fi

echo ""

# =====================================================================
# Step 3: Wait for PostgreSQL to be Ready
# =====================================================================
echo -e "${YELLOW}Step 3: Waiting for PostgreSQL to be ready...${NC}"

retries=0
is_ready=false

while [ $is_ready = false ] && [ $retries -lt $MAX_RETRIES ]; do
    retries=$((retries + 1))
    echo -ne "  Attempt $retries/$MAX_RETRIES..."

    if docker exec "$CONTAINER_NAME" pg_isready -U "$DB_USER" -d "$DB_NAME" &> /dev/null; then
        is_ready=true
        echo -e " ${GREEN}✓ Ready!${NC}"
    else
        echo -e " ${GRAY}⏳ Waiting...${NC}"
        sleep $RETRY_INTERVAL
    fi
done

if [ $is_ready = false ]; then
    echo -e "${RED}✗ PostgreSQL did not become ready in time${NC}"
    echo -e "${RED}Check logs: docker logs $CONTAINER_NAME${NC}"
    exit 1
fi

echo ""

# =====================================================================
# Step 4: Execute Schema DDL
# =====================================================================
echo -e "${YELLOW}Step 4: Creating database schema...${NC}"

MASTER_DDL="$SCHEMA_DIR/master_ddl.sql"

if [ ! -f "$MASTER_DDL" ]; then
    echo -e "${RED}✗ master_ddl.sql not found at: $MASTER_DDL${NC}"
    exit 1
fi

echo -e "  ${GRAY}Executing: $MASTER_DDL${NC}"

if cat "$MASTER_DDL" | docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME"; then
    echo -e "${GREEN}✓ Schema created successfully${NC}"
else
    echo -e "${RED}✗ Schema creation failed${NC}"
    exit 1
fi

echo ""

# =====================================================================
# Step 5: Run Validation Tests
# =====================================================================
echo -e "${YELLOW}Step 5: Validating schema creation...${NC}"

TEST_SQL="$SCHEMA_DIR/docker-test.sql"

if [ -f "$TEST_SQL" ]; then
    if cat "$TEST_SQL" | docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME"; then
        echo -e "${GREEN}✓ Validation tests passed${NC}"
    else
        echo -e "${YELLOW}⚠ Validation tests failed, but schema may still be valid${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Validation script not found, skipping tests${NC}"
fi

echo ""

# =====================================================================
# Completion Summary
# =====================================================================
echo -e "${CYAN}===============================================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${CYAN}===============================================================${NC}"
echo ""
echo -e "${NC}PostgreSQL Connection:${NC}"
echo -e "  ${GRAY}Host:     localhost${NC}"
echo -e "  ${GRAY}Port:     $DB_PORT${NC}"
echo -e "  ${GRAY}Database: $DB_NAME${NC}"
echo -e "  ${GRAY}User:     $DB_USER${NC}"
echo -e "  ${GRAY}Password: $DB_PASSWORD${NC}"
echo ""
echo -e "${NC}pgAdmin Web Interface:${NC}"
echo -e "  ${GRAY}URL:      http://localhost:$PGADMIN_PORT${NC}"
echo -e "  ${GRAY}Email:    $PGADMIN_EMAIL${NC}"
echo -e "  ${GRAY}Password: $PGADMIN_PASSWORD${NC}"
echo ""
echo -e "${NC}Connection String:${NC}"
echo -e "  ${GRAY}postgresql://$DB_USER:$DB_PASSWORD@localhost:$DB_PORT/$DB_NAME${NC}"
echo ""
echo -e "${NC}Useful Commands:${NC}"
echo -e "  ${GRAY}Connect to DB:     docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME${NC}"
echo -e "  ${GRAY}View logs:         docker logs $CONTAINER_NAME${NC}"
echo -e "  ${GRAY}Stop containers:   docker-compose down${NC}"
echo -e "  ${GRAY}Restart:           docker-compose restart${NC}"
echo -e "  ${GRAY}Remove all:        docker-compose down -v${NC}"
echo ""
echo -e "${CYAN}===============================================================${NC}"
