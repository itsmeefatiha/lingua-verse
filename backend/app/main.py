# uvicorn app.main:app --reload
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.api import api_router
from app.core.config import settings
from app.core.logging import setup_logging

setup_logging()

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="API Backend pour l'application d'apprentissage de langues LinguaVerse",
    version="1.0.0"
)

# Configuration CORS (Indispensable pour connecter un frontend Web ou certaines requêtes mobiles)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Autorise toutes les origines (à restreindre en production)
    allow_credentials=True,
    allow_methods=["*"],  # Autorise tout (GET, POST, PUT, DELETE, etc.)
    allow_headers=["*"],
)

# Les routes de l'API v1
app.include_router(api_router, prefix="/api/v1")

# Route de base pour vérifier que l'API est en ligne
@app.get("/")
def root():
    return {
        "message": "Bienvenue sur l'API de LinguaVerse ! 🌍",
        "docs": "Allez sur /docs pour voir la documentation interactive Swagger."
    }