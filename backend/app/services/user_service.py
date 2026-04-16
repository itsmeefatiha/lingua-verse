import logging
from sqlalchemy.orm import Session
from sqlalchemy import String, func
from datetime import datetime, timedelta, timezone
from app.models.user import User, LeagueEnum
from app.models.analytics import ListeningSession
from app.models.progress import UserLessonProgress, ProgressStatusEnum
from app.models.quiz import QuizAttempt
from app.schemas.user import UserCreate, UserProfileUpdate, AdminUserUpdate
from app.core.security import get_password_hash, generate_otp, verify_password

logger = logging.getLogger(__name__)

def _verify_otp(submitted_otp: str, stored_otp_value: str | None) -> bool:
    """Verifies the OTP using direct string comparison (OTPs are temporary and short-lived)."""
    if not stored_otp_value:
        return False
    
    # Direct comparison for OTP (no hashing needed for 6-digit temporary codes)
    return submitted_otp.strip() == stored_otp_value.strip()

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
        otp_code=otp,  # Store plain text OTP
        otp_expiry=otp_expiry,
        is_active=False
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # TESTING ONLY: Log the plain-text OTP. Remove before production!
    logger.info(f"User created and activation OTP generated: {otp}", extra={"email": user_in.email})
    
    return db_user, otp

def activate_user(db: Session, email: str, otp_code: str) -> User | None:
    user = get_user_by_email(db, email)
    
    if not _is_otp_valid(user, otp_code):
        return None
    
    user.is_active = True
    user.otp_code = None
    user.otp_expiry = None
    db.commit()
    db.refresh(user)
    return user

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
    
    user.otp_code = otp  # Store plain text OTP
    user.otp_expiry = datetime.now(timezone.utc) + timedelta(minutes=15)
    db.commit()
    
    # TESTING ONLY: Log the plain-text OTP. Remove before production!
    logger.info(f"Password reset OTP generated: {otp}", extra={"email": user.email})
    
    return otp
    
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

    role_text = func.lower(User.role.cast(String))
    admin_users = db.query(func.count(User.id)).filter(role_text == "admin").scalar() or 0
    user_users = db.query(func.count(User.id)).filter(role_text.in_(["user", "student", "teacher"])) .scalar() or 0

    total_xp_distributed = db.query(func.coalesce(func.sum(User.total_xp), 0)).scalar() or 0
    average_xp = float(db.query(func.coalesce(func.avg(User.total_xp), 0)).scalar() or 0)

    total_lessons_completed = (
        db.query(func.count(UserLessonProgress.id))
        .filter(UserLessonProgress.status == ProgressStatusEnum.COMPLETED)
        .scalar()
        or 0
    )

    total_listening_seconds = db.query(func.coalesce(func.sum(ListeningSession.duration_seconds), 0)).scalar() or 0
    total_quiz_seconds = db.query(func.coalesce(func.sum(QuizAttempt.duration_seconds), 0)).scalar() or 0
    average_time_spent_minutes = 0.0
    if total_users > 0:
        average_time_spent_minutes = round(((int(total_listening_seconds) + int(total_quiz_seconds)) / total_users) / 60.0, 2)

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

    language_rows = (
        db.query(
            ListeningSession.language_code.label("language_code"),
            func.coalesce(func.sum(ListeningSession.duration_seconds), 0).label("duration_seconds"),
        )
        .group_by(ListeningSession.language_code)
        .all()
    )
    language_rows += (
        db.query(
            QuizAttempt.language_code.label("language_code"),
            func.coalesce(func.sum(QuizAttempt.duration_seconds), 0).label("duration_seconds"),
        )
        .filter(QuizAttempt.language_code.isnot(None))
        .group_by(QuizAttempt.language_code)
        .all()
    )

    aggregated_languages: dict[str, int] = {}
    for row in language_rows:
        code = (row.language_code or "").strip().lower()
        if not code:
            continue
        aggregated_languages[code] = aggregated_languages.get(code, 0) + int(row.duration_seconds or 0)

    popular_languages = [
        {
            "language_code": code,
            "duration_minutes": round(seconds / 60.0, 2),
        }
        for code, seconds in sorted(aggregated_languages.items(), key=lambda item: item[1], reverse=True)[:6]
    ]

    return {
        "total_users": total_users,
        "active_users": active_users,
        "inactive_users": inactive_users,
        "admin_users": admin_users,
        "user_users": user_users,
        "total_xp_distributed": int(total_xp_distributed),
        "average_xp": average_xp,
        "average_time_spent_minutes": average_time_spent_minutes,
        "total_lessons_completed": int(total_lessons_completed),
        "bronze_users": bronze_users,
        "argent_users": argent_users,
        "or_users": or_users,
        "top_users": top_users,
        "popular_languages": popular_languages,
    }


def list_admin_users(db: Session, search: str | None = None) -> list[User]:
    query = db.query(User)
    if search:
        pattern = f"%{search.strip().lower()}%"
        query = query.filter(
            func.lower(User.full_name).like(pattern) | func.lower(User.email).like(pattern)
        )
    return query.order_by(User.created_at.desc()).all()


def delete_user(db: Session, user: User) -> None:
    db.delete(user)
    db.commit()


def update_admin_user(db: Session, user: User, update_in: AdminUserUpdate) -> User:
    update_data = update_in.model_dump(exclude_unset=True)

    if "email" in update_data:
        email = str(update_data["email"]).strip().lower()
        existing_user = db.query(User).filter(User.email == email, User.id != user.id).first()
        if existing_user:
            raise ValueError("Cet email est déjà utilisé")
        user.email = email

    if "full_name" in update_data:
        user.full_name = update_data["full_name"]
    if "avatar_url" in update_data:
        user.avatar_url = update_data["avatar_url"]
    if "source_language" in update_data:
        user.source_language = update_data["source_language"] or user.source_language
    if "target_language" in update_data:
        user.target_language = update_data["target_language"] or user.target_language
    if "role" in update_data and update_data["role"] is not None:
        user.role = update_data["role"]
    if "is_active" in update_data and update_data["is_active"] is not None:
        user.is_active = update_data["is_active"]

    db.commit()
    db.refresh(user)
    return user