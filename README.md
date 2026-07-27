# Legisense — AI-Powered Legal Companion

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20%2B-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-4-000000?logo=express&logoColor=white)](https://expressjs.com/)
[![License](https://img.shields.io/badge/License-MIT-informational)](LICENSE)

**A citizen-first, India-first legal AI companion.** The app UI is in place; the backend is being rebuilt from scratch on Node.js + Express.

> **Status (branch `new_backend`):** Flutter is a **UI shell** (no live API). Backend is a **minimal Express scaffold** (`GET /health`). Features will be reconnected as we rebuild.

---

## Project structure

```
legisense/
├── app/                 # Flutter frontend (UI shell)
├── backend/             # Node.js + Express + TypeScript API
├── docs/superpowers/    # Design specs & plans
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## Prerequisites

- **Flutter** 3.x (Dart 3)
- **Node.js** 20+
- **npm** 10+

---

## Quick start

### Backend

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

API: [http://localhost:3001](http://localhost:3001)  
Health: [http://localhost:3001/health](http://localhost:3001/health)

### Frontend

```bash
cd app
flutter pub get
flutter run
```

The app runs as a UI shell. Upload, documents, simulation, and chat do not call the API yet.

---

## Development checks

```bash
# Backend
cd backend
npm run typecheck

# Frontend
cd app
flutter analyze
flutter test
```

---

## Roadmap (backend rebuild)

- Document upload & parsing
- AI contract analysis
- What-if simulation
- Multilingual translation
- Chat assistant
- Real authentication
- Wire Flutter → new API

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

MIT — see [`LICENSE`](LICENSE).

## Disclaimer

Legisense provides general information, not legal advice. Always consult a qualified legal professional for decisions that affect your rights or obligations.
