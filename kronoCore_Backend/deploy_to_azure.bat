@echo off
echo [KronoCore] Configurando Java para Maven...
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo [KronoCore] Ejecutando configuracion de Azure...
call "%~dp0mvn_portable\apache-maven-3.9.5\bin\mvn.cmd" com.microsoft.azure:azure-webapp-maven-plugin:2.12.0:config

echo [KronoCore] Ejecutando despliegue a Azure...
call "%~dp0mvn_portable\apache-maven-3.9.5\bin\mvn.cmd" clean package azure-webapp:deploy

pause
