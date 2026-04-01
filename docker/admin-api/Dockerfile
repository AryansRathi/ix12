FROM debian:trixie-slim AS build-base

ARG IX_VERSION=latest
ARG INTREXX_ARCHIVE=intrexx.tar.gz

# Make steps fail on error
RUN apt-get update && apt-get install -y bash
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN apt-get update && apt-get install -y \
        curl gnupg ca-certificates binutils

WORKDIR /verify

# Download setup and signature
RUN if [ "${IX_VERSION}" = "latest" ]; then \
        url="https://download.intrexx.com/intrexx/rolling/steady/intrexx-steady-linux.tar.gz"; \
    else \
        url="https://download.intrexx.com/intrexx/rolling/steady/${IX_VERSION}/intrexx-${IX_VERSION}-linux.tar.gz"; \
    fi; \
    curl -fsSL ${url} -o ${INTREXX_ARCHIVE} && \
    curl -fsSL ${url}.asc -o ${INTREXX_ARCHIVE}.asc

# Verify signature
RUN gpg --receive-keys 8679D1BAA7DFA01ED8C39CF46830D53CA20CE310 && \
    gpg --verify ${INTREXX_ARCHIVE}.asc ${INTREXX_ARCHIVE}

# Extract setup
RUN mkdir /out && \
    tar -xzf ${INTREXX_ARCHIVE} -C /out --strip-components=1

WORKDIR /out

# Build JRE
RUN JAVA_HOME=java/packaged/linux/amd64; \
    java/packaged/linux/amd64/bin/jlink \
        --strip-debug \
        --no-man-pages \
        --no-header-files \
        --compress=zip-6 \
        --add-modules ALL-MODULE-PATH \
        --output /opt/java/openjdk && \
    mkdir -p /opt/intrexx/java && ln -snf /opt/java/openjdk /opt/intrexx/java/current

FROM debian:trixie-slim AS build

# Copy admin-api
COPY --from=build-base /opt/intrexx/java /opt/intrexx/java
COPY --from=build-base /out/admin-api /opt/intrexx/admin-api
COPY --from=build-base /out/*.version /opt/intrexx/

# Copy customizations
COPY services/admin-api/cfg/admin-api.yaml.template /opt/intrexx/admin-api/cfg/
COPY --chmod=0755 services/admin-api/bin/linux/admin-api.sh /opt/intrexx/admin-api/bin/linux/
COPY --chmod=0755 services/admin-api/bin/linux/createcertificate.sh /opt/intrexx/admin-api/bin/linux/

FROM debian:trixie-slim AS runtime-base

ENV JAVA_HOME=/opt/java/openjdk
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=${JAVA_HOME}/bin:${PATH} \
    PORTAL_NAME=portal \
    PORTAL_HOST=intrexx \
    PORTAL_API_PORT=8101 \
    PORTAL_API_SCHEME=https \
    PORTAL_ADMIN_USER=Administrator \
    PORTAL_ADMIN_PW=NONE \
    IAA_USER=iaa-admin \
    IAA_PW=P4\$\$w0rD \
    IAA_DEBUG_MODE=false \
    CACERTS_FILE=cacerts \
    CACERTS_PW=changeit \
    IAA_SECRET=changeit \
    IAA_USE_SSL=true \
    IAA_LICENSE=NONE

# Copy entrypoint
COPY --chmod=0755 docker/admin-api/docker-entrypoint.sh /usr/local/bin/
COPY --chmod=0755 docker/admin-api/docker-entrypoint.d /docker-entrypoint.d

# Copy JRE
COPY --from=build-base /opt/java /opt/java

# Install additional software
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gettext-base; \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["docker-entrypoint.sh"]

FROM runtime-base AS rootful

COPY --from=build /opt/intrexx /opt/intrexx

FROM runtime-base AS rootless
ARG USER_GID=1000
ARG USER_UID=1000

RUN groupadd --gid ${USER_GID} intrexx && \
    useradd --no-log-init --uid ${USER_UID} --gid ${USER_GID} --shell /usr/sbin/nologin --home-dir /opt/intrexx intrexx

COPY --from=build --chown=${USER_UID}:${USER_GID} /opt/intrexx /opt/intrexx

WORKDIR /opt/intrexx

USER intrexx

# --- Default
FROM rootful AS final