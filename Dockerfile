FROM cr.loongnix.cn/loongson/loongnix:20

ARG COMPOSE_VERSION=v2.10.2

ENV COMPOSE_VERSION=${COMPOSE_VERSION}

RUN set -ex; \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    apt-get update; \
    apt-get install -y golang-1.18 git file make

RUN set -ex; \
    git clone -b ${COMPOSE_VERSION} https://github.com/docker/compose /opt/compose

WORKDIR /opt/compose

ENV GOPROXY=https://goproxy.io \
    GOFLAGS=-mod=vendor \
    CGO_ENABLED=0 \
    PATH=/usr/lib/go-1.18/bin:$PATH

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

VOLUME /dist

CMD cp -rf dist/* /dist/
