# Legisense

Fresh base: Flutter app + Node/Express backend.

```
legisense/
├── app/        # Flutter
└── backend/    # Express + TypeScript
```

## Backend

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

Health: http://localhost:3001/health

## App

```bash
cd app
flutter pub get
flutter run
```

## License

MIT — see `LICENSE`.
