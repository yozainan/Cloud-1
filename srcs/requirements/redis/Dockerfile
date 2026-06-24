FROM debian:12

ARG REDIS_PORT

COPY tools/start.sh /usr/local/bin/install_redis.sh
RUN chmod +x /usr/local/bin/install_redis.sh \
    && /usr/local/bin/install_redis.sh

EXPOSE ${REDIS_PORT}

CMD ["redis-server", "--protected-mode", "no"]
