FROM debian:bookworm

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
  mariadb-server \
  mariadb-client && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY mariadb-network.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY init-mariadb.sh /usr/local/bin/init-mariadb.sh

RUN chmod +x /usr/local/bin/init-mariadb.sh

RUN mkdir -p /run/mysqld && \
  chown -R mysql:mysql /run/mysqld

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init-mariadb.sh"]
