from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from math import ceil

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.gamification import XPSourceTypeEnum, XPTransaction
from app.models.progress import ProgressStatusEnum, UserLessonProgress
from app.models.user import LeagueEnum, RoleEnum, User

XP_LESSON_COMPLETION = 50
XP_QUIZ_SUCCESS = 20
XP_STREAK_BONUS = 10


def xp_required_for_level(level: int) -> int:
    if level <= 1:
        return 0
    return int(round(100 * (level ** 1.5)))


def compute_level_from_xp(total_xp: int) -> int:
    level = 1
    while total_xp >= xp_required_for_level(level + 1):
        level += 1
    return level


def _get_user(db: Session, user_id: int) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise ValueError("Utilisateur introuvable")
    return user


def _get_existing_transaction(
    db: Session,
    *,
    user_id: int,
    source_type: XPSourceTypeEnum,
    source_ref: str,
) -> XPTransaction | None:
    return (
        db.query(XPTransaction)
        .filter(
            XPTransaction.user_id == user_id,
            XPTransaction.source_type == source_type,
            XPTransaction.source_ref == source_ref,
        )
        .first()
    )


def award_xp(
    db: Session,
    *,
    user_id: int,
    amount: int,
    source_type: XPSourceTypeEnum,
    source_ref: str,
) -> XPTransaction | None:
    if amount <= 0:
        return None

    existing = _get_existing_transaction(db, user_id=user_id, source_type=source_type, source_ref=source_ref)
    if existing:
        return existing

    user = _get_user(db, user_id)
    user.total_xp += amount
    user.weekly_xp += amount
    user.current_level = compute_level_from_xp(user.total_xp)

    transaction = XPTransaction(
        user_id=user_id,
        amount=amount,
        source_type=source_type,
        source_ref=source_ref,
    )
    db.add(transaction)
    db.flush()
    return transaction


def award_quiz_success_xp(db: Session, *, user_id: int, attempt_id: int, score: int) -> XPTransaction | None:
    if score < 80:
        return None
    return award_xp(
        db,
        user_id=user_id,
        amount=XP_QUIZ_SUCCESS,
        source_type=XPSourceTypeEnum.QUIZ_SUCCESS,
        source_ref=str(attempt_id),
    )


def award_lesson_completion_xp(db: Session, *, user_id: int, lesson_id: int) -> XPTransaction | None:
    return award_xp(
        db,
        user_id=user_id,
        amount=XP_LESSON_COMPLETION,
        source_type=XPSourceTypeEnum.LESSON_COMPLETION,
        source_ref=str(lesson_id),
    )


def award_streak_bonus_xp(db: Session, *, user_id: int, streak_count: int) -> XPTransaction | None:
    bonus = XP_STREAK_BONUS if streak_count > 0 and streak_count % 7 == 0 else 0
    if bonus == 0:
        return None
    return award_xp(
        db,
        user_id=user_id,
        amount=bonus,
        source_type=XPSourceTypeEnum.STREAK_BONUS,
        source_ref=f"{datetime.now(timezone.utc).date().isoformat()}-streak-{streak_count}",
    )


def update_streak_on_activity(db: Session, *, user_id: int, activity_date: date | None = None) -> User:
    user = _get_user(db, user_id)
    today = activity_date or datetime.now(timezone.utc).date()

    if user.last_activity_date is None:
        user.streak_count = 1
    else:
        delta_days = (today - user.last_activity_date).days
        if delta_days == 1:
            user.streak_count += 1
        elif delta_days > 1:
            user.streak_count = 0

    user.last_activity_date = today
    db.flush()
    return user


def register_completed_lesson_activity(db: Session, *, user_id: int, lesson_id: int) -> None:
    award_lesson_completion_xp(db, user_id=user_id, lesson_id=lesson_id)
    update_streak_on_activity(db, user_id=user_id)
    user = _get_user(db, user_id)
    award_streak_bonus_xp(db, user_id=user_id, streak_count=user.streak_count)


def register_quiz_success_activity(db: Session, *, user_id: int, attempt_id: int, score: int) -> None:
    award_quiz_success_xp(db, user_id=user_id, attempt_id=attempt_id, score=score)
    update_streak_on_activity(db, user_id=user_id)
    user = _get_user(db, user_id)
    award_streak_bonus_xp(db, user_id=user_id, streak_count=user.streak_count)


def list_weekly_leaderboard(db: Session, limit: int = 10) -> list[User]:
    return (
        db.query(User)
        .filter(User.role != RoleEnum.ADMIN)
        .order_by(User.weekly_xp.desc(), User.total_xp.desc(), User.id.asc())
        .limit(limit)
        .all()
    )


def reset_weekly_leaderboard_and_reassign_leagues(db: Session) -> dict:
    users = db.query(User).order_by(User.weekly_xp.desc(), User.total_xp.desc(), User.id.asc()).all()
    total_users = len(users)
    if total_users == 0:
        return {
            "reset_at": datetime.now(timezone.utc),
            "total_users": 0,
            "promoted_to_or": 0,
            "promoted_to_argent": 0,
            "demoted_to_bronze": 0,
        }

    gold_cutoff = max(1, ceil(total_users * 0.1))
    silver_cutoff = max(gold_cutoff + 1, ceil(total_users * 0.4))

    promoted_to_or = 0
    promoted_to_argent = 0
    demoted_to_bronze = 0

    for index, user in enumerate(users, start=1):
        if index <= gold_cutoff:
            user.current_league = LeagueEnum.OR
            promoted_to_or += 1
        elif index <= silver_cutoff:
            user.current_league = LeagueEnum.ARGENT
            promoted_to_argent += 1
        else:
            user.current_league = LeagueEnum.BRONZE
            demoted_to_bronze += 1

        user.weekly_xp = 0

    db.commit()
    return {
        "reset_at": datetime.now(timezone.utc),
        "total_users": total_users,
        "promoted_to_or": promoted_to_or,
        "promoted_to_argent": promoted_to_argent,
        "demoted_to_bronze": demoted_to_bronze,
    }


def total_weekly_xp(db: Session) -> int:
    return db.query(func.coalesce(func.sum(User.weekly_xp), 0)).scalar() or 0
