# app/api/v1/endpoints/auth.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
import secrets

from app.schemas.user import UserCreate, UserLogin, Token, ForgotPassword, ResetPassword
from app.crud import crud_user
from app.db.session import get_db
from app.core.security import verify_password, create_access_token
from fastapi import APIRouter

router = APIRouter()
#router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=Token)
def register(user: UserCreate, db: Session = Depends(get_db)):

    db_user = crud_user.get_user_by_email(db, user.email)

    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    new_user = crud_user.create_user(db, user.email, user.password, user.role)

    token = create_access_token({"sub": str(new_user.id), "role": new_user.role})

    return {"access_token": token, "token_type": "bearer"}


@router.post("/login", response_model=Token)
def login(user: UserLogin, db: Session = Depends(get_db)):

    db_user = crud_user.get_user_by_email(db, user.email)

    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token({"sub": str(db_user.id), "role": db_user.role})

    return {"access_token": token, "token_type": "bearer"}


@router.post("/forgot-password")
def forgot_password(data: ForgotPassword, db: Session = Depends(get_db)):

    user = crud_user.get_user_by_email(db, data.email)

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    reset_token = secrets.token_urlsafe(32)

    crud_user.set_reset_token(db, user, reset_token)

    return {"message": f"Reset token generated: {reset_token}"}


@router.post("/reset-password")
def reset_password_endpoint(data: ResetPassword, db: Session = Depends(get_db)):

    user = db.query(crud_user.User).filter(crud_user.User.reset_token == data.token).first()

    if not user:
        raise HTTPException(status_code=404, detail="Invalid token")

    if user.reset_token_expire < int(datetime.utcnow().timestamp()):
        raise HTTPException(status_code=400, detail="Token expired")

    crud_user.reset_password(db, user, data.new_password)

    return {"message": "Password updated successfully"}