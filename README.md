# LinguaVerse

LinguaVerse is a full-stack language learning application with a FastAPI backend and a Flutter frontend.

This README provides a concise, project-aligned setup and the primary commands to run the app locally.

**Tech Stack**
- **Backend:** FastAPI, SQLAlchemy, Alembic, PostgreSQL
- **Frontend:** Flutter

**Prerequisites**
- Python 3.11+
- PostgreSQL
- Flutter SDK

**Quick Start — Backend**
1. From the project root, open a terminal and change to the backend folder:

```bash
cd backend
```

2. Create and activate a virtual environment (PowerShell example):

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

3. Install Python dependencies:

```bash
pip install -r requirements.txt
```

4. Create `backend/.env` with your local settings. Minimal example:

```env
SECRET_KEY=change_me
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_SERVER=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_DB=linguaverse
```

5. Run database migrations:

```bash
python -m alembic upgrade head
```

6. (Optional) Seed sample data:

```bash
psql -d linguaverse -f sql/seed_learning_engine.sql
```

7. Start the backend server (from the `backend` directory):

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be reachable on http://0.0.0.0:8000 and the OpenAPI docs at http://0.0.0.0:8000/docs

**Quick Start — Frontend**
1. From project root, open a terminal and change to the frontend folder:

```bash
cd frontend
flutter pub get
```

2. Main command to run the Flutter app (replace `<LOCAL_ADDRESS>` or add additional Dart defines as needed):

```bash
flutter run --dart-define=API_BASE_URL=http://<LOCAL_ADDRESS>:8000/api/v1 --dart-define=OTHER_DEFINE=...
```

- For local web testing you can use `http://127.0.0.1:8000/api/v1`.
- For Android emulator use `http://10.0.2.2:8000/api/v1` when running on the Android emulator.

**Primary Commands (copyable)**
- Backend: `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload` (run from `backend`)
- Frontend: `flutter run --dart-define=API_BASE_URL=http://<LOCAL_ADDRESS>:8000/api/v1 --dart-define=...`

If you want, I can replace `<LOCAL_ADDRESS>` with concrete examples for web, emulator, or a connected device.

**Notes**
- The frontend reads the API URL from the `API_BASE_URL` Dart define. Passing it explicitly is recommended for local testing.
- Keep `TTS`/`STT` settings and other environment values in `backend/.env`.

If you'd like I can also:
- Add a one-line `Makefile` or PowerShell script for these commands
- Replace the `<LOCAL_ADDRESS>` placeholders with exact examples for web, emulator and device

---

