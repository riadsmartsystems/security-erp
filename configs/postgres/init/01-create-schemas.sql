-- =============================================================================
-- Security ERP Platform - PostgreSQL Initialization
-- Creates 5 schemas with isolated users per service
-- =============================================================================

-- Create schemas
CREATE SCHEMA IF NOT EXISTS fsm;
CREATE SCHEMA IF NOT EXISTS cmdb;
CREATE SCHEMA IF NOT EXISTS ai;
CREATE SCHEMA IF NOT EXISTS integration;
CREATE SCHEMA IF NOT EXISTS audit;

-- Create service users
CREATE USER fsm_user WITH PASSWORD 'fsm_secret';
CREATE USER cmdb_user WITH PASSWORD 'cmdb_secret';
CREATE USER ai_user WITH PASSWORD 'ai_secret';
CREATE USER integration_user WITH PASSWORD 'integration_secret';
CREATE USER audit_user WITH PASSWORD 'audit_secret';

-- Grant schema permissions
GRANT USAGE ON SCHEMA fsm TO fsm_user;
GRANT CREATE ON SCHEMA fsm TO fsm_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA fsm GRANT ALL ON TABLES TO fsm_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA fsm GRANT ALL ON SEQUENCES TO fsm_user;

GRANT USAGE ON SCHEMA cmdb TO cmdb_user;
GRANT CREATE ON SCHEMA cmdb TO cmdb_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA cmdb GRANT ALL ON TABLES TO cmdb_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA cmdb GRANT ALL ON SEQUENCES TO cmdb_user;

GRANT USAGE ON SCHEMA ai TO ai_user;
GRANT CREATE ON SCHEMA ai TO ai_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA ai GRANT ALL ON TABLES TO ai_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA ai GRANT ALL ON SEQUENCES TO ai_user;

GRANT USAGE ON SCHEMA integration TO integration_user;
GRANT CREATE ON SCHEMA integration TO integration_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA integration GRANT ALL ON TABLES TO integration_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA integration GRANT ALL ON SEQUENCES TO integration_user;

GRANT USAGE ON SCHEMA audit TO audit_user;
GRANT CREATE ON SCHEMA audit TO audit_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT ALL ON TABLES TO audit_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT ALL ON SEQUENCES TO audit_user;

-- Grant CREATE on public schema for ENUM types (SQLAlchemy requirement)
GRANT CREATE ON SCHEMA public TO fsm_user;
GRANT CREATE ON SCHEMA public TO cmdb_user;
GRANT CREATE ON SCHEMA public TO ai_user;
GRANT CREATE ON SCHEMA public TO integration_user;
GRANT CREATE ON SCHEMA public TO audit_user;

-- Set search_path for each user
ALTER USER fsm_user SET search_path TO fsm, public;
ALTER USER cmdb_user SET search_path TO cmdb, public;
ALTER USER ai_user SET search_path TO ai, public;
ALTER USER integration_user SET search_path TO integration, public;
ALTER USER audit_user SET search_path TO audit, public;

-- Grant postgres user access to all schemas (for migrations)
GRANT ALL PRIVILEGES ON SCHEMA fsm TO postgres;
GRANT ALL PRIVILEGES ON SCHEMA cmdb TO postgres;
GRANT ALL PRIVILEGES ON SCHEMA ai TO postgres;
GRANT ALL PRIVILEGES ON SCHEMA integration TO postgres;
GRANT ALL PRIVILEGES ON SCHEMA audit TO postgres;
