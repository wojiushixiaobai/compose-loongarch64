FROM golang:1.21-buster as builder

ARG COMPOSE_VERSION=v2.26.0

ENV COMPOSE_VERSION=${COMPOSE_VERSION}

RUN set -ex; \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    apt-get update; \
    apt-get install -y git file make

RUN set -ex; \
    git clone -b ${COMPOSE_VERSION} https://github.com/docker/compose /opt/compose --depth=1

WORKDIR /opt/compose

ENV GOFLAGS=-mod=vendor \
    CGO_ENABLED=0

RUN set -ex; \
    go mod download -x; \
    go mod tidy; \
    go mod vendor; \
    PKG=github.com/docker/compose/v2 VERSION=$(git describe --match 'v[0-9]*' --dirty='.m' --always --tags); \
    echo "-X ${PKG}/internal.Version=${VERSION}" | tee /tmp/.ldflags; \
    echo -n "${VERSION}" | tee /tmp/.version

RUN set -ex; \
    mkdir /opt/compose/dist; \
    go build -trimpath -tags "$BUILD_TAGS" -ldflags "$(cat /tmp/.ldflags) -w -s" -o /opt/compose/dist/docker-compose ./cmd; \
    cd /opt/compose/dist; \
    mv docker-compose docker-compose-linux-$(uname -m); \
    sha256sum docker-compose-linux-loongarch64 > /tmp/checksums.txt; \
    cat /tmp/checksums.txt | while read sum file; do echo "$sum *$file" > ${file#\*}.sha256; done

FROM debian:buster-slim

WORKDIR /opt/compose

COPY --from=builder /opt/compose/dist /opt/compose/dist

VOLUME /dist

CMD cp -rf dist/* /dist/
