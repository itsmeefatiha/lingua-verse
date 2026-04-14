from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, require_role
from app.db.database import get_db
from app.models.content import Lesson, Vocabulary
from app.models.quiz import Question
from app.models.user import RoleEnum, User
from app.schemas.quiz import (
    QuizAttemptResponse,
    QuizGenerateRequest,
    QuizSubmitRequest,
    QuizSubmitResponse,
    QuestionCreate,
    QuestionPublicResponse,
    QuestionResponse,
    QuestionUpdate,
    STTValidationRequest,
    STTValidationResponse,
)
from app.services import quiz_generator, quiz_service, stt_service

router = APIRouter()


@router.post("/questions", response_model=QuestionResponse, status_code=status.HTTP_201_CREATED)
def create_question(
    question_in: QuestionCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(RoleEnum.TEACHER)),
):
    lesson = db.query(Lesson).filter(Lesson.id == question_in.lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leçon introuvable")
    return quiz_service.create_question(db, question_in.model_dump())


@router.get("/questions/{question_id}", response_model=QuestionResponse)
def get_question(
    question_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    question = quiz_service.get_question(db, question_id)
    if not question:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Question introuvable")
    return question


@router.get("/lessons/{lesson_id}/questions", response_model=list[QuestionResponse])
def list_questions_by_lesson(
    lesson_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leçon introuvable")
    return quiz_service.list_questions_by_lesson(db, lesson_id)


@router.put("/questions/{question_id}", response_model=QuestionResponse)
def update_question(
    question_id: int,
    question_in: QuestionUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(RoleEnum.TEACHER)),
):
    question = quiz_service.get_question(db, question_id)
    if not question:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Question introuvable")

    update_data = question_in.model_dump(exclude_unset=True)
    if "lesson_id" in update_data:
        lesson = db.query(Lesson).filter(Lesson.id == update_data["lesson_id"]).first()
        if not lesson:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leçon introuvable")

    return quiz_service.update_question(db, question, update_data)


@router.delete("/questions/{question_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_question(
    question_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(RoleEnum.TEACHER)),
):
    question = quiz_service.get_question(db, question_id)
    if not question:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Question introuvable")
    quiz_service.delete_question(db, question)
    return None


@router.post("/generate", response_model=list[QuestionPublicResponse])
def generate_quiz(
    request: QuizGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        if request.level_code is not None:
            questions = quiz_generator.generate_level_quiz_questions(
                db,
                level_code=request.level_code,
                language_code=(request.language_code or current_user.target_language).strip().lower(),
                question_count=request.question_count,
            )
        else:
            questions = quiz_generator.generate_adaptive_quiz(
                db,
                user_id=current_user.id,
                question_count=request.question_count,
                level_code=request.level_code,
            )

        vocabulary_ids = {q.vocabulary_id for q in questions if q.vocabulary_id is not None}
        vocab_terms: dict[int, str] = {}
        if vocabulary_ids:
            vocab_rows = (
                db.query(Vocabulary.id, Vocabulary.term)
                .filter(Vocabulary.id.in_(vocabulary_ids))
                .all()
            )
            vocab_terms = {v_id: term for v_id, term in vocab_rows}

        response_items: list[QuestionPublicResponse] = []
        for question in questions:
            text = question.text
            if (
                question.question_type.value == "qcm"
                and question.vocabulary_id is not None
                and "highlighted word" in text.lower()
            ):
                term = vocab_terms.get(question.vocabulary_id)
                if term:
                    text = f'Choose the correct translation for "{term}".'

            response_items.append(
                QuestionPublicResponse(
                    id=question.id,
                    text=text,
                    question_type=question.question_type,
                    correct_answer=question.correct_answer,
                    choices=question.choices,
                    grammatical_explanation=question.grammatical_explanation,
                    lesson_id=question.lesson_id,
                    vocabulary_id=question.vocabulary_id,
                    concept_id=question.concept_id,
                )
            )

        return response_items
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc


@router.post("/attempts/submit", response_model=QuizSubmitResponse)
def submit_quiz_attempt(
    request: QuizSubmitRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    attempt, feedback = quiz_service.process_quiz_submission(
        db,
        user_id=current_user.id,
        answers=request.answers,
        level_code=request.level_code.value if request.level_code else None,
        language_code=request.language_code or current_user.target_language,
        duration_seconds=request.duration_seconds,
    )
    return {
        "score": attempt.score,
        "total_questions": attempt.total_questions,
        "correct_answers": attempt.correct_answers,
        "feedback": feedback,
    }


@router.get("/attempts/me", response_model=list[QuizAttemptResponse])
def list_my_quiz_attempts(
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    clamped_limit = min(max(limit, 1), 100)
    return quiz_service.list_user_attempts(db, user_id=current_user.id, limit=clamped_limit)


@router.post("/questions/{question_id}/stt-validate", response_model=STTValidationResponse)
def validate_voice_answer(
    question_id: int,
    request: STTValidationRequest,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    question = quiz_service.get_question(db, question_id)
    if not question:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Question introuvable")

    try:
        transcribed_text = stt_service.transcribe_audio(
            audio_base64=request.audio_base64,
            transcript=request.transcript,
            language=request.language or "en-US",
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    is_correct = quiz_service.evaluate_answer(
        provided_answer=transcribed_text,
        correct_answer=question.correct_answer,
    )

    return {
        "transcribed_text": transcribed_text,
        "is_correct": is_correct,
        "correct_answer": question.correct_answer,
        "explanation": question.grammatical_explanation,
    }
