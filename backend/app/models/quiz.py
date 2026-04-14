from datetime import datetime, timezone
import enum

from sqlalchemy import Column, DateTime, Enum, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import relationship

from app.db.base import Base


class QuestionTypeEnum(str, enum.Enum):
    QCM = "qcm"
    GAP_TEXT = "gap_text"
    ORDERING = "ordering"
    VOICE = "voice"


class Question(Base):
    __tablename__ = "questions"

    id = Column(Integer, primary_key=True, index=True)
    text = Column(Text, nullable=False)
    question_type = Column(Enum(QuestionTypeEnum), nullable=False)
    correct_answer = Column(Text, nullable=False)
    choices = Column(JSON, nullable=True)
    grammatical_explanation = Column(Text, nullable=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)
    vocabulary_id = Column(Integer, ForeignKey("vocabularies.id", ondelete="SET NULL"), nullable=True, index=True)
    concept_id = Column(String, nullable=True, index=True)

    lesson = relationship("Lesson")
    vocabulary = relationship("Vocabulary")


class UserProgress(Base):
    __tablename__ = "user_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    vocabulary_id = Column(Integer, ForeignKey("vocabularies.id", ondelete="CASCADE"), nullable=True, index=True)
    concept_id = Column(String, nullable=True, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=True, index=True)
    error_count = Column(Integer, nullable=False, default=0)
    success_count = Column(Integer, nullable=False, default=0)
    last_seen_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User")
    vocabulary = relationship("Vocabulary")
    lesson = relationship("Lesson")


class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    language_code = Column(String, nullable=True, index=True)
    score = Column(Integer, nullable=False)
    total_questions = Column(Integer, nullable=False)
    correct_answers = Column(Integer, nullable=False)
    duration_seconds = Column(Integer, nullable=True)
    level_code = Column(String, nullable=True, index=True)
    attempted_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    submitted_answers = Column(JSON, nullable=False)

    user = relationship("User")
