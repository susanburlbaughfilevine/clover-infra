
@{
    jdk = @{
        PackageName      = "jdk-11.0.13+8.zip"
        FileLink         = "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.13%2B8/OpenJDK11U-jdk_x64_windows_hotspot_11.0.13_8.zip"
        Version          = "11.0.13_8"
        Checksum         = "087d096032efe273d7e754a25c85d8e8cf44738a3e597ad86f55e0971acc3b8e"
        ChecksumType     = "sha256"
    }

    tomcat = @{
        PackageName      = "apache-tomcat-9.0.62.zip"
        FileLink         = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.62/bin/apache-tomcat-9.0.62-windows-x64.zip"
        Version          = "9.0.60"
        Checksum         = "fc44356c8b59e878631036bf9fd32203e0eaa66421cd34efc88afc534fd861ea428c3a596f6aff19482529d2422a333f6373eea3167289f0f74fb8c50f6ef62c"
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
        FileLink         = "https://support.cloverdx.com/download?file=5.14.0/server/deploy/tomcat7-9/Application%20Files/clover.war"
        Version          = "5.14.0"
        Checksum         = "3a29dd539eaed93ff77b27917388b9b348dc1ee29fe449bdd34148367fbce265"
        ChecksumType     = "sha256"
    }

    profiler = @{
        PackageName      = "profiler.war"
        FileLink         = "https://support.cloverdx.com/download?file=5.14.0/server/deploy/tomcat7-9/Application%20Files/profiler.war"
        Version          = "5.14.0"
        Checksum         = "2d0a7e69929e03b2561db409450e5e8f4039c7a11fd6d625e983b71fed3f7f40"
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