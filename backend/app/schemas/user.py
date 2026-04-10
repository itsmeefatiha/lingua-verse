from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
import re
from datetime import date
from app.models.user import RoleEnum, LeagueEnum

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
    email: EmailStr
    password: str

# Mise à jour du profil
class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    source_language: Optional[str] = None
    target_language: Optional[str] = None

# Réponse standard de l'API
class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: Optional[str]
    role: RoleEnum
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

# Réinitialisation Mot de passe
class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    email: EmailStr
    otp_code: str
    new_password: str