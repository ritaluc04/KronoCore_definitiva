@echo off
:: Arranca el backend con PostgreSQL (perfil Spring "postgres").
:: Lee credenciales desde .env en esta carpeta (ver .env.example).

echo [KronoCore] Modo PostgreSQL (perfil: postgres)
echo.

cd /d "%~dp0"

if exist ".env" (
  echo [KronoCore] Cargando variables desde .env ...
  for /f "usebackq eol=# tokens=1,* delims==" %%a in (".env") do (
    if not "%%b"=="" set "%%a=%%b"
  )
) else (
  echo [!] No existe .env - copia .env.example a .env y configura tu servidor.
  pause
  exit /b 1
)

:: ---------------------------------------------------------------------------
:: Liberar el puerto 8080 si ya está en uso
:: (para evitar "Port 8080 was already in use")
:: Usamos PowerShell para evitar problemas de parseo en cmd/netstat.
:: ---------------------------------------------------------------------------
set "PORT_TO_FREE=8080"
echo Verificando si el puerto %PORT_TO_FREE% esta en uso...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$port=%PORT_TO_FREE%; $pids = (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique); if($pids){ foreach($procId in $pids){ Write-Host \"[INFO] Deteniendo proceso PID $procId en puerto $port\"; Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue | Out-Null } } else { Write-Host \"[OK] Puerto $port libre.\" }"

set "JAVA_BIN=C:\Program Files\Android\Android Studio\jbr\bin\java.exe"
if not exist "%JAVA_BIN%" echo [!] No se encontro Java en Android Studio && pause && exit /b 1

set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"

if exist "mvn_portable" goto :ejecutar

echo Descargando Maven portable (solo la primera vez)...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $url = 'https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.zip'; Invoke-WebRequest -Uri $url -OutFile 'maven.zip'; Expand-Archive -Path 'maven.zip' -DestinationPath 'mvn_portable' -Force; Remove-Item 'maven.zip'"

:ejecutar
set "MVN_CMD=%~dp0mvn_portable\apache-maven-3.9.5\bin\mvn.cmd"
if not exist "%MVN_CMD%" echo [ERROR] Maven no encontrado. && pause && exit /b 1

set "MAVEN_OPTS=-Dfile.encoding=UTF-8"
echo Conectando a jdbc:postgresql://%POSTGRES_HOST%:%POSTGRES_PORT%/%POSTGRES_DB% usuario=%POSTGRES_USER%
echo Verificando/creando base de datos "%POSTGRES_DB%" si es necesario...
echo.

:: ---------------------------------------------------------------------------
:: Crear la base de datos automáticamente (si existe psql en el PATH)
:: Nota: PostgreSQL no permite conectar a una BD inexistente; por eso usamos la
:: BD "postgres" para ejecutar el CREATE DATABASE si falta.
:: ---------------------------------------------------------------------------
where psql >nul 2>nul
if %errorlevel%==0 (
  set "PGPASSWORD=%POSTGRES_PASSWORD%"
  for /f "usebackq delims=" %%i in (`psql -h "%POSTGRES_HOST%" -p "%POSTGRES_PORT%" -U "%POSTGRES_USER%" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='%POSTGRES_DB%';" 2^>nul`) do set "DB_EXISTS=%%i"
  if "%DB_EXISTS%"=="1" (
    echo [OK] La base "%POSTGRES_DB%" ya existe.
  ) else (
    echo [INFO] La base "%POSTGRES_DB%" no existe. Creandola...
    psql -h "%POSTGRES_HOST%" -p "%POSTGRES_PORT%" -U "%POSTGRES_USER%" -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE %POSTGRES_DB%;" 1>nul
    if %errorlevel%==0 (
      echo [OK] Base creada: "%POSTGRES_DB%".
    ) else (
      echo [ERROR] No se pudo crear la base "%POSTGRES_DB%".
      echo Revisa permisos del usuario "%POSTGRES_USER%" o crea la BD manualmente con:
      echo   db\CREAR_BD_KRONOCORE.sql
      pause
      exit /b 1
    )
  )
) else (
  echo [WARN] No se encontro "psql" en el PATH. No puedo crear la BD automaticamente.
  echo Crea la base "%POSTGRES_DB%" manualmente con:
  echo   db\CREAR_BD_KRONOCORE.sql
  echo.
)

call "%MVN_CMD%" clean spring-boot:run -Dspring-boot.run.profiles=postgres

echo.
pause
