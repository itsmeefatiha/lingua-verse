# app/models/lesson.py
from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from ..db.base import Base

class Lesson(Base):
    __tablename__ = "lessons"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    level = Column(String, nullable=False)
    words = relationship("Word", back_populates="lesson")

class Word(Base):
    __tablename__ = "words"
    id = Column(Integer, primary_key=True, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id"))
    native = Column(String, nullable=False)
    target = Column(String, nullable=False)
    example = Column(String)
    lesson = relationship("Lesson", back_populates="words")