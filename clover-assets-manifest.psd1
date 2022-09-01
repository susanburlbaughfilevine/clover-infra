
@{
    jdk = @{
        PackageName      = "jdk-11.0.13+8.zip"
        FileLink         = "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.13%2B8/OpenJDK11U-jdk_x64_windows_hotspot_11.0.13_8.zip"
        Version          = "11.0.13_8"
        Checksum         = "087d096032efe273d7e754a25c85d8e8cf44738a3e597ad86f55e0971acc3b8e"
        ChecksumType     = "sha256"
    }

    tomcat = @{
        PackageName      = "apache-tomcat-9.0.65-windows-x64.zip"
        FileLink         = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.65/bin/apache-tomcat-9.0.65-windows-x64.zip"
        Version          = "9.0.65"
        Checksum         = "9ca8b1e734b7c815335d408de172212be3b8beacdcb6a7b742ff30b859cb1653477b02c7b8eccc1c6dc76153d4275cc958a8f704feffb47ab2aa89b917472b47"
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
        PackageName      = "secure-cfg-tool.5.14.1.zip"
        FileLink         = "https://support.cloverdx.com/download?file=5.14.1/server/common/Utilities/secure-cfg-tool.5.14.1.zip"
        Version          = "5.14.1"
        Checksum         = "b740b100a4bbd6ed34ae33a664dfb80e3e4c45da6dc6ebff698517f58a8c27ef"
        ChecksumType     = "sha256"
    }

    clover = @{
        PackageName      = "clover.war"
        FileLink         = "https://support.cloverdx.com/download?file=5.14.1/server/deploy/tomcat7-9/Application%20Files/clover.war"
        Version          = "5.14.1"
        Checksum         = "09104cb0e2581111842cd0e5dccfef38b378e09326ce72bd36e4b9bc04cc96e0"
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
}