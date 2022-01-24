
@{
    jdk = @{
        PackageName      = "jdk-11.0.13+8.zip"
        FileLink         = "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.13%2B8/OpenJDK11U-jdk_x64_windows_hotspot_11.0.13_8.zip"
        Version          = "11.0.13_8"
        Checksum         = "087d096032efe273d7e754a25c85d8e8cf44738a3e597ad86f55e0971acc3b8e"
        ChecksumType     = "sha256"
    }

    tomcat = @{
        PackageName      = "apache-tomcat-9.0.58.zip"
        FileLink         = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.58/bin/apache-tomcat-9.0.58-windows-x64.zip"
        Version          = "9.0.58"
        Checksum         = "e2e70436cb29de2a53c2ce6bf1232dc7fb280aea57359f5d1b337569aa860ac6339e9ea847d597e9cfd93240e2daa36329c66e65f024129da9f67b1b6c24bf39"
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