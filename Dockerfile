from cr.loongnix.cn/loongson/loongnix:20 as build
WORKDIR /opt
ARG CRYPTOGRAPHY_VERSION=36.0.1
ENV CRYPTOGRAPHY_VERSION=${CRYPTOGRAPHY_VERSION}

COPY config /root/.cargo/config

RUN set -ex \
    && apt-get update \
    && apt-get install -y git \
    && apt-get install -y python3.7 python3.7-dev python3-pip python3-venv docker-ce-cli cargo \
    && apt-get install --no-install-recommends -y curl wget gcc libc-dev libffi-dev libgcc-8-dev libssl-dev make openssl zlib1g-dev \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/*

RUN set -ex \
    && python3 -m venv /opt/py3 \
    && . /opt/py3/bin/activate \
    && pip install --upgrade pip \
    && pip install --upgrade setuptools \
    && pip install --upgrade wheel \
    && pip download cryptography==${CRYPTOGRAPHY_VERSION} \
    && tar -xf cryptography-${CRYPTOGRAPHY_VERSION}.tar.gz \
    && cd /opt/cryptography-${CRYPTOGRAPHY_VERSION} \
    && sed -i 's@checksum = "fbe5e23404da5b4f555ef85ebed98fb4083e55a00c317800bc2a50ede9f3d219"@# checksum = "fbe5e23404da5b4f555ef85ebed98fb4083e55a00c317800bc2a50ede9f3d219"@g' src/rust/Cargo.lock \
    && pip wheel --wheel-dir=/opt/wheels ./ \
    && pip install /opt/wheels/$(ls /opt/wheels/ | grep cryptography)

from cr.loongnix.cn/loongson/loongnix:20
ARG COMPOSE_VERSION=1.29.2
ENV COMPOSE_VERSION=${COMPOSE_VERSION}

RUN set -ex \
    && apt-get update \
    && apt-get install -y git \
    && apt-get install -y python3.7 python3.7-dev python3-pip python3-venv docker-ce-cli cargo \
    && apt-get install --no-install-recommends -y curl wget gcc libc-dev libffi-dev libgcc-8-dev libssl-dev make openssl zlib1g-dev \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/*

RUN set -ex \
    && git clone -b ${COMPOSE_VERSION} https://github.com/docker/compose /code

WORKDIR /code

COPY --from=build /opt/wheels /tmp/wheels

RUN set -ex \
    && python3 -m venv /opt/py3 \
    && . /opt/py3/bin/activate \
    && pip install wheel \
    && pip install /tmp/wheels/$(ls /tmp/wheels/ | grep cryptography) \
    && pip install -r requirements.txt -r requirements-dev.txt \
    && pip install pyinstaller \
    && rm -rf ~/.cache/pip

RUN set -ex \
    && echo "$(script/build/write-git-sha)" > compose/GITSHA \
    && . /opt/py3/bin/activate \
    && pyinstaller docker-compose.spec \
    && mv dist/docker-compose "dist/docker-compose-Linux-$(uname -m)" \
    && chmod 755 "dist/docker-compose-Linux-$(uname -m)" \
    && echo "$(md5sum dist/docker-compose-Linux-$(uname -m) | awk '{print $1}')" > "dist/docker-compose-Linux-$(uname -m).md5"

VOLUME /dist

CMD cp -rf dist/* /dist/
