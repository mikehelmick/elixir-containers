FROM elixir:1.6.6-alpine

ARG APP_NAME=concurrentCount
ARG PHOENIX_SUBDIR=.
ENV MIX_ENV=prod REPLACE_OS_VARS=true TERM=xterm
WORKDIR /opt/app
RUN apk update \
    && apk --no-cache --update add nodejs nodejs-npm \
    && mix local.rebar --force \
    && mix local.hex --force
COPY . .

RUN mix do deps.get, deps.compile, compile
RUN cd ${PHOENIX_SUBDIR}/assets \
    && npm install \
    && ./node_modules/brunch/bin/brunch build -p \
    && cd .. \
    && mix phx.digest
RUN mix release --env=prod --verbose \
    && mv _build/prod/rel/${APP_NAME} /opt/release \
    && mv /opt/release/bin/${APP_NAME} /opt/release/bin/start_server

FROM alpine:latest
RUN apk update && apk --no-cache --update add bash openssl-dev


RUN addgroup -g 1000 appuser && \
    adduser -S -u 1000 -G appuser appuser

RUN mkdir -p /opt/app/var
RUN chown appuser /opt/app/var

USER appuser

ENV PORT=8080 MIX_ENV=prod REPLACE_OS_VARS=true
WORKDIR /opt/app
EXPOSE 8080
COPY --from=0 /opt/release .
## ENV RELEASE_MUTABLE_DIR /tmp
## ENV RUNNER_LOG_DIR /var/log
CMD ["/opt/app/bin/start_server", "foreground"]
