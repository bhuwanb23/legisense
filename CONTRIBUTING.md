# Contributing to Legisense

Thanks for your interest in improving Legisense. This document describes how to
set up the project and what we expect from contributions.

## Code of Conduct

Be respectful and constructive. We want Legisense to be a welcoming project for
contributors of all experience levels.

## Getting Started

1. Fork the repository and clone your fork.
2. Pick up an issue or open one describing the change you intend to make.
3. Follow the setup instructions in [README.md](README.md) (Docker is the
   fastest path; manual setup is documented there as well).

## Branching

- Create a feature branch off `main`: `git checkout -b feature/short-name`.
- Use clear, imperative commit messages (`add`, `fix`, `refactor`, `docs`).
- Keep each commit focused; we prefer one logical change per commit.

## Development Workflow

### Backend (Django)

```bash
cd legisense_backend
python -m venv venv && source venv/bin/activate   # or venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
# in a second terminal, run the background worker:
celery -A legisense_backend worker -l info
```

- Run `python manage.py check` before pushing.
- Run the test suite: `python manage.py test`.

### Frontend (Flutter)

```bash
cd legisense
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=LEGISENSE_API_BASE=http://localhost:8000
```

- `flutter analyze` must pass with no errors or warnings.
- Fix lint issues rather than disabling rules.

## Pull Requests

- Open a PR against `main` with a clear description of the change and the
  motivation behind it.
- Reference any related issues (e.g. `Closes #123`).
- Ensure CI/local checks pass (backend `manage.py check` + tests, frontend
  `flutter analyze` + tests).
- Keep PRs reasonably sized; large changes are easier to review in stages.

## Reporting Issues

- Search existing issues before opening a new one.
- Include steps to reproduce, expected vs. actual behavior, and your environment
  (OS, Flutter/Dart version, Python version).

## License

By contributing, you agree that your contributions will be licensed under the
[MIT License](LICENSE).
