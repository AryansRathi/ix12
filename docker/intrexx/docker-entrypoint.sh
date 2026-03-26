#!/bin/bash

set -eu

TEMPLATE_DIR="/tmp/portal-template"
PORTAL_ZIP_MNTPT="/tmp/import"
PORTAL_DIR="/opt/intrexx/org/${PORTAL_NAME}"
LICENSE_CFG="${PORTAL_DIR}/internal/cfg/license.cfg"
LICENSE_CFG_TEMPLATE="${PORTAL_DIR}/internal/cfg/license.cfg.template"
SERVICE_CFG="/opt/intrexx/cfg/service.cfg"
SERVICE_CFG_TEMPLATE="${PORTAL_DIR}/internal/cfg/service.cfg.template"
KAHAB=0

create_portal() {
  PORTAL_CFG="/opt/intrexx/cfg/portal/portal_configuration.xml"

  # Set template path
  TEMPLATE_ZIP_PATH="${PORTAL_ZIP_MNTPT}/${PORTAL_ZIP_NAME}"
  [ -f "${TEMPLATE_ZIP_PATH}" ] && mkdir -p ${TEMPLATE_DIR} && bsdtar -xf ${TEMPLATE_ZIP_PATH} -C ${TEMPLATE_DIR} && export TEMPLATE_PATH="${TEMPLATE_DIR}"

  envsubst < ${PORTAL_CFG}.template > ${PORTAL_CFG}

  if [ "$(id -u)" -eq 0 ]; then
      # rootful
      /opt/intrexx/bin/linux/buildportal.sh -t --nostart --configFile="${PORTAL_CFG}"
  else
      # rootless
      /opt/intrexx/bin/linux/buildportal.sh -t --noroot --nostart --disableHttpsRest --configFile="${PORTAL_CFG}"
  fi
  KAHAB=1

  # Copy configuration files to shared folder
  if [ "${IX_DISTRIBUTED}" == "true" ]; then
    if [ -d "/tmp/ix-cfg" ]; then
      cp -R /opt/intrexx/cfg/* /tmp/ix-cfg
    else
      echo "Skipped copying '/opt/intrexx/cfg' to '/tmp/ix-cfg' (target folder does not exist)."
    fi
  fi
}

patch_portal() {
  VERSION_PORTAL=`cat $PORTAL_DIR/internal/cfg/portal.cfg | grep -oP "version=\"\d+\"" | grep -oP "\d+"`
  VERSION_SETUP=`/opt/intrexx/bin/linux/getversion.sh`

  if [ $VERSION_PORTAL -gt $VERSION_SETUP ]; then
    echo "The portal must be less than or equal the setup version."
    exit 1
  fi

  if [ $VERSION_PORTAL -lt $VERSION_SETUP ]; then
    /opt/intrexx/bin/linux/updatefilesfromblank.sh "$PORTAL_DIR"
    /opt/intrexx/bin/linux/patchportal.sh "$PORTAL_DIR"
  else
    echo "The portal already has the setup version. Nothing to do."
  fi
}

configure_ignite() {
  nodes=$(echo ${IX_DISTRIBUTED_NODELIST} | tr "," "\n")

  values=""
  for node in ${nodes}
  do
      values="${values}<value>${node}</value>\n"
  done

  sed "s|<value>127.0.0.1:47500..47509</value>|${values}|g" /opt/intrexx/orgtempl/blank/internal/cfg/spring/distributed/00-ignite-config-context.xml > ${PORTAL_DIR}/internal/cfg/spring/00-ignite-config-context.xml

  # If no nodes are defined, use shared filesystem folder for node addresses
  if [ "${values}" == "" ]; then
    cp /opt/intrexx/cfg/portal/00-ignite-config-context.xml ${PORTAL_DIR}/internal/cfg/spring/00-ignite-config-context.xml
  fi
}

# Set server mode
[ "${IX_DISTRIBUTED}" == "true" ] && sed -i 's/STANDALONE/DISTRIBUTED/g' /opt/intrexx/cfg/initial.cfg

# Patch the portal, if present but not up to date
[ -d "$PORTAL_DIR" ] && patch_portal

# Create the portal, if not already present
[ -d "$PORTAL_DIR" ] || create_portal

# Cleanup
[ -d "$TEMPLATE_DIR" ] && rm -rf $TEMPLATE_DIR

# Migration step for 10.15.0: If old license cfg template exists, use it instead of the new (empty) license cfg
[ -f ${LICENSE_CFG_TEMPLATE} ] && mv ${LICENSE_CFG_TEMPLATE} ${LICENSE_CFG}

# Migration step for 10.15.0: If old service cfg template exists, use it instead of the new (empty) service cfg
[ -f ${SERVICE_CFG_TEMPLATE} ] && rm ${SERVICE_CFG} && cp ${SERVICE_CFG_TEMPLATE} ${SERVICE_CFG}

# Configure list of cluster nodes
[ "${IX_DISTRIBUTED}" == "true" ] && configure_ignite


# Run additional init scripts (they inherit all exported variables)
if [ -d /docker-entrypoint.d ]; then
  for file in /docker-entrypoint.d/*.sh; do
    [ -e "$file" ] || continue    # handle "no match" case
    [ -r "$file" ] || continue
    . "$file"
  done
  unset file
fi

# Clean sensitive env vars
unset DB_PASSWORD
unset SOLR_PASSWORD

if [ "$#" -eq 0 ]; then
  # Start the portal
  if [ "${IX_DISTRIBUTED:-}" = "true" ]; then
    exec /opt/intrexx/bin/linux/portal-distributed.sh $PORTAL_DIR
  else
    exec /opt/intrexx/bin/linux/portal.sh $PORTAL_DIR
  fi
else
  # User command passthrough
  exec "$@"
fi
