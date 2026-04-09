import uuid
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, JSON, Boolean
from sqlalchemy.sql import func
from app.db.base import Base


class Lesson(Base):
    __tablename__ = "lessons"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, index=True)
    description = Column(String, nullable=True)
    cefr_level = Column(String, default="A1")
    is_published = Column(Boolean, default=False)
    order_index = Column(Integer, default=0)
    professor_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    content = Column(String, nullable=True)  # Markdown or HTML content
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Quiz(Base):
    __tablename__ = "quizzes"

    id = Column(String, primary_key=True, index=True)
    lesson_id = Column(String, ForeignKey("lessons.id"), index=True)
    title = Column(String, index=True)
    total_questions = Column(Integer, default=10)
    professor_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(String, primary_key=True, index=True)
    quiz_id = Column(String, ForeignKey("quizzes.id"), index=True)
    question_text = Column(String)
    type = Column(String, default="mcq")
    options = Column(JSON, nullable=True)
    correct_answer = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    quiz_id = Column(String, ForeignKey("quizzes.id"), index=True)
    score = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class LessonProgress(Base):
    __tablename__ = "lesson_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    lesson_id = Column(String, ForeignKey("lessons.id"), index=True)
    status = Column(String, default="started")  # started, completed
    last_accessed = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)


class VocabularyItem(Base):
    __tablename__ = "vocabulary_items"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    lesson_id = Column(String, ForeignKey("lessons.id"), index=True)
    term = Column(String, index=True)
    translation = Column(String, nullable=True)
    example = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
