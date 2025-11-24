-- =====================================================================
-- DIM_DEVICES - Device Dimension Table
-- =====================================================================
-- Purpose: Device fingerprinting for fraud detection and security
-- Grain: One row per unique device fingerprint
-- =====================================================================

CREATE TABLE dim.dim_devices (
    -- Primary Key
    device_id VARCHAR(50) PRIMARY KEY,

    -- Device Fingerprint (Business Key)
    device_fingerprint VARCHAR(128) NOT NULL UNIQUE,

    -- Device Classification
    device_type VARCHAR(50),
    device_brand VARCHAR(100),
    device_model VARCHAR(100),

    -- Operating System
    operating_system VARCHAR(50),
    os_version VARCHAR(50),

    -- Browser Information
    browser_name VARCHAR(50),
    browser_version VARCHAR(50),
    screen_resolution VARCHAR(20),
    user_agent TEXT,

    -- Device Flags
    is_mobile BOOLEAN DEFAULT FALSE,
    is_tablet BOOLEAN DEFAULT FALSE,
    is_rooted BOOLEAN DEFAULT FALSE,
    is_emulator BOOLEAN DEFAULT FALSE,

    -- Application Information
    app_version VARCHAR(50),
    sdk_version VARCHAR(50),

    -- Network Information
    network_type VARCHAR(50),
    carrier_name VARCHAR(100),

    -- Temporal Tracking
    firstseendate DATE NOT NULL,
    lastseendate DATE NOT NULL,

    -- Security & Risk
    trust_score NUMERIC(5, 4) CHECK (trust_score BETWEEN 0 AND 1),
    fraud_flag BOOLEAN DEFAULT FALSE,
    blacklist_flag BOOLEAN DEFAULT FALSE,

    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_seen_dates CHECK (lastseendate >= firstseendate)
);

-- Indexes
CREATE UNIQUE INDEX idx_dim_devices_fingerprint ON dim.dim_devices(device_fingerprint);
CREATE INDEX idx_dim_devices_type ON dim.dim_devices(device_type);
CREATE INDEX idx_dim_devices_fraud ON dim.dim_devices(fraud_flag) WHERE fraud_flag = TRUE;
CREATE INDEX idx_dim_devices_blacklist ON dim.dim_devices(blacklist_flag) WHERE blacklist_flag = TRUE;
CREATE INDEX idx_dim_devices_rooted ON dim.dim_devices(is_rooted) WHERE is_rooted = TRUE;
CREATE INDEX idx_dim_devices_emulator ON dim.dim_devices(is_emulator) WHERE is_emulator = TRUE;
CREATE INDEX idx_dim_devices_trust ON dim.dim_devices(trust_score);
CREATE INDEX idx_dim_devices_last_seen ON dim.dim_devices(lastseendate);

-- Comments
COMMENT ON TABLE dim.dim_devices IS 'Device dimension for fraud detection with fingerprinting, security flags, and trust scores';
COMMENT ON COLUMN dim.dim_devices.device_fingerprint IS 'Unique device identifier generated from device attributes (browser, OS, screen, etc.)';
COMMENT ON COLUMN dim.dim_devices.is_rooted IS 'True if device has been rooted/jailbroken (security risk)';
COMMENT ON COLUMN dim.dim_devices.is_emulator IS 'True if device appears to be an emulator (fraud risk)';
COMMENT ON COLUMN dim.dim_devices.trust_score IS 'Device trust score from 0 (untrusted) to 1 (fully trusted)';
COMMENT ON COLUMN dim.dim_devices.blacklist_flag IS 'True if device has been blacklisted due to fraudulent activity';
