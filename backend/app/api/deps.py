from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from app.db.database import get_db
from app.models.user import User, RoleEnum, normalize_role_value
from app.core.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

def get_current_user(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)) -> User:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token invalide")
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Utilisateur introuvable ou inactif")
    return user

def require_role(required_role: RoleEnum):
    def role_checker(current_user: User = Depends(get_current_user)):
        current_role = normalize_role_value(current_user.role)
        required = normalize_role_value(required_role)
        if current_role == "admin":
            return current_user
        if current_role != required:
            raise HTTPException(status_code=403, detail="Privilèges insuffisants")
        return current_user
    return role_checker