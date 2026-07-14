from __future__ import annotations

import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "legisense_backend.settings")

redis_url = os.getenv("REDIS_URL", "")

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
