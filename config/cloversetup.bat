CALL SET JvmArgs="-Dclover.config.file=##tomcatConfDir## -Djdk.nio.maxcacheBufferSize=262144"

CALL SET CATALINA_OPTS="USE_DIRECT_MEMORY=false -XX:ReservedCodeCacheSize-256m -XX:MaxMetaspaceSize=512m -Xms128m -Xmx1024m"

REM CALL CD %CATALINA_HOME%\bin
REM service install "cloverDx"
service install