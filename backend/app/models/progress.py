from datetime import datetime, timezone
import enum

from sqlalchemy import Column, DateTime, Enum, ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import relationship

from app.db.base import Base


class ProgressStatusEnum(str, enum.Enum):
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"


class UserViewedVocab(Base):
    __tablename__ = "user_viewed_vocab"
    __table_args__ = (
        UniqueConstraint("user_id", "vocabulary_id", name="uq_user_viewed_vocab_user_vocab"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    vocabulary_id = Column(Integer, ForeignKey("vocabularies.id", ondelete="CASCADE"), nullable=False, index=True)
    viewed_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User")
    vocabulary = relationship("Vocabulary")


class UserLessonProgress(Base):
    __tablename__ = "user_lesson_progress"
    __table_args__ = (
        UniqueConstraint("user_id", "lesson_id", name="uq_user_lesson_progress_user_lesson"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(Enum(ProgressStatusEnum), nullable=False, default=ProgressStatusEnum.IN_PROGRESS)
    last_score = Column(Integer, nullable=True)
    last_activity_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User")
    lesson = relationship("Lesson")
