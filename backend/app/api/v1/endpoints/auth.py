from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
import logging
from pydantic import BaseModel, Field
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
from app.db.database import get_db
from app.schemas.user import LoginRequest, UserCreate, UserResponse, OTPVerify, PasswordResetRequest, PasswordResetConfirm
from app.services import user_service, email_service
from app.core.security import verify_password, create_access_token
from app.core.config import settings
from app.models.user import User, RoleEnum

logger = logging.getLogger(__name__)

router = APIRouter()


class GoogleAuthRequest(BaseModel):
    id_token: str = Field(..., alias="idToken")

    model_config = {"populate_by_name": True}

def send_email_with_error_handling(email: str, otp_code: str, email_type: str):
    """Wrapper to handle email sending errors in background tasks."""
    try:
        if email_type == "activation":
            email_service.send_activation_otp_email(email, otp_code)
        elif email_type == "reset":
            email_service.send_reset_password_email(email, otp_code)
    except Exception as e:
        logger.error(f"Failed to send {email_type} email to {email}: {e}", exc_info=True)


def verify_google_token(token: str) -> dict:
    if not settings.GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=500, detail="GOOGLE_CLIENT_ID non configuré")

    try:
        payload = google_id_token.verify_oauth2_token(
            token,
            google_requests.Request(),
            settings.GOOGLE_CLIENT_ID,
        )
    except ValueError:
        raise HTTPException(status_code=401, detail="Google idToken invalide")

    issuer = payload.get("iss")
    if issuer not in {"accounts.google.com", "https://accounts.google.com"}:
        raise HTTPException(status_code=401, detail="Issuer Google invalide")

    if not payload.get("sub") or not payload.get("email"):
        raise HTTPException(status_code=400, detail="Payload Google incomplet")

    if payload.get("email_verified") is False:
        raise HTTPException(status_code=401, detail="Email Google non vérifié")

    return payload

@router.post("/register", response_model=UserResponse)
def register(user_in: UserCreate, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    # 1. Vérifier si l'email existe
    if user_service.get_user_by_email(db, email=user_in.email):
        raise HTTPException(status_code=400, detail="Email déjà utilisé")
    
    # 2. Créer l'utilisateur (cette fonction doit vous retourner l'utilisateur ET son code OTP généré)
    new_user, otp_code = user_service.create_user(db=db, user_in=user_in) 
    
    # 3. Envoyer l'e-mail EN ARRIÈRE-PLAN avec gestion d'erreurs
    background_tasks.add_task(send_email_with_error_handling, new_user.email, otp_code, "activation")
    
    # 4. Retourner la réponse immédiatement (n'attend pas que l'e-mail parte !)
    return new_user

@router.post("/verify-account")
def verify_account(data: OTPVerify, db: Session = Depends(get_db)):
    user = user_service.activate_user(db, data.email, data.otp_code)
    if not user:
        raise HTTPException(status_code=400, detail="OTP invalide ou expiré")
    
    access_token = create_access_token(subject=user.id)
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    # Notice we now use request.email and request.password
    user = user_service.get_user_by_email(db, email=request.email)
    
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Identifiants incorrects")
        
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Veuillez valider votre compte avec l'OTP")
    
    access_token = create_access_token(subject=user.id)
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/forgot-password")
def forgot_password(request: PasswordResetRequest, 
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    user = user_service.get_user_by_email(db, email=request.email)
    if user:
        # Générer l'OTP et l'enregistrer en BDD
        otp_code = user_service.create_password_reset_otp(db, user)
        
        # Lancer l'envoi de l'e-mail en arrière-plan avec gestion d'erreurs
        background_tasks.add_task(send_email_with_error_handling, user.email, otp_code, "reset")
    
    return {"msg": "Si cet email est associé à un compte, un code OTP a été envoyé."}

@router.post("/reset-password")
def reset_password(data: PasswordResetConfirm, db: Session = Depends(get_db)):
    """
    Vérifie l'OTP et met à jour le mot de passe.
    """
    success = user_service.reset_password_with_otp(
        db, 
        email=data.email, 
        otp_code=data.otp_code, 
        new_password=data.new_password
    )
    
    if not success:
        raise HTTPException(status_code=400, detail="Code OTP invalide ou expiré")
        
    return {"msg": "Mot de passe réinitialisé avec succès. Vous pouvez maintenant vous connecter."}


@router.post("/auth/google")
def auth_google(data: GoogleAuthRequest, db: Session = Depends(get_db)):
    payload = verify_google_token(data.id_token)

    google_sub = str(payload["sub"]).strip()
    email = str(payload["email"]).strip().lower()
    full_name = payload.get("name")
    avatar_url = payload.get("picture")

    user = (
        db.query(User)
        .filter(
            or_(
                and_(User.oauth_provider == "google", User.oauth_id == google_sub),
                User.email == email,
            )
        )
        .first()
    )

    if user:
        user.email = email
        user.oauth_provider = "google"
        user.oauth_id = google_sub
        user.is_active = True
        if full_name:
            user.full_name = full_name
        if avatar_url:
            user.avatar_url = avatar_url
    else:
        user = User(
            email=email,
            hashed_password=None,
            oauth_provider="google",
            oauth_id=google_sub,
            full_name=full_name,
            avatar_url=avatar_url,
            role=RoleEnum.USER,
            is_active=True,
        )
        db.add(user)

    db.commit()
    db.refresh(user)

    access_token = create_access_token(subject=user.id)
    return {"access_token": access_token, "token_type": "bearer"}

# L'intégration OAuth2 (Google/GitHub) en utilisant Authlib.
@router.get("/login/google")
def login_google():
    pass # Redirection vers l'URL Google OAuth2