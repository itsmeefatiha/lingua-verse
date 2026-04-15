from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.database import get_db
from app.models.content import CEFRLevelEnum, Level
from app.models.user import User, is_admin_role
from app.schemas.content import (
    LanguageResponse,
    LevelCreate,
    LessonCreate,
    LessonResponse,
    LessonUpdate,
    LevelByLanguageResponse,
    LevelResponse,
    VocabularyCreate,
    VocabularyResponse,
    VocabularyUpdate,
)
from app.services import content_service

router = APIRouter()


def require_content_write_access(current_user: User = Depends(get_current_user)) -> User:
    if not is_admin_role(current_user.role):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Privilèges insuffisants")
    return current_user


@router.get("/levels", response_model=list[LevelResponse])
def list_levels(db: Session = Depends(get_db)):
    return content_service.list_levels(db)


@router.post("/levels", response_model=LevelResponse, status_code=status.HTTP_201_CREATED)
def create_level(
    level_in: LevelCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_content_write_access),
):
    existing = (
        db.query(Level)
        .filter(
            Level.language_id == level_in.language_id,
            Level.code == level_in.code,
        )
        .first()
    )
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Niveau deja existant pour cette langue")

    return content_service.create_level(db, level_in)


@router.get("/languages", response_model=list[LanguageResponse])
def list_languages(
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    return content_service.list_supported_languages(db)


@router.get("/languages/{language_code}/levels", response_model=list[LevelByLanguageResponse])
def list_levels_by_language(
    language_code: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        return content_service.list_levels_for_language(
            db,
            language_code=language_code,
            user_id=current_user.id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc


@router.get("/levels/{level_code}/lessons", response_model=list[LessonResponse])
def list_lessons_by_level(
    level_code: CEFRLevelEnum,
    language_code: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    resolved_language = language_code or current_user.target_language
    return content_service.list_lessons_by_level_code_and_language(
        db,
        level_code=level_code,
        language_code=resolved_language,
    )


@router.get("/levels/id/{level_id}/lessons", response_model=list[LessonResponse])
def list_lessons_by_level_id(
    level_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    return content_service.list_lessons_by_level_id(db, level_id)


@router.post("/lessons", response_model=LessonResponse, status_code=status.HTTP_201_CREATED)
def create_lesson(
    lesson_in: LessonCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_content_write_access),
):
    level = db.query(Level).filter(Level.id == lesson_in.level_id).first()
    if not level:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Niveau introuvable")

    return content_service.create_lesson(db, lesson_in)


@router.get("/lessons/{lesson_id}", response_model=LessonResponse)
def get_lesson(lesson_id: int, db: Session = Depends(get_db)):
    lesson = content_service.get_lesson(db, lesson_id)
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leçon introuvable")
    return lesson


@router.put("/lessons/{lesson_id}", response_model=LessonResponse)
def update_lesson(
    lesson_id: int,
    lesson_in: LessonUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_content_write_access),
):
    lesson = content_service.get_lesson(db, lesson_id)
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leçon introuvable")

    if lesson_in.level_id is not None:
        level = db.query(Level).filter(Level.id == lesson_in.level_id).first()
        if not level:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Niveau introuvable")

    return content_service.update_lesson(db, lesson, lesson_in)


@router.delete("/lessons/{lesson_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_lesson(
    lesson_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_content_write_access),
):
    lesson = content_service.get_lesson(db, lesson_id)
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leçon introuvable")

    content_service.delete_lesson(db, lesson)
    return None


@router.get("/lessons/{lesson_id}/vocabulary", response_model=list[VocabularyResponse])
def list_vocabulary_by_lesson(lesson_id: int, db: Session = Depends(get_db)):
    lesson = content_service.get_lesson(db, lesson_id)
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leçon introuvable")
    return content_service.list_vocabulary_by_lesson(db, lesson_id)


@router.post("/lessons/{lesson_id}/vocabulary", response_model=VocabularyResponse, status_code=status.HTTP_201_CREATED)
def create_vocabulary(
    lesson_id: int,
    vocabulary_in: VocabularyCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_content_write_access),
):
    lesson = content_service.get_lesson(db, lesson_id)
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leçon introuvable")

    return content_service.create_vocabulary(db, lesson_id=lesson_id, vocabulary_in=vocabulary_in)


@router.put("/vocabulary/{vocabulary_id}", response_model=VocabularyResponse)
def update_vocabulary(
    vocabulary_id: int,
    vocabulary_in: VocabularyUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_content_write_access),
):
    vocabulary = content_service.get_vocabulary(db, vocabulary_id)
    if not vocabulary:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vocabulaire introuvable")

    return content_service.update_vocabulary(db, vocabulary, vocabulary_in)


@router.delete("/vocabulary/{vocabulary_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_vocabulary(
    vocabulary_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_content_write_access),
):
    vocabulary = content_service.get_vocabulary(db, vocabulary_id)
    if not vocabulary:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vocabulaire introuvable")

    content_service.delete_vocabulary(db, vocabulary)
    return None
