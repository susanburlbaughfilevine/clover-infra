
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
        PackageName      = "apache-tomcat-9.0.68.zip"
        FileLink         = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.69/bin/apache-tomcat-9.0.69-windows-x64.zip"
        Version          = "9.0.69"
        Checksum         = "8fa143543f6ea811bf445824aab4afa329b000aeba530aeb908849556671db1830b0fbe47f7a30b6ebb8e97e47ed95dc66e3d1135fbba9ebb8ad5c1335069cd1"
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
        PackageName      = "secure-cfg-tool.5.16.1.zip"
        FileLink         = "https://support.cloverdx.com/download?file=5.16.1/server/common/Utilities/secure-cfg-tool.5.16.1.zip"
        Version          = "5.16.1"
        Checksum         = "e83a3a81f31a3f014e3644e66e6063145fc3b709ad921408e76f72331cdfa6e7"
        ChecksumType     = "sha256"
    }

    clover = @{
        PackageName      = "clover.war"
        FileLink         = "https://support.cloverdx.com/download?file=5.16.1/server/deploy/tomcat7-9/Application%20Files/clover.war"
        Version          = "5.16.1"
        Checksum         = "1aec6eafe13a644f68ffaba4fbeba306225cf076ee47f63db879ac99e985982e"
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
