# FRIS 2.0 - PostgreSQL Schema

Este directorio contiene todos los scripts DDL (Data Definition Language) para crear el esquema completo del data warehouse de FRIS.

## Estructura del Esquema

El modelo de datos sigue un **esquema estrella (constellation)** con dos tablas de hechos principales que comparten dimensiones comunes:

### Schemas PostgreSQL

- **`dim`**: Tablas de dimensiones (atributos descriptivos)
- **`fact`**: Tablas de hechos (eventos transaccionales con métricas)
- **`audit`**: Tablas de auditoría y logging

### Tablas de Dimensiones (9)

1. **dim_time**: Calendario con períodos fiscales y festivos
2. **dim_locations**: Jerarquía geográfica y zonas de riesgo
3. **dim_customers**: Perfiles de clientes con KYC/AML
4. **dim_accounts**: Ciclo de vida de cuentas y exposición crediticia
5. **dim_cards**: Tarjetas con capacidades y flags de fraude
6. **dim_merchants**: Comercios con MCC y métricas de riesgo
7. **dim_products**: Catálogo de productos financieros
8. **dim_devices**: Fingerprinting de dispositivos
9. **dim_regulatory_docs**: Documentos regulatorios para RAG

### Tablas de Hechos (3)

1. **fact_transactions**: Transacciones financieras (particionada por mes)
2. **fact_agent_decisions**: Decisiones de agentes IA con audit trail
3. **fact_agent_decision_docs**: Enlaces a documentos regulatorios (factless fact)

---

## 🚀 Quick Start con Docker

### Opción 1: Script Automatizado (Recomendado)

**Windows (PowerShell)**:
```powershell
.\src\data\schema\docker-setup.ps1
```

**Linux/Mac/Git Bash**:
```bash
chmod +x src/data/schema/docker-setup.sh
./src/data/schema/docker-setup.sh
```

El script automáticamente:
- ✅ Verifica Docker instalado
- ✅ Levanta PostgreSQL + pgAdmin
- ✅ Espera a que PostgreSQL esté listo
- ✅ Ejecuta `master_ddl.sql`
- ✅ Valida con `docker-test.sql`
- ✅ Muestra resumen de conexión

### Opción 2: Manual con Docker

```bash
# 1. Levantar contenedores
docker-compose up -d

# 2. Esperar 10-20 segundos

# 3. Ejecutar schema
docker exec -i fris-postgres psql -U fris_user -d fris_warehouse < src/data/schema/master_ddl.sql

# 4. Validar (opcional)
docker exec -i fris-postgres psql -U fris_user -d fris_warehouse < src/data/schema/docker-test.sql
```

### Opción 3: PostgreSQL Local (sin Docker)

Si tienes PostgreSQL instalado localmente:

```bash
# Ejecutar script maestro
psql -U postgres -d fris_warehouse -f src/data/schema/master_ddl.sql
```

---

## 🔗 Conexión a la Base de Datos

### Credenciales

**IMPORTANTE**: Las credenciales están definidas en el archivo `.env` (raíz del proyecto).

Valores por defecto:
```bash
# Ver archivo .env para credenciales actuales
POSTGRES_USER=fris_user
POSTGRES_PASSWORD=fris_password
POSTGRES_DB=fris_warehouse
POSTGRES_PORT=5432
```

⚠️ **Seguridad**: El archivo `.env` está en `.gitignore` y NO debe commitearse. Cambia las credenciales para producción.

### Connection String

```bash
# Formato general (usa valores de tu .env)
postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}
```

### Conectar desde Docker CLI

```bash
# Usa las variables de .env
docker exec -it fris-postgres psql -U fris_user -d fris_warehouse
```

### pgAdmin Web UI

```bash
# Acceso configurado en .env
URL:      http://localhost:${PGADMIN_PORT}  # Default: 5050
Email:    ${PGADMIN_EMAIL}                  # Default: admin@fris.local
Password: ${PGADMIN_PASSWORD}               # Default: admin
```

**Agregar servidor en pgAdmin**:
1. Click en "Add New Server"
2. General > Name: `FRIS Local`
3. Connection:
   - Host: `fris-postgres` (nombre del contenedor Docker)
   - Port: `5432`
   - Database: (valor de `POSTGRES_DB` en `.env`)
   - Username: (valor de `POSTGRES_USER` en `.env`)
   - Password: (valor de `POSTGRES_PASSWORD` en `.env`)

---

## 📁 Estructura de Archivos

### Scripts DDL

```
src/data/schema/
├── 00_init_schemas.sql
├── 01_dimensions/          # 9 tablas de dimensiones
├── 02_facts/               # 3 tablas de hechos
├── 03_indexes.sql
├── 04_constraints.sql
├── 05_triggers.sql
├── master_ddl.sql          # Script ejecutor maestro
├── docker-test.sql         # Validación
├── docker-setup.ps1        # Setup PowerShell
├── docker-setup.sh         # Setup Bash
└── README.md
```

### Docker Setup

```
raíz/
├── docker-compose.yml      # Configuración Docker
├── .env                    # ⚠️ Variables de entorno (NO commitear)
└── src/data/schema/
```

## Características Clave

### Particionamiento

**fact_transactions** está particionada por mes usando `transaction_datetime`:
- Mejora performance en queries temporales
- Facilita archivado de datos históricos
- Permite mantenimiento por partición

```sql
-- Crear nueva partición manualmente
CREATE TABLE fact.fact_transactions_2025_01 PARTITION OF fact.fact_transactions
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

### Índices de Performance

Los índices están optimizados para:
- Queries de análisis de fraude (`is_fraud`, `fraud_score`)
- Búsquedas por cliente/comercio/tarjeta
- Filtrado temporal (`transaction_datetime`)
- Análisis geográfico (`location_id`)
- Patrones de dispositivos (`device_id`, `fraud_flag`)

### Triggers Automáticos

1. **Actualización de `updated_at`**: Todas las dimensiones
2. **Cálculo de `utilization_rate`**: `dim_accounts`
3. **Actualización de `lastseendate`**: `dim_devices` cuando hay transacción
4. **Actualización de `lastactivitydate`**: `dim_customers` cuando hay transacción
5. **Validación de montos**: `fact_transactions` (exchange rate consistency)
6. **Flagging de riesgo**: Transacciones con fraud_score > 0.8

### Constraints de Negocio

- Validación de rangos de scores (0-1)
- Montos positivos
- Consistencia de fechas
- Reglas de estado (ej: tarjetas con fraude deben estar bloqueadas)
- Integridad referencial con FKs

### Roles y Permisos

El script maestro crea 3 roles:

1. **fris_readonly**: Solo lectura en dim y fact
2. **fris_readwrite**: Lectura y escritura en dim, inserción en fact
3. **fris_etl**: Acceso completo para procesos ETL

```sql
-- Crear usuario y asignar rol
CREATE USER etl_user WITH PASSWORD 'secure_password';
GRANT fris_etl TO etl_user;
```

## Tipos de Datos PostgreSQL

| Tipo en ER Diagram | PostgreSQL | Uso |
|-------------------|------------|-----|
| `string` | `VARCHAR(50-255)` | IDs, códigos, nombres |
| `decimal` | `NUMERIC(18,4)` | Montos financieros |
| `boolean` | `BOOLEAN` | Flags |
| `int` | `INTEGER` | Contadores, días |
| `date` | `DATE` | Fechas calendario |
| `timestamp` | `TIMESTAMP` | Marcas temporales |
| `json` | `JSONB` | Datos estructurados (decision_output) |
| `text` | `TEXT` | Contenido largo (reasoning_trace) |

## Verificación del Esquema

```sql
-- Ver todas las tablas
\dt dim.*
\dt fact.*

-- Describir estructura de una tabla
\d+ dim.dim_customers

-- Ver índices
\di dim.*
\di fact.*

-- Ver constraints
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE connamespace = 'dim'::regnamespace;

-- Ver triggers
\dft dim.*
\dft fact.*

-- Ver particiones de fact_transactions
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE tablename LIKE 'fact_transactions%'
ORDER BY tablename;
```

## Mantenimiento

### Crear Nuevas Particiones

Se recomienda crear particiones con anticipación:

```sql
-- Crear partición para próximo mes
CREATE TABLE fact.fact_transactions_2025_02 PARTITION OF fact.fact_transactions
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
```

### Archivar Particiones Antiguas

```sql
-- Desvincular partición (datos permanecen)
ALTER TABLE fact.fact_transactions DETACH PARTITION fact.fact_transactions_2023_01;

-- Mover a tablespace de archivo
ALTER TABLE fact.fact_transactions_2023_01 SET TABLESPACE archive_tablespace;
```

### Actualizar Estadísticas

```sql
-- Después de cargas grandes de datos
ANALYZE dim.dim_customers;
ANALYZE fact.fact_transactions;

-- O todas las tablas
ANALYZE;
```

### Reconstruir Índices

```sql
-- Si hay bloat en índices
REINDEX INDEX CONCURRENTLY idx_fact_transactions_datetime;

-- O toda la tabla
REINDEX TABLE CONCURRENTLY fact.fact_transactions;
```

## Monitoreo

### Tamaño de Tablas

```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS indexes_size
FROM pg_tables
WHERE schemaname IN ('dim', 'fact')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Uso de Índices

```sql
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname IN ('dim', 'fact')
ORDER BY idx_scan DESC;
```

### Actividad de Transacciones

```sql
SELECT
    schemaname,
    relname,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del
FROM pg_stat_user_tables
WHERE schemaname IN ('dim', 'fact')
ORDER BY n_tup_ins + n_tup_upd + n_tup_del DESC;
```

## Troubleshooting

### Error: Relation already exists

```bash
# Eliminar esquema completo (⚠️ CUIDADO - borra todos los datos)
psql -U postgres -d fris_warehouse -c "DROP SCHEMA dim CASCADE;"
psql -U postgres -d fris_warehouse -c "DROP SCHEMA fact CASCADE;"

# Recrear
psql -U postgres -d fris_warehouse -f master_ddl.sql
```

### Error: Permission denied

```bash
# Asegurar permisos del usuario actual
psql -U postgres -d fris_warehouse -c "GRANT ALL ON SCHEMA dim, fact TO CURRENT_USER;"
```

### Error: Out of shared memory

```sql
-- Aumentar shared_buffers en postgresql.conf
shared_buffers = 2GB
max_connections = 200
```

## Referencias

- **Diagrama ER**: [docs/architecture/erDiagram.md](../../../docs/architecture/erDiagram.md)
- **Modelo de Datos**: [docs/daily-learning/día1-data-model-fris.md](../../../docs/daily-learning/día1-data-model-fris.md)
- **CLAUDE.md**: Guía arquitectónica completa
- **PostgreSQL Partitioning**: https://www.postgresql.org/docs/current/ddl-partitioning.html
- **ISO 18245 (MCC Codes)**: https://www.iso.org/standard/80998.html
