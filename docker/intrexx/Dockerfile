FROM debian:trixie-slim AS build-base

ARG IX_VERSION=latest
ARG INTREXX_ARCHIVE=intrexx.tar.gz

# Make steps fail on error
RUN apt-get update && apt-get install -y bash
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN apt-get update && apt-get install -y \
        curl gnupg ca-certificates binutils

WORKDIR /verify

# Download intrexx setup and signature
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

# Copy intrexx resources
COPY --from=build-base /out/*.version /opt/intrexx/
COPY --from=build-base /opt/intrexx/java /opt/intrexx/java
COPY --from=build-base /out/cfg /opt/intrexx/cfg
COPY --from=build-base /out/log /opt/intrexx/log
COPY --from=build-base /out/tmp /opt/intrexx/tmp
COPY --from=build-base /out/xml /opt/intrexx/xml
COPY --from=build-base /out/admin /opt/intrexx/admin
COPY --from=build-base /out/tika /opt/intrexx/tika
COPY --from=build-base /out/lib /opt/intrexx/lib
COPY --from=build-base /out/bin/docker /opt/intrexx/bin/linux
COPY --from=build-base \
     /out/installer/lic* \
     /out/installer/*.properties \
     /opt/intrexx/installer/
COPY --from=build-base /out/orgtempl/update /opt/intrexx/orgtempl/update
COPY --from=build-base /out/orgtempl/blank /opt/intrexx/orgtempl/blank

RUN mkdir -p /opt/intrexx/export && \
    mkdir -p /opt/intrexx/org

# Copy customizations
COPY services/intrexx/cfg/portal/ /opt/intrexx/cfg/portal/
COPY services/intrexx/cfg/initial.cfg /opt/intrexx/cfg/
COPY services/intrexx/cfg/installer/* /opt/intrexx/installer/cfg/

FROM debian:trixie-slim AS runtime-base
ARG INSTALL_IMAGEMAGICK=true
ARG INSTALL_LIBREOFFICE=false

ENV JAVA_HOME=/opt/java/openjdk
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=${JAVA_HOME}/bin:${PATH} \
    DOCKER=true \
    IX_DISTRIBUTED=false \
    IX_DISTRIBUTED_NODELIST=ix12-intrexx-in-docker-intrexx-1,ix12-intrexx-in-docker-intrexx-2,ix12-intrexx-in-docker-intrexx-3 \
    PORTAL_NAME=portal \
    PORTAL_BASE_URL=http://localhost:1337/ \
    DB_HOST=postgres \
    DB_PORT=5432 \
    DB_NAME=ixportal \
    DB_USER=postgres \
    DB_PASSWORD=postgres \
    DB_CREATE=true \
    SOLR_HOST=solr \
    SOLR_PORT=9983 \
    SOLR_USER=solr \
    SOLR_PASSWORD=SolrRocks \
    SOLR_PATH= \
    TEMPLATE_PATH=/opt/intrexx/orgtempl/blank \
    PORTAL_ZIP_NAME=portal-template.zip \
    TOMCAT_SEC_HEADER_XUSER=deny \
    TOMCAT_SEC_HEADER_XDOMAIN=deny \
    TOMCAT_SEC_HEADER_XKRBTICKET=deny \
    TOMCAT_SEC_HEADER_XACCOUNTNAME=deny \
    TOMCAT_SEC_HEADER_XFORWARDEDFOR=deny \
    TOMCAT_SEC_HEADER_FORWARDED=deny \
    TOMCAT_SEC_HEADER_XREALIP=deny \
    TOMCAT_SEC_HEADER_XFORWARDEDHOST=deny \
    TOMCAT_SEC_HEADER_XFORWARDEDPROTO=deny \
    TOMCAT_SEC_HEADER_XORIGINALURL=deny \
    TOMCAT_SEC_HEADER_RECEIVEONNONLOOPBACKINTERFACE=false

# Copy entrypoint
COPY --chmod=0755 docker/intrexx/docker-entrypoint.d/ /docker-entrypoint.d/
COPY --chmod=0755 docker/intrexx/docker-entrypoint.sh /usr/local/bin/

# Copy JRE
COPY --from=build-base /opt/java /opt/java

# Install additional software
RUN set -eux; \
    apt-get update; \
    packages="gettext-base libarchive-tools"; \
    if [ "${INSTALL_IMAGEMAGICK}" = "true" ]; then \
        packages="${packages} imagemagick librsvg2-bin"; \
    fi; \
    if [ "${INSTALL_LIBREOFFICE}" = "true" ]; then \
        packages="${packages} libreoffice"; \
    fi; \
    apt-get install -y --no-install-recommends ${packages}; \
    rm -rf /var/lib/apt/lists/*

# Portal volume
VOLUME /opt/intrexx/org

ENTRYPOINT ["docker-entrypoint.sh"]

FROM runtime-base AS rootful
# Copy intrexx installation
COPY --from=build /opt/intrexx /opt/intrexx

FROM runtime-base AS rootless
ARG USER_GID=1000
ARG USER_UID=1000

# Create user, group and portal directory
RUN groupadd --gid ${USER_GID} intrexx && \
    useradd --no-log-init --uid ${USER_UID} --gid ${USER_GID} --shell /usr/sbin/nologin --home-dir /opt/intrexx intrexx

# Copy intrexx installation (owned by created user)
COPY --from=build --chown=${USER_UID}:${USER_GID} /opt/intrexx /opt/intrexx

WORKDIR /opt/intrexx

USER intrexx

# --- Default
FROM rootful AS final
