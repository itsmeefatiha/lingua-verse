# LinguaVerse

LinguaVerse is a full-stack language learning platform with a FastAPI backend, PostgreSQL persistence, and a Flutter frontend. The project includes learning flows, quizzes, progress tracking, gamification, analytics, and admin features.

## Project Structure

- `backend/` FastAPI app, SQLAlchemy models, Alembic migrations, and seed data
- `frontend/` Flutter application and UI feature modules
- `sql/` local seed scripts for development data

## Tech Stack

- Backend: FastAPI, SQLAlchemy, Alembic, PostgreSQL
- Frontend: Flutter, Provider, HTTP client libraries

## Requirements

- Python 3.11+
- PostgreSQL 15+ or a compatible version
- Flutter SDK 3.11+
- Node.js is not required

## Backend Setup

1. Open a terminal in the project root and move into the backend folder.

```bash
cd backend
```

2. Create and activate a virtual environment.

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

3. Install dependencies.

```bash
pip install -r requirements.txt
```

4. Create `backend/.env` with your local configuration.

```env
SECRET_KEY=change_me
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_SERVER=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_DB=linguaverse

SMTP_SERVER=localhost
SMTP_PORT=1025
SMTP_USER=
SMTP_PASSWORD=

TTS_ENGINE=mock
TTS_DEFAULT_LANG=en
STT_ENGINE=simulated
```

5. Run database migrations.

```bash
python -m alembic upgrade head
```

6. Optionally load sample data.

```bash
psql -d linguaverse -f ../sql/seed_learning_engine.sql
```

7. Start the API server.

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The API is available at `http://127.0.0.1:8000` and the interactive docs are at `http://127.0.0.1:8000/docs`.

## Frontend Setup

1. Open a terminal in the project root and move into the frontend folder.

```bash
cd frontend
flutter pub get
```

2. Run the app with the backend URL passed through `API_BASE_URL`.

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

### Recommended API URLs

- Web or desktop: `http://127.0.0.1:8000/api/v1`
- Android emulator: `http://10.0.2.2:8000/api/v1`
- Physical device: use your machine’s LAN IP, for example `http://192.168.1.20:8000/api/v1`

The Flutter app reads the backend URL from `API_BASE_URL` in `frontend/lib/app/config/app_config.dart`. If the define is omitted, the app falls back to `127.0.0.1` on web/desktop and `10.0.2.2` on Android emulator.

## Common Commands

Backend:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Frontend:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Migration reset for local development:

```bash
python -m alembic upgrade head
```

## Environment Variables

### Backend

- `SECRET_KEY` JWT signing secret
- `ALGORITHM` token algorithm, default `HS256`
- `ACCESS_TOKEN_EXPIRE_MINUTES` access token lifetime
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_SERVER`, `POSTGRES_PORT`, `POSTGRES_DB` database connection values
- `SMTP_SERVER`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD` mail settings
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET` optional OAuth credentials
- `TTS_ENGINE`, `TTS_DEFAULT_LANG`, `TTS_STORAGE_BASE_URL`, `TTS_OUTPUT_DIR` text-to-speech configuration
- `STT_ENGINE` speech-to-text configuration

### Frontend

- `API_BASE_URL` backend base URL, including `/api/v1`
- `GOOGLE_WEB_CLIENT_ID` optional Google sign-in client ID

## Notes

- The backend is mounted under `/api/v1` through the FastAPI router.
- CORS is currently permissive for development, so tighten it before production deployment.
- Keep local seed data and migration order aligned when changing quiz, content, or role-related models.
