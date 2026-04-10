from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.models.progress import ProgressStatusEnum


class UserViewedVocabResponse(BaseModel):
    id: int
    user_id: int
    vocabulary_id: int
    viewed_at: datetime

    model_config = {"from_attributes": True}


class UserLessonProgressResponse(BaseModel):
    id: int
    user_id: int
    lesson_id: int
    status: ProgressStatusEnum
    last_score: Optional[int]
    last_activity_at: datetime
    progress_percent: float
    viewed_vocab_count: int
    total_vocab_count: int
    quiz_completed: bool
    vocab_completed: bool

    model_config = {"from_attributes": True}


class ProgressOverviewResponse(BaseModel):
    user_id: int
    overall_completion_percent: float
    completed_lessons: int
    total_lessons: int
    lessons: list["ProgressLessonDetailResponse"]


class ProgressLessonDetailResponse(UserLessonProgressResponse):
    lesson_title: str
    lesson_description: Optional[str] = None


ProgressOverviewResponse.model_rebuild()

