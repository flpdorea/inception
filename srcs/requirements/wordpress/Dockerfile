FROM debian:bookworm

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
  php8.2-fpm \
  php8.2-mysql \
  php8.2-curl \
  php8.2-gd \
  php8.2-mbstring \
  php8.2-xml \
  php8.2-xmlrpc \
  php8.2-zip \
  php8.2-intl \
  curl \
  mariadb-client \
  less && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
  chmod +x wp-cli.phar && \
  mv wp-cli.phar /usr/local/bin/wp

COPY php-fpm-pool.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY setup-wordpress.sh /usr/local/bin/setup-wordpress.sh

RUN chmod +x /usr/local/bin/setup-wordpress.sh

RUN mkdir -p /var/www/html && \
  chown -R www-data:www-data /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup-wordpress.sh"]
