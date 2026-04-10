from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.database import get_db
from app.models.user import User
from app.schemas.progress import (
    ProgressLessonDetailResponse,
    ProgressOverviewResponse,
    UserViewedVocabResponse,
)
from app.services import progress_service

router = APIRouter()


@router.get("/me", response_model=ProgressOverviewResponse)
def get_my_progress_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return progress_service.get_dashboard_overview(db, user_id=current_user.id)


@router.get("/lessons/{lesson_id}", response_model=ProgressLessonDetailResponse)
def get_my_lesson_progress(
    lesson_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        return progress_service.get_lesson_detail(db, user_id=current_user.id, lesson_id=lesson_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc


@router.post("/vocabularies/{vocabulary_id}/view", response_model=UserViewedVocabResponse, status_code=status.HTTP_201_CREATED)
def mark_vocabulary_viewed(
    vocabulary_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        return progress_service.mark_vocabulary_viewed(db, user_id=current_user.id, vocabulary_id=vocabulary_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
