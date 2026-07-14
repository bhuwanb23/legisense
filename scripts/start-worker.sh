#!/usr/bin/env bash
set -euo pipefail

# Start the Celery worker that processes pending document analyses.
# Requires the backend dependencies installed (pip install -r requirements.txt)
# and REDIS_URL (or a running Redis) configured in the environment / .env.

cd "$(dirname "$0")/.."

export DJANGO_SETTINGS_MODULE=legisense_backend.settings

if [ -z "${REDIS_URL:-}" ] && [ -f .env ]; then
    set -a
    source .env
    set +a
fi

exec celery -A legisense_backend worker -l info
