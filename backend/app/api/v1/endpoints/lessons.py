from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from fastapi.security import OAuth2PasswordBearer

from app.crud import crud_lesson
from app.schemas.lesson import LessonCreate, LessonResponse
from app.db.session import get_db
from app.core.security import decode_access_token

router = APIRouter()

# OAuth2 pour récupérer le token
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


# -------- JWT USER DEPENDENCY --------
def get_current_user(token: str = Depends(oauth2_scheme)):

    payload = decode_access_token(token)

    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    user_id = payload.get("sub")
    role = payload.get("role")

    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )

    return {
        "id": user_id,
        "role": role
    }


# -------- CREATE LESSON (teacher only) --------
@router.post(
    "/",
    response_model=LessonResponse,
    status_code=status.HTTP_201_CREATED
)
def create_lesson_endpoint(
    lesson: LessonCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):

    if current_user["role"] != "teacher":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only teachers can create lessons"
        )

    return crud_lesson.create_lesson(
        db,
        lesson.title,
        lesson.level,
        [w.dict() for w in lesson.words]
    )


# -------- LIST LESSONS --------
@router.get(
    "/",
    response_model=List[LessonResponse]
)
def list_lessons(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):

    return crud_lesson.get_lessons(db)


# -------- GET SINGLE LESSON --------
@router.get(
    "/{lesson_id}",
    response_model=LessonResponse
)
def get_lesson(
    lesson_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):

    lesson = crud_lesson.get_lesson(db, lesson_id)

    if not lesson:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found"
        )

    return lesson