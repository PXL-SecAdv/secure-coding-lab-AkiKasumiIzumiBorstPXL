#!/bin/bash
set -e

DB_USER="${DB_USER:-secadv}"
DB_PASSWORD="${DB_PASSWORD:-ilovesecurity}"
DB_NAME="${DB_NAME:-pxldb}"

echo "Initializing database for user: $DB_USER"

# Schrijf naar /tmp/ i.p.v. de beveiligde docker map
cat <<EOF > /tmp/01-init.sql
\c $DB_NAME

DROP USER IF EXISTS $DB_USER;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

BEGIN;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    user_name TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    password_hashed BOOLEAN DEFAULT FALSE
);

GRANT ALL PRIVILEGES ON TABLE users TO $DB_USER;
GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO $DB_USER;

INSERT INTO users (user_name, password, password_hashed) VALUES
    ('pxl-admin', 'insecureandlovinit', FALSE),
    ('george', 'iwishihadbetteradmins', FALSE);

COMMIT;
EOF

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /tmp/01-init.sql

rm /tmp/01-init.sql

echo "Database initialized successfully!"