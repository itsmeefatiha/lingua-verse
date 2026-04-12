import logging
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta, timezone
from app.models.user import User, RoleEnum, LeagueEnum
from app.schemas.user import UserCreate, UserProfileUpdate
from app.core.security import get_password_hash, generate_otp, verify_password

logger = logging.getLogger(__name__)

def _verify_otp(submitted_otp: str, stored_otp_value: str | None) -> bool:
    """Verifies the OTP, falling back to direct comparison for legacy plain-text OTPs."""
    if not stored_otp_value:
        return False

    try:
        return verify_password(submitted_otp, stored_otp_value)
    except Exception:
        return submitted_otp == stored_otp_value

def _is_otp_valid(user: User | None, otp_code: str) -> bool:
    """Helper function to validate user existence, OTP correctness, and expiration."""
    if (
        not user
        or not _verify_otp(otp_code, user.otp_code)
        or not user.otp_expiry
        or user.otp_expiry < datetime.now(timezone.utc)
    ):
        return False
    return True

def get_user_by_email(db: Session, email: str) -> User | None:
    return db.query(User).filter(User.email == email).first()

def create_user(db: Session, user_in: UserCreate) -> tuple[User, str]:
    otp = generate_otp()
    otp_expiry = datetime.now(timezone.utc) + timedelta(minutes=15)
    
    db_user = User(
        email=user_in.email,
        hashed_password=get_password_hash(user_in.password),
        full_name=user_in.full_name,
        otp_code=get_password_hash(otp),
        otp_expiry=otp_expiry,
        is_active=False
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # TESTING ONLY: Log the plain-text OTP. Remove before production!
    logger.info(f"User created and activation OTP generated: {otp}", extra={"email": user_in.email})
    
    return db_user, otp

def activate_user(db: Session, email: str, otp_code: str) -> bool:
    user = get_user_by_email(db, email)
    
    if not _is_otp_valid(user, otp_code):
        return False
    
    user.is_active = True
    user.otp_code = None
    user.otp_expiry = None
    db.commit()
    return True

def update_profile(db: Session, user: User, profile_in: UserProfileUpdate) -> User:
    update_data = profile_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    return user

def create_password_reset_otp(db: Session, user: User) -> str:
    """Génère un OTP de réinitialisation et l'assigne à l'utilisateur."""
    otp = generate_otp()
    
    user.otp_code = get_password_hash(otp)
    user.otp_expiry = datetime.now(timezone.utc) + timedelta(minutes=15)
    db.commit()
    
    # TESTING ONLY: Log the plain-text OTP. Remove before production!
    logger.info(f"Password reset OTP generated: {otp}", extra={"email": user.email})
    
    return otp

def reset_password_with_otp(db: Session, email: str, otp_code: str, new_password: str) -> bool:
    """Vérifie l'OTP et enregistre le nouveau mot de passe."""
    user = get_user_by_email(db, email)
    
    if not _is_otp_valid(user, otp_code):
        return False
    
    user.hashed_password = get_password_hash(new_password)
    user.otp_code = None
    user.otp_expiry = None
    db.commit()
    return True


def get_admin_dashboard_stats(db: Session) -> dict:
    total_users = db.query(func.count(User.id)).scalar() or 0
    active_users = db.query(func.count(User.id)).filter(User.is_active.is_(True)).scalar() or 0
    inactive_users = total_users - active_users

    admin_users = db.query(func.count(User.id)).filter(User.role == RoleEnum.ADMIN).scalar() or 0
    teacher_users = db.query(func.count(User.id)).filter(User.role == RoleEnum.TEACHER).scalar() or 0
    student_users = db.query(func.count(User.id)).filter(User.role == RoleEnum.STUDENT).scalar() or 0

    total_xp_distributed = db.query(func.coalesce(func.sum(User.total_xp), 0)).scalar() or 0
    average_xp = float(db.query(func.coalesce(func.avg(User.total_xp), 0)).scalar() or 0)

    bronze_users = (
        db.query(func.count(User.id)).filter(User.current_league == LeagueEnum.BRONZE).scalar() or 0
    )
    argent_users = (
        db.query(func.count(User.id)).filter(User.current_league == LeagueEnum.ARGENT).scalar() or 0
    )
    or_users = db.query(func.count(User.id)).filter(User.current_league == LeagueEnum.OR).scalar() or 0

    top_users_query = (
        db.query(User)
        .order_by(User.total_xp.desc(), User.current_level.desc(), User.streak_count.desc())
        .limit(10)
        .all()
    )

    top_users = [
        {
            "user_id": user.id,
            "full_name": user.full_name,
            "email": user.email,
            "total_xp": user.total_xp,
            "current_level": user.current_level,
            "streak_count": user.streak_count,
            "current_league": user.current_league,
        }
        for user in top_users_query
    ]

    return {
        "total_users": total_users,
        "active_users": active_users,
        "inactive_users": inactive_users,
        "admin_users": admin_users,
        "teacher_users": teacher_users,
        "student_users": student_users,
        "total_xp_distributed": int(total_xp_distributed),
        "average_xp": average_xp,
        "bronze_users": bronze_users,
        "argent_users": argent_users,
        "or_users": or_users,
        "top_users": top_users,
    }