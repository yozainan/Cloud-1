FROM debian:12

ARG MARIADB_PORT

RUN apt-get update \
    && apt-get install -y mariadb-server \
    && rm -rf /var/lib/mysql/* \
    && rm -rf /var/lib/apt/lists/*

COPY ./tools/50-server.cnf   /etc/mysql/mariadb.conf.d/50-server.cnf
COPY ./tools/start.sh       /usr/local/bin/

RUN chmod +x /usr/local/bin/start.sh

EXPOSE ${MARIADB_PORT}

CMD ["bash", "/usr/local/bin/start.sh"]

