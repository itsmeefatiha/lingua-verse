# app/schemas/lesson.py
from pydantic import BaseModel
from typing import List, Optional

class WordBase(BaseModel):
    native: str
    target: str
    example: Optional[str]

class WordCreate(WordBase):
    pass

class WordResponse(WordBase):
    id: int
    class Config:
        orm_mode = True

class LessonBase(BaseModel):
    title: str
    level: str

class LessonCreate(LessonBase):
    words: List[WordCreate] = []

class LessonResponse(LessonBase):
    id: int
    words: List[WordResponse] = []
    class Config:
        orm_mode = True