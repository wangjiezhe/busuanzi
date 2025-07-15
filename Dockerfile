FROM docker.m.daocloud.io/golang:1.22-alpine AS builder
WORKDIR /app

ENV GOPROXY=https://goproxy.cn,direct
COPY . .
RUN set -evx -o pipefail        \
    && apk update               \
    && apk add --no-cache git   \
    && rm -rf /var/cache/apk/*  \
    && go build -ldflags="-s -w" -o busuanzi main.go

FROM docker.m.daocloud.io/node:21-alpine AS ts-builder
WORKDIR /app
COPY ./dist .
RUN set -evx -o pipefail        \
    && npm install -g pnpm      \
    && pnpm install             \
    && pnpm run build           \
    && rm -rf node_modules      \
    && rm -rf pnpm-lock.yaml    \
    && rm -rf tsconfig.json

FROM docker.m.daocloud.io/alpine:3.16
WORKDIR /app

COPY --from=builder /app/busuanzi /app
COPY --from=ts-builder /app /app/dist
COPY --from=builder /app/config.yaml /app/config.yaml
COPY --from=builder /app/entrypoint.sh /app

RUN chmod +x /app/entrypoint.sh

EXPOSE 8080
ENTRYPOINT  [ "sh", "entrypoint.sh" ]
