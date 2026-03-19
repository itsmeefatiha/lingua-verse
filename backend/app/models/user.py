from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum
from datetime import datetime, timezone
import enum
from app.db.base import Base

class RoleEnum(str, enum.Enum):
    STUDENT = "student"
    TEACHER = "teacher"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=True) # Nullable pour OAuth2
    
    # OAuth2 (Google/GitHub)
    oauth_provider = Column(String, nullable=True)
    oauth_id = Column(String, unique=True, nullable=True)

    # Profil
    full_name = Column(String, nullable=True)
    avatar_url = Column(String, nullable=True)
    source_language = Column(String, default="fr")
    target_language = Column(String, default="en")

    # RBAC
    role = Column(Enum(RoleEnum), default=RoleEnum.STUDENT)

    # Statut & OTP
    is_active = Column(Boolean, default=False)
    otp_code = Column(String, nullable=True)
    otp_expiry = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))