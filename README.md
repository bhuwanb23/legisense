<div align="center">

# <strong>🌐 Legisense – AI‑Powered Legal Companion</strong>

[![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Django](https://img.shields.io/badge/Django-4.x-092E20?logo=django&logoColor=white)](https://www.djangoproject.com/)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-informational)](#license)

</div>

---

## 🚨 Problem
- **Low legal literacy in India**: 70%+ struggle with legal jargon across everyday contracts (rentals, loans, insurance, ToS).
- **Hidden risks**: Users unknowingly accept auto‑renewals, penalties, and unfair clauses leading to disputes and losses.
- **Access gap**: SMEs, freelancers, tenants often can’t afford lawyers; billions lost annually to fraud/unfair terms.
- **Existing tools misaligned**: Solutions like Spellbook, DoNotPay, LawGeex, LegalZoom target lawyers/Western markets, not Indian citizens.

---

## 🌟 Vision
Build a trustworthy AI co‑pilot that makes legal documents:
- **Understandable**: Simplifies contracts into plain language.
- **Actionable**: Simulates what‑if outcomes and obligations.
- **Protective**: Flags hidden risks and unfair terms.
- **Empathetic**: Guides users with clarity, stress detection, and multilingual support.

---

## 💡 Solution — Legisense
An AI‑powered Legal Empathy & Simulation Companion that:
- **Simplifies** contracts into accessible language.
- **Analyzes** clauses, flags risks, and explains “why it matters”.
- **Simulates** real‑world outcomes (e.g., “Miss 2 EMIs → Default in 90 days → Foreclosure in 6 months”).
- **Adapts** to local laws (e.g., Karnataka vs Maharashtra eviction rules).
- **Supports** empathetically, detecting stress/confusion and adapting tone.
- **Guides action** with checklists, negotiation drafts, and links to NGOs/legal aid.

---

## 📱 App Structure (Pages)

### 🔹 Basic Pages
- **Home Page**: Quick insights, recent documents, alerts, and central “Upload Document” button.
- **Documents Page**: List of uploads → open in Display (abstract text view) or Analysis (risk & summaries).
- **Profile Page**: History, saved simulations, preferences (readability level, languages, privacy).
- **Simulation Page (Entry)**: Hub to run what‑if contract simulations.

### 🔹 Document Analyzer
- **Document Display Page**: Extracted text + original scans with highlighting and search.
- **Document Analysis Page**: Clause explanations, red‑flag alerts, risk scoring, checklists, and Q&A with citations.

### 🔹 Document Simulation
- **Simulation Overview Page**: Topic grid (obligations, penalties, exits, comparative, jurisdiction, forecasts) + what‑if toggles.
- **Simulation Details Page**: Interactive flowchart + timeline of obligations and outcomes.
- **Enhanced Simulation Page**: Rich scenario inputs, jurisdiction filters, narrative outcomes, contextual risk alerts, export/save.

---

## ⚙️ Technical Flow (5 Layers)
- **Ingestion**: Upload → storage → metadata.
- **Preprocessing**: OCR/contract parsing → clean text → clause detection → embeddings.
- **Analysis**: Retrieval‑augmented generation → summaries, risks, Q&A.
- **Application Logic**: Clause Explorer, Red‑Flag Reports, What‑If Simulation, Checklists, Q&A.
- **User Layer**: Home, Documents, Analyzer, Simulation, Profile → clean UI.

Notes:
- **Current OSS stack (this repo)**: Flutter app (`legisense/`) + Django API (`legisense_backend/`).
- **Reference cloud architecture (optional for MVP)**: Google Cloud (Cloud Run, Firestore, Document AI, Vertex AI) for scale‑out.

---

## 🔑 Features
- **Plain‑Language Summaries**: 3 levels — basic, standard, detailed.
- **Clause Explorer**: Risks, why‑it‑matters, suggested actions.
- **Red‑Flag Report**: Sorted by severity.
- **Contract‑to‑Life Simulation**: Obligations → breaches → consequences.
- **Jurisdiction‑Aware Guidance**: State‑level rules.
- **Empathetic Support**: Stress detection, adaptive tone, resources.
- **Actionable Guidance**: Checklists, draft letters, connect to aid.
- **Multilingual**: English ↔ Hindi/Marathi.
- **Privacy Controls**: Ephemeral mode, local redaction.

---

## 🚀 Why Unique (Differentiation)

| Existing Tools (Spellbook, LawGeex, DoNotPay, LegalZoom) | Legisense |
| --- | --- |
| Lawyer‑focused, Western markets | Citizen‑first, India‑first |
| Reactive: Summarization & review | Proactive: Simulation & empathy |
| Expensive ($15–20/doc avg) | Affordable (~$3–4/doc) |
| English‑heavy, complex UI | Multilingual, mobile‑first, simple |
| No emotional support | Empathetic + stress‑aware guidance |

---

## 📊 Feasibility, Scalability, Viability
- **Feasibility**: Serverless GCP reference (Cloud Run, Firestore, Document AI, Vertex AI); MVP in 6–8 weeks.
- **Scalability**: Serverless infra auto‑scales; cost grows with usage.
- **Viability**: Freemium (free summary + red flags; paid simulations). Low processing cost (~$0.30–0.50/doc).
- **Market Opportunity**: India → 500M+ smartphone users; 70% low legal literacy.
- **Sustainability**: Efficient infra, caching, reuse, green defaults.

---

## 📈 Impact
- **Prevents fraud & unfair penalties** → saves billions annually.
- **Reduces legal burden** for SMEs, freelancers, tenants.
- **Increases access to justice** for citizens without lawyers.
- **Empowers with foresight** via simulations of obligations.
- **Improves legal literacy** through plain explanations and scenarios.

---

## 💰 Implementation Cost (Lean MVP)
- **Storage + Hosting**: 20%
- **Document AI Parsing**: 25%
- **AI Analysis**: 30%
- **Database (Firestore/BigQuery)**: 10%
- **Security + Compliance**: 10%
- **Misc (APIs, logs)**: 5%

➡️ Estimated cost per doc: **$3–4** vs **$15–20** for enterprise tools.

---

## 🔗 Quick Links
- **Frontend (Flutter)**: `legisense/`
- **Backend (Django)**: `legisense_backend/`
- **Design Prototypes**: `prototype_design/`

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
Backend runs at `http://localhost:8000` (Android emulator uses `http://10.0.2.2:8000`).

### 2) Frontend (Flutter)
```bash
cd legisense
flutter pub get
flutter run
```

Web/Desktop example:
```bash
flutter run --dart-define=LEGISENSE_API_BASE=http://localhost:8000
```

---

## ⚙️ Configuration
Flutter app reads the backend base URL via a compile‑time define:

| Var | Default | Notes |
| --- | --- | --- |
| `LEGISENSE_API_BASE` | `http://10.0.2.2:8000` | Default for Android emulators. Use `http://localhost:8000` for local web/desktop. |

---

## 🧩 Key Code Paths
- **App entry & shell**: `legisense/lib/main.dart`
  - `SafeArea` wrapping
  - `IndexedStack` + global bottom nav
- **Nav bar**: `legisense/lib/components/bottom_nav_bar.dart`
- **Documents**:
  - Page: `legisense/lib/pages/documents/documents_page.dart`
  - Analysis (polling fallback): `legisense/lib/pages/documents/document_analysis.dart`
  - Repository (HTTP): `legisense/lib/api/parsed_documents_repository.dart`
- **Simulation**: `legisense/lib/pages/simulation/`
- **Notifications**: `legisense/lib/pages/notifications/notifications_page.dart`
- **Theme helpers**: `legisense/lib/theme/app_theme.dart`
- **Responsive helpers**: `legisense/lib/utils/responsive.dart`

---

## 🧪 Backend Endpoints (high level)
- `GET /api/documents/` — list documents
- `GET /api/documents/{id}/` — document detail
- `GET /api/documents/{id}/analysis/` — analysis JSON
- `POST /api/parse-pdf/` — upload and parse a PDF

---

## 🛠️ Development Notes
- Prefer `Color.withValues(alpha: ...)` (replaces deprecated `withOpacity()`).
- Notifications page uses a responsive header and persistent bottom nav.
- Global navigation helper: `navigateToPage(int index)` in `main.dart`.

---

## 🖼️ Screenshots
Add screenshots/GIFs into `assets/` and update paths:

| Home | Documents | Notifications |
| :--: | :-------: | :-----------: |
| ![Home](assets/screenshots/home.png) | ![Docs](assets/screenshots/documents.png) | ![Notifications](assets/screenshots/notifications.png) |

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
flutter build web
```

---

## 🧯 Troubleshooting
- **Android networking**: use `http://10.0.2.2:8000` for the emulator.
- **Analysis 404 initially**: UI polls for ~30s, then shows a friendly message.
- **Overlap with status bar**: ensure `SafeArea` wraps page bodies (already applied).

---

## ✅ In Summary
**Legisense** is a citizen‑first, India‑first legal AI companion that not only explains contracts but also simulates consequences, adapts to local laws, and supports users empathetically — bridging a major access‑to‑justice gap while remaining feasible, scalable, and affordable.

---

## 📄 License
MIT — see the `LICENSE` file (if not present, feel free to add one).
