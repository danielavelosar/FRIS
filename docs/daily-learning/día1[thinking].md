Día 1: Setup y Modelado de Datos
Entregable:

Esquema estrella completo en SQL con DDL scripts
Docker-compose con PostgreSQL configurado
Diagrama ER del modelo de datos

Criterios de completitud:

 4 tablas dimensionales creadas (dim_customer, dim_product, dim_time, dim_channel)
 1 tabla de hechos (fact_transactions) con al menos 15 campos
 Constraints y foreign keys implementados
 Script de generación de datos dummy (10,000 transacciones)

Pregunta de evaluación:

Finance: ¿Por qué un esquema estrella es óptimo para análisis de riesgo crediticio vs un modelo normalizado?
AI: ¿Cómo estructurarías los datos para que sean consumibles por agentes LLM?

## Proceso

### Diagrama estrella vs diagrama copo de nieve 
en un diagrama estrella solo hay una tabla de hechos y unas dimensiones a lo largo mientras que en copo de nieve esas dimensiones también se parten en tablas

como quiero que el agente se confunda lo menos posible vamos a usar Un diagrama estrella, tiene menos joinses más simple, para modelos tambipen es el más usado 

Estándar en Risk Marts: Los "Data Marts" de Riesgo Crediticio suelen ser tablas de hechos (pagos, saldos mensuales) rodeadas de dimensiones.

### Encontrar modelos de datos para hacer datos Dummy 

1. busqué 
filetype:pdf "data dictionary" "credit risk" loan performance dataset 

así encontré el Dataset de Freddie Mac que me dice que las métricas estándar de la industria son 
LTV, DTI, Credit Score

La LTV, ou Loan To Value, est une notion utilisée dans le cadre de l’octroi d’un crédit immobilier. Le principe de la LTV consiste à rapporter le montant de l’emprunt au montant de l’actif financé. Ainsi, pour un actif valant 100 000 €, un crédit de 90 000 € permettra d’afficher une LTV de 90%. 

Your debt-to-income ratio (DTI) is all your monthly debt payments divided by your gross monthly income.

2. estos son los códigos usados en MCC
https://classification.codes/classifications/industry/mcc#version_1_iso-182452023
The standard is available for purchase at the ISO website. Each MCC code consists of 4 digits. As given by Monite Docs, the range of MCCs in ISO 18245:2023 are:

Range of Codes

Description

0001⁠–1499

Agricultural services

1500⁠–2999

Contracted services

4000⁠–4799

Transportation services

4800⁠–4999

Utility services

5000⁠–5599

Retail outlet services

5600⁠–5699

Clothing shops

4800-4999

Utilities

5700⁠–7299

Miscellaneous shops

7300⁠–7999

Business services

8000⁠–8999

Professional services and membership organizations

9000⁠–9999

Government services

The Merchant Category Codes classification system has codes for various business activities (e.g. MCC 5532 - Automotive Tire Stores), as well as codes for specific merchants (e.g. MCC 3001 - American Airlines, or MCC 3513 Westin Hotels). The most popular implementations of ISO 18245:2023 are Visa MCC and MasterCard MCC. MasterCard refers to MCCs as Card Acceptor Business Codes, whereas Visa sticks to the conventional name Merchant Category Codes. Both implementations are mostly similar, and the main differences between them are inclusion of particular merchants from the list, and codes specific to activities carried by a particular payment card organization. For example, MCC 3176 Metroflight Airlines is included only in the Visa MCC list (2024 edition), and MCC 3547 Breakers Resort and MCC 6537 MoneySend Intercountry only in MasterCard MCC list (2018 edition). A complete list of MCC codes specifying differences between Visa and MasterCard versions is available at citibank website.


Análisis de Datasets e Insights para el
Modelo de Datos
1. Análisis del Dataset de Home Credit
Default Risk
Insights Clave:
1.1 Arquitectura de Datos Modular
Separación por dominios funcionales: Los archivos están
organizados por tipo de información (bureau, application,
installments)
Relaciones maestro-detalle: Utiliza SKIDCURR como clave
principal y SKIDPREV para historial
Datos comportamentales temporales: Tracking mensual
de balances y pagos
1.2 Patrones de Riesgo Crediticio
Historial crediticio externo: Integración con bureau de
crédito
Análisis de comportamiento de pago: Datos detallados de
instalments_payments
•
•
•
•
•
Información contextual: Datos demográficos y laborales
del solicitante
1.3 Métricas de Evaluación
Scoring multidimensional: Combina datos internos y
externos
Análisis temporal: Evolución del comportamiento crediticio
Agregaciones a múltiples niveles: Cliente, producto,
tiempo
2. Análisis del Dataset de IEEE-CIS Fraud
Detection
Insights Clave:
2.1 Arquitectura Transaccional
Separación identidad-transacción: No todas las
transacciones tienen identidad asociada
Feature engineering extensivo: 393 features V1-V339
anonimizadas
Datos temporales relativos: TransactionDT como timedelta
2.2 Detección de Fraude
Patrones de dispositivo: DeviceType, DeviceInfo para
fingerprinting
Análisis de email: Pemaildomain, Remaildomain para
validación
Categorías de producto: ProductCD para segmentación
2.3 Características de Seguridad
Anonimización avanzada: Features V protegen información
sensible
•
•
•
•
•
•
•
•
•
•
•
Múltiples capas de validación: M1-M9 para verificaciones
cruzadas
Análisis de dirección: addr1, addr2 para geolocalización

3. Análisis del Dataset de Freddie Mac
Insights Clave:
3.1 Gestión de Hipotecas
Ciclo de vida completo: Desde originación hasta disposición
Tracking mensual detallado: Performance data con 32
campos
Gestión de defectos: Sistema de códigos para identificar
problemas
3.2 Evaluación de Riesgo
Métricas estándar de la industria: LTV, DTI, Credit Score
Análisis geográfico: MSA, State, Postal Code
Modificaciones de préstamo: Tracking de cambios en
términos
3.3 Cálculo de Pérdidas
Componentes detallados: Net proceeds, expenses,
recoveries
Códigos de balance cero: 9 razones diferentes de
terminación
Actualización periódica: Dataset "vivo" con correcciones
•
•
•
•
•
•
•
•
•
•
•
4. Análisis de ISO 18245 (Merchant
Category Codes)
Insights Clave:
4.1 Categorización de Comercios
Sistema jerárquico: 9 categorías principales
Granularidad de 4 dígitos: Permite 9999 categorías únicas
Orientación por industria: Agrupación lógica por tipo de
servicio
4.2 Aplicación en Riesgo
Perfilamiento de riesgo por MCC: Diferentes niveles según
categoría
Análisis de patrones de gasto: Comportamiento por tipo
de comercio
Detección de anomalías: Transacciones inusuales por
categoría
5. Análisis de Basel Committee - Risk
Data Aggregation
Insights Clave:
5.1 Principios de Agregación
14 principios fundamentales: Governance, arquitectura,
capabilities
Enfoque en crisis: Capacidad de respuesta en situaciones
de estrés
Calidad de datos: Accuracy, completeness, timeliness
•
•
•
•
•
•
•
•
•
5.2 Requerimientos Regulatorios
Implementación gradual: Timeline específico para G-SIBs
Supervisión continua: Monitoreo por autoridades
Documentación exhaustiva: Trazabilidad com


➡️ fact_agent_decisions debe ser FACT, no dimensión.
Y sí sigues teniendo un modelo estrella, solo que ahora tienes dos estrellas que comparten dimensiones (eso se llama constellation, pero conceptualmente sigue siendo “star-based”).

1. ¿Por qué fact_agent_decisions es una FACT y no una dimensión?

Piensa en la diferencia:

Dimensión = catálogo descriptivo, relativamente estable

Ej: cliente, cuenta, tarjeta, agente, modelo, documento regulatorio…

No son “eventos”, sino “cosas” con atributos.

Hecho (fact) = evento en el tiempo, con métricas que se analizan

Ej: una transacción, un pago, un login, una decisión de un agente.

fact_agent_decisions tiene exactamente pinta de evento:

Pasa en un momento: created_at, time_id

Tiene métricas: execution_time_ms, tokens_used, token_cost_usd, confidence_score

Tiene FK a otras dimensiones: transaction_id, customer_id, agent_name, model_version, etc.

Eso es textbook tabla de hechos.

Si lo vuelves dimensión:

Se te rompe el grano: ¿qué es una fila? ¿el tipo de decisión? ¿cada combinación agente+modelo?

No puedes fácilmente sumar tiempos, costos, número de decisiones por día / por agente / por cliente.

Pierdes la semántica de “evento auditable”.

2. ¿Se rompe el STAR schema si tengo dos facts?

No 😊

Ahora tienes algo así:

Star 1: Transacciones

fact_transactions

dims: dim_customers, dim_accounts, dim_cards, dim_merchants, dim_locations, dim_time, dim_devices, etc.

Star 2: Decisiones de agentes

fact_agent_decisions

dims: dim_time, dim_customers, dim_ai_agents, dim_ai_models, dim_regulatory_docs (a través del bridge), etc.

Ambas comparten dimensiones (ej. dim_time, dim_customers) → eso es una constellation schema, pero sigue siendo diseño estrella: cada fact está rodeada de dimensiones, solo que hay más de un fact.

En BI real, esto es hiper normal: fact_ventas, fact_cobros, fact_llamadas_callcenter, etc. Todas “estrellas” que comparten dim_clientes, dim_tiempo, etc.


na "Bridge Table" y fact_agent_decision_docs resuelven el mismo problema (la relación Muchos-a-Muchos), pero con un enfoque diferente.

Déjame explicarte por qué tu recomendación es probablemente mejor para tu caso de Inteligencia Artificial y cómo definirá esto tu PDF final.

La Diferencia: Técnica vs. Negocio
Bridge Table (Concepto Técnico): Es el nombre genérico del patrón de diseño. Suelen ser tablas "invisibles" que solo tienen dos columnas de IDs (decision_id, doc_id). Son aburridas y solo sirven para unir.

fact_agent_decision_docs (Enfoque de Negocio/Auditoría): Al llamarla "Fact Table", le estás dando estatus de evento. No es solo un puente; estás diciendo: "El hecho de que el Agente consultó este documento es un evento importante por sí mismo".

¿Por qué fact_agent_decision_docs es superior para FRIS 2.0?
Para un sistema de IA con RAG (Retrieval-Augmented Generation), una Bridge Table simple se queda corta. Tú necesitas guardar métricas de esa interacción.

Si el Agente Auditor dice que una transacción es sospechosa basándose en una ley, necesitas saber:

¿Qué ley? (La relación).

¿Qué tan seguro estaba? (El Similarity Score del vector search).

¿Qué párrafo específico leyó? (El Chunk o snippet exacto).

Una Bridge Table clásica no suele guardar texto ni scores. Una fact_agent_decision_docs sí.


Consideraciones de Implementación

1.	Seguridad y Privacidad

•	Implementar encriptación en reposo y en tránsito
•	Aplicar masking y tokenización para datos sensibles
 
•	Cumplir con regulaciones GDPR, PCI-DSS, SOX

2.	Performance

•	Índices en todas las foreign keys
•	Particionamiento por fecha en fact_transactions
•	Materialización de vistas para reportes frecuentes

3.	Calidad de Datos

•	Validaciones en tiempo de ingesta
•	Procesos de data cleansing automatizados
•	Monitoreo continuo de completitud y precisión

4.	Escalabilidad

•	Diseño para crecimiento horizontal
•	Archivado histórico después de 7 años
•	Compresión de datos antiguos

5.	Auditoría

•	Logs de todos los cambios
•	Tracking de lineage de datos
•	Versionado de esquemas



Conclusiones

FRIS 2.0 representa una evolución significativa en la gestión de riesgo financiero, integrando las mejores prácticas observadas en los datasets analizados:
1.	Arquitectura robusta: Modelo dimensional optimizado para análisis
2.	Cobertura integral: Desde originación hasta disposición
 
3.	Machine Learning ready: Features preparadas para modelos avanzados
4.	Cumplimiento regulatorio: Alineado con Basel III y estándares internacionales
5.	Escalabilidad: Diseñado para Big Data y procesamiento en tiempo real
Este modelo de datos proporciona la base para un sistema de inteligencia de riesgo de clase mundial, capaz de detectar fraude, evaluar riesgo crediticio y cumplir con requisitos regulatorios de manera eficiente y efectiva.



¿Por qué es un “factless fact” y no un bridge?

Porque:

✔ Representa un evento auditable

“Un documento regulatorio fue utilizado en una decisión de un agente”.

Es un evento, no solo un vínculo.

✔ Tiene atributos propios del evento

similarity_score

chunk_reference

used_as

retrieved_at

Un BRIDGE no tiene atributos propios salvo llaves.

✔ Se analiza con métricas derivadas

Ejemplos:

“¿Cuántas veces fue usada esta circular en decisiones de riesgo alto?”

“¿Cuál es el documento más citado por el Compliance Agent?”

“¿Qué normas utiliza cada tipo de agente?”

“¿Qué documentos generan más costo en tokens?”

Estas preguntas requieren hechos, no dimensiones.


sí tiene sentido duplicar un poco de info del producto en dim_accounts, pero con reglas claras.

Te lo resumiría así:

1. Patrón: “mini-producto” dentro de dim_accounts

Dejas:

dim_products = fuente canónica del catálogo de productos (toda la definición).

dim_accounts = la cuenta del cliente + un subconjunto de atributos de producto para reporting rápido.

Por ejemplo, en dim_accounts podrías tener:

product_id (FK a dim_products) ✅ obligatorio

product_name

product_family o product_category (ej. “Tarjeta crédito”, “Cuenta ahorro”).

Algún atributo clave de riesgo/reporte (ej. risk_bucket del producto).

3. Reglas para no romper la consistencia

Si haces esto por performance, define estas reglas:

Fuente de verdad

dim_products = verdad oficial del producto.

Lo de dim_accounts es cache para reporting.

Actualización
En el ETL:

cada vez que se carga/actualiza dim_accounts, rellenas product_name, product_family, etc. desde dim_products usando product_id.

decide el comportamiento:

Type 1: si cambia el nombre de producto, sobreescribes en dim_accounts (para que todo se vea actualizado).

Snapshot: si quieres congelar cómo se veía al momento de apertura de la cuenta, cambia el nombre del campo a algo como product_name_at_opening.

Estándar para los analistas

“Para reportes rápidos por tipo de producto → usen atributos de dim_accounts.”

“Para análisis profundos de características del producto → joinear con dim_products.”

4. Beneficio real de performance

Este patrón te da:

Menos joins en las queries típicas (FACT → ACCOUNTS en vez de FACT → ACCOUNTS → PRODUCTS).

Menos riesgo de que un mal modelado en BI termine haciendo 3–4 joins gigantes.

Flexibilidad: si más adelante ves que cierto atributo de producto se usa muchísimo, lo puedes “promocionar” y copiar también a dim_accounts.

https://www.kaggle.com/c/ieee-fraud-detection/data
https://classification.codes/classifications/industry/mcc#version_1_iso-182452023
https://www.bis.org/publ/bcbs239.pdf