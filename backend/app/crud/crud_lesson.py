# app/crud/crud_lesson.py
from sqlalchemy.orm import Session
from app.models.lesson import Lesson, Word

def create_lesson(db: Session, title: str, level: str, words: list[dict]):
    lesson = Lesson(title=title, level=level)
    for w in words:
        lesson.words.append(Word(**w))
    db.add(lesson)
    db.commit()
    db.refresh(lesson)
    return lesson

def get_lessons(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Lesson).offset(skip).limit(limit).all()

def get_lesson(db: Session, lesson_id: int):
    return db.query(Lesson).filter(Lesson.id == lesson_id).first()