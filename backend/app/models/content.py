from datetime import datetime, timezone
import enum

from sqlalchemy import Column, DateTime, Enum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.db.base import Base


class CEFRLevelEnum(str, enum.Enum):
    A1 = "A1"
    A2 = "A2"
    B1 = "B1"
    B2 = "B2"
    C1 = "C1"
    C2 = "C2"


class Level(Base):
    __tablename__ = "levels"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(Enum(CEFRLevelEnum), unique=True, nullable=False)
    display_order = Column(Integer, nullable=False, default=0)

    lessons = relationship("Lesson", back_populates="level", cascade="all, delete-orphan")


class Lesson(Base):
    __tablename__ = "lessons"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    level_id = Column(Integer, ForeignKey("levels.id", ondelete="CASCADE"), nullable=False, index=True)
    display_order = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    level = relationship("Level", back_populates="lessons")
    vocabulary_items = relationship("Vocabulary", back_populates="lesson", cascade="all, delete-orphan")


class Vocabulary(Base):
    __tablename__ = "vocabularies"

    id = Column(Integer, primary_key=True, index=True)
    category = Column(String, nullable=True, index=True)
    term = Column(String, nullable=False)
    translation = Column(String, nullable=False)
    example = Column(Text, nullable=True)
    image_url = Column(String, nullable=True)
    audio_url = Column(String, nullable=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)

    lesson = relationship("Lesson", back_populates="vocabulary_items")
