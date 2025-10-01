@echo off
REM Legisense Docker Development Script for Windows
REM This script helps manage the development environment

setlocal enabledelayedexpansion

REM Colors (Windows doesn't support colors in batch, but we can use echo)
set "INFO=[INFO]"
set "SUCCESS=[SUCCESS]"
set "WARNING=[WARNING]"
set "ERROR=[ERROR]"

REM Function to check if Docker is running
:check_docker
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo %ERROR% Docker is not running. Please start Docker and try again.
    exit /b 1
)
goto :eof

REM Function to check if docker-compose is available
:check_docker_compose
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %ERROR% docker-compose is not installed. Please install it and try again.
    exit /b 1
)
goto :eof

REM Function to start development environment
:start_dev
echo %INFO% Starting Legisense development environment...
call :check_docker
call :check_docker_compose

REM Check if .env file exists
if not exist .env (
    echo %WARNING% .env file not found. Creating from template...
    copy env.example .env
    echo %WARNING% Please edit .env file with your configuration before continuing.
)

REM Start services
docker-compose -f docker-compose.dev.yml up --build -d

echo %SUCCESS% Development environment started!
echo %INFO% Frontend: http://localhost:8080
echo %INFO% Backend: http://localhost:8000
echo %INFO% Database: localhost:5432
echo %INFO% Redis: localhost:6379
goto :eof

REM Function to stop development environment
:stop_dev
echo %INFO% Stopping Legisense development environment...
docker-compose -f docker-compose.dev.yml down
echo %SUCCESS% Development environment stopped!
goto :eof

REM Function to restart development environment
:restart_dev
echo %INFO% Restarting Legisense development environment...
call :stop_dev
call :start_dev
goto :eof

REM Function to view logs
:view_logs
set service=%1
if "%service%"=="" (
    echo %INFO% Viewing logs for all services...
    docker-compose -f docker-compose.dev.yml logs -f
) else (
    echo %INFO% Viewing logs for %service%...
    docker-compose -f docker-compose.dev.yml logs -f %service%
)
goto :eof

REM Function to run database migrations
:run_migrations
echo %INFO% Running database migrations...
docker-compose -f docker-compose.dev.yml exec backend python manage.py migrate
echo %SUCCESS% Database migrations completed!
goto :eof

REM Function to create superuser
:create_superuser
echo %INFO% Creating Django superuser...
docker-compose -f docker-compose.dev.yml exec backend python manage.py createsuperuser
echo %SUCCESS% Superuser created!
goto :eof

REM Function to collect static files
:collect_static
echo %INFO% Collecting static files...
docker-compose -f docker-compose.dev.yml exec backend python manage.py collectstatic --noinput
echo %SUCCESS% Static files collected!
goto :eof

REM Function to run tests
:run_tests
set service=%1
if "%service%"=="backend" (
    echo %INFO% Running backend tests...
    docker-compose -f docker-compose.dev.yml exec backend python manage.py test
) else if "%service%"=="frontend" (
    echo %INFO% Running frontend tests...
    docker-compose -f docker-compose.dev.yml exec frontend flutter test
) else (
    echo %ERROR% Invalid service. Use 'backend' or 'frontend'
    exit /b 1
)
echo %SUCCESS% Tests completed!
goto :eof

REM Function to clean up
:cleanup
echo %INFO% Cleaning up Docker resources...
docker-compose -f docker-compose.dev.yml down -v
docker system prune -f
echo %SUCCESS% Cleanup completed!
goto :eof

REM Function to show status
:show_status
echo %INFO% Legisense Development Environment Status:
echo.
docker-compose -f docker-compose.dev.yml ps
echo.
echo %INFO% Service URLs:
echo %INFO%   Frontend: http://localhost:8080
echo %INFO%   Backend: http://localhost:8000
echo %INFO%   Database: localhost:5432
echo %INFO%   Redis: localhost:6379
goto :eof

REM Function to show help
:show_help
echo Legisense Docker Development Script
echo.
echo Usage: %0 [COMMAND]
echo.
echo Commands:
echo   start       Start the development environment
echo   stop        Stop the development environment
echo   restart     Restart the development environment
echo   logs        View logs (optionally specify service: backend, frontend, db, redis)
echo   migrate     Run database migrations
echo   superuser   Create Django superuser
echo   static      Collect static files
echo   test        Run tests (specify service: backend, frontend)
echo   status      Show environment status
echo   cleanup     Clean up Docker resources
echo   help        Show this help message
echo.
echo Examples:
echo   %0 start
echo   %0 logs backend
echo   %0 test frontend
echo   %0 migrate
goto :eof

REM Main script logic
set command=%1
if "%command%"=="" set command=help

if "%command%"=="start" (
    call :start_dev
) else if "%command%"=="stop" (
    call :stop_dev
) else if "%command%"=="restart" (
    call :restart_dev
) else if "%command%"=="logs" (
    call :view_logs %2
) else if "%command%"=="migrate" (
    call :run_migrations
) else if "%command%"=="superuser" (
    call :create_superuser
) else if "%command%"=="static" (
    call :collect_static
) else if "%command%"=="test" (
    call :run_tests %2
) else if "%command%"=="status" (
    call :show_status
) else if "%command%"=="cleanup" (
    call :cleanup
) else if "%command%"=="help" (
    call :show_help
) else (
    echo %ERROR% Unknown command: %command%
    call :show_help
    exit /b 1
)
