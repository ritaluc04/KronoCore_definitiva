@echo off
:: Este script esta diseñado para funcionar incluso en rutas con parentesis como (3)

echo [PASO 0] Verificando inicio...
echo Directorio: %~dp0
echo.

:: 1. CONFIGURAR JAVA (Ruta de Android Studio)
set "JAVA_BIN=C:\Program Files\Android\Android Studio\jbr\bin\java.exe"
if not exist "%JAVA_BIN%" echo [!] No se encontro Java en Android Studio && pause && exit /b 1

set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo [PASO 1] Java configurado correctamente.

:: 2. VERIFICAR MAVEN
if exist "mvn_portable" goto :ejecutar

echo [PASO 2] No tienes Maven. Descargandolo (solo una vez)...
echo Esto tardara un minuto, por favor no cierres la ventana.
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $url = 'https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.zip'; Invoke-WebRequest -Uri $url -OutFile 'maven.zip'; Expand-Archive -Path 'maven.zip' -DestinationPath 'mvn_portable' -Force; Remove-Item 'maven.zip'"

:ejecutar
echo [PASO 3] Iniciando el servidor...
echo.

:: Definimos la ruta de Maven y ejecutamos
set "MVN_CMD=%~dp0mvn_portable\apache-maven-3.9.5\bin\mvn.cmd"
if not exist "%MVN_CMD%" echo [ERROR] No se pudo instalar Maven. && pause && exit /b 1

set "MAVEN_OPTS=-Dfile.encoding=UTF-8"
call "%MVN_CMD%" clean spring-boot:run

echo.
echo El proceso ha terminado.
pause
