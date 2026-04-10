from datetime import datetime, timezone
import re
import unicodedata

from sqlalchemy.orm import Session

from app.models.quiz import Question, QuizAttempt, UserProgress
from app.schemas.quiz import QuizAnswerInput
from app.services import gamification_service, progress_service


def _normalize_answer(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    normalized = normalized.strip().lower()
    normalized = re.sub(r"\s+", " ", normalized)
    return normalized


def evaluate_answer(*, provided_answer: str, correct_answer: str) -> bool:
    return _normalize_answer(provided_answer) == _normalize_answer(correct_answer)


def list_questions_by_lesson(db: Session, lesson_id: int) -> list[Question]:
    return db.query(Question).filter(Question.lesson_id == lesson_id).order_by(Question.id.asc()).all()


def get_question(db: Session, question_id: int) -> Question | None:
    return db.query(Question).filter(Question.id == question_id).first()


def create_question(db: Session, question_in: dict) -> Question:
    question = Question(**question_in)
    db.add(question)
    db.commit()
    db.refresh(question)
    return question


def update_question(db: Session, question: Question, update_data: dict) -> Question:
    for field, value in update_data.items():
        setattr(question, field, value)
    db.commit()
    db.refresh(question)
    return question


def delete_question(db: Session, question: Question) -> None:
    db.delete(question)
    db.commit()


def _resolve_progress_row(db: Session, *, user_id: int, question: Question) -> UserProgress:
    progress_query = db.query(UserProgress).filter(UserProgress.user_id == user_id)

    if question.vocabulary_id is not None:
        progress_query = progress_query.filter(UserProgress.vocabulary_id == question.vocabulary_id)
    elif question.concept_id is not None:
        progress_query = progress_query.filter(UserProgress.concept_id == question.concept_id)
    else:
        progress_query = progress_query.filter(UserProgress.lesson_id == question.lesson_id)

    progress = progress_query.first()
    if progress:
        return progress

    return UserProgress(
        user_id=user_id,
        vocabulary_id=question.vocabulary_id,
        concept_id=question.concept_id,
        lesson_id=question.lesson_id,
        error_count=0,
        success_count=0,
        last_seen_at=datetime.now(timezone.utc),
    )


def process_quiz_submission(
    db: Session,
    *,
    user_id: int,
    answers: list[QuizAnswerInput],
    level_code: str | None,
    language_code: str | None = None,
    duration_seconds: int | None = None,
) -> tuple[QuizAttempt, list[dict]]:
    feedback: list[dict] = []
    correct_count = 0
    submitted_answers_payload: list[dict] = []
    touched_lesson_ids: set[int] = set()

    for answer_item in answers:
        question = get_question(db, answer_item.question_id)
        if not question:
            feedback.append(
                {
                    "question_id": answer_item.question_id,
                    "is_correct": False,
                    "correct_answer": "",
                    "explanation": "Question introuvable",
                }
            )
            submitted_answers_payload.append(
                {
                    "question_id": answer_item.question_id,
                    "answer": answer_item.answer,
                    "is_correct": False,
                }
            )
            continue

        is_correct = evaluate_answer(provided_answer=answer_item.answer, correct_answer=question.correct_answer)
        if is_correct:
            correct_count += 1

        feedback.append(
            {
                "question_id": question.id,
                "is_correct": is_correct,
                "correct_answer": question.correct_answer,
                "explanation": question.grammatical_explanation,
            }
        )
        touched_lesson_ids.add(question.lesson_id)
        submitted_answers_payload.append(
            {
                "question_id": question.id,
                "answer": answer_item.answer,
                "is_correct": is_correct,
            }
        )

        progress = _resolve_progress_row(db, user_id=user_id, question=question)
        progress.last_seen_at = datetime.now(timezone.utc)
        if is_correct:
            progress.success_count += 1
        else:
            progress.error_count += 1

        if progress.id is None:
            db.add(progress)

    total_questions = len(answers)
    score = int((correct_count / total_questions) * 100)

    attempt = QuizAttempt(
        user_id=user_id,
        language_code=language_code,
        score=score,
        total_questions=total_questions,
        correct_answers=correct_count,
        duration_seconds=duration_seconds,
        level_code=level_code,
        submitted_answers=submitted_answers_payload,
    )

    db.add(attempt)
    db.flush()
    progress_service.update_lesson_progress_from_quiz(
        db,
        user_id=user_id,
        lesson_ids=touched_lesson_ids,
        score=score,
    )
    if score >= 80:
        gamification_service.register_quiz_success_activity(db, user_id=user_id, attempt_id=attempt.id, score=score)
    else:
        gamification_service.update_streak_on_activity(db, user_id=user_id)
    db.commit()
    db.refresh(attempt)
    return attempt, feedback


def list_user_attempts(db: Session, user_id: int, limit: int = 20) -> list[QuizAttempt]:
    return (
        db.query(QuizAttempt)
        .filter(QuizAttempt.user_id == user_id)
        .order_by(QuizAttempt.attempted_at.desc())
        .limit(limit)
        .all()
    )
