import os
import bcrypt
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from pathlib import Path

from app.api.v1.api import api_router
from app.core.config import settings
from app.core.logging import setup_logging
from app.routers import auth, professor, quizzes, student, admin, gamification, catalog, ar
from app.database import engine, Base

setup_logging()

if not hasattr(bcrypt, "__about__"):
    bcrypt.__about__ = type("about", (object,), {"__version__": bcrypt.__version__})

os.makedirs("static/audio", exist_ok=True)
os.makedirs("uploads/audio", exist_ok=True)
os.makedirs("uploads/images", exist_ok=True)

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="API Backend pour l'application d'apprentissage de langues LinguaVerse",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Montage des fichiers statiques
app.mount("/static", StaticFiles(directory="static"), name="static")
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Inclusion des routeurs
app.include_router(api_router, prefix="/api/v1")

app.include_router(professor.router, prefix="/api/v1/professor", tags=["Professor"])
app.include_router(student.router, prefix="/api/v1/student", tags=["Student"])
app.include_router(quizzes.router, prefix="/api/v1/quizzes", tags=["Quizzes"])
app.include_router(admin.router, prefix="/api/v1/admin", tags=["Admin"])
app.include_router(gamification.router, prefix="/api/v1/gamification", tags=["Gamification"])
app.include_router(catalog.router, prefix="/api/v1/catalog", tags=["Catalog"])
app.include_router(ar.router, prefix="/api/v1/ar", tags=["AR"])

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(status_code=500, content={"detail": "Internal Server Error"})

@app.on_event("startup")
async def startup():
    print("LinguaVerse API is starting up...")

@app.get("/")
async def root():
    return {
        "message": "Bienvenue sur l'API de LinguaVerse ! 🌍",
        "docs": "Allez sur /docs pour voir la documentation interactive Swagger."
    }

@app.get("/health")
async def health():
    return {"status": "healthy", "service": settings.PROJECT_NAME}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
