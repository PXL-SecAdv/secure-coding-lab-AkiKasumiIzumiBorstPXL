#!/bin/bash
set -e
DB_USER="${DB_USER:-secadv}"
DB_PASSWORD="${DB_PASSWORD:-ilovesecurity}"
DB_NAME="${DB_NAME:-pxldb}"

echo "Initializing database for user: $DB_USER"

cat <<EOF > /docker-entrypoint-initdb.d/01-create-user-and-db.sql
-- Create the database
CREATE DATABASE $DB_NAME;

-- Connect to the database
\c $DB_NAME

-- Create the user with the secure password from env
DROP USER IF EXISTS $DB_USER;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

BEGIN;

-- Create the users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    user_name TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    password_hashed BOOLEAN DEFAULT FALSE
);

GRANT ALL PRIVILEGES ON TABLE users TO $DB_USER;
GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO $DB_USER;

-- Insert test users (PLAINTEXT for lazy migration)
INSERT INTO users (user_name, password, password_hashed) VALUES 
    ('pxl-admin', 'insecureandlovinit', FALSE),
    ('george', 'iwishihadbetteradmins', FALSE);

COMMIT;
EOF

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/01-create-user-and-db.sql

rm /docker-entrypoint-initdb.d/01-create-user-and-db.sql