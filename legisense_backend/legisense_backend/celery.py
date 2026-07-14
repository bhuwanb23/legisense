from __future__ import annotations

import os

try:
    from celery import Celery
except ImportError:  # celery not installed -> app runs via the threaded fallback
    Celery = None

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "legisense_backend.settings")

redis_url = os.getenv("REDIS_URL", "")

if Celery is not None:
    app = Celery("legisense_backend")

    if redis_url:
        app.conf.update(
            broker_url=redis_url,
            result_backend=redis_url,
            task_serializer="json",
            result_serializer="json",
            accept_content=["json"],
            task_track_started=True,
            timezone="UTC",
        )

    app.autodiscover_tasks()

    @app.task(bind=True)
    def debug_task(self):
        print(f"Request: {self.request!r}")
else:
    app = None
