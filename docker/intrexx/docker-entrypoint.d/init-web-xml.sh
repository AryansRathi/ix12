#!/bin/bash

WEB_XML="${PORTAL_DIR}/external/htmlroot/WEB-INF/web.xml"

sed -i "s/connector\.security\.header\..*\.xuser/connector.security.header.${TOMCAT_SEC_HEADER_XUSER}.xuser/g" ${WEB_XML}
sed -i "s/connector\.security\.header\..*\.xdomain/connector.security.header.${TOMCAT_SEC_HEADER_XDOMAIN}.xdomain/g" ${WEB_XML}
sed -i "s/connector\.security\.header\..*\.xkrbticket/connector.security.header.${TOMCAT_SEC_HEADER_XKRBTICKET}.xkrbticket/g" ${WEB_XML}
sed -i "s/connector\.security\.header\..*\.xaccountname/connector.security.header.${TOMCAT_SEC_HEADER_XACCOUNTNAME}.xaccountname/g" ${WEB_XML}
sed -i "s/connector\.security\.header\..*\.xforwardedfor/connector.security.header.${TOMCAT_SEC_HEADER_XFORWARDEDFOR}.xforwardedfor/g" ${WEB_XML}
sed -i "s/connector\.security\.header\..*\.forwarded/connector.security.header.${TOMCAT_SEC_HEADER_FORWARDED}.forwarded/g" ${WEB_XML}
sed -i "s/connector\.security\.header\..*\.xrealip/connector.security.header.${TOMCAT_SEC_HEADER_XREALIP}.xrealip/g" ${WEB_XML}
sed -i "s/connector\.security\.header\..*\.xforwardedhost/connector.security.header.${TOMCAT_SEC_HEADER_XFORWARDEDHOST}.xforwardedhost/g" ${WEB_XML}
sed -i "s/connector\.security\.header\..*\.xforwardedproto/connector.security.header.${TOMCAT_SEC_HEADER_XFORWARDEDPROTO}.xforwardedproto/g" ${WEB_XML}
sed -i "s/connector\.security\.header\..*\.xoriginalurl/connector.security.header.${TOMCAT_SEC_HEADER_XORIGINALURL}.xoriginalurl/g" ${WEB_XML}

perl -0777 -pi -e "s/connector\.security\.header\.receiveOnNonLoopbackInterface<\/param-name>\n\s*<param-value>\w+<\/param-value>/connector.security.header.receiveOnNonLoopbackInterface<\/param-name>\n            <param-value>${TOMCAT_SEC_HEADER_RECEIVEONNONLOOPBACKINTERFACE}<\/param-value>/igs" ${WEB_XML}

