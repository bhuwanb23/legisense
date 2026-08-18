# 🏛️ LegalLens AI — Master Project Plan

---

## 🎯 PROJECT OVERVIEW

```
App Name     : LegalLens AI
Type         : Legal Document Intelligence Platform
Platform     : Mobile (Android + iOS) + Web
Stack        : Flutter + Node.js + Supabase + Claude AI
Hackathon    : QuantumHacks (Submission: Aug 20)
Categories   : AI Agents + Social Impact + Consumer App
```

### One Line Pitch:
> *"Upload any legal document in any language, from any state — and know exactly what you're signing in 60 seconds."*

---

## 🗂️ MASTER STRUCTURE MAP

```
LEGALLENS AI
│
├── 🔐 AUTH SYSTEM
│   ├── Register / Login / OTP
│   ├── Google OAuth
│   └── JWT + Refresh Token
│
├── 👤 USER PROFILE
│   ├── Profession + Jurisdiction
│   └── Language + Preferences
│
├── 📄 DOCUMENT SYSTEM
│   ├── Upload (File/Scan/Paste/URL)
│   ├── OCR Processing
│   └── Document History
│
├── 🤖 AI ANALYSIS ENGINE
│   ├── Type Detection
│   ├── Clause Breakdown
│   ├── Risk Scoring
│   ├── Plain Language
│   ├── Summary Generation
│   ├── Missing Clause Detection
│   ├── Risky Pattern Flagging
│   └── Counter-Clause Generation
│
├── ⚖️ JURISDICTION ENGINE
│   ├── Multi-State Compliance
│   └── State Conflict Detection
│
├── 🌍 MULTILINGUAL ENGINE
│   ├── Language Detection
│   └── Translation Layer
│
├── 📅 DEADLINE SYSTEM
│   ├── Auto-Extraction
│   ├── Calendar Export
│   └── Reminder Engine
│
└── 💬 CHAT SYSTEM
    ├── RAG Pipeline
    ├── Document Chat
    └── Clause Citation
```

---

## 📱 COMPLETE PAGES MASTER LIST

### GROUP 1 — AUTH PAGES
```
P01  Splash Screen
P02  Onboarding (3 slides)
P03  Register Page
P04  Login Page
P05  OTP Verification
P06  Forgot Password
P07  Reset Password
```

### GROUP 2 — PROFILE PAGES
```
P08  Profile Setup (First time)
P09  Profile & Account Page
P10  Edit Profile Page
P11  Notification Settings
P12  App Settings (Language, Theme, Jurisdiction)
```

### GROUP 3 — CORE APP PAGES
```
P13  Home Dashboard
P14  Upload Document Page
P15  Camera Scan Page
P16  Processing / Loading Page
P17  Document History Page
```

### GROUP 4 — ANALYSIS PAGES
```
P18  Analysis Results (Master Hub Page)
P19  Document Summary Page
P20  Clause Breakdown Page
P21  Clause Detail Page (expanded single clause)
P22  Risk Dashboard Page
P23  Risk Category Detail Page
P24  Plain Language Translator Page
P25  Missing Clauses Page
P26  Risky Patterns Page
P27  Counter-Clause Suggestions Page
```

### GROUP 5 — JURISDICTION PAGES
```
P28  Jurisdiction Selector Page
P29  Jurisdiction Flags Page
P30  State Conflict Comparison Page
```

### GROUP 6 — DEADLINE PAGES
```
P31  All Deadlines Page
P32  Deadline Detail Page
P33  Reminder Settings Page
P34  Calendar Export Page
```

### GROUP 7 — CHAT PAGES
```
P35  Document Chat Page
P36  Citation Viewer Panel (slide-up)
```

### GROUP 8 — EXPORT / SHARE PAGES
```
P37  Export Options Page
P38  Shareable Report Preview
```

---

**TOTAL: 38 Pages**

---

## 🗄️ COMPLETE DATABASE SCHEMA PLAN

### TABLES LIST:

```
01  users
02  user_sessions
03  documents
04  analysis_results
05  clauses
06  risk_items
07  risk_patterns          (pre-seeded master data)
08  clause_flags
09  missing_clauses
10  counter_suggestions
11  jurisdictions           (pre-seeded master data)
12  legal_rules             (pre-seeded master data)
13  jurisdiction_flags
14  jurisdiction_conflicts
15  required_clause_templates (pre-seeded master data)
16  deadlines
17  deadline_reminders
18  chat_sessions
19  chat_messages
20  document_embeddings     (ChromaDB — vector store)
21  notifications
22  legal_glossary          (pre-seeded master data)
23  usage_logs
```

### RELATIONSHIPS MAP:

```
users
  ├── has many → documents
  ├── has many → notifications
  ├── has many → chat_sessions
  └── has many → deadlines

documents
  ├── belongs to → users
  ├── has one  → analysis_results
  ├── has many → clauses
  ├── has many → deadlines
  └── has many → chat_sessions

analysis_results
  ├── belongs to → documents
  ├── has many → clauses
  ├── has many → risk_items
  ├── has many → missing_clauses
  └── has many → jurisdiction_flags

clauses
  ├── belongs to → analysis_results
  ├── has many → clause_flags
  ├── has one  → counter_suggestions
  └── referenced by → chat_messages (citations)

chat_sessions
  ├── belongs to → documents
  └── has many → chat_messages
```

---

## 🔌 COMPLETE API ROUTES PLAN

```
/auth
  POST   /register
  POST   /login
  POST   /logout
  POST   /refresh-token
  POST   /verify-otp
  POST   /resend-otp
  POST   /forgot-password
  POST   /reset-password
  GET    /google
  GET    /google/callback

/users
  GET    /profile
  PUT    /profile
  PUT    /preferences
  PUT    /jurisdiction
  PUT    /fcm-token
  DELETE /account

/documents
  POST   /upload/file
  POST   /upload/scan
  POST   /upload/paste
  POST   /upload/url
  GET    /
  GET    /:id
  DELETE /:id

/analysis
  POST   /start/:documentId
  GET    /:documentId
  GET    /:documentId/summary
  GET    /:documentId/clauses
  GET    /:documentId/clause/:clauseId
  GET    /:documentId/risks
  GET    /:documentId/risk-dashboard
  GET    /:documentId/plain-english
  GET    /:documentId/missing-clauses
  GET    /:documentId/flagged-clauses
  GET    /:documentId/counter-clauses

/jurisdiction
  GET    /countries
  GET    /:country/states
  GET    /:documentId/flags
  GET    /:documentId/conflicts
  POST   /:documentId/reanalyze

/chat
  POST   /:documentId/session
  POST   /:documentId/message
  GET    /:documentId/history
  DELETE /:documentId/session

/deadlines
  GET    /
  GET    /:documentId
  GET    /upcoming
  PUT    /:id/complete
  PUT    /:id/dismiss
  PUT    /:id/reminders
  POST   /export/ics
  POST   /export/google-calendar

/notifications
  GET    /
  PUT    /:id/read
  PUT    /read-all
  DELETE /:id

/languages
  GET    /supported
  POST   /:documentId/translate
```

---

## 🤖 AI SYSTEM PLAN

### The Master Prompt Structure:

```
EVERY DOCUMENT ANALYSIS = ONE AI CALL
That single call returns:

{
  detection: {
    document_type,
    confidence,
    sub_type
  },

  summary: {
    overview,
    key_parties,
    critical_dates,
    key_obligations,
    breach_scenarios
  },

  clauses: [{
    number,
    title,
    original_text,
    plain_english_text,
    risk_level,
    risk_score,
    risk_category,
    risk_reason,
    key_legal_terms,
    page_reference
  }],

  risks: {
    overall_score,
    risk_level,
    flagged_patterns,
    missing_clauses
  },

  jurisdiction: {
    flags,
    conflicts
  }
}
```

### AI Provider Strategy:

```
Document < 100K tokens   → Claude 3.5 Sonnet (primary)
Document > 100K tokens   → Gemini 1.5 Pro (large context)
Multilingual document    → Gemini 1.5 Pro (best multilingual)
Counter-clause writing   → GPT-4o (best at rewrites)
Chat / Q&A               → Claude 3.5 (best reasoning)
Embeddings for RAG       → OpenAI text-embedding-3-small
Fallback (any failure)   → rotate to next provider

ALL managed via LangChain.js provider abstraction
```

### Queue Strategy:

```
QUEUE 1: document-analysis    → Heavy AI work
QUEUE 2: ocr-processing       → Image to text
QUEUE 3: counter-clauses      → Runs AFTER analysis
QUEUE 4: embeddings           → Runs AFTER analysis (for chat)
QUEUE 5: notifications        → Reminders + alerts
QUEUE 6: auto-delete          → Privacy cleanup (cron)
QUEUE 7: deadline-reminders   → Daily cron at 8AM
```

---

## 🏗️ BACKEND FOLDER STRUCTURE

```
backend/
│
├── src/
│   ├── config/
│   │   ├── database.ts          → Supabase connection
│   │   ├── ai.ts                → Claude, Gemini, OpenAI setup
│   │   ├── storage.ts           → Supabase storage setup
│   │   ├── queue.ts             → BullMQ setup
│   │   ├── socket.ts            → Socket.io setup
│   │   └── chroma.ts            → ChromaDB setup
│   │
│   ├── routes/
│   │   ├── auth.routes.ts
│   │   ├── user.routes.ts
│   │   ├── document.routes.ts
│   │   ├── analysis.routes.ts
│   │   ├── jurisdiction.routes.ts
│   │   ├── chat.routes.ts
│   │   ├── deadline.routes.ts
│   │   └── notification.routes.ts
│   │
│   ├── controllers/
│   │   ├── auth.controller.ts
│   │   ├── user.controller.ts
│   │   ├── document.controller.ts
│   │   ├── analysis.controller.ts
│   │   ├── jurisdiction.controller.ts
│   │   ├── chat.controller.ts
│   │   ├── deadline.controller.ts
│   │   └── notification.controller.ts
│   │
│   ├── services/
│   │   ├── ai/
│   │   │   ├── analysis.service.ts     → Master analysis
│   │   │   ├── chat.service.ts         → RAG chat
│   │   │   ├── counter.service.ts      → Counter clauses
│   │   │   ├── embedding.service.ts    → Vector embeddings
│   │   │   └── provider.service.ts     → Provider switching
│   │   │
│   │   ├── document/
│   │   │   ├── parser.service.ts       → Route to right parser
│   │   │   ├── pdf.service.ts
│   │   │   ├── docx.service.ts
│   │   │   ├── ocr.service.ts
│   │   │   └── scraper.service.ts      → URL import
│   │   │
│   │   ├── jurisdiction/
│   │   │   ├── compliance.service.ts
│   │   │   └── conflict.service.ts
│   │   │
│   │   ├── deadline/
│   │   │   ├── extractor.service.ts
│   │   │   ├── calendar.service.ts
│   │   │   └── reminder.service.ts
│   │   │
│   │   ├── notification/
│   │   │   ├── push.service.ts         → FCM
│   │   │   └── email.service.ts        → Nodemailer
│   │   │
│   │   └── export/
│   │       ├── pdf.export.service.ts
│   │       └── ics.export.service.ts
│   │
│   ├── workers/
│   │   ├── analysis.worker.ts
│   │   ├── ocr.worker.ts
│   │   ├── counter.worker.ts
│   │   ├── embedding.worker.ts
│   │   └── reminder.worker.ts
│   │
│   ├── middleware/
│   │   ├── auth.middleware.ts
│   │   ├── upload.middleware.ts
│   │   ├── validate.middleware.ts
│   │   ├── rateLimit.middleware.ts
│   │   ├── logger.middleware.ts
│   │   └── error.middleware.ts
│   │
│   ├── models/
│   │   ├── user.model.ts
│   │   ├── document.model.ts
│   │   ├── analysis.model.ts
│   │   ├── clause.model.ts
│   │   ├── risk.model.ts
│   │   ├── deadline.model.ts
│   │   ├── chat.model.ts
│   │   └── notification.model.ts
│   │
│   ├── prompts/
│   │   ├── master-analysis.prompt.ts   → Main AI prompt
│   │   ├── counter-clause.prompt.ts
│   │   ├── chat-system.prompt.ts
│   │   ├── jurisdiction.prompt.ts
│   │   └── templates/
│   │       ├── rental.prompt.ts
│   │       ├── employment.prompt.ts
│   │       ├── nda.prompt.ts
│   │       └── general.prompt.ts
│   │
│   ├── utils/
│   │   ├── response.util.ts            → Standard API response format
│   │   ├── token.util.ts               → JWT helpers
│   │   ├── chunk.util.ts               → Document chunking
│   │   ├── risk-calculator.util.ts     → Risk score math
│   │   ├── date.util.ts                → Deadline date logic
│   │   └── language.util.ts            → Language detection
│   │
│   ├── seeds/
│   │   ├── jurisdictions.seed.ts       → All countries + states
│   │   ├── legal-rules.seed.ts         → Law rules per state
│   │   ├── risk-patterns.seed.ts       → 50+ risky patterns
│   │   ├── required-clauses.seed.ts    → Templates per doc type
│   │   └── glossary.seed.ts            → Legal terms dictionary
│   │
│   ├── crons/
│   │   ├── auto-delete.cron.ts
│   │   └── deadline-reminder.cron.ts
│   │
│   └── app.ts                          → App entry point
│
├── .env
├── .env.example
├── docker-compose.yml
├── Dockerfile
├── package.json
└── tsconfig.json
```

---

## 📱 FLUTTER FOLDER STRUCTURE

```
lib/
│
├── main.dart
│
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── colors.dart
│   │   └── text_styles.dart
│   │
│   ├── router/
│   │   └── app_router.dart             → go_router setup
│   │
│   ├── constants/
│   │   ├── api_constants.dart          → Base URL, endpoints
│   │   ├── app_constants.dart
│   │   └── document_types.dart
│   │
│   ├── network/
│   │   ├── dio_client.dart             → Dio setup + interceptors
│   │   ├── socket_client.dart          → Socket.io client
│   │   └── api_response.dart           → Response model
│   │
│   └── utils/
│       ├── validators.dart
│       ├── formatters.dart
│       └── extensions.dart
│
├── features/
│   │
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_api.dart
│   │   ├── models/
│   │   │   └── user_model.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── pages/
│   │       ├── splash_page.dart        → P01
│   │       ├── onboarding_page.dart    → P02
│   │       ├── register_page.dart      → P03
│   │       ├── login_page.dart         → P04
│   │       ├── otp_page.dart           → P05
│   │       ├── forgot_password_page.dart → P06
│   │       └── reset_password_page.dart  → P07
│   │
│   ├── profile/
│   │   ├── data/
│   │   ├── models/
│   │   ├── providers/
│   │   └── pages/
│   │       ├── profile_setup_page.dart → P08
│   │       ├── profile_page.dart       → P09
│   │       ├── edit_profile_page.dart  → P10
│   │       ├── notification_settings_page.dart → P11
│   │       └── app_settings_page.dart  → P12
│   │
│   ├── home/
│   │   ├── data/
│   │   ├── providers/
│   │   └── pages/
│   │       └── home_page.dart          → P13
│   │
│   ├── documents/
│   │   ├── data/
│   │   │   ├── document_repository.dart
│   │   │   └── document_api.dart
│   │   ├── models/
│   │   │   └── document_model.dart
│   │   ├── providers/
│   │   │   └── document_provider.dart
│   │   └── pages/
│   │       ├── upload_page.dart        → P14
│   │       ├── scan_page.dart          → P15
│   │       ├── processing_page.dart    → P16
│   │       └── history_page.dart       → P17
│   │
│   ├── analysis/
│   │   ├── data/
│   │   │   ├── analysis_repository.dart
│   │   │   └── analysis_api.dart
│   │   ├── models/
│   │   │   ├── analysis_model.dart
│   │   │   ├── clause_model.dart
│   │   │   └── risk_model.dart
│   │   ├── providers/
│   │   │   └── analysis_provider.dart
│   │   └── pages/
│   │       ├── results_page.dart       → P18
│   │       ├── summary_page.dart       → P19
│   │       ├── clause_breakdown_page.dart → P20
│   │       ├── clause_detail_page.dart    → P21
│   │       ├── risk_dashboard_page.dart   → P22
│   │       ├── risk_category_page.dart    → P23
│   │       ├── plain_english_page.dart    → P24
│   │       ├── missing_clauses_page.dart  → P25
│   │       ├── risky_patterns_page.dart   → P26
│   │       └── counter_clause_page.dart   → P27
│   │
│   ├── jurisdiction/
│   │   ├── data/
│   │   ├── models/
│   │   ├── providers/
│   │   └── pages/
│   │       ├── jurisdiction_selector_page.dart → P28
│   │       ├── jurisdiction_flags_page.dart    → P29
│   │       └── state_conflict_page.dart        → P30
│   │
│   ├── deadlines/
│   │   ├── data/
│   │   ├── models/
│   │   │   └── deadline_model.dart
│   │   ├── providers/
│   │   └── pages/
│   │       ├── deadlines_page.dart     → P31
│   │       ├── deadline_detail_page.dart → P32
│   │       ├── reminder_settings_page.dart → P33
│   │       └── calendar_export_page.dart → P34
│   │
│   ├── chat/
│   │   ├── data/
│   │   │   └── chat_repository.dart
│   │   ├── models/
│   │   │   └── chat_model.dart
│   │   ├── providers/
│   │   │   └── chat_provider.dart
│   │   └── pages/
│   │       ├── chat_page.dart          → P35
│   │       └── widgets/
│   │           └── citation_panel.dart → P36
│   │
│   └── export/
│       ├── data/
│       └── pages/
│           ├── export_page.dart        → P37
│           └── report_preview_page.dart → P38
│
└── shared/
    ├── widgets/
    │   ├── primary_button.dart
    │   ├── risk_badge.dart
    │   ├── clause_card.dart
    │   ├── loading_overlay.dart
    │   ├── empty_state.dart
    │   ├── error_state.dart
    │   ├── bottom_nav.dart
    │   └── document_card.dart
    └── services/
        ├── local_storage.service.dart  → flutter_secure_storage
        ├── socket.service.dart
        ├── notification.service.dart
        └── fcm.service.dart
```

---

## ⚙️ COMPLETE TECH STACK SUMMARY

```
LAYER               TECHNOLOGY              PURPOSE
─────────────────────────────────────────────────────────
Frontend            Flutter                 Mobile + Web UI
State Management    Riverpod                App-wide state
Navigation          go_router               Page routing
HTTP Client         Dio                     API calls
Real-time           Socket.io client        Live updates
Charts              fl_chart                Risk gauges + graphs
PDF Viewer          syncfusion_flutter_pdf  Document display
File Picker         file_picker             Upload from device
Camera              image_picker            Scan documents
OCR (device)        tesseract.dart          On-device OCR
Calendar            table_calendar          Deadline UI
TTS                 flutter_tts             Read aloud
Storage (local)     flutter_secure_storage  Auth tokens
─────────────────────────────────────────────────────────
Backend             Node.js + TypeScript    API server
Framework           Fastify                 HTTP framework
Real-time           Socket.io               Push events
Queues              BullMQ + Redis          Background jobs
Validation          Zod                     Input validation
Auth                JWT + bcrypt            Security
File Upload         Multer                  Accept files
─────────────────────────────────────────────────────────
AI — Primary        Anthropic Claude 3.5    Document analysis
AI — Large Docs     Google Gemini 1.5 Pro   100K+ tokens
AI — Rewrites       OpenAI GPT-4o           Counter clauses
AI — Embeddings     OpenAI Embeddings       Chat RAG vectors
AI Orchestration    LangChain.js            Chain + fallbacks
─────────────────────────────────────────────────────────
Doc Parsing         pdf-parse               Digital PDFs
Doc Parsing         mammoth.js              DOCX files
OCR (server)        Tesseract.js            Image/scan OCR
OCR (production)    Mistral OCR API         High accuracy OCR
Scraping            Cheerio / Puppeteer     URL import
─────────────────────────────────────────────────────────
Database            Supabase PostgreSQL      Main database
Auth                Supabase Auth           User management
File Storage        Supabase Storage        Document files
Vector DB           ChromaDB                Chat embeddings
─────────────────────────────────────────────────────────
Push Notifications  Firebase FCM            Mobile alerts
Email              Nodemailer              Deadline emails
Calendar API       Google Calendar API     Export events
─────────────────────────────────────────────────────────
DevOps             Docker                  Containerization
CI/CD              GitHub Actions          Auto deployment
Hosting            Railway / Render        Backend hosting
Version Control    GitHub                  Code + README
─────────────────────────────────────────────────────────
```

---

## 📋 FEATURE MASTER TABLE

```
ID   FEATURE                          TIER    PRIORITY   DEPENDS ON
──────────────────────────────────────────────────────────────────────
F01  Universal Format Upload          Core    P0         —
F02  OCR Scan Support                 Core    P0         F01
F03  AI Document Analysis             Core    P0         F01, F02
F04  Auto Document Summary            Core    P0         F03
F05  Risk Score Dashboard             Core    P0         F03
F06  Risk Categorization              Core    P1         F05
F07  Plain Language Translation       Core    P1         F03
F08  Document Type Auto-Detection     Core    P0         F03
F09  Multi-Jurisdiction Compliance    Power   P1         F03, F08
F10  State Conflict Detection         Power   P2         F09
F11  Multilingual Support             Power   P2         F03
F12  Risky Clause Flagging            Power   P1         F03
F13  Missing Clause Detection         Power   P1         F03, F08
F14  Counter-Clause Suggestions       Power   P2         F12, F13
F15  Deadline Tracker                 Power   P1         F04
F16  Calendar Export                  Power   P2         F15
F17  Deadline Reminders               Power   P2         F15
F18  Interactive Document Chat        Power   P2         F03, embeddings
F19  Clause Citation in Chat          Power   P2         F18
F20  Doc Comparison (Diff Mode)       Wow     P3         F03
F21  Fairness Score                   Wow     P3         F05, F03
F22  AI Playbook System               Wow     P3         F03
F23  One-Click Better Version         Wow     P3         F14
F24  Domain-Specific Templates        Wow     P3         F08
F25  Jurisdiction Map (Visual)        Wow     P3         F09
F26  Privacy-First Architecture       Security P0        F01
F27  End-to-End Encryption            Security P0        —
F28  Auto-Delete After Processing     Security P1        F01
F29  Export as PDF                    Output  P2         F03
F30  Export as DOCX                   Output  P3         F03
F31  Export as JSON/CSV               Output  P3         F03
F32  Shareable Link                   Output  P2         F03
F33  REST API Endpoint                Output  P3         —
F34  Dark / Light Mode                UX      P2         —
F35  Document History Dashboard       UX      P1         F03
F36  Offline Mode (past analyses)     UX      P3         —
F37  Annotation Mode                  UX      P3         F20
F38  Read Aloud (TTS)                 UX      P3         F07
F39  Multi-User Sharing               UX      P3         —
F40  Voice Input in Chat              UX      P3         F18
F41  Onboarding Walkthrough           UX      P2         —
F42  Notification Center              UX      P1         F17
```

---

## 📅 MASTER TIMELINE PLAN

### PHASE 0 — FOUNDATION *(Already Done)*
```
✅ Project setup
✅ Node.js + TypeScript boilerplate
✅ Supabase connected
✅ All DB tables created
✅ Middleware setup
✅ Auth routes (register, login, OTP)
✅ Flutter project setup
✅ Dio + Riverpod + go_router setup
```

---

### PHASE 1 — CORE ENGINE
*(Target: Days 1-13)*

```
DAY 01-02  →  Document Upload System (F01)
              Backend: /upload routes, Multer, Supabase Storage
              Flutter: Upload Page (P14), 4 upload tiles

DAY 03     →  OCR Pipeline (F02)
              Backend: Tesseract worker, OCR queue
              Flutter: Scan Page (P15), camera + preview

DAY 04     →  Document Type Detection (F08)
              Backend: lightweight classify prompt
              Flutter: type chip on Processing Page

DAY 05-07  →  Master AI Analysis Engine (F03 + F04 + F05 + F06 + F07)
              Backend: ONE master prompt, parse response
              Save: clauses, summary, risk scores, plain english
              Flutter: Processing Page (P16) with live Socket.io steps

DAY 08     →  Analysis Results Hub Page (P18)
              Flutter: Master page with tab bar
              Connect: all 4 tabs to API data

DAY 09     →  Clause Breakdown Page (P20, P21)
              Flutter: clause list + filter chips + clause detail

DAY 10     →  Risk Dashboard Page (P22, P23)
              Flutter: gauge + chart + category cards (fl_chart)

DAY 11     →  Document Summary Page (P19)
              Flutter: parties, dates table, obligations

DAY 12     →  Plain Language Page (P24)
              Flutter: toggle view + legal term tap definitions

DAY 13     →  Integration testing — full flow end-to-end
              Upload → Process → Results → all tabs working
```

---

### PHASE 2 — POWER FEATURES
*(Target: Days 14-37)*

```
DAY 14-15  →  Risky Clause Flagging (F12)
              Backend: risk_patterns table + seed 50+ patterns
              Flutter: Risky Patterns Page (P26), 🚩 flags on clauses

DAY 16-17  →  Missing Clause Detection (F13)
              Backend: required_clauses_templates + seed per doc type
              Flutter: Missing Clauses Page (P25)

DAY 18-19  →  Counter-Clause Suggestions (F14)
              Backend: counter-clause worker + GPT-4o prompt
              Flutter: Counter Clause Page (P27), diff view

DAY 20-21  →  Deadline Tracker (F15)
              Backend: extract deadlines from analysis, Deadline model
              Flutter: Deadlines Page (P31), Deadline Detail (P32)

DAY 22     →  Calendar Export (F16)
              Backend: .ics generator, Google Calendar API
              Flutter: Calendar Export Page (P34)

DAY 23-24  →  Deadline Reminders (F17)
              Backend: FCM setup, Nodemailer, reminder cron
              Flutter: Reminder Settings (P33), notification handler

DAY 25-26  →  Jurisdiction Compliance (F09)
              Backend: jurisdictions + legal_rules seed, flag engine
              Flutter: Jurisdiction Selector (P28), Flags Page (P29)

DAY 27-28  →  State Conflict Detection (F10)
              Backend: conflict detection service
              Flutter: State Conflict Page (P30)

DAY 29-30  →  Multilingual Support (F11)
              Backend: language detection, Gemini multilingual
              Flutter: language toggle on all analysis pages

DAY 31-34  →  Interactive Document Chat (F18)
              Backend: ChromaDB setup, embeddings, RAG pipeline
              Flutter: Chat Page (P35), streaming responses

DAY 35     →  Clause Citation (F19)
              Backend: citation parser, validation
              Flutter: Citation Panel (P36), tappable chips

DAY 36-37  →  Phase 2 Integration testing
              All power features working end-to-end
```

---

### PHASE 3 — WOW FEATURES + POLISH
*(Target: Days 38-50)*

```
DAY 38-39  →  Fairness Score (F21)
              Backend: fairness scoring algorithm
              Flutter: fairness meter on Results page

DAY 40-41  →  Document Comparison Diff Mode (F20)
              Backend: diff comparison service
              Flutter: side-by-side diff view

DAY 42     →  AI Playbook System (F22)
              Backend: user rules engine
              Flutter: playbook management page

DAY 43     →  Export Features (F29-F32)
              Backend: PDF/DOCX/JSON generators
              Flutter: Export Page (P37), Report Preview (P38)

DAY 44     →  Dark Mode + UI Polish (F34)
              Flutter: theme toggle, consistent design system

DAY 45     →  Onboarding + Walkthrough (F41)
              Flutter: 3-slide onboarding, first-run tips

DAY 46-47  →  Security Hardening (F26-F28)
              Backend: AES encryption, auto-delete cron, rate limits

DAY 48     →  Performance Optimization
              Backend: query optimization, caching common responses
              Flutter: lazy loading, pagination on history page

DAY 49     →  End-to-End QA
              Test every feature, every page, every API
              Fix bugs, edge cases

DAY 50     →  Deployment
              Docker build, Railway deploy
              Supabase production switch
              GitHub README finalize
```

---

### PHASE 4 — HACKATHON SUBMISSION
*(Target: Days 51-56 — Final week)*

```
DAY 51     →  Demo document preparation
              Find real contracts (lease, NDA, employment)
              Test full flow with real documents

DAY 52     →  Demo video recording
              60-second screen recording
              Show: upload → scan → results → chat → export

DAY 53-54  →  Pitch deck creation
              Problem → Solution → Features → Tech → Impact
              10 slides max

DAY 55     →  GitHub cleanup
              Clean README with screenshots
              Architecture diagram
              Setup instructions
              Feature list

DAY 56     →  SUBMIT ✅
```

---

## 🎯 PRIORITY MATRIX

```
          HIGH IMPACT    |    LOW IMPACT
          ─────────────────────────────────
EASY  →   F01, F03, F04  |  F34, F41, F42
          F05, F08, F35  |
          ─────────────────────────────────
HARD  →   F18, F09, F11  |  F22, F24, F25
          F15, F17, F21  |  F36, F39, F40
```

**Rule:**
```
BUILD FIRST  → High Impact + Easy  (guaranteed demo value)
BUILD NEXT   → High Impact + Hard  (competitive edge)
BUILD LAST   → Low Impact + Easy   (polish)
SKIP IF TIME → Low Impact + Hard   (cut scope here)
```

---

## 🏆 MINIMUM VIABLE DEMO (If time runs out)

These features ALONE can win the hackathon:

```
✅ F01 — Upload PDF
✅ F03 — AI Clause Analysis
✅ F04 — Document Summary
✅ F05 — Risk Score Dashboard
✅ F07 — Plain Language Translation
✅ F08 — Type Detection
✅ F12 — Risky Clause Flagging
✅ F18 — Document Chat (wow factor)
✅ P18 — Beautiful Results Page
```

> These 9 features + polished UI = a hackathon-winning submission

---

## 📊 FINAL NUMBERS

```
Total Pages          : 38
Total Features       : 42
Total API Routes     : 45+
Total DB Tables      : 23
Total Backend Files  : 60+
Total Flutter Files  : 80+
AI Providers         : 3 (Claude, Gemini, GPT-4o)
Estimated Build Time : 56 days
Hackathon Deadline   : Aug 20
```

---

## 🚀 START TODAY — FIRST 3 THINGS TO DO

```
1. Create all 23 DB tables in Supabase right now
   (schema is defined, just execute it)

2. Run all seed scripts:
   → jurisdictions (countries + states)
   → risk_patterns (50+ risky clause patterns)
   → required_clause_templates (per document type)
   → legal_glossary (200+ legal terms)

3. Build the Document Upload API endpoint
   → That is step one of the entire feature chain
   → Every other feature waits for this
```

> **Everything flows from the upload. The upload unlocks the parser. The parser unlocks the AI. The AI unlocks every feature on every page.**

---

Want me to now go deeper into any specific phase, write the **master AI prompt template**, or plan the **GitHub README structure** for the hackathon submission?