-- Postgre init script

-- Create user (using DO block to handle "user already exists" error)
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'fhir_app_user') THEN

      CREATE USER fhir_app_user WITH PASSWORD 'password';
   END IF;
END
$do$;

-- Create FHIR schema and assign ownership to the application user
CREATE SCHEMA IF NOT EXISTS fhir_data AUTHORIZATION fhir_app_user;

-- Grant all necessary permissions to the application user on their schema
GRANT ALL PRIVILEGES ON SCHEMA fhir_data TO fhir_app_user;

-- Set default privileges so future objects created in the schema belong to fhir_app_user
ALTER DEFAULT PRIVILEGES IN SCHEMA fhir_data GRANT ALL ON TABLES TO fhir_app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA fhir_data GRANT ALL ON SEQUENCES TO fhir_app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA fhir_data GRANT ALL ON FUNCTIONS TO fhir_app_user;

-- Create additional schemas if needed
-- CREATE SCHEMA IF NOT EXISTS another_schema AUTHORIZATION fhir_app_user;

-- Grant permissions on additional schemas
-- GRANT ALL PRIVILEGES ON SCHEMA another_schema TO fhir_app_user;

-- Set search path for the application user (optional but recommended)
ALTER USER fhir_app_user SET search_path = fhir_data, public;
-- add additional schemas here if created