-- =====================================================================
-- DIM_TIME - Time Dimension Table
-- =====================================================================
-- Purpose: Calendar dimension for time-based analysis
-- Grain: One row per calendar date
-- =====================================================================

CREATE TABLE dim.dim_time (
    -- Primary Key
    time_id INTEGER PRIMARY KEY,

    -- Date Attributes
    full_date DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL CHECK (quarter BETWEEN 1 AND 4),
    quarter_name VARCHAR(10) NOT NULL,
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    month_name VARCHAR(20) NOT NULL,
    month_short VARCHAR(3) NOT NULL,
    weekofyear INTEGER NOT NULL CHECK (weekofyear BETWEEN 1 AND 53),
    dayofyear INTEGER NOT NULL CHECK (dayofyear BETWEEN 1 AND 366),
    dayofmonth INTEGER NOT NULL CHECK (dayofmonth BETWEEN 1 AND 31),
    dayofweek INTEGER NOT NULL CHECK (dayofweek BETWEEN 1 AND 7),
    day_name VARCHAR(20) NOT NULL,
    day_short VARCHAR(3) NOT NULL,

    -- Calendar Flags
    is_weekend BOOLEAN NOT NULL DEFAULT FALSE,
    is_holiday BOOLEAN NOT NULL DEFAULT FALSE,
    holiday_name VARCHAR(100),
    isbusinessday BOOLEAN NOT NULL DEFAULT TRUE,

    -- Fiscal Calendar
    fiscal_year INTEGER NOT NULL,
    fiscal_quarter INTEGER NOT NULL CHECK (fiscal_quarter BETWEEN 1 AND 4),
    fiscal_month INTEGER NOT NULL CHECK (fiscal_month BETWEEN 1 AND 12),
    season VARCHAR(20),

    -- Period End Flags
    ismonthend BOOLEAN NOT NULL DEFAULT FALSE,
    isquarterend BOOLEAN NOT NULL DEFAULT FALSE,
    isyearend BOOLEAN NOT NULL DEFAULT FALSE,
    daysinmonth INTEGER NOT NULL CHECK (daysinmonth BETWEEN 28 AND 31),

    -- Audit Fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_dim_time_full_date ON dim.dim_time(full_date);
CREATE INDEX idx_dim_time_year_month ON dim.dim_time(year, month);
CREATE INDEX idx_dim_time_is_weekend ON dim.dim_time(is_weekend);
CREATE INDEX idx_dim_time_is_holiday ON dim.dim_time(is_holiday);

-- Comments
COMMENT ON TABLE dim.dim_time IS 'Time dimension table for calendar-based analysis with fiscal periods and business day flags';
COMMENT ON COLUMN dim.dim_time.time_id IS 'Surrogate key for time dimension (format: YYYYMMDD as integer)';
COMMENT ON COLUMN dim.dim_time.full_date IS 'Actual calendar date';
COMMENT ON COLUMN dim.dim_time.isbusinessday IS 'True if date is a business day (not weekend or holiday)';
