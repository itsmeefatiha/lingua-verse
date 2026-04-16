from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.schemas.user import UserResponse, UserProfileUpdate, AdminDashboardStatsResponse, AdminUserSummary, AdminUserUpdate
from app.models.user import User, RoleEnum, is_admin_role
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


@router.get("/admin/dashboard/stats", response_model=AdminDashboardStatsResponse)
def get_admin_dashboard_stats(
    _: User = Depends(require_role(RoleEnum.ADMIN)),
    db: Session = Depends(get_db),
):
    return user_service.get_admin_dashboard_stats(db)


@router.get("/admin/users", response_model=list[AdminUserSummary])
def list_admin_users(
    search: str | None = None,
    _: User = Depends(require_role(RoleEnum.ADMIN)),
    db: Session = Depends(get_db),
):
    return user_service.list_admin_users(db, search=search)


@router.patch("/admin/users/{user_id}", response_model=AdminUserSummary)
def update_admin_user(
    user_id: int,
    update_in: AdminUserUpdate,
    _: User = Depends(require_role(RoleEnum.ADMIN)),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Utilisateur introuvable")

    try:
        return user_service.update_admin_user(db, user, update_in)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc


@router.delete("/admin/users/{user_id}", status_code=204)
def delete_admin_user(
    user_id: int,
    _: User = Depends(require_role(RoleEnum.ADMIN)),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Utilisateur introuvable")
    if is_admin_role(user.role):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Impossible de supprimer un admin")
    user_service.delete_user(db, user)
    return None