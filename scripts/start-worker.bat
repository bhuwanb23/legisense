@echo off
REM Start the Celery worker that processes pending document analyses.
REM Requires the backend dependencies installed (pip install -r requirements.txt)
REM and REDIS_URL (or a running Redis) configured in the environment / .env.

cd /d "%~dp0.."

set DJANGO_SETTINGS_MODULE=legisense_backend.settings

if not defined REDIS_URL (
    if exist .env (
        for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
            if /i "%%A"=="REDIS_URL" set "REDIS_URL=%%B"
        )
    )
)

celery -A legisense_backend worker -l info
