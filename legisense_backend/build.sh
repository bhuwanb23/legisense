#!/usr/bin/env bash
# Exit on any error
set -o errexit

# Install dependencies
pip install -r requirements.txt

# Run database migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Make gunicorn config executable
chmod +x gunicorn.conf.py

echo "Build completed successfully!"
