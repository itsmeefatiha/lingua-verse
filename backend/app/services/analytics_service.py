from __future__ import annotations

from collections import defaultdict
from datetime import date, datetime, timedelta, timezone
from io import BytesIO
from typing import Iterable

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Spacer, Table, TableStyle, Paragraph
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.analytics import ListeningSession
from app.models.content import CEFRLevelEnum, Lesson, Level, Vocabulary
from app.models.gamification import XPTransaction
from app.models.progress import ProgressStatusEnum, UserLessonProgress
from app.models.quiz import QuizAttempt, Question
from app.models.user import User


def _seconds_to_minutes(seconds: int) -> float:
    return round(seconds / 60.0, 2)


def _get_user(db: Session, user_id: int) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise ValueError("Utilisateur introuvable")
    return user


def _get_current_cefr_level(db: Session, user_id: int) -> str:
    completed = (
        db.query(Level.code)
        .join(Lesson, Lesson.level_id == Level.id)
        .join(UserLessonProgress, UserLessonProgress.lesson_id == Lesson.id)
        .filter(UserLessonProgress.user_id == user_id, UserLessonProgress.status == ProgressStatusEnum.COMPLETED)
        .order_by(Level.display_order.desc())
        .first()
    )
    if completed and completed[0]:
        return completed[0].value if hasattr(completed[0], "value") else str(completed[0])

    fallback = db.query(Level.code).order_by(Level.display_order.asc()).first()
    if fallback and fallback[0]:
        return fallback[0].value if hasattr(fallback[0], "value") else str(fallback[0])
    return CEFRLevelEnum.A1.value


def get_time_spent_by_language(db: Session, user_id: int) -> list[dict]:
    listening_rows = (
        db.query(ListeningSession.language_code, func.coalesce(func.sum(ListeningSession.duration_seconds), 0))
        .filter(ListeningSession.user_id == user_id)
        .group_by(ListeningSession.language_code)
        .all()
    )
    quiz_rows = (
        db.query(QuizAttempt.language_code, func.coalesce(func.sum(QuizAttempt.duration_seconds), 0))
        .filter(QuizAttempt.user_id == user_id, QuizAttempt.language_code.isnot(None))
        .group_by(QuizAttempt.language_code)
        .all()
    )

    aggregated: dict[str, int] = defaultdict(int)
    for language_code, duration_seconds in listening_rows:
        aggregated[language_code] += int(duration_seconds or 0)
    for language_code, duration_seconds in quiz_rows:
        aggregated[language_code] += int(duration_seconds or 0)

    return [
        {
            "language_code": language_code,
            "duration_seconds": duration_seconds,
            "duration_minutes": _seconds_to_minutes(duration_seconds),
        }
        for language_code, duration_seconds in sorted(aggregated.items(), key=lambda item: item[1], reverse=True)
    ]


def get_theme_success_rates(db: Session, user_id: int) -> list[dict]:
    questions = (
        db.query(
            Question.id.label("question_id"),
            func.coalesce(Vocabulary.category, Lesson.title).label("theme"),
        )
        .join(Lesson, Question.lesson_id == Lesson.id)
        .outerjoin(Vocabulary, Question.vocabulary_id == Vocabulary.id)
        .all()
    )
    question_theme_map = {row.question_id: row.theme or "Général" for row in questions}

    totals: dict[str, int] = defaultdict(int)
    corrects: dict[str, int] = defaultdict(int)

    attempts = db.query(QuizAttempt.submitted_answers).filter(QuizAttempt.user_id == user_id).all()
    for (submitted_answers,) in attempts:
        for answer in submitted_answers or []:
            question_id = answer.get("question_id")
            theme = question_theme_map.get(question_id)
            if not theme:
                continue
            totals[theme] += 1
            if answer.get("is_correct"):
                corrects[theme] += 1

    results = []
    for theme, total_answers in totals.items():
        correct_answers = corrects.get(theme, 0)
        success_rate = round((correct_answers / total_answers) * 100, 2) if total_answers else 0.0
        results.append(
            {
                "theme": theme,
                "total_answers": total_answers,
                "correct_answers": correct_answers,
                "success_rate": success_rate,
            }
        )

    return sorted(results, key=lambda item: item["success_rate"], reverse=True)


def get_progression_curve(db: Session, user_id: int, days: int = 30) -> list[dict]:
    start_date = (datetime.now(timezone.utc) - timedelta(days=days - 1)).date()
    attempt_rows = (
        db.query(func.date(QuizAttempt.attempted_at).label("attempt_date"), func.avg(QuizAttempt.score), func.count(QuizAttempt.id))
        .filter(QuizAttempt.user_id == user_id, func.date(QuizAttempt.attempted_at) >= start_date)
        .group_by(func.date(QuizAttempt.attempted_at))
        .all()
    )
    rows_map = {row.attempt_date: (float(row[1] or 0), int(row[2] or 0)) for row in attempt_rows}

    points: list[dict] = []
    for offset in range(days):
        current_day = start_date + timedelta(days=offset)
        average_score, attempts_count = rows_map.get(current_day, (0.0, 0))
        points.append(
            {
                "date": current_day,
                "average_score": round(average_score, 2),
                "attempts_count": attempts_count,
            }
        )
    return points


def get_recent_completed_lessons(db: Session, user_id: int, limit: int = 5) -> list[dict]:
    rows = (
        db.query(UserLessonProgress, Lesson, Level)
        .join(Lesson, UserLessonProgress.lesson_id == Lesson.id)
        .join(Level, Lesson.level_id == Level.id)
        .filter(UserLessonProgress.user_id == user_id, UserLessonProgress.status == ProgressStatusEnum.COMPLETED)
        .order_by(UserLessonProgress.last_activity_at.desc())
        .limit(limit)
        .all()
    )
    return [
        {
            "lesson_id": lesson.id,
            "lesson_title": lesson.title,
            "cefr_level": level.code.value if hasattr(level.code, "value") else str(level.code),
            "last_score": progress.last_score,
            "completed_at": progress.last_activity_at,
        }
        for progress, lesson, level in rows
    ]


def get_dashboard_analytics(db: Session, user_id: int) -> dict:
    user = _get_user(db, user_id)
    total_lessons = db.query(Lesson).count()
    completed_lessons = (
        db.query(UserLessonProgress).filter(UserLessonProgress.user_id == user_id, UserLessonProgress.status == ProgressStatusEnum.COMPLETED).count()
    )
    average_quiz_score_30d = (
        db.query(func.coalesce(func.avg(QuizAttempt.score), 0))
        .filter(
            QuizAttempt.user_id == user_id,
            QuizAttempt.attempted_at >= datetime.now(timezone.utc) - timedelta(days=30),
        )
        .scalar()
        or 0.0
    )

    return {
        "user_id": user.id,
        "student_name": user.full_name,
        "current_cefr_level": _get_current_cefr_level(db, user_id),
        "current_level": user.current_level,
        "current_league": user.current_league,
        "total_xp": user.total_xp,
        "weekly_xp": user.weekly_xp,
        "streak_count": user.streak_count,
        "completed_lessons": completed_lessons,
        "total_lessons": total_lessons,
        "average_quiz_score_30d": round(float(average_quiz_score_30d), 2),
        "time_spent_by_language": get_time_spent_by_language(db, user_id),
        "success_rate_by_theme": get_theme_success_rates(db, user_id),
        "progression_curve": get_progression_curve(db, user_id),
        "recent_completed_lessons": get_recent_completed_lessons(db, user_id),
    }


def generate_progress_report_pdf(db: Session, user_id: int) -> bytes:
    analytics = get_dashboard_analytics(db, user_id)
    buffer = BytesIO()
    document = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=1.5 * cm, leftMargin=1.5 * cm, topMargin=1.5 * cm, bottomMargin=1.5 * cm)
    styles = getSampleStyleSheet()
    title_style = styles["Title"]
    subtitle_style = ParagraphStyle("Subtitle", parent=styles["Heading2"], textColor=colors.HexColor("#2c3e50"))
    normal_style = styles["BodyText"]

    story = []
    story.append(Paragraph("LinguaVerse - Rapport de progression", title_style))
    story.append(Spacer(1, 0.4 * cm))
    story.append(Paragraph(f"Étudiant: {analytics['student_name'] or 'Anonyme'}", subtitle_style))
    story.append(Paragraph(f"Niveau CECRL actuel: {analytics['current_cefr_level']}", normal_style))
    story.append(Paragraph(f"Niveau gamifié: {analytics['current_level']} | Ligue: {analytics['current_league'].value if hasattr(analytics['current_league'], 'value') else analytics['current_league']}", normal_style))
    story.append(Spacer(1, 0.4 * cm))

    key_metrics = [
        ["XP total", analytics["total_xp"]],
        ["XP semaine", analytics["weekly_xp"]],
        ["Séries", analytics["streak_count"]],
        ["Leçons complétées", f"{analytics['completed_lessons']} / {analytics['total_lessons']}"],
        ["Score moyen 30 jours", f"{analytics['average_quiz_score_30d']}%"],
    ]
    key_table = Table(key_metrics, colWidths=[6 * cm, 7 * cm])
    key_table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#eef2f7")),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#c7d0db")),
                ("FONTNAME", (0, 0), (-1, -1), "Helvetica"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("ROWBACKGROUNDS", (0, 0), (-1, -1), [colors.white, colors.HexColor("#f8fafc")]),
            ]
        )
    )
    story.append(key_table)
    story.append(Spacer(1, 0.5 * cm))

    story.append(Paragraph("Dernières leçons complétées", subtitle_style))
    lesson_rows = [["Leçon", "CECRL", "Score", "Date"]]
    for lesson in analytics["recent_completed_lessons"]:
        lesson_rows.append(
            [
                lesson["lesson_title"],
                lesson["cefr_level"],
                f"{lesson['last_score'] if lesson['last_score'] is not None else '-'}",
                lesson["completed_at"].strftime("%Y-%m-%d %H:%M") if lesson["completed_at"] else "-",
            ]
        )
    lessons_table = Table(lesson_rows, colWidths=[6 * cm, 2.5 * cm, 2.5 * cm, 2.5 * cm])
    lessons_table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f2937")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#c7d0db")),
                ("FONTSIZE", (0, 0), (-1, -1), 8.5),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f8fafc")]),
            ]
        )
    )
    story.append(lessons_table)

    document.build(story)
    return buffer.getvalue()


def create_listening_session(db: Session, *, user_id: int, language_code: str, duration_seconds: int, source_type: str | None = None, source_ref: str | None = None):
    session = ListeningSession(
        user_id=user_id,
        language_code=language_code,
        duration_seconds=duration_seconds,
        source_type=source_type,
        source_ref=source_ref,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session
