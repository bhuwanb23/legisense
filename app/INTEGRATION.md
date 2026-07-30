# App ↔ Backend

## Run

```bash
# Terminal 1 — backend
cd backend
cp .env.example .env   # set JWT_SECRET + at least one AI key
npm install && npm run dev

# Terminal 2 — Flutter
cd app
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3001
```

Android emulator: `--dart-define=API_BASE_URL=http://10.0.2.2:3001`

## Auth

Email/password via `/api/auth`. OTP is not on the happy path.

## Checklist

1. Register → profile setup → home (empty docs)
2. Upload PDF / paste / URL → processing (socket progress) → analysis
3. Open risk / clauses / plain language / jurisdiction / missing / counter-clauses
4. Chat with citations
5. Deadlines + notifications
6. Logout
