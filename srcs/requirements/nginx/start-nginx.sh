#!/bin/bash

set -e 

echo "[NGINX] Starting NGINX setup script..."

SSL_DIR="/etc/nginx/ssl"
SSL_CERT="${SSL_DIR}/nginx.crt"
SSL_KEY="${SSL_DIR}/nginx.key"

mkdir -p "${SSL_DIR}"

if [ ! -f "${SSL_CERT}" ] || [ ! -f "${SSL_KEY}" ]; then
    echo "[NGINX] Generating self-signed SSL certificate..."
    
    openssl req -x509 \
        -nodes \
        -days 365 \
        -newkey rsa:2048 \
        -keyout "${SSL_KEY}" \
        -out "${SSL_CERT}" \
        -subj "/C=BR/ST=SaoPaulo/L=SaoPaulo/O=42SP/OU=Inception/CN=fdorea.42.fr"
    
    echo "[NGINX] SSL certificate generated successfully!"
    echo "[NGINX] Certificate: ${SSL_CERT}"
    echo "[NGINX] Private Key: ${SSL_KEY}"
else
    echo "[NGINX] SSL certificate already exists. Skipping generation."
fi

chmod 600 "${SSL_KEY}"
chmod 644 "${SSL_CERT}"

echo "[NGINX] Testing NGINX configuration..."
nginx -t

echo "[NGINX] Configuration is valid!"
echo "[NGINX] Starting NGINX server..."

exec nginx -g 'daemon off;'
