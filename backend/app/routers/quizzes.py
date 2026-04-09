from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.core.security import get_current_user, require_professor
from app.models.quiz import Lesson, Quiz, QuizQuestion
from pydantic import BaseModel

router = APIRouter()

class QuizCreate(BaseModel):
    lesson_id: str
    title: str
    total_questions: int = 10

class QuestionCreate(BaseModel):
    quiz_id: str
    question_text: str
    type: str = "mcq"
    options: List[str] | None = None
    correct_answer: str

# ==================== QUIZ CRUD ====================

@router.post("/lessons/{lesson_id}/quizzes", status_code=201)
async def create_quiz(
    lesson_id: str,
    quiz: QuizCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    # Verify lesson
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.professor_id == current_user.id).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found or access denied")
    
    db_quiz = Quiz(
        lesson_id=lesson_id,
        title=quiz.title,
        professor_id=current_user.id
    )
    db.add(db_quiz)
    db.commit()
    db.refresh(db_quiz)
    return db_quiz

@router.get("/lessons/{lesson_id}/quizzes")
async def get_lesson_quizzes(lesson_id: str, db: Session = Depends(get_db)):
    return db.query(Quiz).filter(Quiz.lesson_id == lesson_id).all()

# GET /quizzes/{id}, PUT, DELETE similar async

# ==================== QUESTION CRUD ====================

@router.post("/quizzes/{quiz_id}/questions", status_code=201)
async def create_question(
    quiz_id: str,
    question: QuestionCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    # Vérifier que le quiz appartient bien au professeur
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id, Quiz.professor_id == current_user.id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found or access denied")
    
    db_question = QuizQuestion(
        quiz_id=quiz_id,
        question_text=question.question_text,
        type=question.type,
        options=question.options,
        correct_answer=question.correct_answer
    )
    db.add(db_question)
    db.commit()
    db.refresh(db_question)
    return db_question
