#!/bin/sh

mkdir -p /run/postgresql
chown -R postgres:postgres /run/postgresql

mkdir -p /var/lib/postgresql/data
chown -R postgres:postgres /var/lib/postgresql

su postgres -c 'initdb -D /var/lib/postgresql/data'
su postgres -c 'pg_ctl start -D /var/lib/postgresql/data'

if ! psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$POSTGRES_DB"; then
  echo "Database '$POSTGRES_DB' does not exist yet. Creating database. ⏳"

  psql -U postgres -c "CREATE DATABASE $POSTGRES_DB;"

  echo "Created database '$POSTGRES_DB'. ✅"
else
  echo "Database '$POSTGRES_DB' already exists. ✅"
fi

if psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER'" | grep -q 1; then
  echo "Database user '$POSTGRES_USER' already exists. ✅"
else
  echo "Database user '$POSTGRES_USER' does not exist yet. Creating user. ⏳"

  psql -U postgres -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';"
  psql -U postgres -c "ALTER USER $POSTGRES_USER WITH SUPERUSER;"

  echo "Created database user '$POSTGRES_USER'. ✅"
fi

echo "Starting Umami server. ⏳"
yarn start-docker
