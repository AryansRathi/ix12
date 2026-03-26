#!/bin/bash

if [ "${KAHAB:-0}" = "1" ]; then
    java -cp "/docker-entrypoint.d:/opt/intrexx/lib/ix-common.jar" KahabInit
fi
#[ $KAHAB = 1 ] && java -cp "/docker-entrypoint.d:/opt/intrexx/lib/ix-common.jar" KahabInit

