
@{
    jdk = @{
        PackageName      = "jdk-11.0.13+8.zip"
        FileLink         = "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.13%2B8/OpenJDK11U-jdk_x64_windows_hotspot_11.0.13_8.zip"
        Version          = "11.0.13_8"
        Checksum         = "087d096032efe273d7e754a25c85d8e8cf44738a3e597ad86f55e0971acc3b8e"
        ChecksumType     = "sha256"
    }

    tomcat = @{
        PackageName      = "apache-tomcat-9.0.56.zip"
        FileLink         = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.56/bin/apache-tomcat-9.0.56.zip"
        Version          = "9.0.56"
        Checksum         = "d575df6ffe46b48105aac3b95af39eddf230c588d2d30ed8cac0184f8f3679c4926818533e3047d0cd001106761887a36e2d12a8941d198071cc71bda0fe6fbb"
        ChecksumType     = "sha512"
    }

    # Pulling from maven mirror because primary BC site only uses SSLv3, with ciphers .NET5/Powershell 7.1.0+ won't respect without OS confg tweaks
    bouncycastle = @{
        PackageName      = "bouncycastle.jar"
        FileLink         = "https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk15on/1.70/bcprov-jdk15on-1.70.jar"
        Version          = "1.70"
        Checksum         = "4636a0d01f74acaf28082fb62b317f1080118371"
        ChecksumType     = "sha1"
    }

    securecfg = @{
        PackageName      = "secure-cfg-tool.5.13.1.zip"
        FileLink         = "https://support.cloverdx.com/download?file=5.13.1/server/common/Utilities/secure-cfg-tool.5.13.1.zip"
        Version          = "5.13.1"
        Checksum         = "9acedcdc5118f22e28658a88268cbb3b5c4c7fc8437d8bcbc3d04015a24cc3ae"
        ChecksumType     = "sha256"
    }

    clover = @{
        PackageName      = "clover.war"
        FileLink         = "https://support.cloverdx.com/download?file=5.13.1/server/deploy/tomcat7-9/Application%20Files/clover.war"
        Version          = "5.13.1"
        Checksum         = "e628419229b491cb1599e64524f5d444a82e79a7f0b9bbdf08f07658793c30f4"
        ChecksumType     = "sha256"
    }

    profiler = @{
        PackageName      = "profiler.war"
        FileLink         = "https://support.cloverdx.com/download?file=5.13.1/server/deploy/tomcat7-9/Application%20Files/profiler.war"
        Version          = "5.13.1"
        Checksum         = "e0edfe23a2fbab178211633042c65b83e9b7d7d9ee806a25dd676fe4152ea465"
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