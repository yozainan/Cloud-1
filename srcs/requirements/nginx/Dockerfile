FROM debian:12

ARG NGINX_PORT

RUN apt-get update \
    && apt-get install -y nginx openssl procps \
    && rm -rf /var/lib/apt/lists/*

COPY ./tools/start.sh       /usr/local/bin/
COPY ./tools/default.conf   /etc/nginx/conf.d/default.conf

RUN chmod +x /usr/local/bin/start.sh

EXPOSE ${NGINX_PORT}

CMD ["bash", "/usr/local/bin/start.sh"]
