from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, require_role
from app.db.database import get_db
from app.models.user import RoleEnum, User
from app.schemas.gamification import LeaderboardEntryResponse, WeeklyResetResponse
from app.services import gamification_service

router = APIRouter()


@router.get("/leaderboard", response_model=list[LeaderboardEntryResponse])
def get_weekly_leaderboard(
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    users = gamification_service.list_weekly_leaderboard(db, limit=10)
    return [
        {
            "rank": index,
            "user_id": user.id,
            "full_name": user.full_name,
            "avatar_url": user.avatar_url,
            "weekly_xp": user.weekly_xp,
            "total_xp": user.total_xp,
            "current_level": user.current_level,
            "current_league": user.current_league,
            "streak_count": user.streak_count,
        }
        for index, user in enumerate(users, start=1)
    ]


@router.post("/admin/gamification/weekly-reset", response_model=WeeklyResetResponse)
def reset_weekly_gamification(
    db: Session = Depends(get_db),
    _: User = Depends(require_role(RoleEnum.ADMIN)),
):
    return gamification_service.reset_weekly_leaderboard_and_reassign_leagues(db)
