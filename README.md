# LinguaVerse

LinguaVerse is a full-stack language learning app built with a FastAPI backend and a Flutter frontend.

The project is designed around a simple but powerful learning loop:
- pick a target language
- unlock levels progressively
- complete lessons word by word (with optional TTS)
- pass level quizzes to unlock the next level

It is also built to preserve progress per language, so users can switch languages without losing what they already completed.

---

## Tech Stack

### Backend
- FastAPI
- SQLAlchemy
- Alembic
- PostgreSQL
- Uvicorn

### Frontend
- Flutter
- Provider
- HTTP client
- flutter_tts (mobile/desktop)

---

## Project Structure

- `backend/` API, database models, migrations, services
- `frontend/` Flutter app
- `backend/sql/seed_learning_engine.sql` sample data for testing learning flow

---

## Prerequisites

Before running the project, make sure you have:
- Python 3.11+ (project can also run on 3.13 as in your setup)
- PostgreSQL
- Flutter SDK
- Android Studio + Android SDK (for Android runs)
- Git

Optional but recommended:
- VS Code with Flutter and Python extensions

---

## 1) Backend Setup

From project root:

```bash
cd backend
```

Create and activate a virtual environment (Windows PowerShell):

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

Install dependencies:

```bash
pip install -r requirements.txt
```

### Create `.env`

Create `backend/.env` with your local values:

```env
SECRET_KEY=change_me
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_SERVER=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_DB=linguaverse

SMTP_SERVER=smtp.example.com
SMTP_PORT=587
SMTP_USER=test@example.com
SMTP_PASSWORD=test

TTS_ENGINE=mock
TTS_DEFAULT_LANG=en
TTS_STORAGE_BASE_URL=https://storage.linguaverse.local/audio
TTS_OUTPUT_DIR=generated_audio

STT_ENGINE=simulated
```

### Run migrations

```bash
python -m alembic upgrade head
```

### Seed learning data

```bash
psql -d linguaverse -f sql/seed_learning_engine.sql
```

### Start backend server

```bash
uvicorn app.main:app --reload
```

API should be available at:
- `http://127.0.0.1:8000`
- Swagger docs: `http://127.0.0.1:8000/docs`

---

## 2) Frontend Setup

From project root:

```bash
cd frontend
flutter pub get
```

The frontend reads backend URL from a Dart define (`API_BASE_URL`) and falls back to:
- `http://127.0.0.1:8000/api/v1`

For reliable local testing, pass it explicitly.

---

## 3) Run Frontend (Web)

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Notes:
- `flutter_tts` is not fully implemented for web platforms.
- The lesson player is coded to continue in text-only mode when TTS is unavailable.

---

## 4) Run Frontend (Android)

### A) Android Emulator

Use Android emulator loopback URL:

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

### B) Real Android Device (USB)

Option 1: use your PC LAN IP

```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8000/api/v1
```

Option 2: use USB reverse (recommended for local testing)

```bash
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

---

## 5) Learning Engine Flow (What to Test)

After seeding:
1. Log in and open learning dashboard
2. Pick a target language
3. Open level A1
4. Complete all A1 lessons
5. Take A1 quiz and pass (>= 80)
6. Confirm A2 unlocks
7. Switch to another language and confirm prior language progress is preserved

---

## Common Issues and Fixes

### 1) `questions.choices does not exist`
Cause:
- backend code expects `questions.choices` but DB schema is not migrated.

Fix:
```bash
cd backend
python -m alembic upgrade head
```

### 2) `MissingPluginException` with `flutter_tts`
Cause:
- running on web where plugin method is not implemented.

Fix:
- use Android/iOS for full TTS, or continue on web in text-only mode.

### 3) `alembic` command not found
Fix:
```bash
cd backend
python -m alembic upgrade head
```

### 4) Frontend cannot reach backend on Android
Fix:
- emulator: use `10.0.2.2`
- real device: use LAN IP or `adb reverse`

---

## Handy Commands

Backend:

```bash
cd backend
python -m alembic upgrade head
uvicorn app.main:app --reload
```

Frontend web:

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Frontend android emulator:

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

---

## Final Notes

This repo is actively evolving. If something feels off while testing, run migrations first, then re-seed data, then restart backend and frontend.

If you want, a Docker setup can be added next (Postgres + API + Flutter web) to make onboarding one-command for new contributors.
