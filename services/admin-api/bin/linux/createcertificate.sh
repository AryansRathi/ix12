#!/bin/bash

# ------------------------------------------------------------------------------
# Copyright 2002-2026 INTREXX GmbH, Freiburg, Germany
# All Rights Reserved.
# ------------------------------------------------------------------------------


SANS_ARRAY=()

help() {
    echo "Please provide the following parameter for the certificate generation";
    echo "-i, --admin-api:  this flag has to be set if you want to generate a new certificate for the INTREXX Administration API";
    echo "-a, --san:        this specifies the subject alternative names. A subject alternative name can either be an IP-address or a DNS-mame.";
    echo "                  IP-addresses must have the prefix \"ip:\", DNS-names must have the prefix \"dns:\"";
    echo "";
    echo "Example admin-api  certificate: createcertificate -i --san dns:www.example.org ip:198.51.100.12 ip:127.0.0.1";
    exit 1;
}

die() {
    echo "Error: $@";
    exit 1;
}

[ $# -eq 0 ] && help

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    help
    shift # past argument
    shift # past value
    ;;
    -i|--admin-api)
    IRMA=true
    shift # past argument
    ;;
    -a|--san|*) #subject alternative names
    SANS_ARRAY+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

set -- "${SANS_ARRAY[@]}" # restore SANS_ARRAY parameters

echo "Subject alternative names:"

SUBJECT_ALT_NAMES=""

for i in "${SANS_ARRAY[@]}"
do
    if [ "$i" != "--san" ] && [ "$i" != "-a" ]; then
        echo $i
        [[ $i = ip:* ]] || [[ $i = dns:* ]] || die "$i does not contain the prefix \"ip:\" or \"dns:\"" # checks if san starts with ip: or dns:

        if [ "$SUBJECT_ALT_NAMES" != "" ]; then
            SUBJECT_ALT_NAMES="$SUBJECT_ALT_NAMES,$i"
        else
            SUBJECT_ALT_NAMES="$i"
        fi
    fi
done

KEYSTORE_PATH="/opt/intrexx/admin-api/cfg/cacerts"

$JAVA_HOME/bin/keytool \
    -list \
    -keystore "$KEYSTORE_PATH" \
    -storepass changeit \
    -alias irma \
    > /dev/null 2>&1 && \
$JAVA_HOME/bin/keytool \
    -delete \
    -alias irma \
    -keystore "$KEYSTORE_PATH" \
    -storepass changeit

$JAVA_HOME/bin/keytool \
    -genkeypair \
    -alias irma \
    -keyalg RSA \
    -keysize 2048 \
    -validity 1095 \
    -keystore "$KEYSTORE_PATH" \
    -storepass changeit \
    -keypass changeit \
    -dname "CN=localhost, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown" \
    -ext san="$SUBJECT_ALT_NAMES" \
    -noprompt
[ $? -ne 0 ] && die "Could not create certificate"

echo ""
echo "Keystore created successfully."
exit 0
