from sqlalchemy.orm import Session

from app.models.content import CEFRLevelEnum, Language, Level, Lesson, Vocabulary
from app.models.progress import ProgressStatusEnum, UserLessonProgress
from app.models.quiz import QuizAttempt
from app.schemas.content import LevelCreate, LessonCreate, LessonUpdate, VocabularyCreate, VocabularyUpdate
from app.services import tts_service


def list_levels(db: Session) -> list[Level]:
    return db.query(Level).order_by(Level.display_order.asc()).all()


def create_level(db: Session, level_in: LevelCreate) -> Level:
    level = Level(**level_in.model_dump())
    db.add(level)
    db.commit()
    db.refresh(level)
    return level


def list_supported_languages(db: Session) -> list[dict]:
    return [
        {
            "id": language.id,
            "name": language.name,
            "code": language.code,
        }
        for language in db.query(Language).order_by(Language.name.asc()).all()
    ]


def get_supported_language(db: Session, code: str) -> Language | None:
    normalized = code.strip().lower()
    return db.query(Language).filter(Language.code == normalized).first()


def list_levels_for_language(
    db: Session,
    *,
    language_code: str,
    user_id: int,
) -> list[dict]:
    language = get_supported_language(db, language_code)
    if language is None:
        raise ValueError("Langue cible non supportee")

    levels = (
        db.query(Level)
        .filter(Level.language_id == language.id)
        .order_by(Level.display_order.asc(), Level.id.asc())
        .all()
    )
    passed_codes = {
        (attempt.level_code or "").upper()
        for attempt in (
            db.query(QuizAttempt)
            .filter(
                QuizAttempt.user_id == user_id,
                QuizAttempt.score >= 80,
                QuizAttempt.level_code.isnot(None),
                QuizAttempt.language_code == language.code,
            )
            .all()
        )
        if attempt.level_code
    }

    payload = []
    previous_level_completed_and_passed = True

    for level in levels:
        lessons = (
            db.query(Lesson)
            .filter(Lesson.level_id == level.id)
            .order_by(Lesson.display_order.asc(), Lesson.id.asc())
            .all()
        )
        lesson_ids = [lesson.id for lesson in lessons]
        total_lessons = len(lesson_ids)

        completed_lessons = 0
        if lesson_ids:
            completed_lessons = (
                db.query(UserLessonProgress)
                .filter(
                    UserLessonProgress.user_id == user_id,
                    UserLessonProgress.lesson_id.in_(lesson_ids),
                    UserLessonProgress.status == ProgressStatusEnum.COMPLETED,
                )
                .count()
            )

        all_lessons_completed = total_lessons > 0 and completed_lessons == total_lessons
        code = level.code.value if isinstance(level.code, CEFRLevelEnum) else str(level.code)
        level_quiz_passed = code.upper() in passed_codes

        is_completed = all_lessons_completed and level_quiz_passed
        is_locked = not previous_level_completed_and_passed

        payload.append(
            {
                "id": level.id,
                "language_id": language.id,
                "name": code,
                "order_index": level.display_order,
                "is_completed": is_completed,
                "is_locked": is_locked,
            }
        )

        previous_level_completed_and_passed = is_completed

    return payload


def get_level_by_code(db: Session, level_code: CEFRLevelEnum) -> Level | None:
    return db.query(Level).filter(Level.code == level_code).first()


def list_lessons_by_level_code(db: Session, level_code: CEFRLevelEnum) -> list[Lesson]:
    return (
        db.query(Lesson)
        .join(Level, Lesson.level_id == Level.id)
        .filter(Level.code == level_code)
        .order_by(Lesson.display_order.asc(), Lesson.id.asc())
        .all()
    )


def list_lessons_by_level_code_and_language(
    db: Session,
    *,
    level_code: CEFRLevelEnum,
    language_code: str,
) -> list[Lesson]:
    normalized = language_code.strip().lower()
    return (
        db.query(Lesson)
        .join(Level, Lesson.level_id == Level.id)
        .join(Language, Level.language_id == Language.id)
        .filter(Level.code == level_code, Language.code == normalized)
        .order_by(Lesson.display_order.asc(), Lesson.id.asc())
        .all()
    )


def list_lessons_by_level_id(db: Session, level_id: int) -> list[Lesson]:
    return (
        db.query(Lesson)
        .filter(Lesson.level_id == level_id)
        .order_by(Lesson.display_order.asc(), Lesson.id.asc())
        .all()
    )


def get_lesson(db: Session, lesson_id: int) -> Lesson | None:
    return db.query(Lesson).filter(Lesson.id == lesson_id).first()


def create_lesson(db: Session, lesson_in: LessonCreate) -> Lesson:
    lesson = Lesson(**lesson_in.model_dump())
    db.add(lesson)
    db.commit()
    db.refresh(lesson)
    return lesson


def update_lesson(db: Session, lesson: Lesson, lesson_in: LessonUpdate) -> Lesson:
    update_data = lesson_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(lesson, field, value)

    db.commit()
    db.refresh(lesson)
    return lesson


def delete_lesson(db: Session, lesson: Lesson) -> None:
    db.delete(lesson)
    db.commit()


def list_vocabulary_by_lesson(db: Session, lesson_id: int) -> list[Vocabulary]:
    return (
        db.query(Vocabulary)
        .filter(Vocabulary.lesson_id == lesson_id)
        .order_by(Vocabulary.id.asc())
        .all()
    )


def get_vocabulary(db: Session, vocabulary_id: int) -> Vocabulary | None:
    return db.query(Vocabulary).filter(Vocabulary.id == vocabulary_id).first()


def create_vocabulary(db: Session, lesson_id: int, vocabulary_in: VocabularyCreate) -> Vocabulary:
    data = vocabulary_in.model_dump()
    if not data.get("audio_url"):
        data["audio_url"] = tts_service.generate_audio_url(term=data["term"])

    vocabulary = Vocabulary(lesson_id=lesson_id, **data)
    db.add(vocabulary)
    db.commit()
    db.refresh(vocabulary)
    return vocabulary


def update_vocabulary(db: Session, vocabulary: Vocabulary, vocabulary_in: VocabularyUpdate) -> Vocabulary:
    update_data = vocabulary_in.model_dump(exclude_unset=True)

    # If term changes and no explicit audio URL is provided, refresh TTS pointer.
    if "term" in update_data and "audio_url" not in update_data:
        update_data["audio_url"] = tts_service.generate_audio_url(term=update_data["term"])

    for field, value in update_data.items():
        setattr(vocabulary, field, value)

    db.commit()
    db.refresh(vocabulary)
    return vocabulary


def delete_vocabulary(db: Session, vocabulary: Vocabulary) -> None:
    db.delete(vocabulary)
    db.commit()
