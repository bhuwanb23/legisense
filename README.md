<div align="center">

# ⚖️ Legisense

Powerful, cross‑platform legal document analysis. Built with Flutter (frontend) and Django (backend).

[![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Django](https://img.shields.io/badge/Django-4.x-092E20?logo=django&logoColor=white)](https://www.djangoproject.com/)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-informational)](#license)

</div>

---

## ✨ Highlights
- 📄 Upload and parse legal documents via a Django API
- 🔍 Smart analysis: TL;DR, clause breakdowns, risk flags, comparative context, suggested questions
- 🧭 Simulations: standard and enhanced flows with rich, animated UI
- 🔔 Notifications page with responsive header and quick filters
- 📱 Beautiful responsive Flutter UI for mobile, tablet, and desktop
- 🎨 Modern colors API (uses `Color.withValues(alpha: ...)` instead of deprecated `withOpacity()`)

---

## 🔗 Quick Links
- Frontend (Flutter): `legisense/`
- Backend (Django): `legisense_backend/`
- Design Prototypes: `prototype_design/`

---


## 🏗️ Architecture
```
Flutter (UI)  ──►  Django API  ──►  Parser/Analysis
   │                 │
   │                DB
   │
   └── Platforms: Android • iOS • Web • macOS • Windows
```
- The Flutter app communicates with the Django backend for document parsing and analysis.
- The UI uses an `IndexedStack` and a global bottom navigation for a smooth multi‑page experience.

---

## 🖼️ Screenshots
> Add your screenshots/GIFs into `assets/` and update the paths below.

| Home | Documents | Notifications |
| :--: | :-------: | :-----------: |
| ![Home](assets/screenshots/home.png) | ![Docs](assets/screenshots/documents.png) | ![Notifications](assets/screenshots/notifications.png) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.22+ (Dart 3)
- Python 3.10+

### 1) Backend (Django)
```bash
cd legisense_backend
python -m venv venv
# Windows
venv\Scripts\activate
# macOS/Linux
# source venv/bin/activate

pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```
Backend will run at `http://localhost:8000` (Android emulator uses `http://10.0.2.2:8000`).

### 2) Frontend (Flutter)
```bash
cd legisense
flutter pub get
flutter run
```

> Web/Desktop example:
```bash
flutter run --dart-define=LEGISENSE_API_BASE=http://localhost:8000
```

---

## ⚙️ Configuration
The Flutter app reads the backend base URL via a compile‑time define:

| Var | Default | Notes |
| --- | --- | --- |
| `LEGISENSE_API_BASE` | `http://10.0.2.2:8000` | Use this default for Android emulators. For local web/desktop, set to `http://localhost:8000`. |

---

## 🧩 Key Code Paths
- App entry & shell: `legisense/lib/main.dart`
  - `SafeArea` prevents overlap with system UI
  - `IndexedStack` + global bottom nav
- Nav bar: `legisense/lib/components/bottom_nav_bar.dart`
- Notifications:
  - Page: `legisense/lib/pages/notifications/notifications_page.dart`
  - Components: `legisense/lib/pages/notifications/components/`
- Documents:
  - Page: `legisense/lib/pages/documents/documents_page.dart`
  - Analysis (with polling fallback): `legisense/lib/pages/documents/document_analysis.dart`
  - Repository (HTTP): `legisense/lib/api/parsed_documents_repository.dart`
- Simulation pages: `legisense/lib/pages/simulation/`
- Theme helpers: `legisense/lib/theme/app_theme.dart`
- Responsive helpers: `legisense/lib/utils/responsive.dart`

---

## 🗂️ Folder Structure (partial)
```
legisense/
  lib/
    api/
    components/
    pages/
      documents/
      home/
      login/
      notifications/
      profile/
      simulation/
    theme/
    utils/
legisense_backend/
  api/
  legisense_backend/
  manage.py
prototype_design/
```

---

## 🧪 Backend Endpoints (high level)
- `GET /api/documents/` — list documents
- `GET /api/documents/{id}/` — document detail
- `GET /api/documents/{id}/analysis/` — analysis JSON
- `POST /api/parse-pdf/` — upload and parse a PDF

---

## 🛠️ Development Notes
- Prefer `Color.withValues(alpha: ...)` (replaces deprecated `withOpacity()`)
- Notifications page uses a responsive header (back button, title, filters) and bottom nav consistent with the main shell
- Global navigation helper: `navigateToPage(int index)` in `main.dart`

---

## 🗺️ Roadmap
- [ ] Authentication & user sessions
- [ ] Persistent notifications & settings
- [ ] Real‑time progress for long parses
- [ ] Role‑based access and sharing

---

## 📦 Build
```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
aflutter build web
```

---

## 🧯 Troubleshooting
- Android networking: use `http://10.0.2.2:8000` for the emulator
- Analysis initially 404: UI polls for ~30s, then shows a friendly message
- Overlap with device status bar: ensure `SafeArea` wraps page bodies (already applied)

---

## 📄 License
MIT — see the LICENSE file (if not present, feel free to add one).
