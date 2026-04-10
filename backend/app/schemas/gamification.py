from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.models.user import LeagueEnum


class LeaderboardEntryResponse(BaseModel):
    rank: int
    user_id: int
    full_name: Optional[str]
    avatar_url: Optional[str]
    weekly_xp: int
    total_xp: int
    current_level: int
    current_league: LeagueEnum
    streak_count: int


class WeeklyResetResponse(BaseModel):
    reset_at: datetime
    total_users: int
    promoted_to_or: int
    promoted_to_argent: int
    demoted_to_bronze: int
