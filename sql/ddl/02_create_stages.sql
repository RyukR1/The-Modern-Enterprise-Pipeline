-- ============================================================================
-- Snowflake File Formats & Stage Definitions
-- ============================================================================

USE DATABASE RAW_DB;
USE SCHEMA BRONZE;

-- Create File Formats
CREATE OR REPLACE FILE FORMAT json_file_format
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    ENABLE_OCTAL = FALSE
    ALLOW_DUPLICATE = FALSE
    STRIP_NULL_VALUES = FALSE
    IGNORE_UTF8_ERRORS = FALSE;

CREATE OR REPLACE FILE FORMAT csv_file_format
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', '')
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- Create Internal Snowflake Stage for API Data Ingestion
CREATE OR REPLACE STAGE RAW_S3_STAGE
    FILE_FORMAT = json_file_format
    COMMENT = 'Stage for staging raw REST API JSON payloads';
