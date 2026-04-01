#!/bin/bash

set -eu

CACERTS_PATH=/tmp/admin-api/cfg/${CACERTS_FILE}
# Provide certificate
[ -f ${CACERTS_PATH} ] && echo "Custom cacerts file found. Using it, instead of default." && cp ${CACERTS_PATH} /opt/intrexx/admin-api/cfg/cacerts

# Create certificate
[ -z "${CACERTS_SAN_LIST}" ] || echo "creating certificate from CACERTS_SAN_LIST: \"${CACERTS_SAN_LIST}\"" && /opt/intrexx/admin-api/bin/linux/createcertificate.sh -i --san ${CACERTS_SAN_LIST}

ADMIN_API_YAML="/opt/intrexx/admin-api/cfg/admin-api.yaml"

if [ "${PORTAL_ADMIN_PW}" = "NONE" ]; then
    export PORTAL_ADMIN_PW=""
fi

envsubst < ${ADMIN_API_YAML}.template > ${ADMIN_API_YAML}

unset PORTAL_ADMIN_PW
unset CACERTS_PW
unset IAA_SECRET
unset IAA_PW

# Run additional init scripts
if test -d /docker-entrypoint.d/; then
  for entrypoint in /docker-entrypoint.d/*.sh; do
    test -r "$entrypoint" && . "$entrypoint"
  done
  unset entrypoint
fi

# Start the admin-api
exec /opt/intrexx/admin-api/bin/linux/admin-api.sh