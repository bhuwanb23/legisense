<p align="center">
  <img src="docs/diagrams/stats.svg" alt="LegiSense Stats" width="100%"/>
</p>

<h1 align="center">⚖️ LegiSense</h1>

<p align="center">
  <strong>AI-Powered Legal Document Intelligence Platform</strong><br/>
  <em>Upload any legal document → know exactly what you're signing in 60 seconds</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Node.js-20+-339933?style=for-the-badge&logo=node.js&logoColor=white" alt="Node.js"/>
  <img src="https://img.shields.io/badge/TypeScript-5.7-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript"/>
  <img src="https://img.shields.io/badge/AI-4_Providers-8B5CF6?style=for-the-badge&logo=openai&logoColor=white" alt="AI"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License"/>
</p>

---

## 😟 The Problem

Legal documents are **everywhere** — rental agreements, employment contracts, NDAs, loan terms, court notices. But they're written in dense legalese that most people can't understand.

**What goes wrong:**

- 📄 People sign contracts **without understanding** what they're agreeing to
- ⚠️ One-sided clauses hide in plain sight — long non-competes, unlimited liability, forfeiture penalties
- 📅 Critical deadlines get missed — renewal dates, notice periods, payment schedules
- 💰 Lawyers charge **$200-500/hour** just to read and explain a single document
- 🌍 Documents arrive in **different languages and jurisdictions** — state laws change everything
- 🔍 Missing protections go unnoticed — no confidentiality, no data protection, no dispute resolution

> **Millions of people sign legal documents every day without understanding what they're signing.**

---

## 💡 Our Solution

**LegiSense** is an AI-powered legal document intelligence platform that makes any legal document **understandable by everyone** — in 60 seconds.

### How It Works

<p align="center">
  <img src="docs/diagrams/pipeline.svg" alt="Analysis Pipeline" width="100%"/>
</p>

**Upload** → **Extract** → **Analyze** → **Understand**

1. **Upload** any document — PDF, DOCX, scan a photo, paste text, or import from URL
2. **AI reads** the entire document clause-by-clause using 15 type-specific legal prompts
3. **Get instant results** — risk scores, plain-English translations, key dates, missing protections
4. **Ask questions** — chat with your document and get cited answers

### What You Get

<p align="center">
  <img src="docs/diagrams/features.svg" alt="Features" width="100%"/>
</p>

| What | How |
|------|-----|
| **Risk Score** | 0-100 score with color-coded gauge — know instantly if it's dangerous |
| **Plain English** | Every clause rewritten in everyday language — no law degree needed |
| **Missing Clauses** | Flags protections that are absent — confidentiality, dispute resolution, etc. |
| **Deadline Tracker** | Auto-extracts renewal dates, notice periods, payment schedules |
| **Fairness Score** | "This contract favors the Landlord at 78/100" — with breakdown |
| **Counter Clauses** | AI suggests fairer alternatives for risky terms |
| **Document Chat** | Ask "Can I terminate early?" — get cited answers from the actual text |
| **Jurisdiction Check** | Knows which state laws apply and flags violations |

### The Tech

<p align="center">
  <img src="docs/diagrams/architecture.svg" alt="Architecture" width="100%"/>
</p>

**One AI call produces everything.** No separate API calls per feature. One master prompt returns clauses, risk scores, summary, deadlines, fairness analysis, and breach scenarios — then we split it into structured data.

**4 AI providers with automatic failover.** Ollama (local, free) → Gemini → OpenRouter → OpenAI. Works offline, works everywhere.

**Privacy-first.** Documents encrypted at rest with AES-256. Auto-deleted after processing. Never sold, never shared.

---

## 🚀 Quick Start

### Prerequisites

- **Node.js** ≥ 20
- **Flutter** ≥ 3.9 *(for mobile/web app)*
- **Ollama** *(optional — for free local AI)*

### Backend

```bash
cd backend
cp .env.example .env        # add your AI API keys
npm install
npm run dev                  # → http://localhost:3001
```

### App

```bash
cd app
flutter pub get
flutter run
```

### Verify it works

```bash
curl http://localhost:3001/health
# → {"status":"ok","service":"legisense-backend"}
```

---

## 📊 By the Numbers

| Metric | Value |
|--------|-------|
| Lines of Code | 44,000+ |
| Source Files | 234 |
| API Endpoints | 88+ |
| Database Tables | 26 |
| Features | 42 |
| Document Types | 15 |
| Flutter Pages | 37 |
| AI Providers | 4 |
| Test Files | 24 |
| Supported Languages | 37+ |

---

## 📄 License

MIT — see [`LICENSE`](LICENSE).

---

<p align="center">
  <strong>Built with ❤️ for making legal documents understandable by everyone.</strong>
</p>
