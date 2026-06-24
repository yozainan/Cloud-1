FROM debian:12

ARG WORDPRESS_PORT

RUN apt-get update -y \
    && apt-get install \
    php${PHP_VERSION:-8.2}-fpm \
    php${PHP_VERSION:-8.2}-mysql \
    php${PHP_VERSION:-8.2}-cli \
    php${PHP_VERSION:-8.2}-curl \
    php${PHP_VERSION:-8.2}-gd \
    php${PHP_VERSION:-8.2}-mbstring \
    php${PHP_VERSION:-8.2}-xml \
    php${PHP_VERSION:-8.2}-zip \
    default-mysql-client \
    php-redis \
    net-tools \
    curl \
    wget \
    tini -y \
    && rm -rf /var/lib/apt/lists/*


COPY ./tools/start.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/start.sh

EXPOSE ${WORDPRESS_PORT}

CMD ["bash" , "/usr/local/bin/start.sh"]