-- Initialize the Legisense database
-- This script runs when the PostgreSQL container starts for the first time

-- Create extensions if they don't exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create additional databases if needed
-- CREATE DATABASE legisense_test;

-- Set timezone
SET timezone = 'UTC';

-- Create any additional users or roles if needed
-- CREATE USER legisense_readonly WITH PASSWORD 'readonly_password';
-- GRANT CONNECT ON DATABASE legisense TO legisense_readonly;
-- GRANT USAGE ON SCHEMA public TO legisense_readonly;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO legisense_readonly;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO legisense_readonly;
