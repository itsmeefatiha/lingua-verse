from datetime import datetime, timezone
import enum

from sqlalchemy import Column, DateTime, Enum, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship

from app.db.base import Base


class CEFRLevelEnum(str, enum.Enum):
    A1 = "A1"
    A2 = "A2"
    B1 = "B1"
    B2 = "B2"
    C1 = "C1"
    C2 = "C2"


class Language(Base):
    __tablename__ = "languages"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    code = Column(String, nullable=False, unique=True, index=True)

    levels = relationship("Level", back_populates="language", cascade="all, delete-orphan")


class Level(Base):
    __tablename__ = "levels"
    __table_args__ = (
        UniqueConstraint("language_id", "code", name="uq_levels_language_code"),
    )

    id = Column(Integer, primary_key=True, index=True)
    code = Column(Enum(CEFRLevelEnum), nullable=False)
    language_id = Column(Integer, ForeignKey("languages.id", ondelete="CASCADE"), nullable=False, index=True)
    display_order = Column(Integer, nullable=False, default=0)

    language = relationship("Language", back_populates="levels")
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
