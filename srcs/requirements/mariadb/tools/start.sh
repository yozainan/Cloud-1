#!/bin/bash
set -e
set -x # for debugging

if [ -z "${MARIADB_DATABASE}" ] || [ -z "${MARIADB_USER_NAME}" ] || [ -z "${MARIADB_USER_PASSWORD}" ] || [ -z "${MARIADB_ROOT_PASSWORD}" ]; then
  echo "[mariadb] ERROR: Required environment variables are missing."
  exit 1
fi

DATA_DIR="/var/lib/mysql"
RUN_DIR="/run/mysqld"

mkdir -p "${RUN_DIR}"
chown -R mysql:mysql "${RUN_DIR}"

if [ ! -d "${DATA_DIR}/mysql" ]; then
  echo "[mariadb] First run detected — initializing data directory..."
  mysql_install_db --user=mysql --datadir="${DATA_DIR}" > /dev/null
  chown -R mysql:mysql "${DATA_DIR}"

  echo "[mariadb] Bootstrapping database and user..."

  mysqld --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
  MYSQL_PID=$!

  # Wait until the socket is ready
  RETRIES=30
  until mysqladmin --socket=/run/mysqld/mysqld.sock ping --silent 2>/dev/null; do
    RETRIES=$((RETRIES - 1))
    if [ "${RETRIES}" -eq 0 ]; then
      echo "[mariadb] ERROR: timed out waiting for temporary instance"
      exit 1
    fi
    sleep 0.5
  done

  mysql --socket=/run/mysqld/mysqld.sock -u root << EOF
FLUSH PRIVILEGES;
DELETE FROM mysql.user WHERE user='';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';

/* Remove the default test database */
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MARIADB_USER_NAME}'@'%' IDENTIFIED BY '${MARIADB_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER_NAME}'@'%';
FLUSH PRIVILEGES;
EOF

  # Shut down the temporary instance
  mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${MARIADB_ROOT_PASSWORD}" shutdown
  wait "${MYSQL_PID}"
  echo "[mariadb] Bootstrap complete."
fi

echo "[mariadb] Starting MariaDB..."
exec mysqld --user=mysql