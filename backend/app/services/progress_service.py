from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.content import Lesson, Level, Vocabulary
from app.models.progress import ProgressStatusEnum, UserLessonProgress, UserViewedVocab
from app.services import gamification_service


def _now() -> datetime:
    return datetime.now(timezone.utc)


def get_or_create_lesson_progress(db: Session, *, user_id: int, lesson_id: int) -> UserLessonProgress:
    progress = (
        db.query(UserLessonProgress)
        .filter(UserLessonProgress.user_id == user_id, UserLessonProgress.lesson_id == lesson_id)
        .first()
    )
    if progress:
        return progress

    progress = UserLessonProgress(
        user_id=user_id,
        lesson_id=lesson_id,
        status=ProgressStatusEnum.IN_PROGRESS,
        last_score=None,
        last_activity_at=_now(),
    )
    db.add(progress)
    db.flush()
    return progress


def mark_vocabulary_viewed(db: Session, *, user_id: int, vocabulary_id: int) -> UserViewedVocab:
    vocabulary = db.query(Vocabulary).filter(Vocabulary.id == vocabulary_id).first()
    if not vocabulary:
        raise ValueError("Vocabulaire introuvable")

    viewed = (
        db.query(UserViewedVocab)
        .filter(UserViewedVocab.user_id == user_id, UserViewedVocab.vocabulary_id == vocabulary_id)
        .first()
    )
    if viewed:
        viewed.viewed_at = _now()
    else:
        viewed = UserViewedVocab(user_id=user_id, vocabulary_id=vocabulary_id, viewed_at=_now())
        db.add(viewed)

    progress = get_or_create_lesson_progress(db, user_id=user_id, lesson_id=vocabulary.lesson_id)
    previous_status = progress.status
    progress.last_activity_at = _now()
    viewed_count = _count_viewed_vocab(db, user_id=user_id, lesson_id=vocabulary.lesson_id)
    total_count = _count_total_vocab(db, lesson_id=vocabulary.lesson_id)
    _update_lesson_status(progress, viewed_count=viewed_count, total_count=total_count)

    if previous_status != ProgressStatusEnum.COMPLETED and progress.status == ProgressStatusEnum.COMPLETED:
        gamification_service.register_completed_lesson_activity(db, user_id=user_id, lesson_id=vocabulary.lesson_id)
    else:
        gamification_service.update_streak_on_activity(db, user_id=user_id)

    db.commit()
    db.refresh(viewed)
    db.refresh(progress)
    return viewed


def _count_viewed_vocab(db: Session, *, user_id: int, lesson_id: int) -> int:
    return (
        db.query(UserViewedVocab)
        .join(Vocabulary, UserViewedVocab.vocabulary_id == Vocabulary.id)
        .filter(UserViewedVocab.user_id == user_id, Vocabulary.lesson_id == lesson_id)
        .count()
    )


def _count_total_vocab(db: Session, *, lesson_id: int) -> int:
    return db.query(Vocabulary).filter(Vocabulary.lesson_id == lesson_id).count()


def _update_lesson_status(progress: UserLessonProgress, *, viewed_count: int, total_count: int) -> None:
    vocab_completed = total_count > 0 and viewed_count >= total_count
    quiz_completed = progress.last_score is not None and progress.last_score >= 80
    progress.status = ProgressStatusEnum.COMPLETED if (vocab_completed or quiz_completed) else ProgressStatusEnum.IN_PROGRESS


def update_lesson_progress_from_quiz(
    db: Session,
    *,
    user_id: int,
    lesson_ids: set[int],
    score: int,
) -> None:
    for lesson_id in lesson_ids:
        progress = get_or_create_lesson_progress(db, user_id=user_id, lesson_id=lesson_id)
        previous_status = progress.status
        progress.last_score = score
        progress.last_activity_at = _now()
        viewed_count = _count_viewed_vocab(db, user_id=user_id, lesson_id=lesson_id)
        total_count = _count_total_vocab(db, lesson_id=lesson_id)
        _update_lesson_status(progress, viewed_count=viewed_count, total_count=total_count)

        if previous_status != ProgressStatusEnum.COMPLETED and progress.status == ProgressStatusEnum.COMPLETED:
            gamification_service.register_completed_lesson_activity(db, user_id=user_id, lesson_id=lesson_id)


def calculate_lesson_progress(db: Session, *, user_id: int, lesson_id: int) -> dict:
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
    if not lesson:
        raise ValueError("Leçon introuvable")

    progress = get_or_create_lesson_progress(db, user_id=user_id, lesson_id=lesson_id)
    viewed_count = _count_viewed_vocab(db, user_id=user_id, lesson_id=lesson_id)
    total_count = _count_total_vocab(db, lesson_id=lesson_id)
    vocab_percent = 0.0 if total_count == 0 else round((viewed_count / total_count) * 100, 2)
    quiz_percent = float(progress.last_score or 0)
    progress_percent = 100.0 if vocab_percent >= 100.0 or quiz_percent >= 80.0 else round(max(vocab_percent, quiz_percent), 2)
    quiz_completed = quiz_percent >= 80.0
    vocab_completed = total_count > 0 and viewed_count >= total_count
    status = ProgressStatusEnum.COMPLETED if (quiz_completed or vocab_completed) else ProgressStatusEnum.IN_PROGRESS

    if progress.status != status:
        progress.status = status
    db.commit()

    return {
        "id": progress.id,
        "user_id": user_id,
        "lesson_id": lesson_id,
        "status": progress.status,
        "last_score": progress.last_score,
        "last_activity_at": progress.last_activity_at,
        "progress_percent": progress_percent,
        "viewed_vocab_count": viewed_count,
        "total_vocab_count": total_count,
        "quiz_completed": quiz_completed,
        "vocab_completed": vocab_completed,
        "lesson_title": lesson.title,
        "lesson_description": lesson.description,
    }


def get_dashboard_overview(db: Session, *, user_id: int) -> dict:
    lessons = db.query(Lesson).order_by(Lesson.display_order.asc(), Lesson.id.asc()).all()
    levels = db.query(Level).order_by(Level.display_order.asc(), Level.id.asc()).all()
    lesson_payloads = []
    level_payloads = []
    completed_lessons = 0
    progress_by_level: dict[int, list[float]] = {level.id: [] for level in levels}
    completed_by_level: dict[int, int] = {level.id: 0 for level in levels}

    for lesson in lessons:
        payload = calculate_lesson_progress(db, user_id=user_id, lesson_id=lesson.id)
        lesson_payloads.append(payload)
        if payload["status"] == ProgressStatusEnum.COMPLETED:
            completed_lessons += 1
            completed_by_level[lesson.level_id] = completed_by_level.get(lesson.level_id, 0) + 1
        progress_by_level.setdefault(lesson.level_id, []).append(float(payload["progress_percent"]))

    total_lessons = len(lessons)
    overall_completion_percent = 0.0 if total_lessons == 0 else round((completed_lessons / total_lessons) * 100, 2)

    lessons_by_level = {level.id: 0 for level in levels}
    for lesson in lessons:
        lessons_by_level[lesson.level_id] = lessons_by_level.get(lesson.level_id, 0) + 1

    for level in levels:
        level_progress_values = progress_by_level.get(level.id, [])
        level_payloads.append(
            {
                "level_id": level.id,
                "level_name": level.code.value,
                "level_code": level.code.value,
                "progress_percent": 0.0 if not level_progress_values else round(sum(level_progress_values) / len(level_progress_values), 2),
                "completed_lessons": completed_by_level.get(level.id, 0),
                "total_lessons": lessons_by_level.get(level.id, 0),
            }
        )

    return {
        "user_id": user_id,
        "overall_completion_percent": overall_completion_percent,
        "completed_lessons": completed_lessons,
        "total_lessons": total_lessons,
        "lessons": lesson_payloads,
        "levels": level_payloads,
    }


def get_lesson_detail(db: Session, *, user_id: int, lesson_id: int) -> dict:
    return calculate_lesson_progress(db, user_id=user_id, lesson_id=lesson_id)
