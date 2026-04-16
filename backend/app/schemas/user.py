from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
import re
from datetime import date, datetime
from app.models.user import RoleEnum, LeagueEnum, normalize_role_value

# Inscription classique
class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(
        min_length=8,
        max_length=128,
        description="Password must be at least 8 characters with uppercase, lowercase, digit, and special character"
    )
    full_name: str = Field(min_length=2, max_length=100)
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        if not re.search(r"[A-Z]", v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not re.search(r"[a-z]", v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not re.search(r"\d", v):
            raise ValueError("Password must contain at least one digit")
        if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", v):
            raise ValueError("Password must contain at least one special character (!@#$%^&*...)")
        return v

# Activation OTP
class OTPVerify(BaseModel):
    email: EmailStr
    otp_code: str

# Login
class LoginRequest(BaseModel):
    email: str
    password: str

    @field_validator('email')
    @classmethod
    def validate_login_email(cls, v: str) -> str:
        value = v.strip()
        if '@' not in value or value.startswith('@') or value.endswith('@'):
            raise ValueError('Invalid email format')
        return value

# Mise à jour du profil
class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    source_language: Optional[str] = None
    target_language: Optional[str] = None


class AdminUserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    avatar_url: Optional[str] = None
    source_language: Optional[str] = None
    target_language: Optional[str] = None
    role: Optional[RoleEnum] = None
    is_active: Optional[bool] = None

# Réponse standard de l'API
class UserResponse(BaseModel):
    id: int
    email: str
    full_name: Optional[str]
    avatar_url: Optional[str]
    role: str
    source_language: str
    target_language: str
    is_active: bool
    total_xp: int
    current_level: int
    weekly_xp: int
    current_league: LeagueEnum
    streak_count: int
    last_activity_date: Optional[date]

    model_config = {"from_attributes": True}

    @field_validator('role', mode='before')
    @classmethod
    def normalize_role(cls, v):
        return normalize_role_value(v)


class AdminTopUserStat(BaseModel):
    user_id: int
    full_name: Optional[str]
    email: str
    total_xp: int
    current_level: int
    streak_count: int
    current_league: LeagueEnum


class AdminUserSummary(BaseModel):
    id: int
    email: str
    full_name: Optional[str]
    avatar_url: Optional[str]
    role: str
    source_language: str
    target_language: str
    is_active: bool
    total_xp: int
    current_level: int
    weekly_xp: int
    current_league: LeagueEnum
    streak_count: int
    created_at: Optional[datetime] = None

    @field_validator('role', mode='before')
    @classmethod
    def normalize_role(cls, v):
        return normalize_role_value(v)


class AdminLanguagePopularity(BaseModel):
    language_code: str
    duration_minutes: float


class AdminDashboardStatsResponse(BaseModel):
    total_users: int
    active_users: int
    inactive_users: int
    admin_users: int
    user_users: int
    total_xp_distributed: int
    average_xp: float
    average_time_spent_minutes: float
    total_lessons_completed: int
    bronze_users: int
    argent_users: int
    or_users: int
    top_users: list[AdminTopUserStat]
    popular_languages: list[AdminLanguagePopularity]

# Réinitialisation Mot de passe
class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    email: EmailStr
    otp_code: str
    new_password: str