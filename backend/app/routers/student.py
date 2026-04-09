from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.core.security import get_current_user, require_student
from app.models.quiz import Lesson, Quiz, QuizQuestion, QuizAttempt, LessonProgress, VocabularyItem
from datetime import datetime, timezone
from pydantic import BaseModel

router = APIRouter()

class QuizSubmission(BaseModel):
    quiz_id: str
    answers: List[dict]
    time_taken_seconds: int

class ProgressSummary(BaseModel):
    total_lessons: int
    completed_lessons: int
    average_quiz_score: float
    current_level: str

class JoinClassRequest(BaseModel):
    code: str

# ==================== CLASS MANAGEMENT ====================

@router.post("/join-class")
async def join_class(
    req: JoinClassRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_student)
):
    from app.models.user import User as UserModel, ProfessorStudentLink
    professor = db.query(UserModel).filter(UserModel.professor_code == req.code, UserModel.role == "professor").first()
    if not professor:
        raise HTTPException(status_code=404, detail="Invalid class code")
    
    existing = db.query(ProfessorStudentLink).filter(
        ProfessorStudentLink.professor_id == professor.id,
        ProfessorStudentLink.student_id == current_user.id
    ).first()
    
    if existing:
        return {"message": "You are already in this class"}
        
    link = ProfessorStudentLink(professor_id=professor.id, student_id=current_user.id)
    db.add(link)
    db.commit()
    return {"message": f"Successfully joined {professor.full_name}'s class"}

# ==================== LESSONS ACCESS ====================

@router.get("/lessons")
async def get_published_lessons(
    cefr_level: str | None = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_student)
):
    from app.models.user import ProfessorStudentLink
 
    prof_links = db.query(ProfessorStudentLink.professor_id).filter(ProfessorStudentLink.student_id == current_user.id).all()
    prof_ids = [link[0] for link in prof_links]

    
    if not prof_ids:
        return []


    query = db.query(Lesson).filter(Lesson.is_published == True, Lesson.professor_id.in_(prof_ids))
    if cefr_level:
        query = query.filter(Lesson.cefr_level == cefr_level)
    return query.order_by(Lesson.cefr_level, Lesson.order_index).offset(skip).limit(limit).all()

@router.get("/lessons/{lesson_id}")
async def get_lesson_detail(
    lesson_id: str, 
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_student)
):
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.is_published == True).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")
        
    vocabulary = db.query(VocabularyItem).filter(VocabularyItem.lesson_id == lesson_id).all()

    # LOG PROGRESS (START)
    if current_user:
        existing = db.query(LessonProgress).filter(
            LessonProgress.user_id == current_user.id,
            LessonProgress.lesson_id == lesson_id
        ).first()
        if not existing:
            new_progress = LessonProgress(user_id=current_user.id, lesson_id=lesson_id, status="started")
            db.add(new_progress)
            db.commit()
    
    return {
        "lesson": lesson,
        "vocabulary": vocabulary
    }


@router.get("/lessons/{lesson_id}/vocabulary")
async def get_lesson_vocabulary(
    lesson_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_student)
):
    """Retourne toutes les fiches de vocabulaire d'une leçon (term, translation, example, image_url)."""
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.is_published == True).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")

    vocabulary = db.query(VocabularyItem).filter(VocabularyItem.lesson_id == lesson_id).all()
    return [
        {
            "id": item.id,
            "term": item.term,
            "translation": item.translation,
            "example": item.example,
            "image_url": item.image_url,
        }
        for item in vocabulary
    ]


@router.post("/lessons/{lesson_id}/complete")
async def mark_lesson_complete(lesson_id: str, db: Session = Depends(get_db), current_user: dict = Depends(require_student)):
    progress = db.query(LessonProgress).filter(
        LessonProgress.user_id == current_user.id,
        LessonProgress.lesson_id == lesson_id
    ).first()
    if not progress:
        progress = LessonProgress(user_id=current_user.id, lesson_id=lesson_id, status="completed", completed_at=datetime.now(timezone.utc))
        db.add(progress)
    else:
        progress.status = "completed"
        progress.completed_at = datetime.now(timezone.utc)
    db.commit()
    return {"message": "Lesson marked as complete"}

# ==================== QUIZ TAKING ====================

@router.get("/lessons/{lesson_id}/quizzes")
async def get_lesson_quizzes(lesson_id: str, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    # Vérifier que la leçon est publiée avant de lister ses quiz
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.is_published == True).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found or not published")
    return db.query(Quiz).filter(Quiz.lesson_id == lesson_id).all()

@router.get("/quizzes/{quiz_id}/start")
async def start_quiz(quiz_id: str, db: Session = Depends(get_db)):
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    
    questions = db.query(QuizQuestion).filter(QuizQuestion.quiz_id == quiz_id).all()
    
    # On ne renvoie pas la bonne réponse (correct_answer) à l'étudiant au début
    return {
        "quiz_title": quiz.title,
        "questions": [
            {
                "id": q.id,
                "question_text": q.question_text,
                "type": q.type,
                "options": q.options
            } for q in questions
        ]
    }

@router.post("/quizzes/submit")
async def submit_quiz(submission: QuizSubmission, db: Session = Depends(get_db), current_user: dict = Depends(require_student)):
    questions = db.query(QuizQuestion).filter(QuizQuestion.quiz_id == submission.quiz_id).all()
    if not questions:
        raise HTTPException(status_code=404, detail="Quiz not found")

    # Calcul dynamique du score
    correct_answers = 0
    details = []
    
    for q in questions:
        user_ans = ""
        for submission_ans in submission.answers:
            if str(submission_ans.get("question_id")) == str(q.id):
                user_ans = submission_ans.get("answer", "")
                break
        
        is_correct = (user_ans == q.correct_answer)
        if is_correct:
            correct_answers += 1
            
        details.append({
            "question_text": q.question_text,
            "user_answer": user_ans,
            "correct_answer": q.correct_answer,
            "is_correct": is_correct
        })
            
    score = (correct_answers / len(questions)) * 100 if questions else 0
    
    # Sauvegarde de la tentative dans la base de données
    db_attempt = QuizAttempt(
        user_id=current_user.id,
        quiz_id=submission.quiz_id,
        score=int(score)
    )
    db.add(db_attempt)
    db.commit()
    
    return {
        "score": score,
        "correct_count": correct_answers,
        "total": len(questions),
        "details": details,
        "message": "Soumission enregistrée avec succès"
    }

# ==================== PROGRESS ====================

@router.get("/progress")
async def get_overall_progress(db: Session = Depends(get_db), current_user: dict = Depends(require_student)):
    # Calcul dynamique basé sur les données réelles
    total_lessons = db.query(Lesson).filter(Lesson.is_published == True).count()
    completed_count = db.query(LessonProgress).filter(
        LessonProgress.user_id == current_user.id,
        LessonProgress.status == "completed"
    ).count()
    
    attempts = db.query(QuizAttempt).filter(QuizAttempt.user_id == current_user.id).all()
    avg_score = sum([a.score for a in attempts]) / len(attempts) if attempts else 0.0
    
    current_level = "A1 Beginner"
    if avg_score >= 70:
        current_level = "B1 Intermediate"
    elif avg_score >= 40:
        current_level = "A2 Elementary"
        
    return {
        "total_lessons": total_lessons,
        "completed_lessons": completed_count,
        "average_quiz_score": round(avg_score, 2),
        "current_level": current_level
    }

@router.get("/progress/lessons/{lesson_id}")
async def get_lesson_progress(lesson_id: str, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    progress = db.query(LessonProgress).filter(
        LessonProgress.user_id == current_user.id,
        LessonProgress.lesson_id == lesson_id
    ).first()
    
    if not progress:
        return {"status": "not_started", "completed_at": None}
        
    return {
        "status": progress.status,
        "completed_at": progress.completed_at
    }

@router.get("/progress/quiz-history")
async def get_quiz_history(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_student)
):
    """Récupère l'historique complet des quiz pour l'étudiant connecté."""
    history = db.query(
        QuizAttempt.id,
        QuizAttempt.score,
        QuizAttempt.created_at,
        Quiz.title.label("quiz_title")
    ).join(Quiz, QuizAttempt.quiz_id == Quiz.id)\
     .filter(QuizAttempt.user_id == current_user.id)\
     .order_by(QuizAttempt.created_at.desc())\
     .offset(skip).limit(limit).all()
    
    return [
        {
            "id": h.id,
            "score": h.score,
            "date": h.created_at,
            "quiz_title": h.quiz_title
        } for h in history
    ]
