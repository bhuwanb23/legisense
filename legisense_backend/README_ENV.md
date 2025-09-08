# Backend environment setup

Create a `.env` file in `legisense_backend/` with:

OPENROUTER_API_KEY=your-openrouter-key-here
OPENROUTER_MODEL=anthropic/claude-3.5-sonnet
DEBUG=true
ALLOWED_HOSTS=*

Windows PowerShell quick start:

cd legisense_backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000

The Django settings load variables from `.env` automatically (python-dotenv).
