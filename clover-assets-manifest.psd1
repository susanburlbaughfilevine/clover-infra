
@{
    jdk = @{
        PackageName      = "jdk-11.0.13+8.zip"
        FileLink         = "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.13%2B8/OpenJDK11U-jdk_x64_windows_hotspot_11.0.13_8.zip"
        Version          = "11.0.13_8"
        Checksum         = "087d096032efe273d7e754a25c85d8e8cf44738a3e597ad86f55e0971acc3b8e"
        ChecksumType     = "sha256"
    }

    tomcat = @{
        # PackageName should be the name of the folder inside of the downladed zip
        PackageName      = "apache-tomcat-9.0.76.zip"
        FileLink         = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.76/bin/apache-tomcat-9.0.76-windows-x64.zip"
        Version          = "9.0.76"
        Checksum         = "A96582CE2903CEF810B9C9564661846EBDB9ECBD9D2AB9D286E646E1E7A8B9DAC093ECB319DE4A345B3A0EA00A05BEBD566C81310C1F9A79360FF82D5CD3F33F"
        ChecksumType     = "sha512"
    }

    # Pulling from maven mirror because primary BC site only uses SSLv3, with ciphers .NET5/Powershell 7.1.0+ won't respect without OS confg tweaks
    bouncycastle = @{
        PackageName      = "bcprov-jdk15on-1.70.jar"
        FileLink         = "https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk15on/1.70/bcprov-jdk15on-1.70.jar"
        Version          = "1.70"
        Checksum         = "4636a0d01f74acaf28082fb62b317f1080118371"
        ChecksumType     = "sha1"
    }

    securecfg = @{
        PackageName      = "secure-cfg-tool.6.0.0.zip"
        FileLink         = "https://support.cloverdx.com/download?file=6.0.0/server/common/Utilities/secure-cfg-tool.6.0.0.zip"
        Version          = "6.0.0"
        Checksum         = "b120d93a7b6cd1ecf0bb6e3121b8586f36e3048149d7834e91dc316dea0dacd0"
        ChecksumType     = "sha256"
    }

    clover = @{
        PackageName      = "clover.war"
        FileLink         = "https://support.cloverdx.com/download?file=6.0.0/server/deploy/tomcat7-9/Application%20Files/clover.war"
        Version          = "6.0.0"
        Checksum         = "a46eb2173fbc26dbdcf7d90a4ea9250fb1349b6756007d926b8c987a8cf70c9d"
        ChecksumType     = "sha256"
    }

    profiler = @{
        PackageName      = "profiler.war"
        FileLink         = "https://support.cloverdx.com/download?file=5.14.2/server/deploy/tomcat7-9/Application%20Files/profiler.war"
        Version          = "5.14.2"
        Checksum         = "f1c463a529e8bd9a80dfd84d7df68fd8e25cb4fa830119fb554e20b1188ec9c5"
        ChecksumType     = "sha256"
    }

    pg_jdbc = @{
        PackageName      = "pgjdbc.jar"
        FileLink         = "https://jdbc.postgresql.org/download/postgresql-42.3.1.jar"
        Version          = "42.3.1"
        Checksum         = "none"
        ChecksumType     = "none"
    }

    reload4j = @{
        PackageName      = "reload4j.jar"
        FileLink         = "https://repo1.maven.org/maven2/ch/qos/reload4j/reload4j/1.2.22/reload4j-1.2.22.jar"
        Version          = "1.2.22"
        Checksum         = "FA09C72FB0E6973B10D8129BD379C30E0EADD530C725BA965743AB272046500FFEA975A0F824E9059038E4178FB9AD8B9C85DB60C6CF39A771E458A195600276"
        ChecksumType     = "sha512"
    }
}
