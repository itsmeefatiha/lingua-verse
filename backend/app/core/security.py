from datetime import datetime, timedelta, timezone
import random
import string
import bcrypt
from jose import jwt

from typing import Any
from fastapi import Depends, HTTPException, status
from app.api.deps import get_current_user
from app.models.user import User, RoleEnum

from app.core.config import settings

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Vérifie si le mot de passe en clair correspond au hash enregistré."""
    try:
        return bcrypt.checkpw(
            plain_password.encode('utf-8'),
            hashed_password.encode('utf-8')
        )
    except ValueError:
        # Failsafe in case of a malformed hash
        return False

def get_password_hash(password: str) -> str:
    """Génère un hash bcrypt sécurisé pour le mot de passe."""
    salt = bcrypt.gensalt()
    hashed_bytes = bcrypt.hashpw(password.encode('utf-8'), salt)
    
    # Decode back to string so it can be saved in the database text column
    return hashed_bytes.decode('utf-8')

def create_access_token(subject: str, expires_delta: timedelta = None) -> str:
    """Génère un JWT token pour l'authentification."""
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode = {"exp": expire, "sub": str(subject)}
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def generate_otp() -> str:
    """Génère un code OTP à 6 chiffres."""
    return ''.join(random.choices(string.digits, k=6))


def require_professor(current_user: User = Depends(get_current_user)) -> dict:
    if current_user.role != RoleEnum.PROFESSOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Professor access required"
        )
    return current_user.__dict__


def require_student(current_user: User = Depends(get_current_user)) -> dict:
    if current_user.role != RoleEnum.STUDENT:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Student access required"
        )
    return current_user.__dict__


def require_admin(current_user: User = Depends(get_current_user)) -> dict:
    if current_user.role != RoleEnum.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user.__dict__


# Re-export for routers that import get_current_user from here
get_current_user = get_current_user
