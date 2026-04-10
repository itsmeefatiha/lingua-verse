from app.db.database import SessionLocal
from app.services.gamification_service import reset_weekly_leaderboard_and_reassign_leagues


def run_weekly_gamification_reset() -> dict:
    db = SessionLocal()
    try:
        return reset_weekly_leaderboard_and_reassign_leagues(db)
    finally:
        db.close()
