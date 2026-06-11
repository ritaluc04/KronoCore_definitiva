@echo off
echo [KronoCore] Generando archivo JAR actualizado...
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
call "%~dp0mvn_portable\apache-maven-3.9.5\bin\mvn.cmd" clean package -DskipTests
copy /Y "%~dp0target\backend-0.0.1-SNAPSHOT.jar" "%~dp0target\app.jar" > nul
echo.
echo [KronoCore] COMPILACION TERMINADA.
echo Tu archivo actualizado esta en la carpeta 'target' con el nombre app.jar (listo para Azure)
pause
