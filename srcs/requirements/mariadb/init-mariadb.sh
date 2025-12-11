#!/bin/bash

set -e

echo "[MariaDB] Starting MariaDB initialization script..."

if [ ! -f "/var/lib/mysql/.init-complete" ]; then
    echo "[MariaDB] Data directory not found. Initializing MariaDB..."
    
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    echo "[MariaDB] Database system tables installed."
    
    echo "[MariaDB] Starting temporary MariaDB instance for configuration..."
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    MYSQL_PID=$!
    
    echo "[MariaDB] Waiting for MariaDB to be ready..."
    until mysqladmin ping --silent; do
        echo "[MariaDB] Waiting for database to start..."
        sleep 1
    done
    
    echo "[MariaDB] MariaDB is ready. Running initialization SQL commands..."
    
    mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    
    echo "[MariaDB] Database '${MYSQL_DATABASE}' created."
    echo "[MariaDB] User '${MYSQL_USER}' created and granted privileges."
    echo "[MariaDB] Root password set."
    
    echo "[MariaDB] Stopping temporary MariaDB instance..."
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $MYSQL_PID
    
    touch /var/lib/mysql/.init-complete
    
    echo "[MariaDB] Initialization complete."
else
    echo "[MariaDB] Database already initialized. Skipping setup."
fi

echo "[MariaDB] Starting MariaDB server..."

exec mysqld --user=mysql --datadir=/var/lib/mysql
