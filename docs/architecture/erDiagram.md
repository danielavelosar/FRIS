erDiagram
    FACT_TRANSACTIONS {
        string   transaction_id PK
        timestamp transaction_datetime
        decimal  transaction_amount
        decimal  transactionamountusd
        string   currency_code
        decimal  exchange_rate
        string   transaction_type
        string   channel_code
        boolean  is_fraud
        decimal  fraud_score
        decimal  risk_score
        string   mlmodelversion
        string   authorization_code
        string   response_code
        string   declinereasoncode
        int      processingtimems
        string   network_code
        string   acquirer_id
        string   issuer_id
        string   ip_address
        string   session_id
        string   customer_id FK
        string   account_id FK
        string   card_id FK
        string   merchant_id FK
        string   product_id FK
        int      location_id FK
        int      time_id FK
        string   device_id FK
    }

    FACT_AGENT_DECISIONS {
        string   decision_id PK
        string   transaction_id FK
        string   agent_name
        json     decision_output
        text     reasoning_trace
        string   model_version
        int      execution_time_ms
        int      tokens_used
        decimal  token_cost_usd
        decimal  confidence_score
        timestamp created_at
    }

    FACT_AGENT_DECISION_DOCS {
        string   evidence_id PK
        string   decision_id FK
        string   doc_id FK
        string   chunk_id
        decimal  relevance_score
        text     citation_snippet
        int      retrieval_rank
        timestamp created_at
    }

    DIM_CUSTOMERS {
        string   customer_id PK
        string   customer_number
        string   first_name
        string   last_name
        string   full_name
        string   document_type
        string   document_number
        date     birth_date
        string   age_group
        string   gender
        string   marital_status
        string   education_level
        string   occupation
        string   employment_type
        string   employer_name
        decimal  monthly_income
        string   income_bracket
        string   customer_segment
        string   risk_profile
        int      credit_score
        string   creditscorerange
        date     registration_date
        date     activation_date
        date     lastactivitydate
        string   customer_status
        string   kyc_status
        date     kycverificationdate
        string   amlrisklevel
        boolean  pep_flag
        boolean  blacklist_flag
        boolean  vip_flag
        string   email_domain
        string   phonecountrycode
        string   phoneareacode
        string   preferred_language
        string   preferred_channel
        decimal  churn_probability
        decimal  lifetime_value
        int      total_products
        timestamp created_at
        timestamp updated_at
    }

    DIM_ACCOUNTS {
        string   account_id PK
        string   account_number
        string   account_type
        string   account_subtype
        string   product_name
        date     opening_date
        date     closing_date
        string   account_status
        decimal  credit_limit
        decimal  available_credit
        decimal  current_balance
        decimal  interest_rate
        int      paymentduedate
        decimal  minimum_payment
        int      delinquency_days
        string   delinquency_status
        date     lastpaymentdate
        decimal  lastpaymentamount
        decimal  utilization_rate
        string   branch_code
        string   officer_id
        string   collection_status
        boolean  writeoffflag
        date     writeoffdate
        timestamp created_at
        timestamp updated_at
    }

    DIM_CARDS {
        string   card_id PK
        string   cardnumberhash
        string   cardlast4_digits
        string   card_brand
        string   card_type
        string   card_level
        string   issuing_bank
        date     issue_date
        date     expiry_date
        date     activation_date
        string   card_status
        string   block_reason
        boolean  chip_enabled
        boolean  contactless_enabled
        boolean  international_enabled
        boolean  online_enabled
        boolean  atm_enabled
        decimal  dailylimitpos
        decimal  dailylimitatm
        decimal  monthly_limit
        int      pin_attempts
        date     lastpinchange_date
        int      replacement_count
        boolean  fraud_flag
        timestamp created_at
        timestamp updated_at
    }

    DIM_MERCHANTS {
        string   merchant_id PK
        string   merchant_name
        string   legal_name
        string   merchantcategorycode
        string   mcc_description
        string   industry_category
        string   business_type
        date     registration_date
        string   merchant_status
        string   risk_level
        decimal  fraud_rate
        decimal  chargeback_rate
        decimal  average_ticket
        decimal  monthly_volume
        int      transaction_count
        string   website_url
        string   email_domain
        string   phone_number
        string   tax_id
        string   acquirer_name
        int      terminal_count
        boolean  ecommerceenabled
        boolean  recurring_billing
        boolean  highriskflag
        boolean  pci_compliant
        date     lastreviewdate
        timestamp created_at
        timestamp updated_at
    }

    DIM_PRODUCTS {
        string   product_id PK
        string   product_code
        string   product_name
        string   product_category
        string   product_type
        string   product_family
        date     launch_date
        date     discontinue_date
        string   product_status
        string   target_segment
        decimal  minimum_amount
        decimal  maximum_amount
        decimal  baseinterestrate
        decimal  annual_fee
        text     features
        int      terms_months
        int      graceperioddays
        decimal  penalty_rate
        string   rewards_program
        decimal  profitability_score
        decimal  risk_weight
        timestamp created_at
        timestamp updated_at
    }

    DIM_LOCATIONS {
        int      location_id PK
        string   country_code
        string   country_name
        string   state_code
        string   state_name
        string   city_code
        string   city_name
        string   postal_code
        decimal  latitude
        decimal  longitude
        string   timezone
        string   region
        string   metro_area
        int      population
        decimal  gdppercapita
        string   risk_zone
        string   urban_rural
        int      branch_count
        int      atm_count
        string   competitor_density
        timestamp created_at
        timestamp updated_at
    }

    DIM_TIME {
        int      time_id PK
        date     full_date
        int      year
        int      quarter
        string   quarter_name
        int      month
        string   month_name
        string   month_short
        int      weekofyear
        int      dayofyear
        int      dayofmonth
        int      dayofweek
        string   day_name
        string   day_short
        boolean  is_weekend
        boolean  is_holiday
        string   holiday_name
        boolean  isbusinessday
        int      fiscal_year
        int      fiscal_quarter
        int      fiscal_month
        string   season
        boolean  ismonthend
        boolean  isquarterend
        boolean  isyearend
        int      daysinmonth
        timestamp created_at
        timestamp updated_at
    }

    DIM_DEVICES {
        string   device_id PK
        string   device_fingerprint
        string   device_type
        string   device_brand
        string   device_model
        string   operating_system
        string   os_version
        string   browser_name
        string   browser_version
        string   screen_resolution
        text     user_agent
        boolean  is_mobile
        boolean  is_tablet
        boolean  is_rooted
        boolean  is_emulator
        string   app_version
        string   sdk_version
        string   network_type
        string   carrier_name
        date     firstseendate
        date     lastseendate
        decimal  trust_score
        boolean  fraud_flag
        boolean  blacklist_flag
        timestamp created_at
        timestamp updated_at
    }

    DIM_REGULATORY_DOCS {
        string   doc_id PK
        string   doc_title
        string   doc_type
        string   issuing_body
        date     effective_date
        date     expiration_date
        string   status
        string   s3_path
        string   vector_collection_id
        int      chunk_count
        timestamp last_embedded_at
        text     summary
    }

    FACT_TRANSACTIONS }o--|| DIM_CUSTOMERS       : "customer_id"
    FACT_TRANSACTIONS }o--|| DIM_ACCOUNTS        : "account_id"
    FACT_TRANSACTIONS }o--|| DIM_CARDS           : "card_id"
    FACT_TRANSACTIONS }o--|| DIM_MERCHANTS       : "merchant_id"
    FACT_TRANSACTIONS }o--|| DIM_PRODUCTS        : "product_id"
    FACT_TRANSACTIONS }o--|| DIM_LOCATIONS       : "location_id"
    FACT_TRANSACTIONS }o--|| DIM_TIME            : "time_id"
    FACT_TRANSACTIONS }o--|| DIM_DEVICES         : "device_id"

    FACT_AGENT_DECISIONS }o--|| FACT_TRANSACTIONS : "transaction_id"
    FACT_AGENT_DECISION_DOCS }o--|| FACT_AGENT_DECISIONS : "decision_id"
    FACT_AGENT_DECISION_DOCS }o--|| DIM_REGULATORY_DOCS  : "doc_id"
