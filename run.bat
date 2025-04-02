@echo off
setlocal

:: Set MySQL credentials and DB names
set MYSQL_USER=wso2carbon
set MYSQL_PASSWORD=wso2carbon
set WSO2AM_SHARED_DB=WSO2AM_SHARED_DB
set WSO2AM_DB=WSO2AM_DB

:: Function to print titles
call :print_title "Starting Script"

:: Function to wait for a service to start
call :wait_for_service_start "apim-acp" 0
call :wait_for_service_start "apim-tm" 1
call :wait_for_service_start "apim-universal-gw" 2

:: Parse input arguments
set CMD=
set SEED=
for %%c in (%*) do (
    if "%%c"=="--stop" set CMD=stop
    if "%%c"=="-stop" set CMD=stop
    if "%%c"=="stop" set CMD=stop
    if "%%c"=="--start" set CMD=start
    if "%%c"=="-start" set CMD=start
    if "%%c"=="start" set CMD=start
    if "%%c"=="--seed" set SEED=seed
    if "%%c"=="-seed" set SEED=seed
    if "%%c"=="--restart" set CMD=restart
    if "%%c"=="-restart" set CMD=restart
    if "%%c"=="restart" set CMD=restart
)

:: Stop services if the stop command is passed
if "%CMD%"=="stop" (
    call :stop_services
    exit /b
)

:: Create logs directory and clean it
mkdir logs
del /q logs\*

:: Copy deployment.toml files
call :print_title "Copying deployment.toml files"
xcopy /s /e /y .\conf\apim-acp\repository\* .\components\wso2am-acp\repository\
xcopy /s /e /y .\conf\apim-tm\repository\* .\components\wso2am-tm\repository\
xcopy /s /e /y .\conf\apim-universal-gw\repository\* .\components\wso2am-universal-gw\repository\

:: Copy mysql-connector-j-8.4.0.jar
call :print_title "Copying mysql-connector-j-8.4.0.jar"
xcopy /y .\lib\mysql-connector-j-8.4.0.jar .\components\wso2am-acp\repository\components\lib\
xcopy /y .\lib\mysql-connector-j-8.4.0.jar .\components\wso2am-tm\repository\components\lib\
xcopy /y .\lib\mysql-connector-j-8.4.0.jar .\components\wso2am-universal-gw\repository\components\lib\

:: Start Docker containers
call :print_title "Starting docker containers"
docker-compose up -d

:: Wait for MySQL to start
echo Waiting for MySQL to start...
docker-compose exec mysql mysqladmin --silent --wait=30 -uroot -proot ping
if %errorlevel% neq 0 (
    echo Error: MySQL did not start within the expected time
    exit /b %errorlevel%
)

:: Seed the database if the --seed flag is set
if "%SEED%"=="seed" if not "%CMD%"=="stop" (
    call :print_title "Seeding database"
    docker-compose exec mysql mysql -u%MYSQL_USER% -p%MYSQL_PASSWORD% -e "USE %WSO2AM_SHARED_DB%; source /home/dbScripts/mysql.sql"
    docker-compose exec mysql mysql -u%MYSQL_USER% -p%MYSQL_PASSWORD% -e "USE %WSO2AM_DB%; source /home/dbScripts/apimgt/mysql.sql"
)

if %errorlevel% neq 0 (
    echo Error seeding database. Exiting.
    exit /b %errorlevel%
)

:: Start apim-acp
call :print_title "Starting apim-acp"
start "" .\components\wso2am-acp\bin\api-cp.bat > logs\apim-acp.log 2>&1
if %errorlevel% neq 0 (
    echo Error starting apim-acp. Exiting.
    exit /b %errorlevel%
)
:: Wait for apim-acp to fully start
call :wait_for_service_start "apim-acp" 0

:: Start apim-tm
call :print_title "Starting apim-tm"
start "" .\components\wso2am-tm\bin\traffic-manager.bat -DportOffset=1 > logs\apim-tm.log 2>&1
if %errorlevel% neq 0 (
    echo Error starting apim-tm. Exiting.
    exit /b %errorlevel%
)
:: Wait for apim-tm to fully start
call :wait_for_service_start "apim-tm" 1

:: Start apim-universal-gw
call :print_title "Starting apim-universal-gw"
start "" .\components\wso2am-universal-gw\bin\gateway.bat -DportOffset=2 > logs\apim-universal-gw.log 2>&1
if %errorlevel% neq 0 (
    echo Error starting apim-universal-gw. Exiting.
    exit /b %errorlevel%
)
:: Wait for apim-universal-gw to fully start
call :wait_for_service_start "apim-universal-gw" 2

exit /b

:: Function to print titles
:print_title
echo.
echo === %1 ===
echo.

exit /b

:: Function to wait for a service to start
:wait_for_service_start
set service_name=%1
set port_offset=%2
set base_port=9763
set /a check_port=%base_port%+%port_offset%

echo Waiting for %service_name% to start...
set max_retries=30
set counter=0
:wait_loop
if %counter% lss %max_retries% (
    curl --silent --fail http://localhost:%check_port%/services/Version >nul 2>&1
    if %errorlevel% equ 0 (
        echo %service_name% is up and running
        exit /b 0
    )
    echo Waiting for %service_name% to start... (%counter%/%max_retries%)
    set /a counter+=1
    timeout /t 5 >nul
    goto wait_loop
)

if %counter% equ %max_retries% (
    echo Error: %service_name% did not start within the expected time
    exit /b 1
)

exit /b
