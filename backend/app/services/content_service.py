from sqlalchemy.orm import Session

from app.models.content import CEFRLevelEnum, Level, Lesson, Vocabulary
from app.schemas.content import LessonCreate, LessonUpdate, VocabularyCreate, VocabularyUpdate
from app.services import tts_service


def list_levels(db: Session) -> list[Level]:
    return db.query(Level).order_by(Level.display_order.asc()).all()


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
