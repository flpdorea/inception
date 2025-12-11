FROM debian:bookworm

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
  nginx \
  openssl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY wordpress-https.conf /etc/nginx/sites-available/default

COPY start-nginx.sh /usr/local/bin/start-nginx.sh

RUN chmod +x /usr/local/bin/start-nginx.sh

RUN mkdir -p /etc/nginx/ssl

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/start-nginx.sh"]
