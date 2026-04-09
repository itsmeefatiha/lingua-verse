from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.database import get_db
from app.core.security import require_professor
from pydantic import BaseModel
import uuid
from app.models.quiz import Lesson, Quiz, QuizQuestion, QuizAttempt, LessonProgress, VocabularyItem
from app.models.user import ProfessorStudentLink

router = APIRouter()

class LessonCreate(BaseModel):
    title: str
    description: str | None = None
    content: str | None = None
    cefr_level: str = "A1"

class LessonUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    content: str | None = None
    cefr_level: str | None = None
    is_published: bool | None = None

class QuestionCreate(BaseModel):
    question_text: str
    type: str = "mcq"
    options: list[str] | None = None
    correct_answer: str
    points: int = 10

class QuizCreate(BaseModel):
    title: str
    passing_score: int = 70
    is_adaptive: bool = False
    questions: list[QuestionCreate] = []

class VocabularyCreate(BaseModel):
    term: str
    translation: str
    example: str | None = None
    image_url: str | None = None

# ==================== LESSON MANAGEMENT ====================

@router.get("/dashboard")
async def get_professor_summary(
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Récupère dynamiquement les statistiques pour l'espace professeur."""
    lesson_count = db.query(Lesson).filter(Lesson.professor_id == current_user.id).count()
    # On récupère aussi le nombre de quiz total créés par ce prof
    quiz_count = db.query(Quiz).filter(Quiz.professor_id == current_user.id).count()
    
    return {
        "professor_name": current_user.full_name,
        "professor_code": current_user.professor_code,
        "total_lessons": lesson_count,
        "total_quizzes": quiz_count,
        "recent_lessons": db.query(Lesson).filter(Lesson.professor_id == current_user.id).order_by(Lesson.id.desc()).limit(3).all()
    }

@router.post("/lessons", status_code=201)
async def create_lesson(
    lesson: LessonCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    # Création dynamique dans la base de données
    db_lesson = Lesson(
        title=lesson.title,
        description=lesson.description,
        content=lesson.content,
        cefr_level=lesson.cefr_level,
        is_published=True,  # Automatically publish lessons upon creation
        professor_id=current_user.id  # Liaison avec le prof connecté
    )
    db.add(db_lesson)
    db.commit()
    db.refresh(db_lesson)
    return db_lesson

@router.get("/lessons")
async def get_professor_lessons(
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    # Récupération dynamique des leçons du prof
    lessons = db.query(Lesson).filter(Lesson.professor_id == current_user.id).all()
    return lessons

@router.put("/lessons/{lesson_id}")
async def update_lesson(
    lesson_id: str,
    lesson_update: LessonUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Mettre à jour une leçon (uniquement si elle appartient au prof)."""
    db_lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.professor_id == current_user.id).first()
    if not db_lesson:
        raise HTTPException(status_code=404, detail="Lesson not found or access denied")
    
    update_data = lesson_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_lesson, key, value)
    
    db.commit()
    db.refresh(db_lesson)
    return db_lesson

@router.delete("/lessons/{lesson_id}")
async def delete_lesson(
    lesson_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Supprimer une leçon (uniquement si elle appartient au prof)."""
    db_lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.professor_id == current_user.id).first()
    if not db_lesson:
        raise HTTPException(status_code=404, detail="Lesson not found or access denied")
    
    db.delete(db_lesson)
    db.commit()
    return {"message": "Lesson deleted successfully"}

@router.post("/lessons/{lesson_id}/vocabulary", status_code=201)
async def add_vocabulary(
    lesson_id: str,
    vocab: VocabularyCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Ajouter une fiche de vocabulaire à une leçon."""
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.professor_id == current_user.id).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")

    db_vocab = VocabularyItem(
        lesson_id=lesson_id,
        **vocab.dict()
    )
    db.add(db_vocab)
    db.commit()
    db.refresh(db_vocab)
    return db_vocab


@router.get("/lessons/{lesson_id}/vocabulary")
async def get_lesson_vocabulary(
    lesson_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Lister toutes les fiches de vocabulaire d'une leçon."""
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.professor_id == current_user.id).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found or access denied")
    return db.query(VocabularyItem).filter(VocabularyItem.lesson_id == lesson_id).all()


@router.put("/lessons/{lesson_id}/vocabulary/{vocab_id}")
async def update_vocabulary(
    lesson_id: str,
    vocab_id: str,
    vocab: VocabularyCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Modifier une fiche de vocabulaire (uniquement si la leçon appartient au prof)."""
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.professor_id == current_user.id).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found or access denied")

    db_vocab = db.query(VocabularyItem).filter(
        VocabularyItem.id == vocab_id,
        VocabularyItem.lesson_id == lesson_id
    ).first()
    if not db_vocab:
        raise HTTPException(status_code=404, detail="Vocabulary item not found")

    for key, value in vocab.dict().items():
        setattr(db_vocab, key, value)

    db.commit()
    db.refresh(db_vocab)
    return db_vocab


@router.delete("/lessons/{lesson_id}/vocabulary/{vocab_id}")
async def delete_vocabulary(
    lesson_id: str,
    vocab_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Supprimer une fiche de vocabulaire."""
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.professor_id == current_user.id).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found or access denied")

    db_vocab = db.query(VocabularyItem).filter(
        VocabularyItem.id == vocab_id,
        VocabularyItem.lesson_id == lesson_id
    ).first()
    if not db_vocab:
        raise HTTPException(status_code=404, detail="Vocabulary item not found")

    db.delete(db_vocab)
    db.commit()
    return {"message": "Vocabulary item deleted successfully"}

# ==================== QUIZ MANAGEMENT ====================

@router.post("/lessons/{lesson_id}/quizzes", status_code=201)
async def create_quiz(
    lesson_id: str,
    quiz: QuizCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    # Vérifier que la leçon existe et appartient au professeur
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.professor_id == current_user.id).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found or access denied")

    db_quiz = Quiz(
        id=str(uuid.uuid4()),
        title=quiz.title,
        lesson_id=lesson_id,
        professor_id=current_user.id,
        total_questions=len(quiz.questions)
    )
    db.add(db_quiz)
    
    # Add questions
    for q in quiz.questions:
        db_question = QuizQuestion(
            id=str(uuid.uuid4()),
            quiz_id=db_quiz.id,
            question_text=q.question_text,
            type=q.type,
            options=q.options,
            correct_answer=q.correct_answer
        )
        db.add(db_question)
        
    db.commit()
    db.refresh(db_quiz)
    return db_quiz

@router.get("/lessons/{lesson_id}/quizzes")
async def get_lesson_quizzes(
    lesson_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    # Vérifier que la leçon appartient bien au professeur avant de lister les quiz
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id, Lesson.professor_id == current_user.id).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found or access denied")
        
    return db.query(Quiz).filter(Quiz.lesson_id == lesson_id).all()

@router.get("/quizzes")
async def get_professor_quizzes(
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """List all quizzes created by this professor."""
    return db.query(Quiz).filter(Quiz.professor_id == current_user.id).all()

@router.put("/quizzes/{quiz_id}")
async def update_quiz(
    quiz_id: str,
    quiz_update: QuizCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Mettre à jour un quiz (uniquement si il appartient au prof)."""
    db_quiz = db.query(Quiz).filter(Quiz.id == quiz_id, Quiz.professor_id == current_user.id).first()
    if not db_quiz:
        raise HTTPException(status_code=404, detail="Quiz not found or access denied")
    
    db_quiz.title = quiz_update.title
    db_quiz.total_questions = len(quiz_update.questions)
    
    # Simple strategy: delete old questions and add new ones
    db.query(QuizQuestion).filter(QuizQuestion.quiz_id == quiz_id).delete()
    
    for q in quiz_update.questions:
        db_question = QuizQuestion(
            id=str(uuid.uuid4()),
            quiz_id=db_quiz.id,
            question_text=q.question_text,
            type=q.type,
            options=q.options,
            correct_answer=q.correct_answer
        )
        db.add(db_question)
        
    db.commit()
    db.refresh(db_quiz)
    return db_quiz

@router.delete("/quizzes/{quiz_id}")
async def delete_quiz(
    quiz_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Supprimer un quiz (uniquement si il appartient au prof)."""
    db_quiz = db.query(Quiz).filter(Quiz.id == quiz_id, Quiz.professor_id == current_user.id).first()
    if not db_quiz:
        raise HTTPException(status_code=404, detail="Quiz not found or access denied")
    
    # Questions will be deleted via cascade if configured, but let's be explicit if not
    db.query(QuizQuestion).filter(QuizQuestion.quiz_id == quiz_id).delete()
    db.delete(db_quiz)
    db.commit()
    return {"message": "Quiz deleted successfully"}

@router.get("/analytics/summary")
async def get_analytics_summary(
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Statistiques globales pour le professeur."""
    # Nombre total de tentatives de quiz pour les leçons de ce prof
    total_attempts = db.query(QuizAttempt).join(Quiz).filter(Quiz.professor_id == current_user.id).count()
    
    # Score moyen global
    avg_score = db.query(func.avg(QuizAttempt.score)).join(Quiz).filter(Quiz.professor_id == current_user.id).scalar() or 0.0
    
    # Quiz le plus populaire (plus grand nombre de tentatives)
    popular_quiz = db.query(Quiz.title, func.count(QuizAttempt.id).label('attempts'))\
        .join(QuizAttempt)\
        .filter(Quiz.professor_id == current_user.id)\
        .group_by(Quiz.id)\
        .order_by(func.count(QuizAttempt.id).desc())\
        .first()

    return {
        "total_attempts": total_attempts,
        "average_score": round(float(avg_score), 2),
        "popular_quiz": popular_quiz[0] if popular_quiz else "N/A",
        "popular_quiz_attempts": popular_quiz[1] if popular_quiz else 0
    }

@router.get("/quizzes/{quiz_id}/attempts")
async def get_quiz_attempts(
    quiz_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Liste détaillée des tentatives pour un quiz spécifique."""
    # Vérifier d'abord que le quiz appartient au prof
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id, Quiz.professor_id == current_user.id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found or access denied")
        
    attempts = db.query(QuizAttempt).filter(QuizAttempt.quiz_id == quiz_id).order_by(QuizAttempt.created_at.desc()).all()
    return attempts

@router.get("/students/discover")
async def discover_students(
    query: str = "",
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Rechercher tous les étudiants du système pour les assigner."""
    from app.models.user import User as UserModel
    students = db.query(UserModel).filter(
        UserModel.role == "student",
        (UserModel.full_name.ilike(f"%{query}%")) | (UserModel.username.ilike(f"%{query}%"))
    ).limit(20).all()
    
    # Vérifier l'état d'assignation
    assigned_ids = db.query(ProfessorStudentLink.student_id).filter(ProfessorStudentLink.professor_id == current_user.id).all()
    assigned_ids = [a[0] for a in assigned_ids]
    
    return [
        {
            "id": s.id,
            "username": s.username,
            "full_name": s.full_name,
            "is_assigned": s.id in assigned_ids
        } for s in students
    ]

@router.post("/students/{student_id}/assign")
async def assign_student(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Assigner formellement un étudiant à ce professeur."""
    existing = db.query(ProfessorStudentLink).filter(
        ProfessorStudentLink.professor_id == current_user.id,
        ProfessorStudentLink.student_id == student_id
    ).first()
    if existing:
        return {"message": "Already assigned"}
        
    link = ProfessorStudentLink(professor_id=current_user.id, student_id=student_id)
    db.add(link)
    db.commit()
    return {"message": "Assigned successfully"}

@router.delete("/students/{student_id}/unassign")
async def unassign_student(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Désassigner un étudiant."""
    db.query(ProfessorStudentLink).filter(
        ProfessorStudentLink.professor_id == current_user.id,
        ProfessorStudentLink.student_id == student_id
    ).delete()
    db.commit()
    return {"message": "Unassigned successfully"}

@router.get("/students")
async def get_professor_students(
    mode: str = "my", # "my" for assigned, "active" for those who took quizzes
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Liste les étudiants selon le mode choisi."""
    from app.models.user import User as UserModel
    
    if mode == "my":
        student_ids = db.query(ProfessorStudentLink.student_id).filter(ProfessorStudentLink.professor_id == current_user.id).all()
        student_ids = [a[0] for a in student_ids]
    else:
        # Mode par défaut: ceux ayant fait un quiz
        student_ids = db.query(QuizAttempt.user_id).join(Quiz).filter(Quiz.professor_id == current_user.id).distinct().all()
        student_ids = [s[0] for s in student_ids]
    
    students = db.query(UserModel).filter(UserModel.id.in_(student_ids)).all()
    
    result = []
    for s in students:
        attempts = db.query(QuizAttempt).join(Quiz).filter(QuizAttempt.user_id == s.id, Quiz.professor_id == current_user.id).all()
        avg_score = sum([a.score for a in attempts]) / len(attempts) if attempts else 0.0
        
        # New: Lesson progress
        lessons_started = db.query(LessonProgress).filter(LessonProgress.user_id == s.id).count()
        lessons_completed = db.query(LessonProgress).filter(LessonProgress.user_id == s.id, LessonProgress.status == "completed").count()
        
        result.append({
            "id": s.id,
            "username": s.username,
            "full_name": s.full_name,
            "email": s.email,
            "average_score": round(avg_score, 2),
            "total_attempts": len(attempts),
            "lessons_completed": lessons_completed,
            "lessons_started": lessons_started,
            "is_assigned": True if mode == "my" else (s.id in [a[0] for a in db.query(ProfessorStudentLink.student_id).filter(ProfessorStudentLink.professor_id == current_user.id).all()])
        })
    return result

@router.get("/students/{student_id}")
async def get_student_detail_for_professor(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_professor)
):
    """Détails complets incluant la progression des leçons."""
    from app.models.user import User as UserModel
    
    # SECURITY CHECK: Is this student assigned to this professor OR has taken a quiz from this professor?
    is_assigned = db.query(ProfessorStudentLink).filter(
        ProfessorStudentLink.professor_id == current_user.id,
        ProfessorStudentLink.student_id == student_id
    ).first() is not None
    
    has_taken_quiz = db.query(QuizAttempt).join(Quiz).filter(
        QuizAttempt.user_id == student_id,
        Quiz.professor_id == current_user.id
    ).first() is not None
    
    if not (is_assigned or has_taken_quiz):
        raise HTTPException(status_code=403, detail="Access denied: Student not in your scope")

    student = db.query(UserModel).filter(UserModel.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    attempts = db.query(
        QuizAttempt.id,
        QuizAttempt.score,
        QuizAttempt.created_at,
        Quiz.title.label("quiz_title")
    ).join(Quiz, QuizAttempt.quiz_id == Quiz.id)\
     .filter(QuizAttempt.user_id == student_id, Quiz.professor_id == current_user.id)\
     .order_by(QuizAttempt.created_at.desc()).all()
     
    # New: Lesson progress details
    lessons_progress = db.query(
        LessonProgress.status,
        LessonProgress.last_accessed,
        Lesson.title.label("lesson_title")
    ).join(Lesson, LessonProgress.lesson_id == Lesson.id)\
     .filter(LessonProgress.user_id == student_id)\
     .all()
     
    return {
        "student": {
            "id": student.id,
            "full_name": student.full_name,
            "username": student.username,
            "email": student.email,
            "created_at": student.created_at,
            "role": student.role
        },
        "quiz_history": [
            {
                "id": a.id,
                "score": a.score,
                "date": a.created_at,
                "quiz_title": a.quiz_title
            } for a in attempts
        ],
        "lesson_progress": [
            {
                "title": l.lesson_title,
                "status": l.status,
                "last_active": l.last_accessed
            } for l in lessons_progress
        ]
    }

# Full professor endpoints integrated with models/services
