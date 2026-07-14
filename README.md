<div align="center">

# Legisense — AI-Powered Legal Companion

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Django](https://img.shields.io/badge/Django-5.2-092E20?logo=django&logoColor=white)](https://www.djangoproject.com/)
[![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Celery](https://img.shields.io/badge/Celery-5.4-37814A?logo=celery&logoColor=white)](https://docs.celeryq.dev/)
[![License](https://img.shields.io/badge/License-MIT-informational)](LICENSE)

**A citizen-first, India-first legal AI companion that reads contracts, explains them in plain language, and simulates real-world consequences before you sign.**

</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start (Docker)](#quick-start-docker)
- [Manual Setup](#manual-setup)
- [Background Processing (Celery Worker)](#background-processing-celery-worker)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [Key Code Paths](#key-code-paths)
- [Development](#development)
- [Deployment](#deployment)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Disclaimer](#disclaimer)

---

## Overview

Most people in India — tenants, freelancers, small-business owners — cannot afford a lawyer to review the contracts they sign every day (rent agreements, loans, insurance, terms of service). The language is dense, the risks are hidden, and the consequences (auto-renewals, penalties, foreclosure) only appear after something goes wrong.

**Legisense** is a mobile-first companion that closes that gap:

- **Understandable** — it turns legal jargon into plain-language summaries at three reading levels.
- **Actionable** — it runs *what-if* simulations ("miss 2 EMIs → default in 90 days → foreclosure in 6 months").
- **Protective** — it flags unfair clauses and red-flag risks with clear "why it matters" explanations.
- **Multilingual** — English, Hindi, Tamil, and Telugu.
- **Empathetic** — guides users with checklists, negotiation drafts, and links to legal-aid resources.

---

## Features

- **PDF Upload & Parsing** — extract text from contracts (pdfminer / pdfplumber) and persist the document with its pages.
- **AI Contract Analysis** — structured, JSON-backed analysis of clauses, risks, and obligations via OpenRouter LLMs.
- **What-If Simulation** — generates a scenario model (timeline, penalty forecast, exit comparisons, narratives, long-term projection, risk alerts) from the document.
- **Penalty Forecasts** — visualized month-by-month financial exposure.
- **Gemini Chat** — an in-app legal assistant powered by Google Gemini, with automatic translation of responses.
- **Multilingual Support** — English ↔ Hindi / Tamil / Telugu for documents, analysis, simulations, and chat.
- **Notifications** — category-filtered alerts and recent-activity surfaces.
- **Profiles & Preferences** — reading level, preferred language, and history.

---

## Architecture

Legisense is a two-package monorepo: a **Flutter** front end and a **Django + Django REST Framework** back end, with a **Celery + Redis** worker for long-running analysis and an **nginx** reverse proxy in production.

```mermaid
flowchart LR
    U[User] -->|Flutter app| FE[Frontend :3000 / :8080]
    FE -->|HTTPS /api| NG[Nginx :80]
    NG --> BE[Django + DRF :8000]
    BE -->|enqueue| CEL[Celery Worker]
    CEL --> RED[(Redis :6379)]
    CEL -->|analysis| OR[OpenRouter LLM]
    BE -->|chat| GEM[Google Gemini]
    BE --> DB[(PostgreSQL :5432 / SQLite)]
    BE --> MEDIA[Media & Static Storage]
```

**Request flow (document analysis):**

1. Frontend uploads a PDF to `POST /api/parse-pdf/`.
2. The backend stores the file, extracts text, and creates a `pending` analysis record.
3. A **Celery task** (`api.tasks.process_document_analysis`) runs the LLM analysis asynchronously (works for documents of **any** length) and persists the result, then triggers translations.
4. The frontend polls `GET /api/documents/<id>/analysis/` until the analysis is `success` and renders it.

> **Why a worker?** Analysis calls an external LLM and can take well beyond a normal HTTP request budget, especially for multi-page contracts. Offloading it to Celery keeps uploads fast and the API responsive. If Redis/`REDIS_URL` is not configured, the app gracefully falls back to a background thread so it still works in minimal local setups.

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | Flutter (Dart 3) | Cross-platform mobile-first UI |
| Backend | Django 5.2 + Django REST Framework | API, business logic, ORM |
| Async Workers | Celery 5.4 + Redis | Background document analysis & translation |
| LLM — Analysis | OpenRouter (configurable model) | Contract analysis & simulation generation |
| LLM — Chat | Google Gemini | Conversational legal assistant |
| Database | PostgreSQL (prod) / SQLite (dev) | Persistent storage |
| Web Server | Gunicorn + nginx | WSGI serving & reverse proxy |
| Optional | Ollama | Self-hosted LLM alternative |

---

## Project Structure

```
legisense/
├── legisense/                 # Flutter frontend
│   ├── lib/
│   │   ├── api/            # HTTP repositories (ParsedDocumentsRepository, etc.)
│   │   ├── pages/          # Home, Documents, Simulation, Notifications, Profile
│   │   ├── theme/          # App theme helpers
│   │   └── utils/         # Responsive / navigation helpers
│   ├── assets/            # Images, logos
│   ├── pubspec.yaml
│   └── Dockerfile          # Multi-stage Flutter → nginx build
├── legisense_backend/        # Django backend
│   ├── api/               # Views, models, URLs, Celery tasks
│   ├── ai_models/         # LLM clients (OpenRouter, Gemini), analysis & simulation
│   ├── translation/        # Multilingual translation service
│   ├── documents/         # PDF parsing
│   ├── google_cloud/      # Cloud client config (mock mode supported)
│   ├── legisense_backend/  # Settings, Celery app, WSGI/ASGI
│   ├── requirements.txt
│   └── Dockerfile
├── scripts/                # docker-dev / docker-prod / start-worker helpers
├── nginx/                 # nginx.conf for production
├── docker-compose.yml      # Production composition (backend + worker + db + redis + nginx)
├── docker-compose.dev.yml  # Development composition
├── env.example
├── docker.md
├── CONTRIBUTING.md
└── README.md
```

---

## Prerequisites

- **Docker** 20.10+ and **Docker Compose** v2 (recommended path), **or**
- **Flutter** 3.x (Dart 3) + **Python** 3.11+ for a manual local setup.
- **Git**.
- API keys for live AI features:
  - `OPENROUTER_API_KEY` (contract analysis & simulation)
  - `GOOGLE_GEMINI_API_KEY` (chat assistant)

---

## Quick Start (Docker)

This is the recommended way to run the whole stack.

### 1. Clone and configure

```bash
git clone <your-repository-url>
cd legisense
cp env.example .env
# Edit .env: set DEBUG=false, a strong SECRET_KEY, and your API keys
```

### 2. Start the stack

```bash
# Production-like (nginx + worker + postgres + redis)
docker compose up --build -d

# Or development (hot-reload, frontend on :8080)
docker compose -f docker-compose.dev.yml up --build -d
```

### 3. Apply migrations & create an admin user

```bash
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py createsuperuser
```

### 4. Access the application

| Service | Production | Development |
|---------|------------|-------------|
| Frontend | http://localhost:3000 | http://localhost:8080 |
| Backend API | http://localhost:8000/api/ | http://localhost:8000/api/ |
| Admin | http://localhost:8000/admin/ | http://localhost:8000/admin/ |
| PostgreSQL | localhost:5432 | localhost:5432 |
| Redis | localhost:6379 | localhost:6379 |

---

## Manual Setup

### Backend (Django)

```bash
cd legisense_backend
python -m venv venv
# Windows
venv\Scripts\activate
# macOS / Linux
source venv/bin/activate

pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

In a **second terminal**, start the background worker (required for analysis of any document):

```bash
cd legisense_backend
source venv/bin/activate        # or venv\Scripts\activate
celery -A legisense_backend worker -l info
# or simply:  ./../scripts/start-worker.sh   (Linux/macOS)
#                        scripts\start-worker.bat  (Windows)
```

The backend listens on `http://localhost:8000` (use `http://10.0.2.2:8000` from the Android emulator).

### Frontend (Flutter)

```bash
cd legisense
flutter pub get
flutter run                                  # device / emulator
flutter run --dart-define=LEGISENSE_API_BASE=http://localhost:8000   # web / desktop
```

The frontend reads the backend base URL from the compile-time define `LEGISENSE_API_BASE`. When omitted it falls back to a sensible default; always pass it explicitly for local development.

---

## Background Processing (Celery Worker)

Analysis and translation are handled asynchronously:

- The API creates a `pending` analysis and enqueues `api.tasks.process_document_analysis`.
- The **worker** runs the LLM analysis (any document length), persists the result, and triggers multilingual translations.
- The frontend polls `GET /api/documents/<id>/analysis/` and renders the result when ready.
- **Fallback:** if `REDIS_URL` is unset, the app runs the same pipeline in a background thread — no Redis required for a minimal local run.

Run the worker with the provided helpers:

```bash
# Linux / macOS
./scripts/start-worker.sh

# Windows
scripts\start-worker.bat
```

Or directly:

```bash
celery -A legisense_backend worker -l info
```

The `docker-compose.yml` already includes a `worker` service that starts automatically.

---

## Configuration

All configuration is environment-driven (see `env.example`). The Flutter app is configured at build time via `LEGISENSE_API_BASE`.

| Variable | Default | Notes |
|----------|---------|-------|
| `DATABASE_URL` | _(empty → SQLite)_ | PostgreSQL DSN for production, e.g. `postgresql://user:pass@host:5432/db` |
| `REDIS_URL` | _(empty)_ | Redis broker for Celery, e.g. `redis://:pass@host:6379/0`. Enables the async worker. |
| `SECRET_KEY` | dev placeholder | **Set a strong secret in production.** |
| `DEBUG` | `false` | Enable only in development. |
| `ALLOWED_HOSTS` | `localhost,127.0.0.1` | Comma-separated trusted hosts. |
| `CORS_ALLOWED_ORIGINS` | _(empty)_ | Comma-separated frontend origins allowed by CORS. |
| `OPENROUTER_API_KEY` | _(empty)_ | Required for contract analysis & simulation. |
| `OPENROUTER_MODEL` | `openai/gpt-4o-mini` | Model used for analysis/simulation. |
| `GOOGLE_GEMINI_API_KEY` | _(empty)_ | Required for the chat assistant. |
| `OLLAMA_BASE_URL` | _(empty)_ | Optional self-hosted LLM endpoint. |
| `GCP_CLIENT_MODE` | `mock` | `mock` keeps cloud clients local; switch to `real` only with GCP credentials. |

---

## API Reference

Base path: `/api/`. All analysis/simulation endpoints return JSON.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/parse-pdf/` | Upload & parse a PDF; creates a pending analysis. |
| `GET` | `/documents/` | List parsed documents. |
| `GET` | `/documents/<id>/` | Document detail (pages, metadata, file URL). |
| `GET` | `/documents/<id>/analysis/` | Analysis JSON (404 until `success`). |
| `POST` | `/documents/<id>/analyze/` | (Re)trigger analysis (queues a worker task or runs synchronously). |
| `POST` | `/documents/<id>/simulate/` | Generate a what-if simulation session for a document. |
| `GET` | `/documents/<id>/simulations/` | List simulation sessions for a document. |
| `POST` | `/simulations/import/` | Import a simulation payload. |
| `GET` | `/simulations/<id>/` | Simulation session detail. |
| `POST` | `/documents/<id>/translate/` | Translate document content to a language. |
| `GET` | `/documents/<id>/translations/` | List document translations. |
| `GET` | `/documents/<id>/translations/<lang>/` | Get a document translation. |
| `POST` | `/analysis/<id>/translate/` | Translate an analysis to a language. |
| `GET` | `/analysis/<id>/translations/` | List analysis translations. |
| `GET` | `/analysis/<id>/translations/<lang>/` | Get an analysis translation. |
| `POST` | `/simulations/<id>/translate/` | Translate a simulation to a language. |
| `GET` | `/simulations/<id>/translations/` | List simulation translations. |
| `GET` | `/simulations/<id>/translations/<lang>/` | Get a simulation translation. |
| `POST` | `/chat/gemini/` | Chat with the Gemini legal assistant (JSON `{prompt, model?, language?}`). |

Supported translation languages: **English (`en`), Hindi (`hi`), Tamil (`ta`), Telugu (`te`)**.

---

## Key Code Paths

**Frontend (`legisense/lib`)**

- App shell & navigation: `main.dart` (`SafeArea` + `IndexedStack` + bottom nav), `components/bottom_nav_bar.dart`
- Documents: `pages/documents/documents_page.dart`, `document_display.dart`, `document_analysis.dart` (polls for analysis)
- Data layer: `api/parsed_documents_repository.dart` (`LEGISENSE_API_BASE` define, timeouts, null-safe casts)
- Simulation: `pages/simulation/`
- Notifications: `pages/notifications/notifications_page.dart`
- Theme & responsive helpers: `theme/app_theme.dart`, `utils/responsive.dart`

**Backend (`legisense_backend`)**

- Settings & Celery app: `legisense_backend/settings.py`, `legisense_backend/celery.py`
- API: `api/views.py`, `api/urls.py`, `api/models.py`, `api/tasks.py`
- LLM clients & pipelines: `ai_models/api/openrouter_api.py`, `ai_models/api/google_gemini_api.py`, `ai_models/run_analysis.py`, `ai_models/run_simulation_models_extraction.py`
- Translation: `translation/translator.py`
- PDF parsing: `documents/pdf_document_parser.py`

---

## Development

```bash
# Backend checks
cd legisense_backend
python manage.py check
python -m py_compile -m api.views api.tasks          # syntax check changed modules
python manage.py test                                  # test suite

# Frontend checks
cd legisense
flutter analyze
flutter test
```

Notes:

- Prefer `Color.withValues(alpha: ...)` over the deprecated `withOpacity()`.
- The analysis page polls for completion; for large documents allow up to ~2 minutes before showing a retry.
- Keep navigation wrapped in `SafeArea` to avoid status-bar overlap.

---

## Deployment

1. Copy `env.example` to `.env` and set:
   - `DEBUG=false`
   - A strong, unique `SECRET_KEY`
   - `ALLOWED_HOSTS` and `CORS_ALLOWED_ORIGINS` for your domain
   - `DATABASE_URL` (PostgreSQL), `REDIS_URL` (Redis)
   - Your LLM API keys
2. Build & start with Compose (see `docker.md` for the full reference):

   ```bash
   docker compose up --build -d
   docker compose exec backend python manage.py migrate
   docker compose exec backend python manage.py collectstatic --noinput
   ```

3. Terminate TLS at nginx (certificates in `nginx/ssl/`) and keep the backend off the public internet.

See [`docker.md`](docker.md) for services, volumes, backups, scaling, and troubleshooting.

---

## Roadmap

- Real authentication & user sessions (the auth client currently supports a mock mode).
- Persistent notifications and richer settings.
- Real-time progress indicators for long-running analyses.
- Role-based access and document sharing.
- Optional Google Cloud integration (Document AI, Vertex AI) behind `GCP_CLIENT_MODE=real`.

---

## Contributing

Contributions are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) for branch conventions, setup, testing, and pull-request expectations before opening a PR.

---

## License

Legisense is released under the **MIT License** — see the [`LICENSE`](LICENSE) file.

---

## Disclaimer

Legisense is an educational tool that provides **general information**, not legal advice. It does not create an attorney–client relationship, and its output may be inaccurate or incomplete. Always consult a qualified legal professional for decisions that affect your rights or obligations.
