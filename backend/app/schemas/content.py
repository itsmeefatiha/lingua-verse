from typing import Optional

from pydantic import BaseModel, Field

from app.models.content import CEFRLevelEnum


class LevelResponse(BaseModel):
    id: int
    code: CEFRLevelEnum
    language_id: int
    display_order: int

    model_config = {"from_attributes": True}


class LanguageResponse(BaseModel):
    id: int
    name: str
    code: str


class LevelByLanguageResponse(BaseModel):
    id: int
    language_id: int
    name: str
    order_index: int
    is_completed: bool
    is_locked: bool


class LevelCreate(BaseModel):
    code: CEFRLevelEnum
    language_id: int
    display_order: int = Field(default=0, ge=0)


class LessonBase(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: Optional[str] = None
    level_id: int
    display_order: int = Field(default=0, ge=0)


class LessonCreate(LessonBase):
    pass


class LessonUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=200)
    description: Optional[str] = None
    level_id: Optional[int] = None
    display_order: Optional[int] = Field(default=None, ge=0)


class LessonResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    level_id: int
    display_order: int

    model_config = {"from_attributes": True}


class VocabularyBase(BaseModel):
    category: Optional[str] = None
    term: str = Field(min_length=1, max_length=200)
    translation: str = Field(min_length=1, max_length=200)
    example: Optional[str] = None
    image_url: Optional[str] = None
    audio_url: Optional[str] = None


class VocabularyCreate(VocabularyBase):
    pass


class VocabularyUpdate(BaseModel):
    category: Optional[str] = None
    term: Optional[str] = Field(default=None, min_length=1, max_length=200)
    translation: Optional[str] = Field(default=None, min_length=1, max_length=200)
    example: Optional[str] = None
    image_url: Optional[str] = None
    audio_url: Optional[str] = None


class VocabularyResponse(BaseModel):
    id: int
    category: Optional[str]
    term: str
    translation: str
    example: Optional[str]
    image_url: Optional[str]
    audio_url: Optional[str]
    lesson_id: int

    model_config = {"from_attributes": True}
