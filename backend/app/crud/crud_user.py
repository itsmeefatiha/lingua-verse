from sqlalchemy.orm import Session
from app.models.user import User
from app.core.security import hash_password
from datetime import datetime, timedelta

def create_user(db: Session, email: str, password: str, role: str):
    db_user = User(
        email=email,
        hashed_password=hash_password(password),
        role=role
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def set_reset_token(db: Session, user: User, token: str, expire_minutes: int = 60):
    user.reset_token = token
    user.reset_token_expire = int((datetime.utcnow() + timedelta(minutes=expire_minutes)).timestamp())
    db.commit()
    db.refresh(user)

def reset_password(db: Session, user: User, new_password: str):
    user.hashed_password = hash_password(new_password)
    user.reset_token = None
    user.reset_token_expire = None
    db.commit()
    db.refresh(user)