# app/api/v1/api.py
from fastapi import APIRouter
from .endpoints import auth, lessons

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(lessons.router, prefix="/lessons", tags=["lessons"])