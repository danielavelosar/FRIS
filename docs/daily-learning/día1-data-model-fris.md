# Modelo de Datos FRIS – Financial Risk Intelligence System

Este documento describe el modelo de datos propuesto para FRIS, orientado a análisis de riesgo financiero, fraude, cumplimiento normativo y trazabilidad de decisiones de IA.

El modelo sigue un **esquema estrella** centrado en la tabla de hechos `fact_transactions`, con una tabla de hechos adicional para decisiones de agentes (`fact_agent_decisions`) y una factless (`fact_agent_decision_docs`) para evidencias normativas.

---

## Visión general del modelo

- `fact_transactions`: hechos de **transacciones financieras** a nivel más granular.
- `fact_agent_decisions`: hechos de **decisiones de agentes de IA** sobre transacciones.
- `fact_agent_decision_docs`: tabla de hechos sin medidas para vincular decisiones con **documentos regulatorios** usados como evidencia (RAG).

Dimensiones principales:

- `dim_customers`: datos del cliente y perfil de riesgo.
- `dim_accounts`: información de las cuentas / productos contratados.
- `dim_cards`: detalles operativos de las tarjetas.
- `dim_merchants`: comercios / establecimientos.
- `dim_products`: catálogo de productos financieros.
- `dim_locations`: ubicación geográfica.
- `dim_time`: calendario de fechas.
- `dim_devices`: dispositivos utilizados.
- `dim_regulatory_docs`: documentos regulatorios y de políticas para RAG.

---

## Tabla de Hechos: `fact_transactions`

**Tipo:** Tabla de hechos principal  
**Grano:** Una fila por transacción procesada en el sistema.  

**Clave primaria**
- `transaction_id`

**Foreign keys**
- `customer_id` → `dim_customers`
- `account_id` → `dim_accounts`
- `card_id` → `dim_cards`
- `merchant_id` → `dim_merchants`
- `product_id` → `dim_products`
- `location_id` → `dim_locations`
- `time_id` → `dim_time`
- `device_id` → `dim_devices`

**Contenido principal**
- Importe (`transaction_amount`, `transactionamountusd`, `exchange_rate`)
- Clasificación (`transaction_type`, `channel_code`, `network_code`, `response_code`, `declinereasoncode`)
- Métricas de riesgo y fraude (`is_fraud`, `fraud_score`, `risk_score`, `mlmodelversion`)
- Operación y performance (`authorization_code`, `processingtimems`, `acquirer_id`, `issuer_id`, `ip_address`, `session_id`)
- Metadatos de ETL (`created_at`, `updated_at`, `etlbatchid`)

**Usos típicos**
- Análisis de riesgo de crédito y comportamiento por cliente, producto, cuenta, zona.
- Detección de fraude y monitoreo de modelos de ML.
- Seguimiento de performance de la pasarela de pagos y bancos emisores/adquirentes.
- Base para dashboards de monitoreo operacional y regulatorio.

---

## Tabla de Hechos: `fact_agent_decisions`

**Tipo:** Tabla de hechos (IA / decisiones)  
**Grano:** Una fila por decisión de agente de IA sobre una transacción.

**Clave primaria**
- `decision_id`

**Foreign keys**
- `transaction_id` → `fact_transactions`

**Contenido principal**
- Identidad del agente (`agent_name`)
- Resultado estructurado (`decision_output` como JSON)
- Trazabilidad de razonamiento (`reasoning_trace`)
- Modelo usado (`model_version`)
- Métricas de costo y latencia (`execution_time_ms`, `tokens_used`, `token_cost_usd`)
- Confianza del agente (`confidence_score`)
- Timestamps (`created_at`)

**Usos típicos**
- Auditoría de decisiones automáticas (por qué se aprobó/declinó algo).
- Análisis de performance y costo de agentes / LLMs.
- Generación de datasets para mejorar y re-entrenar modelos.

---

## Tabla de Hechos (Factless): `fact_agent_decision_docs`

**Tipo:** Factless fact table (sin medidas numéricas)  
**Grano:** Una fila por *documento* (o chunk) usado como evidencia en una decisión de agente.

**Clave primaria**
- `evidence_id`

**Foreign keys**
- `decision_id` → `fact_agent_decisions`
- `doc_id` → `dim_regulatory_docs`

**Contenido principal**
- Identificador del fragmento (`chunk_id`)
- Score de relevancia (`relevance_score`)
- Snippet/cita usada (`citation_snippet`)
- Rank de retrieval (`retrieval_rank`)
- `created_at`

**Usos típicos**
- Trazabilidad normativa (qué norma se usó para justificar qué decisión).
- Medición de calidad del RAG (relevancia, ranking, cobertura).
- Soporte a auditorías internas y regulatorias.

---

## Dimensión: `dim_customers`

**Tipo:** Dimensión de clientes  
**Grano:** Una fila por cliente único.

**Clave primaria**
- `customer_id`

**Contenido principal**
- Identificación y datos básicos (`customer_number`, `document_type`, `document_number`, `full_name`, `birth_date`, `age_group`, `gender`).
- Información sociodemográfica y laboral (`marital_status`, `education_level`, `occupation`, `employment_type`, `employer_name`).
- Ingresos y segmentación (`monthly_income`, `income_bracket`, `customer_segment`).
- Riesgo y crédito (`risk_profile`, `credit_score`, `creditscorerange`, `amlrisklevel`, banderas PEP/blacklist/VIP).
- Estado de relación y KYC (`registration_date`, `activation_date`, `lastactivitydate`, `customer_status`, `kyc_status`, `kycverificationdate`).
- Preferencias de comunicación (`email_domain`, `phonecountrycode`, `phoneareacode`, `preferred_language`, `preferred_channel`).
- Métricas de negocio (`churn_probability`, `lifetime_value`, `total_products`).
- Metadatos (`created_at`, `updated_at`).

**Usos típicos**
- Segmentación de clientes y scoring de riesgo.
- Análisis de KYC/AML y población PEP.
- Cálculo de valor de vida del cliente y churn.

---

## Dimensión: `dim_accounts`

**Tipo:** Dimensión de cuentas  
**Grano:** Una fila por cuenta / contrato financiero.

**Clave primaria**
- `account_id`

**Contenido principal**
- Identificación de cuenta (`account_number`, `account_type`, `account_subtype`, `product_name`).
- Ciclo de vida (`opening_date`, `closing_date`, `account_status`).
- Parámetros de crédito y estado financiero (`credit_limit`, `available_credit`, `current_balance`, `interest_rate`, `paymentduedate`, `minimum_payment`, `utilization_rate`).
- Morosidad y cobranza (`delinquency_days`, `delinquency_status`, `lastpaymentdate`, `lastpaymentamount`, `collection_status`, `writeoffflag`, `writeoffdate`).
- Organización (`branch_code`, `officer_id`).
- Metadatos (`created_at`, `updated_at`).

**Usos típicos**
- Análisis de exposiciones y cartera por tipo/subtipo de cuenta.
- Seguimiento de morosidad y flujo de cobranza.
- Monitoreo de utilización de líneas de crédito y write-offs.

---

## Dimensión: `dim_cards`

**Tipo:** Dimensión de tarjetas  
**Grano:** Una fila por tarjeta física/virtual.

**Clave primaria**
- `card_id`

**Contenido principal**
- Identificación segura (`cardnumberhash`, `cardlast4_digits`).
- Clasificación (`card_brand`, `card_type`, `card_level`, `issuing_bank`).
- Fechas clave (`issue_date`, `expiry_date`, `activation_date`, `lastpinchange_date`).
- Estado (`card_status`, `block_reason`, `fraud_flag`).
- Capacidades (`chip_enabled`, `contactless_enabled`, `international_enabled`, `online_enabled`, `atm_enabled`).
- Límites (`dailylimitpos`, `dailylimitatm`, `monthly_limit`).
- Seguridad (`pin_attempts`, `replacement_count`).
- Metadatos (`created_at`, `updated_at`).

**Usos típicos**
- Análisis de riesgo y fraude por tipo/segmento de tarjeta.
- Control de límites y patrones de uso.
- Auditoría de bloqueos y reemplazos.

---

## Dimensión: `dim_merchants`

**Tipo:** Dimensión de comercios  
**Grano:** Una fila por comercio afiliado.

**Clave primaria**
- `merchant_id`

**Contenido principal**
- Identificación comercial y legal (`merchant_name`, `legal_name`, `tax_id`, `website_url`, `email_domain`, `phone_number`).
- Clasificación (`merchantcategorycode`, `mcc_description`, `industry_category`, `business_type`).
- Estado y riesgo (`registration_date`, `merchant_status`, `risk_level`, `fraud_rate`, `chargeback_rate`, `highriskflag`).
- Métricas de actividad (`average_ticket`, `monthly_volume`, `transaction_count`, `terminal_count`).
- Operación (`acquirer_name`, `ecommerceenabled`, `recurring_billing`, `pci_compliant`, `lastreviewdate`).
- Metadatos (`created_at`, `updated_at`).

**Usos típicos**
- Detección de comercios de alto riesgo / alto chargeback.
- Segmentación de volumen y ticket promedio por MCC.
- Análisis de performance de adquirencia.

---

## Dimensión: `dim_products`

**Tipo:** Dimensión de productos financieros  
**Grano:** Una fila por producto del catálogo.

**Clave primaria**
- `product_id`

**Contenido principal**
- Identificación (`product_code`, `product_name`).
- Clasificación (`product_category`, `product_type`, `product_family`, `target_segment`).
- Ciclo de vida (`launch_date`, `discontinue_date`, `product_status`).
- Características financieras (`minimum_amount`, `maximum_amount`, `baseinterestrate`, `annual_fee`, `terms_months`, `graceperioddays`, `penalty_rate`).
- Beneficios (`features`, `rewards_program`).
- Rentabilidad y riesgo (`profitability_score`, `risk_weight`).
- Metadatos (`created_at`, `updated_at`).

**Usos típicos**
- Análisis de portafolio de productos (rentabilidad vs riesgo).
- Comparación de productos por segmento objetivo.
- Soporte a decisiones de pricing y rediseño de productos.

---

## Dimensión: `dim_locations`

**Tipo:** Dimensión geográfica  
**Grano:** Una fila por ubicación específica (país/estado/ciudad).

**Clave primaria**
- `location_id`

**Contenido principal**
- Identificación (`country_code`, `country_name`, `state_code`, `state_name`, `city_code`, `city_name`, `postal_code`).
- Coordenadas (`latitude`, `longitude`, `timezone`).
- Clasificación territorial (`region`, `metro_area`, `urban_rural`, `risk_zone`).
- Métricas de negocio (`population`, `gdppercapita`, `branch_count`, `atm_count`, `competitor_density`).
- Metadatos (`created_at`, `updated_at`).

**Usos típicos**
- Análisis de riesgo por zona geográfica.
- Evaluación de cobertura (sucursales, ATMs) y competencia.
- Cruce de riesgo con variables macroeconómicas.

---

## Dimensión: `dim_time`

**Tipo:** Dimensión de tiempo  
**Grano:** Una fila por fecha de calendario.

**Clave primaria**
- `time_id`

**Contenido principal**
- Fecha base (`full_date`, `year`, `month`, `dayofmonth`, etc.).
- Desagregaciones de calendario (`quarter`, `weekofyear`, `dayofweek`, `day_name`, `day_short`, `month_name`, `month_short`).
- Festivos y negocio (`is_weekend`, `is_holiday`, `holiday_name`, `isbusinessday`).
- Calendario fiscal (`fiscal_year`, `fiscal_quarter`, `fiscal_month`, `season`).
- Flags de cierre (`ismonthend`, `isquarterend`, `isyearend`, `daysinmonth`).
- Metadatos (`created_at`, `updated_at`).

**Usos típicos**
- Análisis temporal estándar (por día/mes/trimestre/año).
- Indicadores de cierre de mes, fin de año, etc.
- Alineación con calendario fiscal.

---

## Dimensión: `dim_devices`

**Tipo:** Dimensión de dispositivos  
**Grano:** Una fila por dispositivo (fingerprint).

**Clave primaria**
- `device_id`

**Contenido principal**
- Identificación técnica (`device_fingerprint`, `device_type`, `device_brand`, `device_model`).
- Sistema y navegador (`operating_system`, `os_version`, `browser_name`, `browser_version`, `user_agent`, `screen_resolution`).
- Flags de riesgo (`is_mobile`, `is_tablet`, `is_rooted`, `is_emulator`).
- Versión de app y SDK (`app_version`, `sdk_version`).
- Red (`network_type`, `carrier_name`).
- Trazabilidad (`firstseendate`, `lastseendate`).
- Riesgo (`trust_score`, `fraud_flag`, `blacklist_flag`).
- Metadatos (`created_at`, `updated_at`).

**Usos típicos**
- Detección de patrones de fraude por dispositivo.
- Gestión de listas negras / dispositivos de confianza.
- Segmentación por tipo de dispositivo y red.

---

## Dimensión: `dim_regulatory_docs`

**Tipo:** Dimensión de documentos regulatorios / políticas (RAG)  
**Grano:** Una fila por documento normativo o de política interna.

**Clave primaria**
- `doc_id`

**Contenido principal**
- Identificación (`doc_title`, `doc_type`, `issuing_body`).
- Vigencia (`effective_date`, `expiration_date`, `status`).
- Almacenamiento (`s3_path`, `vector_collection_id`, `chunk_count`, `last_embedded_at`).
- Resumen (`summary`).

**Usos típicos**
- Soporte a retrieval-augmented generation (RAG) para agentes de compliance.
- Trazabilidad de qué norma se aplicó a cada decisión (`fact_agent_decision_docs`).
- Gestión del ciclo de vida normativo (activa, derogada, borrador).

---

## Notas de diseño

- El modelo está optimizado como **esquema estrella** para consultas analíticas de alto volumen.
- Se incluyen campos de auditoría (`created_at`, `updated_at`, `etlbatchid`) para trazabilidad de carga.
- Campos sensibles (PII y texto libre) deben manejarse con cuidado en términos de cifrado, hashing y políticas de retención.
