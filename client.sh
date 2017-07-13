#!/bin/sh

if [ `echo $CI_BUILD_REF | wc -c` -eq 1 ]; then
    JAR_FILE="swagger-java-client-`date +%Y%m%d-%H%M%S`.jar"
else
    JAR_FILE="swagger-java-client-`echo $CI_BUILD_REF`.jar"
fi


SCRIPT="$0"

while [ -h "$SCRIPT" ] ; do
  ls=`ls -ld "$SCRIPT"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    SCRIPT="$link"
  else
    SCRIPT=`dirname "$SCRIPT"`/"$link"
  fi
done

if [ ! -d "${APP_DIR}" ]; then
  APP_DIR=`dirname "$SCRIPT"`/..
  APP_DIR=`cd "${APP_DIR}"; pwd`
fi

executable="./swagger-codegen-cli.jar"


if [ ! -f "$executable" ]
then
  wget http://central.maven.org/maven2/io/swagger/swagger-codegen-cli/2.2.2/swagger-codegen-cli-2.2.2.jar -O swagger-codegen-cli.jar
fi

# if you've executed sbt assembly previously it will use that instead.
export JAVA_OPTS="${JAVA_OPTS} -XX:MaxPermSize=256M -Xmx1024M -DloggerPath=conf/log4j.properties"
agsJava="$@ generate -i swagger.json -l java -c config.json -o api_client --library=jersey2 -DhideGenerationTimestamp=true"
agsHtml="$@ generate -i swagger.json -l html2 -o html_site"
agsJS="$@ generate \
-i swagger.json -l javascript \
-o clever-cloud-javascript-api \
--additional-properties usePromises=true"
java $JAVA_OPTS -jar $executable $agsJava

# Generate Java Client

TMP_FILE=".tmp.$$"

cp files/OAuth.java api_client/src/main/java/io/swagger/client/auth/
cp files/CleverApiClient.java api_client/src/main/java/io/swagger/client/

echo "import org.glassfish.jersey.client.oauth1.AccessToken;" > $TMP_FILE
cat api_client/src/main/java/io/swagger/client/ApiClient.java | sed 's/String accessToken/AccessToken accessToken/' | sed 's/package io.swagger.client;//' >> $TMP_FILE
echo "package io.swagger.client;" > api_client/src/main/java/io/swagger/client/ApiClient.java
echo >> api_client/src/main/java/io/swagger/client/ApiClient.java
cat $TMP_FILE >> api_client/src/main/java/io/swagger/client/ApiClient.java
rm $TMP_FILE
sed -i   186i"   \<dependency\>\n      \<groupId\>org.glassfish.jersey.security\</groupId\>\n      \<artifactId\>oauth1-client\</artifactId\>\n      \<version\>\$\{jersey-version\}\</version\>\n   \</dependency\>"  api_client/pom.xml

# Generate HTML Static site
java $JAVA_OPTS -jar $executable $agsHtml

# Generate JS client
java $JAVA_OPTS -jar $executable $agsJS

TMP_FILE=".tmp.$$"
cat clever-cloud-javascript-api/src/ApiClient.js | head -n $((`cat clever-cloud-javascript-api/src/ApiClient.js | wc -l`-3)) | sed "s/auth.accessToken/auth.token/" | sed "s/'Bearer ' + auth.token/exports.prototype.getHMACAuthorization(request.method, request.url, {}, auth)/" > $TMP_FILE
cat files/ApiClient.js >> $TMP_FILE && cat $TMP_FILE > clever-cloud-javascript-api/src/ApiClient.js
rm -rf $TMP_FILE

cd clever-cloud-javascript-api
yarn add --save lodash crypto oauth-sign superagent

# FIX doc
sed -i 's/OAuthSecurity.accessToken = .*\;/OAuthSecurity.consumerKey = YOUR CONSUMER KEY\nOAuthSecurity.consumerSecret = YOUR CONSUMER SECRET\nOAuthSecurity.token = YOUR TOKEN\nOAuthSecurity.tokenSecret = YOUR TOKEN SECRET/' docs/DefaultApi.md
