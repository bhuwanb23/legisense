# 📋 LegalLens AI — Complete Feature Documentation

---

## 🟢 TIER 1: CORE FEATURES

---

### F01 — Universal Format Upload

**What it does:**
Accepts legal documents in any format from any source so that no user is blocked from using the app regardless of how they have their document.

**How it works:**
The upload page presents 4 input methods. Based on which method the user picks, the backend routes the input to the correct handler, extracts the raw text, and stores it for AI processing.

**Input:**
```
Method 1 — File Upload
  → User selects file from device storage
  → Accepted: .pdf, .docx, .doc, .txt
  → Max size: 10MB

Method 2 — Camera Scan
  → User photographs a physical document
  → Accepted: .jpg, .jpeg, .png, .heic
  → Single or multi-page capture

Method 3 — Paste Text
  → User copies and pastes raw text
  → Minimum: 50 characters
  → No file needed

Method 4 — URL Import
  → User pastes a web link
  → Accepted: any valid http/https URL
  → Example: Terms of Service page link
```

**Output:**
```
→ Document record created in DB
→ document_id returned to Flutter
→ file stored in Supabase Storage
→ raw_text extracted and saved
→ processing_status: "uploaded"
→ Flutter navigates to Processing Page
```

---

### F02 — OCR Scan Support

**What it does:**
Converts photographs of physical documents (handwritten or printed) into machine-readable text so users can analyze paper contracts, stamp papers, court notices without needing a digital version.

**How it works:**
The uploaded image is sent to an OCR worker via BullMQ queue. Tesseract.js processes the image and extracts text. If confidence is below 70%, it falls back to Mistral OCR API. The extracted text is cleaned and saved as raw_text in the Document table, exactly like a digital upload.

**Input:**
```
→ One or multiple images of a physical document
→ Formats: jpg, jpeg, png, heic
→ Source: device camera or gallery
→ Language hint: from user's preferred language setting
```

**Output:**
```
→ Cleaned extracted text saved to raw_text field
→ OCR confidence score logged
→ processing_status updated to "text_extracted"
→ Socket.io event "ocr:completed" fired to Flutter
→ Flutter advances to analysis step automatically
```

---

### F03 — AI Document Analysis (Clause-by-Clause)

**What it does:**
The core engine of the entire app. It reads the entire document and breaks it down into individual clauses, analyzing each one for meaning, risk, parties involved, and legal significance.

**How it works:**
The extracted raw text is sent to Claude 3.5 Sonnet (or Gemini for large documents) via LangChain.js. A master prompt instructs the AI to identify clause boundaries, title each clause, assess risk, identify parties, and return everything as structured JSON. Each clause is saved as a separate record in the Clause table.

**Input:**
```
→ raw_text from Document table
→ document_type (from F08 detection)
→ user jurisdiction (country + state)
→ user preferred language
→ document_id for saving results
```

**Output:**
```
Per clause record saved:
→ clause_number
→ clause_title
→ original_text
→ plain_english_text
→ risk_level: "low" / "medium" / "high"
→ risk_score: 0-100
→ risk_category
→ risk_reason
→ key_legal_terms: [{term, definition}]
→ page_reference
→ party_references: [who this clause applies to]

Analysis Result record saved:
→ total clauses found
→ key parties identified
→ processing_time
→ ai_model_used
```

---

### F04 — Auto Document Summary

**What it does:**
Generates an instant structured summary of the entire document so users can understand the big picture before diving into individual clauses. Replaces the need to read the full document just to get the basics.

**How it works:**
Runs as part of the same AI call as F03. The master prompt includes instructions to also generate a summary section alongside the clause analysis. The summary extracts who the parties are, what they agreed to, when key things happen, and what consequences exist for violations.

**Input:**
```
→ Same call as F03 (no extra AI request)
→ raw_text
→ detected document_type
→ jurisdiction
```

**Output:**
```
Saved to Analysis Result table:
→ summary: 3-5 sentence plain paragraph overview
→ key_parties: [
    {name, role, type: "individual/company", obligations_summary}
  ]
→ critical_dates: [
    {label, date, urgency, importance_reason}
  ]
→ key_obligations: [
    {party_name, obligation, consequence_if_missed}
  ]
→ breach_scenarios: [
    {scenario, consequence, who_is_affected}
  ]

Side effect:
→ For each critical_date found → auto-creates Deadline record (feeds F15)
```

---

### F05 — Risk Score Dashboard

**What it does:**
Gives the entire document a single 0-100 risk score with a visual gauge so users immediately know how dangerous a document is the moment analysis completes, without reading anything.

**How it works:**
After all clauses are analyzed and saved, a risk calculator utility runs. It takes each clause's risk_score, applies a weighted average formula (high-risk clauses weighted more heavily than low-risk ones), and produces an overall document risk score. If any clause scores above 90, the overall minimum is set to 60 to prevent false comfort.

**Input:**
```
→ All saved clause records for this document
→ Each clause's individual risk_score (0-100)
→ Each clause's risk_level (low/medium/high)
→ Count of missing clauses (from F13)
```

**Output:**
```
Saved to Analysis Result:
→ overall_risk_score: 0-100 number
→ risk_level: "low" / "medium" / "high"
→ clause_count_by_risk: {high: 4, medium: 6, low: 9}
→ highest_risk_clause: {clause_id, title, score}

Returned to Flutter:
→ Score number for animated gauge
→ Color: 🟢 0-33 / 🟡 34-66 / 🔴 67-100
→ Summary label: "High Risk — Favors Landlord"
→ Top 5 riskiest clauses for quick display
```

---

### F06 — Risk Categorization

**What it does:**
Groups all risks by category (Financial, Legal Liability, Privacy, Termination, etc.) so users can understand what type of danger they face, not just that danger exists.

**How it works:**
Each clause already has a risk_category from the master AI prompt (F03). After all clauses are saved, a grouping service aggregates them by category, finds the highest severity within each group, and creates a Risk Item record per category that summarizes the exposure in that area.

**Input:**
```
→ All clause records with their risk_category fields
→ Supported categories:
   "financial" / "liability" / "privacy" /
   "termination" / "intellectual_property" /
   "compliance" / "operational"
```

**Output:**
```
Risk Item records created per category:
→ category_name
→ clause_count: how many clauses in this category
→ highest_severity: worst clause in category
→ overall_category_risk: low/medium/high
→ summary_description
→ recommendation: what user should do
→ linked_clause_ids: array

Flutter display:
→ Category cards with icon, count, severity badge
→ Tap any card → see clauses in that category
→ Filter on Clause Breakdown page by category
```

---

### F07 — Plain Language Translation

**What it does:**
Rewrites every legal clause in simple, everyday English that anyone can understand without a law degree. Includes a built-in legal glossary for tappable definitions.

**How it works:**
The plain_english_text for each clause is generated as part of the master AI prompt (F03 call). The AI is instructed to rewrite each clause at a Grade 8 reading level while preserving the legal meaning. Legal terms detected in the original are extracted and matched against a pre-seeded glossary table. Unknown terms are defined by the AI and cached for future use.

**Input:**
```
→ original_text of each clause
→ risk_reason for context
→ user's reading level preference:
   "simple (Grade 5)" / "standard (Grade 8)" / "technical"
→ user's preferred language
```

**Output:**
```
Per clause:
→ plain_english_text: rewritten version
→ reading_level: grade level used
→ key_legal_terms: [
    {term, definition, found_in_clause_position}
  ]

Glossary table:
→ New terms cached for reuse (no repeat AI calls)

Flutter display:
→ Toggle: [Original] ↔ [Plain English]
→ Tappable highlighted legal terms → popup definition
→ Read Aloud button (TTS) per clause
```

---

### F08 — Document Type Auto-Detection

**What it does:**
Automatically identifies what kind of legal document was uploaded before the full analysis runs, so the AI uses a document-specific prompt and looks for the right things in the right places.

**How it works:**
Only the first 2000 characters of the raw_text are sent in a lightweight classification call. The AI returns a document type from a master list with a confidence score. If confidence is above 60%, it proceeds automatically. Below 60%, Flutter shows a confirmation sheet. The detected type then selects the matching prompt template for F03.

**Input:**
```
→ First 2000 characters of raw_text (fast, cheap)
→ Master document type list:
   rental_agreement, nda, employment_contract,
   freelance_agreement, sale_deed, power_of_attorney,
   loan_agreement, terms_of_service, privacy_policy,
   partnership_deed, will, court_notice, mou,
   service_agreement, unknown
```

**Output:**
```
→ document_type: "rental_agreement"
→ type_label: "Rental Agreement"
→ confidence: 94 (percentage)
→ sub_type: "residential_lease"
→ needs_confirmation: false (true if confidence < 60%)
→ selected_prompt_template: "rental.prompt.ts"

Flutter display:
→ "📄 Detected: Rental Agreement (94% confident)"
→ If needs_confirmation → show type selector bottom sheet
→ Document card in history shows correct type icon
```

---

## 🔵 TIER 2: POWER FEATURES

---

### F09 — Multi-Jurisdiction Compliance

**What it does:**
Checks every clause in the document against the specific laws of the user's selected country and state, and flags any clause that may be illegal, unenforceable, or non-compliant in that jurisdiction.

**How it works:**
A pre-seeded Legal Rules table contains known laws per jurisdiction per document type. After clause analysis, the compliance service fetches all rules matching the user's jurisdiction and document type. For each rule, it scans clause text for keyword matches and runs a semantic AI check. Matches create Jurisdiction Flag records tied to the specific clause and legal rule.

**Input:**
```
→ user's selected country_code + state_code
→ document_type (from F08)
→ all analyzed clause records
→ Legal Rules table (pre-seeded master data):
   {jurisdiction, document_type, rule_title,
    trigger_keywords, severity, legal_reference}
```

**Output:**
```
Jurisdiction Flag records created:
→ clause_id: which clause is affected
→ flag_type: "violation" / "warning" / "required_missing"
→ message: "This clause may be void under Section 27"
→ legal_reference: "Indian Contract Act, Section 27"
→ severity: "critical" / "warning" / "info"
→ jurisdiction: "Maharashtra, India"

Flutter display:
→ Jurisdiction tab on Analysis Results Page
→ ⚠️ alert banners on affected clauses
→ Count: "3 violations, 2 warnings found"
→ "Re-analyze for different state" button
```

---

### F10 — State-vs-State Law Conflict Detection

**What it does:**
Shows how the same clause is treated differently across multiple states — enforceable in one, restricted in another, completely void in a third. Critical for users who operate across state lines.

**How it works:**
Extends the Legal Rules table with a conflicting_jurisdictions field per rule. After the jurisdiction check (F09), the conflict service checks each flagged clause for known cross-state differences. It builds a conflict matrix showing the clause's enforceability status in each relevant state and saves it as Jurisdiction Conflict records.

**Input:**
```
→ flagged clauses from F09
→ Legal Rules with conflicting_jurisdictions data:
   [{state_code, enforceability: "void/limited/enforceable", note}]
→ user's selected state (primary)
→ neighboring or previously used states (secondary)
```

**Output:**
```
Jurisdiction Conflict records:
→ clause_id
→ clause_title
→ conflict_data: [
    {state: "Maharashtra", status: "enforceable"},
    {state: "Delhi", status: "limited — max 1 year"},
    {state: "Kerala", status: "void"}
  ]

Flutter display:
→ Conflict cards below jurisdiction flags
→ ✅ Green / ⚠️ Yellow / ❌ Red per state
→ "Compare States" button → side-by-side view
→ Plain English explanation of why conflicts exist
```

---

### F11 — Multilingual Support

**What it does:**
Allows users to upload documents in any of 37+ languages and receive the full analysis, summary, clause breakdowns, and chat responses in their preferred language.

**How it works:**
After text extraction, a language detection library (franc) identifies the document's primary language. If non-English, Gemini 1.5 Pro (which handles 37+ languages natively) is used for analysis. The AI prompt instructs Gemini to return all analysis results in the user's preferred language while keeping legal terms in their original form with added explanations. Translated results are stored alongside originals.

**Input:**
```
→ raw_text in any language
→ user's preferred_language from profile
→ document's detected_language (auto-detected)
→ Supported language codes: hi, ta, te, kn, mr, bn,
   es, fr, de, ar, zh, ja, pt, ru, and 23+ more
```

**Output:**
```
→ detected_language saved to Document table
→ All clause plain_english_text in user's language
→ Summary in user's language
→ Risk explanations in user's language
→ Legal terms kept in original + explained in user's language

Flutter display:
→ Language chip: "Detected: Hindi 🇮🇳"
→ Language toggle on all analysis pages
→ "Original" / "English" / "My Language" switcher
→ RTL layout auto-applied for Arabic, Urdu, Hebrew
```

---

### F12 — Risky Clause Flagging

**What it does:**
Automatically detects known dangerous clause patterns — like unlimited liability, auto-renewal traps, one-sided termination rights — that commonly harm the signing party, even when buried in legal language.

**How it works:**
A pre-seeded Risk Patterns table contains 50+ known dangerous clause patterns with trigger keywords and semantic descriptions. After clause analysis, each clause is checked against all patterns via keyword matching AND a semantic AI check (to catch paraphrased versions). Matches create Clause Flag records with the specific pattern that was triggered.

**Input:**
```
→ All clause records (original_text)
→ Risk Patterns table (50+ pre-seeded patterns):
   {pattern_name, trigger_keywords, severity,
    explanation, recommendation}

Known patterns include:
→ Unlimited Liability
→ Auto-Renewal Trap
→ One-Sided Termination
→ Unilateral Amendment (they change terms anytime)
→ Broad IP Assignment (they own your work)
→ Non-Compete > 1 year
→ Mandatory Arbitration (no court access)
→ Lock-in with no exit
→ Broad Indemnification
→ Penalty-Heavy Late Payment
→ Governing Law in Inconvenient Jurisdiction
→ Waiver of Class Action
```

**Output:**
```
Clause Flag records:
→ clause_id
→ pattern_id: which pattern matched
→ match_type: "keyword" / "semantic"
→ match_confidence: 0-100%
→ flagged_text_snippet: the exact dangerous text

Flutter display:
→ 🚩 red border on flagged clause cards
→ Pattern name + explanation popup on tap
→ "What to do" recommendation shown
→ "🚩 Flagged Only" filter chip on Clause list
→ Count: "⚠️ 5 Risky Patterns Detected"
```

---

### F13 — Missing Clause Detection

**What it does:**
Identifies clauses that SHOULD be in this type of document based on legal standards and best practices but are completely absent, exposing the user to unprotected risk.

**How it works:**
A Required Clauses Templates table is pre-seeded with what each document type should contain, marked by importance level. After clause analysis, the AI is asked to compare the clauses found against the required list for the detected document type and identify which ones are absent or dangerously vague. Missing clauses are saved with importance levels and explanations.

**Input:**
```
→ List of clauses found in document
→ document_type from F08
→ Required Clauses Templates (pre-seeded per type):
   {document_type, clause_name, importance, why_needed, example_text}

Example required clauses by type:
Rental → deposit refund conditions (critical)
         maintenance responsibility (critical)
         subletting rules (recommended)

Employment → probation period terms (critical)
             leave policy (critical)
             IP ownership (recommended)

NDA → definition of confidential info (critical)
      exclusions from confidentiality (critical)
      duration of obligation (critical)
```

**Output:**
```
Missing Clause records:
→ clause_name
→ importance: "critical" / "recommended" / "optional"
→ why_needed: explanation
→ risk_if_absent: what can go wrong
→ example_text: standard version of this clause
→ is_confirmed_missing: true

Flutter display:
→ Missing Clauses tab on Analysis Results Page
→ Cards per missing clause with importance badge
→ 🔴 Critical / 🟡 Recommended / 🔵 Optional
→ "See Standard Clause" → shows template text
→ Count: "4 critical clauses missing"
```

---

### F14 — Counter-Clause Suggestions

**What it does:**
For every risky clause identified, the AI drafts a fairer alternative version that protects both parties equally, giving users something concrete to negotiate with.

**How it works:**
Runs as a background job AFTER the main analysis completes (so it doesn't delay results). For every clause with risk_score above 50, a targeted GPT-4o prompt is sent asking it to rewrite the clause in a balanced, enforceable, plain-language way that preserves the original intent. The result is saved as a counter_suggestion on the clause record. A negotiation tip is also generated.

**Input:**
```
→ All clauses where risk_score > 50
→ original_text of each risky clause
→ risk_reason: why it's dangerous
→ user's jurisdiction (for local enforceability)
→ document_type (for context)
```

**Output:**
```
Per high-risk clause:
→ counter_suggestion: the rewritten fair clause text
→ negotiation_tip: how to request this change professionally
→ email_template: ready-to-send message to other party

Flutter display:
→ "💡 See Better Version" button on risky clause cards
→ Bottom sheet: Original vs Suggested side by side
→ Word-level diff (added = green, removed = red)
→ "📋 Copy Clause" button
→ "Export All Counter-Clauses as PDF" button
→ Negotiation tip section below comparison
```

---

### F15 — Deadline & Obligation Tracker

**What it does:**
Automatically extracts every important date, deadline, and recurring obligation from the document and organizes them into a tracker so nothing is missed or forgotten.

**How it works:**
The master AI prompt (F03) includes a dedicated section asking for all temporal obligations. The AI returns a structured list of dates with context. The backend parses these, calculates urgency based on how far away each date is from today, handles recurring deadlines by generating the next 12 occurrences, and saves each as a Deadline record.

**Input:**
```
→ Extracted from AI during analysis (same call as F03)
→ Document's critical_dates array
→ Document's key_obligations array
→ Today's date for urgency calculation
```

**Output:**
```
Deadline records per date found:
→ title: "Monthly Rent Due"
→ description
→ due_date
→ is_recurring: true/false
→ recurrence_pattern: "monthly"
→ party_responsible: "Tenant"
→ consequence_if_missed: "2% late fee per week"
→ urgency_level:
   "overdue" 🔴 / "this_week" 🔴 /
   "this_month" 🟡 / "upcoming" 🟢

Flutter display:
→ Deadlines Page with urgency filter chips
→ Deadline cards with swipe actions
→ Swipe right → Mark Complete
→ Swipe left → Dismiss / Snooze
→ Upcoming Deadlines widget on Home Dashboard
→ Timeline/Calendar toggle view
```

---

### F16 — Calendar Export

**What it does:**
Pushes extracted deadlines directly into the user's Google Calendar or generates a downloadable .ics file compatible with any calendar app, so legal deadlines become actual calendar events.

**How it works:**
For Google Calendar: if the user has connected Google OAuth, the backend uses Google Calendar API to create events with reminders. For .ics: the backend generates a valid iCalendar file with all selected deadlines as VEVENT entries including alarm triggers. Both options accept single or bulk deadline selection.

**Input:**
```
→ Selected deadline_ids (single or array)
→ OR document_id (export all deadlines from document)
→ Google Calendar: user's stored OAuth access token
→ .ics: no auth needed — generates file directly
```

**Output:**
```
Google Calendar path:
→ Events created in user's Google Calendar
→ Each event: title, date, description, 2-day-before alarm
→ Confirmation: "✅ 8 events added to Google Calendar"
→ calendar_exported: true saved on each Deadline record

.ics path:
→ .ics file generated and downloaded to device
→ Device auto-prompts to open with calendar app
→ All selected deadlines imported at once

Flutter display:
→ Export button on each deadline card
→ Bottom sheet: [📅 Google Calendar] [📥 Download .ics]
→ ✅ visual indicator on exported deadlines
→ "Export All" button on Document Summary Page
```

---

### F17 — Deadline Reminders

**What it does:**
Automatically sends push notifications and emails before critical legal deadlines so users never miss a payment, notice period, or renewal window.

**How it works:**
When deadlines are created (F15), the user configures reminder preferences (7 days, 3 days, 1 day, same day). A daily cron job runs at 8AM and checks all active deadlines against today's date. When a reminder threshold is hit, a notification job is pushed to BullMQ. The worker sends FCM push notifications via Firebase Admin SDK and emails via Nodemailer. For custom exact-time reminders, BullMQ delayed jobs fire at the precise moment.

**Input:**
```
→ deadline records with due_date
→ user's reminder_times: [7, 3, 1] (days before)
→ user's reminder_channels: ["push", "email"]
→ user's FCM token (sent from Flutter on login)
→ user's email address
```

**Output:**
```
Push notification:
→ Title: "⚠️ Reminder: Monthly Rent Due in 3 days"
→ Body: "Your payment is due Jan 5. Late fee: 2%/week"
→ Action: deep link → opens that deadline in app

Email:
→ Subject: same as push title
→ Body: document name, deadline, consequence, CTA button
→ "View in App" button → deep link

Notification record saved in DB:
→ type, title, body, is_read, document_id, created_at

Flutter display:
→ Reminder Settings per deadline (bottom sheet)
→ Checkboxes: 7 days / 3 days / 1 day / on the day
→ Toggle: push on/off, email on/off
→ Notification Center page with all past alerts
→ Deep link on notification tap → opens deadline detail
```

---

### F18 — Interactive Document Chat

**What it does:**
Lets users have a real conversation with their document — asking plain-English questions like "Can I break this lease early?" and getting accurate answers drawn directly from the document's content, not general AI knowledge.

**How it works:**
After analysis, the document is chunked into 500-token overlapping segments. Each chunk is converted into an embedding vector and stored in ChromaDB with metadata (clause_id, page_number). When a user sends a chat message, the question is also vectorized and the top 5 most similar chunks are retrieved. These chunks plus the conversation history (last 10 messages) form the AI context. Claude responds using ONLY the retrieved chunks, citing sources.

**Input:**
```
→ User's text message (or voice via STT)
→ document_id to scope the search
→ session_id for conversation continuity
→ Conversation history: last 10 messages

Behind the scenes:
→ User message → embedding vector
→ ChromaDB search → top 5 relevant chunks
→ Chunks + history → Claude prompt
```

**Output:**
```
Per AI response:
→ answer_text: plain English response
→ cited_clause_ids: which clauses were referenced
→ cited_pages: page numbers
→ response_time
→ tokens_used (for cost tracking)

Saved to Chat Message table:
→ Both user message and AI response
→ cited_clause_ids array

Flutter display:
→ Chat bubble UI (user right, AI left)
→ Word-by-word streaming response (Socket.io)
→ "AI is thinking..." animated dots
→ Suggested questions chips on first open:
   "Can I terminate early?"
   "What are my payment obligations?"
   "Is this contract fair?"
   "Who owns the IP?"
→ Chat history persists across sessions
→ Voice input via microphone button
```

---

### F19 — Clause Citation in Chat

**What it does:**
Every single answer the AI gives in chat is backed by tappable citations that link directly to the exact clause and page number in the document, so users can verify every claim instantly.

**How it works:**
The chat system prompt forces the AI to always end responses with structured citations in the format "📎 [Clause X.X — Title] (Page Y)". A citation parser extracts these references after each AI response, looks up the clause_id from the Clause table, validates that the cited clause actually contains relevant content, and attaches it to the chat message. Low-confidence citations are flagged.

**Input:**
```
→ AI response text containing citation markers
→ Clause table records for this document
→ Citation format enforced in system prompt:
   "📎 [Clause X.X — Title] (Page Y)"
→ Confidence validation: does cited clause match answer?
```

**Output:**
```
→ cited_clauses: [
    {clause_id, clause_number, clause_title, page, snippet}
  ]
→ citation_confidence: high / low
→ "Not found in document" flag if no source exists

Flutter display:
→ Citation chips below every AI message:
   [📎 Clause 8.3] [📎 Clause 11.1]
→ Tap chip → slide-up panel shows full clause:
   Original text, plain English, risk badge, page
→ "View in Document" button → navigates to clause
→ Grey italic style for "not found in document" answers
→ Trust badge: "All answers cite document sources"
```

---

## 🟡 TIER 3: WOW FEATURES

---

### F20 — Document Comparison (Diff Mode)

**What it does:**
Lets users upload two versions of the same document and see exactly what changed — what was added, what was removed, and what was quietly modified between versions.

**How it works:**
User uploads a second document and links it to an existing analyzed document. Both documents' clause texts are aligned by title/position. A diff algorithm compares them word by word. The AI additionally reviews the changes and flags any new risks introduced in Version 2 that weren't in Version 1.

**Input:**
```
→ document_id of Version 1 (already analyzed)
→ New uploaded file as Version 2
→ Alignment method: by clause title / by position
```

**Output:**
```
→ Diff result per clause:
   {status: "added" / "removed" / "modified" / "unchanged",
    original_text (V1), new_text (V2),
    word_diff: [{word, type: "added/removed/same"}],
    new_risks_introduced: [...]}

Flutter display:
→ Side-by-side clause list: V1 left / V2 right
→ Added words: green highlight
→ Removed words: red strikethrough
→ Modified clauses: yellow border
→ "🚨 New Risk Added" badge on changed clauses
→ Summary: "12 changes found, 3 new risks introduced"
```

---

### F21 — Fairness Score

**What it does:**
Gives an objective assessment of which party the contract favors and by how much, expressed as a single score that immediately shows power imbalance.

**How it works:**
After clause analysis, the AI evaluates the distribution of obligations, rights, penalties, and protections between Party A and Party B. Clauses are scored on a -5 (heavily favors Party A) to +5 (heavily favors Party B) scale. The average determines the overall fairness score and which party benefits more.

**Input:**
```
→ All clause records with identified parties
→ Obligation distribution per party
→ Rights and penalties assigned per party
→ Risk levels of clauses per party
```

**Output:**
```
→ fairness_score: 0-100
  (50 = perfectly balanced, 70 = favors Party A, 30 = favors Party B)
→ favors_party: "Landlord" / "Employer" / "Party A" / "Balanced"
→ imbalance_reason: explanation
→ per_category_fairness: {financial: 60, termination: 80, ...}

Flutter display:
→ Fairness meter on Analysis Results Page
→ "This contract favors the Landlord at 72/100"
→ Per-category breakdown bar chart
→ "Most one-sided clause" highlight
```

---

### F22 — AI Playbook System

**What it does:**
Lets users define their own personal legal rules and preferences, which the AI then automatically enforces on every future document they analyze — like a personal legal policy engine.

**How it works:**
Users create Playbook Rules in their profile. Each rule has a condition and action. When a new document is analyzed, the playbook service runs the user's rules against the clause results and creates custom flags specific to that user's preferences, separate from the system-level risk flags.

**Input:**
```
→ User-defined rules:
   {
     rule_name: "No long non-competes",
     condition: "non_compete_duration > 12_months",
     severity: "high",
     message: "I never accept non-competes over 1 year"
   }

   {
     rule_name: "Flag auto-renewals always",
     condition: "clause_contains: auto-renew OR auto-renewal",
     severity: "medium",
     message: "I want to manually review all renewal terms"
   }
```

**Output:**
```
→ Personal Playbook Flags created per matching clause
→ Separate from system risk flags
→ Tagged: "Your Rule: No long non-competes"

Flutter display:
→ Playbook management page in profile
→ Create/edit/delete personal rules
→ Rule flags shown with personal icon on clauses
→ "Based on your playbook: 3 clauses flagged"
```

---

### F23 — One-Click Better Version

**What it does:**
After analyzing a problematic document, generates a completely rewritten, fairer version of the entire document with all risky clauses replaced, ready to propose to the other party.

**How it works:**
Combines all counter-clause suggestions (F14) with the document's original structure. GPT-4o is used to regenerate the full document, replacing each risky clause with its counter-suggestion, keeping safe clauses unchanged, and adding any missing critical clauses (F13) with standard templates. Output is a complete, clean document.

**Input:**
```
→ Original document structure
→ All counter_suggestion records from F14
→ All missing_clause records from F13 (with templates)
→ User's jurisdiction for enforceability
→ document_type for tone and structure
```

**Output:**
```
→ Complete rewritten document text
→ Change summary: "23 clauses improved, 4 added, 12 unchanged"
→ Exportable as DOCX or PDF
→ Side-by-side comparison available

Flutter display:
→ "Generate Better Version" button on Analysis Results
→ Processing indicator while generating
→ Preview of new document with change highlights
→ Download as DOCX or PDF
→ "Share with Lawyer" button
```

---

### F24 — Domain-Specific Templates

**What it does:**
Provides ready-made fair contract templates for common document types that users can use as a starting point or baseline for comparison.

**How it works:**
A pre-seeded templates library contains standard fair versions of common contracts per jurisdiction. Users can browse, preview, and download templates. When analyzing a document, the AI compares it against the relevant template to identify deviations.

**Input:**
```
→ User selects document type and jurisdiction
→ Supported types:
   Residential Lease, NDA, Employment Contract,
   Freelance Agreement, SaaS Terms, Privacy Policy,
   Partnership Deed, Loan Agreement, Service Agreement
```

**Output:**
```
→ Standard template document text
→ Downloadable as PDF or DOCX
→ "How this compares to your document" analysis

Flutter display:
→ Templates section on Home Dashboard
→ Browse by category
→ Preview + Download buttons
→ "Compare with my document" button
```

---

### F25 — Jurisdiction Map (Visual)

**What it does:**
An interactive visual map where users tap on their state and instantly see how their document's clauses are affected under that state's laws — making the jurisdiction feature visually stunning and intuitive.

**How it works:**
Flutter renders an interactive SVG map of India (or world map). Each state is tappable. On tap, the jurisdiction compliance check (F09) is re-run for the selected state and results are displayed overlaid on the map. States with clause violations are color-coded red, states with warnings are yellow, clean states are green.

**Input:**
```
→ Tap event on state/region on map
→ Selected country → state
→ Current document's analyzed clauses
→ Legal Rules table for jurisdiction matching
```

**Output:**
```
→ Map re-colors based on violation count per state
→ State panel slides up showing:
   Violations: 3 / Warnings: 2 / Clean: 14
   List of affected clauses for that state

Flutter display:
→ Interactive SVG map widget
→ 🔴 Red states = violations
→ 🟡 Yellow states = warnings
→ 🟢 Green states = compliant
→ Tap state → detail panel slides up
→ "Analyze for this state" button
```

---

## 🔒 TIER 4: SECURITY FEATURES

---

### F26 — Privacy-First Architecture

**What it does:**
Ensures the entire system is built with privacy by default — documents are treated as sensitive data, access is strictly controlled, and users are always in control of their data.

**How it works:**
Every document upload is associated only with the uploading user via Row Level Security in Supabase (users cannot access others' documents even if they have the document ID). All files in Supabase Storage use private buckets. API endpoints check ownership before returning any data.

**Input:**
```
→ User's JWT token on every request
→ document_id in request params
→ Supabase RLS policies on all tables
```

**Output:**
```
→ 403 Forbidden if user doesn't own document
→ Private signed URLs for file access (expires in 1 hour)
→ No document data returned without auth token

Security rules:
→ Users see ONLY their own documents
→ Users see ONLY their own analysis results
→ Users see ONLY their own chat history
→ Admin cannot view user documents without audit log
```

---

### F27 — End-to-End Encryption

**What it does:**
Encrypts document content at rest in the database so even a database breach cannot expose users' legal documents.

**How it works:**
Before saving raw_text to the database, it is encrypted using AES-256-CBC with an encryption key stored in environment variables (never in DB). Decryption only happens at the service layer when text is needed for AI processing. Files in Supabase Storage are stored in private buckets with access-controlled signed URLs.

**Input:**
```
→ raw_text before DB save
→ AES-256 encryption key from environment
→ Unique IV generated per document
```

**Output:**
```
→ encrypted_text stored in DB (not readable as plain text)
→ IV stored alongside for decryption
→ Decryption only at service layer, never exposed
→ HTTPS enforced on all API endpoints
→ Signed URLs for file access (1-hour expiry)
```

---

### F28 — Auto-Delete After Processing

**What it does:**
Automatically deletes the raw document file and clears sensitive text from the database after processing is complete, ensuring user documents are never stored longer than necessary.

**How it works:**
When a document is uploaded, an auto_delete_at timestamp is set (default: 24 hours after upload, configurable by user). A cron job runs every hour checking for documents past their auto_delete_at time. It deletes the file from Supabase Storage and wipes the raw_text field from the Document table while keeping the analysis results (which contain no raw document content).

**Input:**
```
→ auto_delete_at timestamp on Document record
→ User's deletion preference:
   "after processing" / "24 hours" / "7 days" / "manual"
→ Cron job runs every hour
```

**Output:**
```
→ File deleted from Supabase Storage
→ raw_text field wiped from Document table (set to null)
→ is_deleted: true on Document record
→ Analysis results KEPT (they contain no raw document)
→ User notified: "Your document file has been securely deleted"
```

---

## 📤 TIER 5: OUTPUT & EXPORT FEATURES

---

### F29 — Export as PDF

**What it does:**
Generates a professionally formatted PDF report of the complete document analysis that users can save, print, or share with their lawyer.

**How it works:**
The export service compiles all analysis data (summary, risk score, clause breakdown, flags, missing clauses, counter-suggestions) into a structured PDF template using a PDF generation library. The report is branded with LegalLens AI header and contains all findings in a readable, printable format.

**Input:**
```
→ document_id
→ analysis_result with all related data
→ User's selection: which sections to include
   [Summary] [Clauses] [Risks] [Missing] [Counter-Clauses]
```

**Output:**
```
→ PDF file generated
→ Sections: Cover page, Summary, Risk Score,
   Clause Breakdown, Flags, Missing Clauses,
   Counter-Clause Suggestions, Deadlines
→ Downloadable to device
→ Shareable via share_plus

Flutter display:
→ Export Options Page
→ Section checkboxes (choose what to include)
→ "Generate PDF" button
→ Report Preview page before download
→ Share button after generation
```

---

### F30 — Export as DOCX

**What it does:**
Exports the analysis or generated counter-document as an editable Word file so lawyers and users can make further edits, add comments, or use it in legal proceedings.

**How it works:**
Uses docx generation library to create a structured Word document. If exporting the analysis report, same structure as PDF. If exporting the "Better Version" from F23, it creates a clean editable contract document with tracked changes formatting.

**Input:**
```
→ document_id
→ export_type: "analysis_report" / "better_version" / "counter_clauses"
```

**Output:**
```
→ .docx file
→ Proper Word formatting: headings, tables, bullet points
→ For better_version: original text in strikethrough,
  new text in bold (tracked-changes style)
→ Downloadable and editable
```

---

### F31 — Export as JSON/CSV

**What it does:**
Provides raw structured data export for developers, legal teams, or power users who want to import the analysis data into their own tools, CRMs, or spreadsheets.

**Input:**
```
→ document_id
→ format: "json" / "csv"
→ scope: "clauses" / "risks" / "deadlines" / "full"
```

**Output:**
```
JSON: Complete structured analysis object
CSV: Tabular format
  Columns: clause_number, title, risk_level,
  risk_score, risk_category, plain_english, flagged, missing
→ Downloadable file
→ Also available via REST API endpoint (F33)
```

---

### F32 — Shareable Link

**What it does:**
Generates a secure, time-limited shareable link to the document analysis so users can send their lawyer or colleague a view-only link without them needing to create an account.

**How it works:**
Backend generates a signed token tied to the analysis_id with an expiry (default 7 days). A public read-only endpoint accepts this token and returns the full analysis in view mode. The view is a clean web page (no editing, no account required).

**Input:**
```
→ document_id / analysis_id
→ expiry preference: 24hrs / 7 days / 30 days
→ scope: which sections to share
   [Summary only] / [Full analysis] / [Specific clauses]
```

**Output:**
```
→ Signed URL: app.legallens.ai/share/{token}
→ Expiry timestamp
→ View count tracking
→ "Revoke link" option

Flutter display:
→ "Share Analysis" button on Results Page
→ Copy link / Share via share sheet
→ Expiry and view count shown
→ "Revoke" button to invalidate link
```

---

### F33 — REST API Endpoint

**What it does:**
Exposes a public API so developers, law firms, and enterprise users can integrate LegalLens AI's analysis capabilities directly into their own systems programmatically.

**Input:**
```
POST /api/v1/analyze
Headers: Authorization: Bearer {api_key}
Body: {
  source_type: "file" / "text" / "url",
  content: base64 file OR text string OR URL,
  jurisdiction: {country, state},
  language: "en",
  options: {
    include_counter_clauses: true,
    include_plain_english: true
  }
}
```

**Output:**
```
JSON response:
{
  document_id,
  document_type,
  risk_score,
  risk_level,
  summary,
  clauses: [...],
  risks: [...],
  missing_clauses: [...],
  deadlines: [...],
  processing_time
}

→ Webhook support for async processing
→ API key management in user profile
→ Rate limited: 100 requests/day (free tier)
```

---

## 🎨 TIER 6: UX FEATURES

---

### F34 — Dark Mode / Light Mode

**What it does:**
Provides full dark and light theme support across all 38 pages.

**Input:**
```
→ User toggle in Settings Page
→ OR auto-follow device system theme
```

**Output:**
```
→ All colors, backgrounds, text switch instantly
→ Preference saved in local storage
→ Persists across app restarts
→ Legal-appropriate color palette for both modes:
   Dark: deep navy / white text / red/yellow/green accents
   Light: white / dark grey text / same accents
```

---

### F35 — Document History Dashboard

**What it does:**
Central library of all documents the user has ever analyzed, with search, filter, and sort capabilities.

**Input:**
```
→ User's document records from DB
→ Search query (by name, type, date)
→ Filter: document type
→ Sort: newest / riskiest / oldest
```

**Output:**
```
→ Paginated list of document cards
→ Each card: name, type icon, risk score badge, date
→ Tap → opens that document's Analysis Results

Flutter display:
→ History Page (P17)
→ Search bar at top
→ Filter chips: All / Lease / NDA / Employment / Others
→ Swipe to delete on each card
→ Empty state: "No documents yet — upload your first one"
```

---

### F36 — Offline Mode

**What it does:**
Allows users to view previously analyzed documents and results without an internet connection.

**How it works:**
When analysis results are fetched, they are cached locally using Hive or flutter_secure_storage. On app open, the app checks connectivity. If offline, it serves from local cache. Any actions taken offline (marking deadlines complete, adding notes) are queued and synced when online.

**Input:**
```
→ Previously fetched and cached analysis data
→ Device connectivity status (connectivity_plus package)
```

**Output:**
```
→ Full read access to past analyses offline
→ Deadlines page works offline
→ Offline banner shown at top when disconnected
→ Sync indicator when reconnected
→ "Available offline" badge on cached documents
```

---

### F37 — Annotation Mode

**What it does:**
Lets users highlight clauses and add personal notes directly on the document analysis, like sticky notes on a contract.

**Input:**
```
→ User taps and holds any clause
→ Writes a personal note
→ Selects highlight color
```

**Output:**
```
→ Annotation saved linked to clause_id and user_id
→ Persists across sessions
→ Notes visible as sticky note icons on clause cards
→ Tap note icon → shows the annotation
→ Annotations included in PDF export (F29)
→ Annotations visible in shared links (optional)
```

---

### F38 — Read Aloud (TTS)

**What it does:**
Reads any clause or section aloud using text-to-speech in the user's language, making the app accessible to users who prefer audio or have reading difficulties.

**Input:**
```
→ Tap "Read Aloud" button on any clause card
→ OR "Read All" on Plain Language Page
→ Selected language for TTS (follows user preference)
→ Reading speed: slow / normal / fast
```

**Output:**
```
→ Plain English version read aloud (not legal jargon)
→ Highlighted word-by-word as it reads (karaoke style)
→ Playback controls: play/pause/stop/speed
→ flutter_tts package handles 40+ language voices
→ Runs in background (user can scroll while listening)
```

---

### F39 — Multi-User Sharing (Workspace)

**What it does:**
Allows a document analysis to be shared as a workspace where multiple users (e.g., user + lawyer + business partner) can view the same analysis and leave notes collaboratively.

**Input:**
```
→ Owner invites via email
→ Invitee role: "viewer" / "commenter"
→ No "editor" role (analysis is AI-generated, not editable)
```

**Output:**
```
→ Shared workspace created linked to analysis_id
→ Invitees get email with workspace link
→ All members see same analysis + each other's annotations
→ Comment threads on clauses (like Google Docs comments)
→ Owner can revoke access anytime
```

---

### F40 — Voice Input in Chat

**What it does:**
Lets users speak their questions to the document chat instead of typing, making the experience faster and more natural.

**Input:**
```
→ Tap microphone button in Chat Page
→ Speech captured via speech_to_text Flutter package
→ Supported languages: follows user's preferred language
```

**Output:**
```
→ Speech converted to text in real time
→ Text auto-populates chat input field
→ User can edit before sending OR auto-send on silence
→ Works in any language supported by device STT engine
```

---

### F41 — Onboarding Walkthrough

**What it does:**
First-time user guided tour that shows new users how to use the app's core features through an interactive overlay walkthrough.

**Input:**
```
→ Triggered automatically on first login
→ Can be replayed from Help section in Settings
```

**Output:**
```
→ 6-step overlay walkthrough:
   Step 1: "Tap + to upload your first document"
   Step 2: "We detect your document type automatically"
   Step 3: "See your risk score at a glance"
   Step 4: "Read every clause in plain English"
   Step 5: "Chat with your document like a lawyer"
   Step 6: "Track all your deadlines here"
→ Skip button on each step
→ Tutorial_coach_mark Flutter package
```

---

### F42 — Notification Center

**What it does:**
A dedicated in-app page showing all past and upcoming notifications, alerts, deadline reminders, and system messages in one organized feed.

**Input:**
```
→ All Notification records for the logged-in user
→ Sorted by: newest first
→ Filtered by: all / unread / deadline / system
```

**Output:**
```
→ Notification feed with:
   - Deadline reminders
   - Analysis completion alerts
   - Jurisdiction warnings added
   - Counter-clauses ready
   - System messages
→ Unread count badge on bell icon in bottom nav
→ Swipe to dismiss individual notifications
→ "Mark All Read" button
→ Tap notification → deep links to relevant page
```

---

## 📊 COMPLETE FEATURE REFERENCE TABLE

| ID | Feature | Tier | Input | Output |
|---|---|---|---|---|
| F01 | Universal Format Upload | Core | File/Image/Text/URL | Document record + raw_text |
| F02 | OCR Scan Support | Core | Device camera image | Extracted + cleaned text |
| F03 | AI Document Analysis | Core | raw_text + doc_type | Clause records in DB |
| F04 | Auto Document Summary | Core | AI analysis response | Summary + parties + dates |
| F05 | Risk Score Dashboard | Core | All clause risk scores | 0-100 score + color level |
| F06 | Risk Categorization | Core | Clauses with categories | Risk Item records per category |
| F07 | Plain Language Translation | Core | Original clause text | Plain English + glossary terms |
| F08 | Document Type Detection | Core | First 2000 chars | Type + confidence + prompt selection |
| F09 | Multi-Jurisdiction Compliance | Power | Clauses + jurisdiction | Jurisdiction Flag records |
| F10 | State Conflict Detection | Power | Flagged clauses + rules | Cross-state conflict matrix |
| F11 | Multilingual Support | Power | Doc in any language | Analysis in user's language |
| F12 | Risky Clause Flagging | Power | Clauses + patterns library | Clause Flag records |
| F13 | Missing Clause Detection | Power | Found clauses + templates | Missing Clause records |
| F14 | Counter-Clause Suggestions | Power | Risky clauses | Rewritten fair alternatives |
| F15 | Deadline Tracker | Power | Extracted dates from AI | Deadline records with urgency |
| F16 | Calendar Export | Power | Deadline records | Google Calendar events / .ics file |
| F17 | Deadline Reminders | Power | Deadlines + user prefs | Push notifications + emails |
| F18 | Interactive Document Chat | Power | User question + doc | AI answer from document context |
| F19 | Clause Citation in Chat | Power | AI response text | Tappable clause reference chips |
| F20 | Document Comparison | Wow | Two document versions | Word-level diff + new risks |
| F21 | Fairness Score | Wow | Clause party distribution | 0-100 fairness score |
| F22 | AI Playbook System | Wow | User-defined rules | Personal clause flags |
| F23 | One-Click Better Version | Wow | All counter-suggestions | Full rewritten document |
| F24 | Domain-Specific Templates | Wow | Doc type + jurisdiction | Standard fair contract template |
| F25 | Jurisdiction Map Visual | Wow | Tap on state | Color-coded compliance map |
| F26 | Privacy-First Architecture | Security | JWT + RLS policies | Access control enforcement |
| F27 | End-to-End Encryption | Security | raw_text before save | AES-256 encrypted storage |
| F28 | Auto-Delete After Processing | Security | auto_delete_at timestamp | File + text wiped from system |
| F29 | Export as PDF | Output | Analysis data + sections | Formatted PDF report |
| F30 | Export as DOCX | Output | Analysis or better version | Editable Word document |
| F31 | Export as JSON/CSV | Output | Analysis data | Structured data file |
| F32 | Shareable Link | Output | analysis_id + expiry | Signed view-only URL |
| F33 | REST API Endpoint | Output | API key + document | JSON analysis response |
| F34 | Dark / Light Mode | UX | User toggle | Full theme switch |
| F35 | Document History | UX | User's documents | Searchable + filterable library |
| F36 | Offline Mode | UX | Cached data | Read access without internet |
| F37 | Annotation Mode | UX | User note + clause | Saved annotation on clause |
| F38 | Read Aloud TTS | UX | Plain English text | Audio playback with highlights |
| F39 | Multi-User Sharing | UX | Invite email + role | Shared analysis workspace |
| F40 | Voice Input in Chat | UX | Spoken question | Text in chat input field |
| F41 | Onboarding Walkthrough | UX | First login trigger | 6-step interactive tour |
| F42 | Notification Center | UX | User notifications | Organized notification feed |

---

> **Total: 42 Features | 6 Tiers | Everything documented with What, How, Input, Output**

Want me to now write the **master AI prompt template** that handles F03 + F04 + F05 + F06 + F07 + F08 all in one single AI call?