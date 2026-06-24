FROM debian:12

ARG ADMINER_PORT

RUN apt-get update && apt-get install -y \
    php php-fpm php-mysqli wget unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/www/html \
    && wget -O /var/www/html/adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php \
    && sed -i "s|listen = /run/php/php8.2-fpm.sock|listen = ${ADMINER_PORT}|g" /etc/php/8.2/fpm/pool.d/www.conf

EXPOSE ${ADMINER_PORT}

CMD ["bash", "-c", "mkdir -p /run/php && exec /usr/sbin/php-fpm8.2 -F"]
