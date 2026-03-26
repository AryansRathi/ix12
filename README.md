# Intrexx Docker Compose (example)

This repository provides a Docker Compose example for running an Intrexx Server and optionally the Intrexx Administration API in Docker. It is designed so that exactly one portal can run in one deployment. The example also includes instructions on how to build an Intrexx Server image and an Intrexx Administration API image.

The Intrexx Server Deployment operates as follows:

1. If the deployment is started for the first time, an empty portal (blank portal) is created.
2. Alternatively, a portal export can be imported during the first startup. The export must be provided as a ZIP file.
3. When the portal is restarted after it has already been initialized, the portal version is checked to ensure it matches the Intrexx version. If it does not, it is patched before it is started. The patch only works when the portal version is lower than the Intrexx version in the image.

> **Disclaimer**
> This deployment is provided as an **example only**.
> There is **no warranty or liability** for functionality, security, or suitability for production use.
> You must adapt it to your environment.

## Table of Contents

- [Quick Start](#quick-start)
- [Access](#access)
- [Repository structure](#repository-structure)
- [Intrexx version](#intrexx-version)
- [Rootful vs Rootless](#rootful-vs-rootless)
- [Optional software](#optional-software-inside-the-intrexx-image)
- [Operating modes](#operating-modes)
- [Portal import](#portal-import)
- [Data storage](#data-storage)
- [Intrexx Administration API](#intrexx-administration-api)
- [Update](#update-to-a-new-intrexx-version)
- [Environment variables](#environment-variables)
- [Cleanup](#docker-disk-usage--cleanup)
- [Migration](#migration-from-previous-deployment-intrexx-in-docker)

# Quick Start

## 1. Create configuration

```bash
cp compose.yaml.example compose.yaml
cp .env.example .env
```

## 2. Build the image

The Intrexx image must be built locally:

```bash
docker compose build intrexx
```
The built image is tagged as follows: `intrexx:${IX_VERSION}-${INTREXX_TARGET}`


## 3. Start the deployment
Without any further configuration, you can now start an Intrexx standalone deployment with an empty Intrexx portal. For additional configuration options, see below.

```bash
docker compose up -d
```
# Access
There are two ways to connect to the portal. End users access it via a browser, while developers connect via the Intrexx Portal Manager to make changes to the portal.
## Via Browser
In a standard local Docker Compose deployment, web access is provided via:
```text
http://localhost:1337
```
## Via Intrexx Portal Manager
The Intrexx Portal Manager can access the portal via `localhost:IX_REST_HOST_PORT`. The environment variable is defined in the `.env` file (the default value is 8101). You need to download the Portal Manager first.

For further information see Intrexx Help Center: [How to connect to your portal](https://help.intrexx.com/intrexx/steady/en-us/Content/OH/portal/portal-connect-to-your-portal.html).
# Repository structure
```text
.
├── compose.yaml.example
├── compose.admin-api.yaml
├── compose.base.yaml
├── compose.bind.yaml
├── compose.distributed.yaml
├── compose.migration.yaml
├── README.md
├── .env.example
├── .dockerignore
├── .gitignore
├── docker/
│   └── <service>
├── services/
│   └── <service>
└── runtime/
    └── <service>
```

## Docker Compose setup
This project uses a modular Docker Compose setup.

The `compose.yaml` file acts as an entrypoint and includes other Compose files depending on the desired setup. You can enable or disable features by modifying the included files. This allows using Docker Compose without any further configuration.

As an alternative to using include statements, the Compose files to be used can also be specified via `docker compose -f <file.yaml> -f ...`. Another option is to use the environment variable [COMPOSE_FILE](https://docs.docker.com/compose/how-tos/environment-variables/envvars/#compose_file).

Here's a quick overview of the available compose files. For more details, see the documentation below.
| File                          | Purpose                                                                                                                                                | When to use                          |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------ |
| `compose.yaml`                | Entry point, includes other Compose files                                                                                                              | Always                               |
| `compose.base.yaml`           | Core services (intrexx, db, solr and zookeeper)                                                                                                        | Always included                      |
| `compose.admin-api.yaml`      | Adds the admin-api service, see [Intrexx Administration API](#intrexx-administration-api)| When the Administration API is needed                       |
| `compose.bind.yaml`           | Overrides the portal volume with a bind mount, see [Bind mount alternative for the portal directory](#bind-mount-alternative-for-the-portal-directory) | If the portal directory should be bind mounted to a dedicated directory on the host system |
| `compose.distributed.yaml`    | Adds/extends services for distributed deployment, see [Operating modes](#operating-modes)                                                              | If horizontal scaling is needed      |
| `compose.migration.yaml`      | Makes volumes compatible with the old ones in intrexx-in-docker, see [Volume migration](#volume-migration)                                             | Quick start with new Compose setup migrating from the old one (not intended for long-term use) |

### Additional configuration
Many things can be controlled using environment variables. For a complete list of available variables, see [Environment variables](#environment-variables) and `.env.example`.

## Meaning of the directories
The `docker` directory contains Docker-specific build resources for the respective service.

The `services` directory contains service-specific build resources.

The `runtime` directory contains service-specific runtime resources.

# Intrexx version
The environment variable `IX_VERSION` defines which Intrexx version will be installed into the Docker image during the build.

You can specify any version available [here](https://download.intrexx.com/intrexx/rolling/steady/) starting from 12.0.0.20240528.8adb14f. The default value is `latest` but it is recommended to use an explicit version like this:

Example `.env` configuration:
```env
IX_VERSION=12.1.5.20251202.1ac48b8
```

# Rootful vs Rootless
The Compose setup supports building and running both rootful and rootless images of the Intrexx Server and the Intrexx Administration API, allowing you to choose between maximum compatibility and enhanced security depending on your environment.

> **Once a portal has been initialized in one of the two modes, it cannot be easily switched to the other mode.**
## Rootful (Default)
The service runs as root.

Example `.env` configuration (enable Administration API line if needed):
```env
INTREXX_TARGET=rootful
...
# ADMIN_API_TARGET=${INTREXX_TARGET}
```

## Rootless
The service runs as non-root user.

Example `.env` configuration (enable Administration API lines if needed):
```env
INTREXX_TARGET=rootless
INTREXX_USER_UID=1000
INTREXX_USER_GID=1000
...
# ADMIN_API_TARGET=${INTREXX_TARGET}
# ADMIN_API_USER_UID=${INTREXX_USER_UID}
# ADMIN_API_USE_GID=${INTREXX_USER_GID}
```

# Optional software inside the intrexx image
During the build, additional software can be installed if desired.

Example `.env` configuration:
```env
INSTALL_IMAGEMAGICK=true
INSTALL_LIBREOFFICE=false
```

## ImageMagick

Intrexx can use ImageMagick to scale images.
For configuration refer to Intrexx Help Center: [Image scaling with ImageMagick](https://help.intrexx.com/intrexx/steady/en-us/Content/OH/application-scale-images.html)

## LibreOffice

Intrexx can use LibreOffice to generate documents.
For configuration refer to Intrexx Help Center: [Generate documents](https://help.intrexx.com/intrexx/steady/en-us/Content/OH/application-document-engine.html)

# Operating modes

The Intrexx Server runtime provides the two operating modes standalone and distributed.
## Standalone (default)
Single Intrexx instance

```bash
docker compose up -d
```
Example `compose.yaml` configuration:

```compose.yaml
include:
  - compose.base.yaml
```
For reverse proxy configuration refer to Intrexx Help Center: [Configure NGINX](https://help.intrexx.com/intrexx/steady/en-us/Content/OH/deploy/nginx/deploy-configure-nginx.html)

## Distributed (horizontal scaling)

Intrexx can also be scaled horizontally by launching multiple instances of the intrexx service (distributed mode). In this example, load balancing is handled by Traefik

Example `.env` configuration:
```env
IX_DEPLOY_MODE=replicated
IX_DEPLOY_REPLICATIONS=3
IX_WEBCONNECTOR_HOST_PORT=1338-1340
IX_REST_HOST_PORT=8101-8103
IX_ODATA_HOST_PORT=9090-9092
IX_DISTRIBUTED_NODELIST="ix12-intrexx-in-docker-intrexx-1,ix12-intrexx-in-docker-intrexx-2,ix12-intrexx-in-docker-intrexx-3"
...
TRAEFIK_VERSION=v3.6
```
Example `compose.yaml` configuration:

```compose.yaml
include:
  - compose.base.yaml
  - compose.distributed.yaml
```

# Portal import
A portal is always created the first time the deployment is started. By default, the portal is empty. However, a portal can also be imported from a provided export. To do this, a portal export ZIP file must be placed in the directory defined below:

```text
./runtime/intrexx/import/
```

Afterwards, the name of the ZIP file must be defined in the `.env` file.

Example `.env` configuration:
```env
IX_PORTAL_ZIP_NAME=myportal.zip
```
> **Please note**
> The export must be from an Intrexx installation with the same operating mode (standalone/distributed) as the deployment into which it is to be imported!

# Data storage

Docker Compose automatically prefixes volume names with the project name (directory name):

```text
<project-name>_<volume-name>
```

Example for the database volume:

```text
ix12-intrexx-in-docker_db-data
```

Used volumes:

| Volume Name         | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `portal-data`       | Persists `/opt/intrexx/org` of the intrexx service if no bind mount is used |
| `intrexx-cfg`       | Persists `/opt/intrexx/cfg` of the intrexx service                          |
| `db-data`           | Persists `/var/lib/postgresql` of the db service                            |
| `zookeeper-data`    | Persists `/data` of the zookeeper service                                   |
| `zookeeper-datalog` | Persists `/datalog` of the zookeeper service                                |
| `solr-data`         | Persists `/var/solr` of the solr service                                    |
| `admin-api-cfg`     | Persists `/opt/intrexx/admin-api/cfg` of the admin-api service              |


## Bind mount alternative for the portal directory

The directory where the portal is stored can alternatively be defined as a bind mount.

Example `.env` configuration:

```env
IX_PORTAL_DIR_HOST=./runtime/intrexx/org
```

Example `compose.yaml` configuration:

```compose.yaml
include:
  - compose.base.yaml
  - compose.bind.yaml
```

# Intrexx Administration API
The Intrexx Administration API can be used to configure an Intrexx portal via REST, see Intrexx Help Center for more information: [Intrexx Administration API](https://help.intrexx.com/intrexx/steady/en-us/Content/OH/api-administration/api-admin-startpage.html)

It is possible to run the Administration API as a Docker Compose service.

> **Restriction**
> The endpoints starting with `/portals` and `/templates` do not work within a Docker deployment!
## Build the image
To build the image, you must first specify whether it should be rootless or rootful, see [Rootful vs Rootless](#rootful-vs-rootless). You also need to specify the Intrexx version, see [Intrexx version](#intrexx-version).

Example `compose.yaml` configuration:
```compose.yaml
include:
  # The compose.base.yaml is optional, the admin-api can also be built and started without all the other services
  - compose.base.yaml
  - compose.admin-api.yaml
```

```bash
docker compose build admin-api
```

## Run the service
Before the service can be started, further configuration is required. First the host port of the API and the connection to the portal to be managed must be defined. In addition either a Java keystore containing a valid certificate for the host must be provided under `./runtime/admin-api/cfg`. The name of the file and the corresponding password must be specified via `CUSTOM_CACERTS_FILE` and `CUSTOM_CACERTS_PW`.
Alternatively, a self-signed certificate can be generated at startup. To do this, the corresponding subject alternative names must be specified via `CACERTS_SAN_LIST`.

Example `.env` configuration (see more variables in .env.example):
```.env
ADMIN_API_HOST_PORT=4242
PORTAL_API_PORT=8101

# either
# CUSTOM_CACERTS_FILE=cacerts
# CUSTOM_CACERTS_PW=changeit
# or
# CACERTS_SAN_LIST="dns:localhost ip:127.0.0.1"
```
```bash
docker compose up -d
```

> **Note**
> If the admin-api service is to be deployed independently of the Intrexx portal, the dependency on the intrexx service must be removed from `compose.admin-api.yaml`:
```compose.admin-api.yaml
services:
  admin-api:
  ...
    #depends_on:
    #  intrexx:
    #    condition: service_healthy
```

# Update to a new Intrexx version
To update Intrexx and the other services to a newer version follow these steps:
1. Stop the deployment
2. Update this repository
3. Compare the recommended versions in `.env.example` with the versions in your `.env` file
4. Specify the new Intrexx version in `.env`
5. Build the necessary Intrexx images. **Caution: The existing images will be overwritten if you didn't change the value of `IX_VERSION`!**
6. Pull new image versions of the other services. **Carefully review the change logs for the services before performing this step!**
7. Start the deployment

```bash
docker compose down # 1.
git pull # 2.
docker compose build intrexx admin-api # 5.
docker compose pull # 6.
docker compose up -d # 7.
```

# Environment variables

### Intrexx build

| Variable              | Description                            | Default   | Notes                                  |
| --------------------- |--------------------------------------- | --------- |--------------------------------------- |
| `IX_VERSION`          | Intrexx version to build and run       | `latest`  |                                        |
| `INTREXX_TARGET`      | Build target (`rootful` or `rootless`) | `rootful` | Controls container user model          |
| `INTREXX_USER_UID`    | UID for rootless container             | `1000`    | Only used if `INTREXX_TARGET=rootless` |
| `INTREXX_USER_GID`    | GID for rootless container             | `1000`    | Only used if `INTREXX_TARGET=rootless` |
| `INSTALL_IMAGEMAGICK` | Install ImageMagick                    | `true`    | Optional dependency                    |
| `INSTALL_LIBREOFFICE` | Install LibreOffice                    | `false`   | Optional dependency                    |

### Intrexx runtime

| Variable                    | Description                           | Default                  | Notes                             |
| --------------------------- | ------------------------------------- | ------------------------ | --------------------------------- |
| `IX_PORTAL_NAME`            | Name of the portal                    | `portal`                 |                                   |
| `IX_DB_NAME`                | Database name                         | `ixportal`               |                                   |
| `IX_DB_CREATE`              | Create database                       | `true`                   |                                   |
| `IX_PORTAL_BASE_URL`        | Base URL of the portal                | `http://localhost:1337/` | Changes in distributed mode       |
| `IX_PORTAL_DIR_HOST`        | Host path for portal directory        | -                        | Only used with bind mount setup   |
| `IX_PORTAL_ZIP_NAME`        | Custom portal ZIP file to be imported | -                        | Must exist in import directory    |
| `IX_WEBCONNECTOR_HOST_PORT` | Web connector publish host port       | `1337`                   | Differs in distributed mode       |
| `IX_REST_HOST_PORT`         | REST API publish host port            | `8101`                   | Differs in distributed mode       |
| `IX_ODATA_HOST_PORT`        | OData publish host port               | `9090`                   | Differs in distributed mode       |
| `IX_DEPLOY_MODE`            | Deployment mode                       | `global`                 | `replicated` in distributed mode  |
| `IX_DEPLOY_REPLICATIONS`    | Number of replicas                    | `1`                      | Required in distributed mode      |
| `IX_DISTRIBUTED_NODELIST`   | List of cluster nodes                 | -                        | Required for distributed mode     |

### PostgreSQL

| Variable      | Description              | Default     |
| ------------- | ------------------------ | ----------- |
| `PG_VERSION`  | PostgreSQL image version | `18-alpine` |
| `PG_USER`     | Database user            | `postgres`  |
| `PG_PASSWORD` | Database password        | `postgres`  |

### Solr

| Variable        | Description         | Default                                                     |
| --------------- | ------------------- |------------------------------------------------------------ |
| `SOLR_VERSION`  | Solr image version  | `9.10.1`                                                    |
| `SOLR_OPTS`     | JVM options         | `-XX:-UseLargePages -Dsolr.jetty.request.header.size=65535` |
| `SOLR_USER`     | Solr user           | `solr`                                                      |
| `SOLR_PASSWORD` | Solr password       | `SolrRocks`                                                 |
| `SOLR_PATH`     | Context path        | empty                                                       |

### Zookeeper

| Variable            | Description       | Default |
| ------------------- | ----------------- | ------- |
| `ZOOKEEPER_VERSION` | Zookeeper version | `3.9.4` |

### Administration API build

| Variable             | Description                            | Default   | Notes                                                 |
| -------------------- |--------------------------------------- | --------- | ----------------------------------------------------- |
| `ADMIN_API_TARGET`   | Build target (`rootful` or `rootless`) | `rootful` | Defaults to `INTREXX_TARGET`                          |
| `ADMIN_API_USER_UID` | UID for rootless container             | `1000`    | Defaults to `INTREXX_USER_UID`, only used if rootless |
| `ADMIN_API_USER_GID` | GID for rootless container             | `1000`    | Defaults to `INTREXX_USER_GID`, only used if rootless |

### Administration API runtime

| Variable              | Description                                                  | Default         | Notes                                                         |
| --------------------- | ------------------------------------------------------------ | --------------- |-------------------------------------------------------------- |
| `ADMIN_API_HOST_PORT` | Admin API publish host port                                  | `4242`          |                                                               |
| `PORTAL_API_PORT`     | The port of the portal's REST API.                           | `8101`          | Within Docker Compose the docker internal port should be used |
| `PORTAL_HOST`         | The portal hostname                                          | `intrexx`       | Within Docker Compose the service name should be used         |
| `PORTAL_NAME`         | The name of the portal to administer.                        | `portal`        | Defaults to `IX_PORTAL_NAME`                                  |
| `PORTAL_API_SCHEME`   | Scheme the Admin API uses to connect to the portal.          | `http`          |                                                               |
| `PORTAL_ADMIN_USER`   | The portal's Administrator user name.                        | `Administrator` |                                                               |
| `PORTAL_ADMIN_PW`     | The password of the portal's Administrator user.             | `NONE`          | Use `NONE` for an empty password.                             |
| `IAA_USER`            | Administrator user of the Intrexx Admin API.                 | `iaa-admin`     |                                                               |
| `IAA_PW`              | Password of the Administrator user of the Intrexx Admin API. | `P4$$w0rD`      | Should be changed                                             |
| `IAA_DEBUG_MODE`      | Debug mode                                                   | `false`         |                                                               |
| `IAA_SECRET`          | Secret used to encode the JWTs.                              | `changeit`      | Should be changed                                             |
| `IAA_USE_SSL`         | Enable SSL                                                   | `true`          |                                                               |
| `IAA_LICENSE`         | License key for IAA                                          | `NONE`          |                                                               |


### Administration API certificates

| Variable              | Description                      | Default                                               |
| --------------------- | -------------------------------- | ----------------------------------------------------- |
| `CACERTS_SAN_LIST`    | SAN list for self-signed cert    | `dns:www.example.org ip:198.51.100.12 ip:127.0.0.1` |
| `CUSTOM_CACERTS_FILE` | Custom keystore file             | `cacerts`                                             |
| `CUSTOM_CACERTS_PW`   | Password of custom keystore file | `changeit`                                            |

### Traefik

| Variable          | Description     | Default | Notes                         |
|------------------ | --------------- |-------- |------------------------------ |
| `TRAEFIK_VERSION` | Traefik version | `v2.11` | Only used in distributed mode |


# Docker Disk Usage & Cleanup
Docker can take up a lot of disk space over time. This should be checked regularly. If in doubt, you should clean it up.
## Check disk usage

```bash
docker system df # docker disk usage
docker buildx du # buildx disk usage
```

## Remove unused images

```bash
docker image prune -a
```

## Remove build cache

```bash
docker buildx prune
```

## Full cleanup
This removes **all unused data including volumes**

```bash
docker system prune -a --volumes
```

# Migration from previous deployment (`intrexx-in-docker`)

The new Docker Compose deployment includes a few changes that may require a manual migration of an existing deployment

## PostgreSQL 18+ – Important change

This example now uses PostgreSQL version 18 or later. The old example used version 16.

> **Important:**
> With version 18, PostgreSQL introduced a breaking change in its Docker images: The internal data directory inside the container has changed from `/var/lib/postgresql/data` to `/var/lib/postgresql/<version>/docker`, see also: [Change PGDATA in 18+](https://github.com/docker-library/postgres/pull/1259)

### Impact on volume migration

Even if you reuse or copy Docker volumes PostgreSQL internally uses a different subdirectory (`PGDATA`).

Result:

* the database may appear **empty**
* or PostgreSQL may **initialize a new cluster**

### What to do
Before you migrate your Intrexx deployment to the new Docker Compose example described in this repository, update PostgreSQL in your old deployment to PostreSQL 18+.

An option for updating PostgreSQL is this:
1. Fully export the database cluster (`pg_dumpall`)
2. Stop the intrexx-in-docker deployment
3. Delete the old database volume (just to be safe, you can create a backup before deleting it - this is done in the same way as described in [Volume migration](#volume-migration)).
4. Update the version of PostgreSQL in `.env`
5. Update the target of the database data volume in `docker-compose.yml`: change `intrexx-db-data:/var/lib/postgresql/data` to `intrexx-db-data:/var/lib/postgresql`
6. Start the database service with the new PostgreSQL version
7. Import the database export you created earlier
8. Restart the entire deployment and make sure everything is working

## Volume migration

Please note the following changes that affect the volume migration:

* The project name has changed: `ix12-intrexx-in-docker`
* Some volume names were simplified:
    | before                      | now                 |
    | --------------------------- | ------------------- |
    | `intrexx-db-data`           | `db-data`           |
    | `intrexx-zookeeper-data`    | `zookeeper-data`    |
    | `intrexx-zookeeper-datalog` | `zookeeper-datalog` |
    | `intrexx-solr-data`         | `solr-data`         |

    As a result, old volumes are **not reused automatically**.


There are two possible ways to migrate existing Docker volumes from the previous example deployment.

### Option 1 – Reuse the old volumes via `compose.migration.yaml`

This is the quickest option.

```bash
docker compose -f compose.yaml -f compose.migration.yaml up -d
```

> **Important:**
> `compose.migration.yaml` only covers the **default volume naming** of the old `intrexx-in-docker` example.
> If your previous deployment was customized, you must adjust the referenced old volume names manually.

To inspect the existing volumes:

```bash
docker volume ls
```

### Option 2 – Migrate to the new volume names

This is the cleaner long-term approach.

Docker volumes cannot be renamed directly.
A clean migration therefore means:

1. create the new volumes with the new names
2. copy the data from the old volumes into the new ones
3. start the new deployment normally, without `compose.migration.yaml`

#### Step 1 – Determine the new project name

Docker Compose volume names follow this pattern:

```text
<project-name>_<volume-name>
```

In most cases, `<project-name>` is the name of the current directory.

You can check it with:

```bash
basename "$PWD"
```

#### Step 2 – Create the new volumes and copy data

```bash
export NEW_PROJECT_NAME="ix12-intrexx-in-docker"
export NEW_VOLUME_NAME="db-data" # or portal-data or zookeeper-data or zookeeper-datalog or solr-data or intrexx-cfg
docker volume create \
  --name "${NEW_PROJECT_NAME}_${NEW_VOLUME_NAME}" \
  --label com.docker.compose.project=${NEW_PROJECT_NAME} \
  --label com.docker.compose.volume=${NEW_VOLUME_NAME}

export OLD_PROJECT_NAME="intrexx-in-docker"
export OLD_VOLUME_NAME="intrexx-db-data" # or portal-data or intrexx-zookeeper-data or intrexx-zookeeper-datalog or intrexx-solr-data or intrexx-cfg
docker run --rm \
  -v ${OLD_PROJECT_NAME}_${OLD_VOLUME_NAME}:/from \
  -v ${NEW_PROJECT_NAME}_${NEW_VOLUME_NAME}:/to \
  alpine sh -c "cd /from ; cp -av . /to"
```
Repeat this for all relevant volumes.

## Other changes

### 1. Clear separation of responsibilities

The portal directory is located within a named volume or a bind mount (like before). The zipped portal, which can be imported optionally, must now be stored in the directory:

```bash
./runtime/intrexx/import/
```
 Previously, this was flexible. For example, it could also be stored in the bind-mounted directory for the portal directory.

As a result, the `IX_PORTAL_ZIP_MNTPT` environment variable has been removed.

No migration should be necessary for existing deployments, as the ZIP file is only relevant during the very first startup.

### 2. Removed port publications

The ports of the services db, solr and zookeeper are no longer published to the host system, because it is not necessary for the operation of the Docker Compose deployment described here.

Port publications can be easily reconfigured by creating a file named `compose.<override>.yaml` and including it in the `compose.yaml` file.

### 3. Removed NGINX example

The NGINX example for the standalone deployment has been removed. A link to the instructions on how to configure a page is provided above.

Like the port publications, this can also be reconfigured via an additional `compose.<override>.yaml` file if needed.