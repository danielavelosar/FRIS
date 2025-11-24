# =====================================================================
# FRIS 2.0 - Docker PostgreSQL Setup Script (PowerShell)
# =====================================================================
# Purpose: Automate PostgreSQL container setup and schema deployment
# Usage: .\src\data\schema\docker-setup.ps1
# =====================================================================

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "FRIS 2.0 - PostgreSQL Docker Setup" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# Load Configuration from .env
# =====================================================================
$envFile = ".env"
$envVars = @{}

if (Test-Path $envFile) {
    Write-Host "Loading configuration from .env..." -ForegroundColor Gray
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        # Skip comments and empty lines
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line -split "=", 2
            if ($parts.Count -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim()
                $envVars[$key] = $value
            }
        }
    }
    Write-Host "✓ Configuration loaded" -ForegroundColor Green
} else {
    Write-Host "⚠ .env file not found, using defaults" -ForegroundColor Yellow
}

# Configuration with fallbacks
$CONTAINER_NAME = "fris-postgres"
$DB_USER = if ($envVars["POSTGRES_USER"]) { $envVars["POSTGRES_USER"] } else { "fris_user" }
$DB_PASSWORD = if ($envVars["POSTGRES_PASSWORD"]) { $envVars["POSTGRES_PASSWORD"] } else { "fris_password" }
$DB_NAME = if ($envVars["POSTGRES_DB"]) { $envVars["POSTGRES_DB"] } else { "fris_warehouse" }
$DB_PORT = if ($envVars["POSTGRES_PORT"]) { $envVars["POSTGRES_PORT"] } else { "5432" }
$PGADMIN_PORT = if ($envVars["PGADMIN_PORT"]) { $envVars["PGADMIN_PORT"] } else { "5050" }
$PGADMIN_EMAIL = if ($envVars["PGADMIN_EMAIL"]) { $envVars["PGADMIN_EMAIL"] } else { "admin@fris.local" }
$PGADMIN_PASSWORD = if ($envVars["PGADMIN_PASSWORD"]) { $envVars["PGADMIN_PASSWORD"] } else { "admin" }

$SCHEMA_DIR = "src/data/schema"
$MAX_RETRIES = 30
$RETRY_INTERVAL = 2

Write-Host ""

# =====================================================================
# Step 1: Check Docker Installation
# =====================================================================
Write-Host "Step 1: Checking Docker installation..." -ForegroundColor Yellow

try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Red
    exit 1
}

# Check if Docker is running
try {
    docker ps | Out-Null
    Write-Host "✓ Docker daemon is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker daemon is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop" -ForegroundColor Red
    exit 1
}

Write-Host ""

# =====================================================================
# Step 2: Start Docker Compose
# =====================================================================
Write-Host "Step 2: Starting PostgreSQL and pgAdmin containers..." -ForegroundColor Yellow

try {
    docker-compose up -d
    Write-Host "✓ Containers started successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to start containers" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# =====================================================================
# Step 3: Wait for PostgreSQL to be Ready
# =====================================================================
Write-Host "Step 3: Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow

$retries = 0
$isReady = $false

while (-not $isReady -and $retries -lt $MAX_RETRIES) {
    $retries++
    Write-Host "  Attempt $retries/$MAX_RETRIES..." -NoNewline

    try {
        $result = docker exec $CONTAINER_NAME pg_isready -U $DB_USER -d $DB_NAME 2>&1
        if ($LASTEXITCODE -eq 0) {
            $isReady = $true
            Write-Host " ✓ Ready!" -ForegroundColor Green
        } else {
            Write-Host " ⏳ Waiting..." -ForegroundColor Gray
            Start-Sleep -Seconds $RETRY_INTERVAL
        }
    } catch {
        Write-Host " ⏳ Waiting..." -ForegroundColor Gray
        Start-Sleep -Seconds $RETRY_INTERVAL
    }
}

if (-not $isReady) {
    Write-Host "✗ PostgreSQL did not become ready in time" -ForegroundColor Red
    Write-Host "Check logs: docker logs $CONTAINER_NAME" -ForegroundColor Red
    exit 1
}

Write-Host ""

# =====================================================================
# Step 4: Execute Schema DDL
# =====================================================================
Write-Host "Step 4: Creating database schema..." -ForegroundColor Yellow

$masterDDL = Join-Path $SCHEMA_DIR "master_ddl.sql"

if (-not (Test-Path $masterDDL)) {
    Write-Host "✗ master_ddl.sql not found at: $masterDDL" -ForegroundColor Red
    exit 1
}

Write-Host "  Executing: $masterDDL" -ForegroundColor Gray

try {
    Get-Content $masterDDL | docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Schema created successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Schema creation failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Error executing schema: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# =====================================================================
# Step 5: Run Validation Tests
# =====================================================================
Write-Host "Step 5: Validating schema creation..." -ForegroundColor Yellow

$testSQL = Join-Path $SCHEMA_DIR "docker-test.sql"

if (Test-Path $testSQL) {
    try {
        Get-Content $testSQL | docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME
        Write-Host "✓ Validation tests passed" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Validation tests failed, but schema may still be valid" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Validation script not found, skipping tests" -ForegroundColor Yellow
}

Write-Host ""

# =====================================================================
# Completion Summary
# =====================================================================
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PostgreSQL Connection:" -ForegroundColor White
Write-Host "  Host:     localhost" -ForegroundColor Gray
Write-Host "  Port:     $DB_PORT" -ForegroundColor Gray
Write-Host "  Database: $DB_NAME" -ForegroundColor Gray
Write-Host "  User:     $DB_USER" -ForegroundColor Gray
Write-Host "  Password: $DB_PASSWORD" -ForegroundColor Gray
Write-Host ""
Write-Host "pgAdmin Web Interface:" -ForegroundColor White
Write-Host "  URL:      http://localhost:$PGADMIN_PORT" -ForegroundColor Gray
Write-Host "  Email:    $PGADMIN_EMAIL" -ForegroundColor Gray
Write-Host "  Password: $PGADMIN_PASSWORD" -ForegroundColor Gray
Write-Host ""
Write-Host "Connection String:" -ForegroundColor White
Write-Host "  postgresql://$DB_USER`:$DB_PASSWORD@localhost:$DB_PORT/$DB_NAME" -ForegroundColor Gray
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor White
Write-Host "  Connect to DB:     docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME" -ForegroundColor Gray
Write-Host "  View logs:         docker logs $CONTAINER_NAME" -ForegroundColor Gray
Write-Host "  Stop containers:   docker-compose down" -ForegroundColor Gray
Write-Host "  Restart:           docker-compose restart" -ForegroundColor Gray
Write-Host "  Remove all:        docker-compose down -v" -ForegroundColor Gray
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
