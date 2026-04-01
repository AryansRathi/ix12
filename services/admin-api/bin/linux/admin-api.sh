#!/bin/bash

# ------------------------------------------------------------------------------
# Copyright 2002-2026 INTREXX GmbH, Freiburg, Germany
# All Rights Reserved.
# ------------------------------------------------------------------------------

# determine the installation directory and use it as the working directory
cd "${0/%admin-api.sh/}"
cd ../..

IRMA_HOME=$(pwd)
export IRMA_HOME

cd ..

# collect used paths
CLASSPATH=$CLASSPATH$(s="$IRMA_HOME/lib"; find "$s" -maxdepth 1 -name '*.jar' -printf ":$s/%f")

# now start the Java VM
LOG4J_CFG=-Dlog4j.configurationFile=$IRMA_HOME/cfg/log4j2_admin_api.xml
MAIN_CLASS=de.uplanet.lucy.irma.MainKt

"$JAVA_HOME/bin/java" -Xmx512m -Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dfile.encoding=UTF-8 -Dirma.serverconfig="$IRMA_HOME/cfg/admin-api.yaml" -Djavax.net.ssl.trustStore="$IRMA_HOME/cfg/cacerts" -classpath "$CLASSPATH" $LOG4J_CFG $MAIN_CLASS $*

exit $?