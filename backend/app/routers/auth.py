from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.database import get_db
from app.core.security import (
    verify_password,
    get_password_hash,
    create_access_token,
)
from app.core.config import settings
from app.models.user import User, ProfessorStudentLink
from app.schemas.user import UserCreate, UserResponse as UserSchema
import secrets
import string
from app.api.deps import get_current_user

router = APIRouter()


@router.post("/register", response_model=UserSchema)
async def register(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new user (student or professor)."""
    # Check if user already exists
    existing_user = db.query(User).filter(
        (User.email == user.email) | (User.username == user.username)
    ).first()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email or username already registered"
        )
    
    # Create new user
    db_user = User(
        email=user.email,
        username=user.username,
        full_name=user.full_name,
        role=user.role,
        hashed_password=get_password_hash(user.password),
        is_active=1
    )
    
    # Generate unique code for professor
    if user.role == "professor":
        while True:
            code = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(6))
            if not db.query(User).filter(User.professor_code == code).first():
                db_user.professor_code = code
                break
    
    db.add(db_user)
    db.flush() # Ensure db_user.id is available
    
    # Auto-link student if invite code is provided
    if user.role == "student" and user.professor_invite_code:
        professor = db.query(User).filter(User.professor_code == user.professor_invite_code, User.role == "professor").first()
        if not professor:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Professor with this invitation code not found"
            )
        
        link = ProfessorStudentLink(professor_id=professor.id, student_id=db_user.id)
        db.add(link)
    
    db.commit()
    db.refresh(db_user)
    
    return db_user


@router.post("/login", response_model=dict)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """Login and get access token."""
    # Find user by username
    # Recherche par nom d'utilisateur OU par email pour correspondre à l'interface
    user = db.query(User).filter(
        (User.username == form_data.username) | (User.email == form_data.username)
    ).first()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    # Return user + token for frontend compatibility
    user_dict = UserSchema.from_orm(user).dict()
    user_dict.update({
        "access_token": access_token,
        "token_type": "bearer"
    })
    return user_dict


@router.get("/me", response_model=UserSchema)
async def get_current_user_info(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get current user information."""
    return current_user