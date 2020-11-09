FROM alpine:3.12 as build

RUN apk add --no-cache --update alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

WORKDIR /usr/src/telegram-bot-api

COPY CMakeLists.txt /usr/src/telegram-bot-api
COPY docker-entrypoint.sh /usr/src/telegram-bot-api
ADD td /usr/src/telegram-bot-api/td
ADD telegram-bot-api /usr/src/telegram-bot-api/telegram-bot-api

RUN mkdir -p build \
 && cd build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. .. \
 && cmake --build . --target install -j $(nproc) \
 && strip /usr/src/telegram-bot-api/bin/telegram-bot-api

FROM alpine:3.12

ENV TELEGRAM_LOGS_DIR="/var/log/telegram-bot-api" \
    TELEGRAM_WORK_DIR="/var/lib/telegram-bot-api" \
    TELEGRAM_TEMP_DIR="/tmp/telegram-bot-api"

RUN apk add --no-cache --update openssl libstdc++ curl
COPY --from=build /usr/src/telegram-bot-api/bin/telegram-bot-api /usr/local/bin/telegram-bot-api
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN addgroup -g 101 -S telegram-bot-api \
 && adduser -S -D -H -u 101 -h ${TELEGRAM_WORK_DIR} -s /sbin/nologin -G telegram-bot-api -g telegram-bot-api telegram-bot-api \
 && chmod +x /docker-entrypoint.sh \
 && mkdir -p ${TELEGRAM_LOGS_DIR} ${TELEGRAM_WORK_DIR} ${TELEGRAM_TEMP_DIR} \
 && chown telegram-bot-api:telegram-bot-api ${TELEGRAM_LOGS_DIR} ${TELEGRAM_WORK_DIR} \
 && chown nobody:nobody /tmp/telegram-bot-api

HEALTHCHECK CMD curl -f http://localhost:8081/ || exit 1
EXPOSE 8081/tcp 8082/tcp
ENTRYPOINT ["/docker-entrypoint.sh"]
