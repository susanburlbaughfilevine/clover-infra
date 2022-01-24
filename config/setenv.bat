REM --- RESET variable ---
set "CATALINA_OPTS="
REM --- set memory ---
set "CATALINA_OPTS=%CATALINA_OPTS% -XX:MaxMetaspaceSize=512m -Xms128m -Xmx1024m"
REM --- set cloverServer properties ---
set "CATALINA_OPTS=%CATALINA_OPTS% -Dclover.config.file=##tomcatConfDir##"
echo "Using CATALINA_OPTS: %CATALINA_OPTS%"