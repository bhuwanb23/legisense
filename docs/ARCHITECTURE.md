# LegiSense Architecture

## Flow: How All Features Connect

```
User uploads document (F1)
         ↓
If image → OCR extracts text (F2)
         ↓
Auto-detect document type (F8) ──────────────────────────────────────┐
         ↓                                                            │
         └─ selects right prompt ─────────────────────────────────┐   │
                                                                   ↓   ↓
Full AI analysis runs (F3) → clause breakdown ←───────────────────────┘
         ↓
Simultaneously generates:
  → Summary + dates + obligations (F4)
  → Risk score per clause (F5)
  → Risk categories (F6)
  → Plain english per clause (F7)
         ↓
Everything saved to DB
         ↓
Flutter fetches and displays across pages
```

## Key Insight

**Features 3, 4, 5, 6, 7, and 8 all run from ONE AI call.** Do not make separate API calls for each. Build ONE master prompt that returns everything, then split the response into separate tables.

## Tech Stack

- **Backend:** Node.js + Express + TypeScript + SQLite (Drizzle ORM)
- **Frontend:** Flutter (Dart)
- **AI:** OpenRouter / Gemini / OpenAI via unified provider layer
- **OCR:** Tesseract.js (local)

## Flow Detail

### 1. Upload (F1)
`backend/src/routes/uploadRoutes.ts`
- Multer receives file → stored in `backend/uploads/`
- Metadata saved to `documents` table: `originalName`, `storagePath`, `fileSize`, `fileFormat`, `sourceType`
- Socket event: `upload:complete`

### 2. OCR (F2)
`backend/src/services/ocrService.ts`
- Triggered on image formats (png, jpg, jpeg, tiff, bmp)
- Tesseract.js processes buffer → raw text
- Raw text written back to `documents.rawText`
- Socket event: `ocr:complete`

### 3. Type Detection (F8)
`backend/src/data/documentTypes.ts` — Master list (15 types)
`backend/src/prompts/classificationPrompt.ts` — Classify prompt + schema
`backend/src/prompts/promptTemplates.ts` — 15 type-specific prompts

- First 2000 chars sent to AI with `CLASSIFY_SYSTEM_PROMPT`
- Returns `{ type, type_label, confidence, sub_type, icon }`
- Stored on `documents`: `detected_type`, `detected_type_confidence`, `needs_type_confirmation`
- If `confidence < 60%` → `needs_type_confirmation = true`, emits `analysis:needs_confirmation`
- Selects type-specific prompt from `promptTemplates.ts`
- **Always proceeds with analysis regardless of confidence**

### 4. Clause Analysis (F3)
`backend/src/services/analysisService.ts`
- `analyzeSingle(userId, docId, rawText)` — entry point
- Steps:
  1. Classify document type (F8)
  2. Select type-specific analysis prompt
  3. Build full prompt: type-specific prefix + base rules + JSON schema
  4. Send to AI provider
  5. Parse response via `parseAiResponse`
  6. If text > model context → `chunkText` → analyze each chunk → `mergeAnalysisResults`
  7. Validate with `AnalysisOutputSchema`
- Results stored in `analysis_results`, `clauses`, `risk_items`, `deadlines` tables
- Socket event: `analysis:complete`

### 5. Summary + Dates + Obligations (F4)
All returned from the single AI response:
- `summary` — 3-5 sentence plain English overview
- `keyParties` — each with `obligations_summary` + `type`
- `criticalDates` — each with `importance` + computed `urgency`
- `keyObligations` — each with `consequence`
- `missingClauses` — notable omissions
- Stored in `analysis_results` (JSON columns)

### 6. Risk Score (F5)
Computed per clause and document-wide:
- Each clause: `riskScore` (0–100) + `riskLevel` (none/low/medium/high/critical)
- Document: `overallRiskScore` + `riskLevel`
- Dashboard endpoint: `GET /:documentId/risk-dashboard`
- Aggregation in `backend/src/services/riskDashboardService.ts`
- Weighted average with critical-floor logic (≥95 floor at 60)

### 7. Risk Categories (F6)
`backend/src/services/riskCategorizationService.ts`
- Each clause assigned `riskCategory`: financial, legal, privacy, termination, obligation, liability, compliance, intellectual_property, operational
- Grouped and aggregated into `risk_items` table
- Endpoints: `GET /risk-items/by-category/:type`

### 8. Plain Language (F7)
Per clause from AI response:
- `plainEnglishText` — everyday language version
- `readingLevel` — grade_5 / grade_8 / standard
- `keyLegalTerms` — array of `{ term, definition }`
- Glossary endpoint for on-demand lookups

## Database Schema

### documents
| Column | Type | Description |
|---|---|---|
| id | INTEGER PK | Auto-increment |
| user_id | INTEGER FK | Owner |
| original_name | TEXT | Upload filename |
| storage_path | TEXT | Server file path |
| file_format | TEXT | pdf/png/jpg/docx/txt |
| file_size | INTEGER | Bytes |
| source_type | TEXT | file/camera/paste |
| upload_status | TEXT | uploading/uploaded/failed |
| processing_status | TEXT | pending/processing/analyzed/error |
| raw_text | TEXT | Extracted text |
| word_count | INTEGER | Rough token estimate |
| detected_type | TEXT | From F8 classification |
| detected_type_confidence | REAL | 0–100 |
| needs_type_confirmation | INTEGER | 0/1, set if < 60% |
| created_at | TEXT | ISO timestamp |
| updated_at | TEXT | ISO timestamp |

### analysis_results
| Column | Type | Description |
|---|---|---|
| id | INTEGER PK | Auto-increment |
| document_id | INTEGER FK | → documents |
| document_type | TEXT | Detected doc type |
| overall_risk_score | INTEGER | 0–100 |
| risk_level | TEXT | low/medium/high/critical |
| fairness_score | INTEGER | 0–100 |
| favors_party | TEXT | Which party favored |
| summary | TEXT | Plain English summary |
| key_parties | TEXT | JSON array |
| critical_dates | TEXT | JSON array |
| key_obligations | TEXT | JSON array |
| breach_scenarios | TEXT | JSON array |
| missing_clauses | TEXT | JSON array |
| deadlines | TEXT | JSON array |
| model | TEXT | AI model used |
| provider | TEXT | AI provider used |

### clauses
| Column | Type | Description |
|---|---|---|
| id | INTEGER PK | Auto-increment |
| document_id | INTEGER FK | → documents |
| analysis_id | INTEGER FK | → analysis_results |
| clause_number | INTEGER | Sequential |
| clause_title | TEXT | Heading/title |
| original_text | TEXT | Verbatim excerpt |
| plain_english_text | TEXT | Simplified version |
| reading_level | TEXT | grade_5 / grade_8 / standard |
| key_legal_terms | TEXT | JSON array |
| risk_level | TEXT | none/low/medium/high/critical |
| risk_score | INTEGER | 0–100 |
| risk_reason | TEXT | Why this score |
| risk_category | TEXT | financial/legal/... |
| counter_suggestion | TEXT | Negotiation tip |
| created_at | TEXT | ISO timestamp |

### risk_items
| Column | Type | Description |
|---|---|---|
| id | INTEGER PK | Auto-increment |
| document_id | INTEGER FK | → documents |
| risk_type | TEXT | Category name |
| title | TEXT | Risk title |
| description | TEXT | Details |
| severity | TEXT | low/medium/high/critical |
| severity_score | INTEGER | 0–100 |
| recommendation | TEXT | Mitigation |
| legal_reference | TEXT | Applicable law |
| created_at | TEXT | ISO timestamp |

### deadlines
| Column | Type | Description |
|---|---|---|
| id | INTEGER PK | Auto-increment |
| document_id | INTEGER FK | → documents |
| title | TEXT | Deadline label |
| description | TEXT | What to do |
| due_date | TEXT | ISO date |
| recurrence | TEXT | one-time/daily/weekly/monthly/yearly |
| created_at | TEXT | ISO timestamp |

### glossary
| Column | Type | Description |
|---|---|---|
| id | INTEGER PK | Auto-increment |
| term | TEXT | Legal term |
| definition | TEXT | Plain English |
| category | TEXT | contract/property/... |

## API Routes (Backend)

### Upload
| Method | Path | Description |
|---|---|---|
| POST | /api/upload | Upload document |
| GET | /api/documents | List user's documents |
| GET | /api/documents/:id | Get document details |
| DELETE | /api/documents/:id | Delete document |

### Analysis
| Method | Path | Description |
|---|---|---|
| POST | /api/analysis/:documentId/analyze | Start analysis pipeline |
| GET | /api/analysis/:documentId | Get analysis result |
| GET | /api/analysis/:documentId/classify | Classify document type |
| POST | /api/analysis/:documentId/confirm-type | Override detected type |
| GET | /api/analysis/:documentId/clauses | Get clauses |
| GET | /api/analysis/:documentId/risks | Get risks |
| GET | /api/analysis/:documentId/risk-dashboard | Dashboard summary |
| GET | /api/analysis/risk-items/by-category/:type | Filtered risks |
| GET | /api/analysis/:documentId/summary | Get summary |
| GET | /api/analysis/:documentId/plain-english | Plain language view |
| POST | /api/analysis/glossary | Term lookup |

### Notifications
| Method | Path | Description |
|---|---|---|
| GET | /api/notifications/settings | User notification prefs |
| PUT | /api/notifications/settings | Update prefs |
| POST | /api/notifications/:channel/send | Send test notification |

### Chat
| Method | Path | Description |
|---|---|---|
| POST | /api/chat/message | Send message |
| GET | /api/chat/history/:documentId | Get history |

## Socket Events

| Event | Direction | Payload |
|---|---|---|
| analysis:progress | Server→Client | `{ documentId, step, progress }` |
| analysis:complete | Server→Client | `{ documentId }` |
| analysis:error | Server→Client | `{ documentId, error }` |
| analysis:needs_confirmation | Server→Client | `{ documentId, type, typeLabel, confidence }` |
| ocr:complete | Server→Client | `{ documentId }` |
| ocr:error | Server→Client | `{ documentId, error }` |

## Build Sequence

| Day(s) | Feature | Why This Order |
|---|---|---|
| 1–2 | F1 — Upload | Everything depends on having a document in the DB |
| 3 | F2 — OCR | Extends upload pipeline for images |
| 4 | F8 — Type Detection | Must classify before analysis can pick the right prompt |
| 5–7 | F3 — Clause Analysis | Core engine; everything else splits from this response |
| 8 | F4 — Summary | Extends analysis prompt, splits from same response |
| 9 | F5 — Risk Score | Computed per clause from existing data |
| 10 | F6 — Risk Categories | Grouping logic on existing risk data |
| 11–12 | F7 — Plain Language | Extends clause data with translations |
| 13 | Integration Testing | Full flow end-to-end |

## Build Estimates

| Feature | Backend | Flutter | Total |
|---|---|---|---|
| F1 — Upload | 1 day | 1 day | 2 days |
| F2 — OCR | 1 day | 0.5 day | 1.5 days |
| F8 — Type Detection | 0.5 day | 0.5 day | 1 day |
| F3 — Clause Analysis | 2 days | 1 day | 3 days |
| F4 — Summary | 0.5 day | 1 day | 1.5 days |
| F5 — Risk Score | 0.5 day | 1 day | 1.5 days |
| F6 — Risk Categories | 0.5 day | 0.5 day | 1 day |
| F7 — Plain Language | 0.5 day | 1 day | 1.5 days |
| **TOTAL** | **6.5 days** | **6.5 days** | **~13 days** |

## Key Files (Backend)

| File | Purpose |
|---|---|
| `src/routes/uploadRoutes.ts` | Upload + document CRUD |
| `src/routes/analysisRoutes.ts` | All analysis endpoints |
| `src/services/ocrService.ts` | Tesseract wrapper |
| `src/services/analysisService.ts` | Orchestrates the full pipeline |
| `src/services/riskDashboardService.ts` | Score aggregation |
| `src/services/riskCategorizationService.ts` | Category grouping |
| `src/controllers/analysisController.ts` | Request handlers |
| `src/prompts/classificationPrompt.ts` | Type detection prompt |
| `src/prompts/promptTemplates.ts` | 15 type-specific prompts |
| `src/data/documentTypes.ts` | 15-type master list |
| `src/models/document.ts` | Document schema |
| `src/models/analysis.ts` | Analysis result + clause schemas |
| `src/models/riskItem.ts` | Risk item schema |
| `src/models/deadline.ts` | Deadline schema |
| `src/models/glossary.ts` | Glossary schema |
| `src/services/ai/provider.ts` | OpenRouter / Gemini / OpenAI |
| `src/services/ai/types.ts` | AiTask union + shared types |
| `src/index.ts` | App entry + migrations |
