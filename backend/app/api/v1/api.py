from fastapi import APIRouter
from .endpoints import auth, users, content, quiz, progress, gamification, analytics

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentification"])
api_router.include_router(users.router, prefix="/users", tags=["Utilisateurs"])
api_router.include_router(content.router, prefix="/content", tags=["Catalogue & Contenu"])
api_router.include_router(quiz.router, prefix="/quiz", tags=["Evaluation & Quiz"])
api_router.include_router(progress.router, prefix="/progress", tags=["Suivi de la Progression"])
api_router.include_router(gamification.router, tags=["Gamification & Social"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["Dashboard & Analytics"])