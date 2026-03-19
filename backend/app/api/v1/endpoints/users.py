from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.schemas.user import UserResponse, UserProfileUpdate
from app.models.user import User, RoleEnum
from app.api.deps import get_current_user, require_role
from app.db.database import get_db
from app.services import user_service

router = APIRouter()

@router.get("/me", response_model=UserResponse)
def get_my_profile(current_user: User = Depends(get_current_user)):
    return current_user

@router.patch("/me", response_model=UserResponse)
def update_my_profile(
    profile_in: UserProfileUpdate, 
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    return user_service.update_profile(db, user=current_user, profile_in=profile_in)