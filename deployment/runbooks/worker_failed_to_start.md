# Worker failed to start
* Double check the URL that the “/clover” is present
* If not, chances you are on older version of the machine image, and need to start the service via command line:
* `PS C:\tomcat\CloverDXServer.5.5.1.Tomcat-9.0.22\bin> .\startup.bat`
* This should be resolved once we can rotate the servers (and figure out the hard drive rotation plan/strategy)