#!/bin/bash

set -e

echo "[WordPress] Starting WordPress setup script..."

cd /var/www/html

echo "[WordPress] Waiting for MariaDB to be ready..."
MAX_TRIES=30
COUNT=0
until mariadb -h"${WORDPRESS_DB_HOST%:*}" -u"${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" -e "SELECT 1" &>/dev/null; do
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $MAX_TRIES ]; then
        echo "[WordPress] ERROR: MariaDB did not become ready in time!"
        exit 1
    fi
    echo "[WordPress] Waiting for database... (attempt $COUNT/$MAX_TRIES)"
    sleep 2
done

echo "[WordPress] MariaDB is ready!"

if [ ! -f "wp-config.php" ]; then
    echo "[WordPress] WordPress not found. Installing..."
    
    echo "[WordPress] Downloading WordPress..."
    wp core download --allow-root
    
    echo "[WordPress] Creating wp-config.php..."
    wp config create \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="${WORDPRESS_DB_PASSWORD}" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --allow-root
    
    echo "[WordPress] Installing WordPress..."
    wp core install \
        --url="${WORDPRESS_URL}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --allow-root
    
    echo "[WordPress] WordPress installed successfully!"
    
    echo "[WordPress] Creating regular user: ${WORDPRESS_USER}..."
    wp user create \
        "${WORDPRESS_USER}" \
        "${WORDPRESS_USER_EMAIL}" \
        --user_pass="${WORDPRESS_USER_PASSWORD}" \
        --role=editor \
        --allow-root
    
    echo "[WordPress] Regular user created successfully!"
    
else
    echo "[WordPress] WordPress already installed. Skipping installation."
fi

echo "[WordPress] Setting file permissions..."
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

echo "[WordPress] Setup complete. Starting PHP-FPM..."

exec php-fpm8.2 -F
