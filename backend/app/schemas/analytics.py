from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel

from app.models.user import LeagueEnum


class LanguageTimeEntryResponse(BaseModel):
    language_code: str
    duration_seconds: int
    duration_minutes: float


class ThemeSuccessRateResponse(BaseModel):
    theme: str
    total_answers: int
    correct_answers: int
    success_rate: float


class ProgressCurvePointResponse(BaseModel):
    date: date
    average_score: float
    attempts_count: int


class RecentCompletedLessonResponse(BaseModel):
    lesson_id: int
    lesson_title: str
    cefr_level: str
    last_score: Optional[int]
    completed_at: datetime


class AnalyticsDashboardResponse(BaseModel):
    user_id: int
    student_name: Optional[str]
    current_cefr_level: str
    current_level: int
    current_league: LeagueEnum
    total_xp: int
    weekly_xp: int
    streak_count: int
    completed_lessons: int
    total_lessons: int
    average_quiz_score_30d: float
    time_spent_by_language: list[LanguageTimeEntryResponse]
    success_rate_by_theme: list[ThemeSuccessRateResponse]
    progression_curve: list[ProgressCurvePointResponse]
    recent_completed_lessons: list[RecentCompletedLessonResponse]


class ListeningSessionCreate(BaseModel):
    language_code: str
    duration_seconds: int
    source_type: Optional[str] = None
    source_ref: Optional[str] = None


class ListeningSessionResponse(ListeningSessionCreate):
    id: int
    user_id: int
    listened_at: datetime

    model_config = {"from_attributes": True}
