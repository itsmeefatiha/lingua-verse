import random

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.content import CEFRLevelEnum, Lesson, Level
from app.models.quiz import Question, UserProgress


def _load_weaknesses(db: Session, user_id: int) -> list[UserProgress]:
    return (
        db.query(UserProgress)
        .filter(UserProgress.user_id == user_id, UserProgress.error_count > 0)
        .order_by(UserProgress.error_count.desc(), UserProgress.last_seen_at.desc())
        .all()
    )


def _pick_question_for_weakness(db: Session, weakness: UserProgress, excluded_ids: set[int]) -> Question | None:
    query = db.query(Question)

    if weakness.vocabulary_id is not None:
        query = query.filter(Question.vocabulary_id == weakness.vocabulary_id)
    elif weakness.concept_id:
        query = query.filter(Question.concept_id == weakness.concept_id)
    elif weakness.lesson_id is not None:
        query = query.filter(Question.lesson_id == weakness.lesson_id)
    else:
        return None

    if excluded_ids:
        query = query.filter(~Question.id.in_(excluded_ids))

    return query.order_by(func.random()).first()


def _balanced_questions_for_level(
    db: Session,
    level_code: CEFRLevelEnum | None,
    limit: int,
    excluded_ids: set[int],
) -> list[Question]:
    query = db.query(Question).join(Lesson, Question.lesson_id == Lesson.id)
    if level_code is not None:
        query = query.join(Level, Lesson.level_id == Level.id).filter(Level.code == level_code)

    if excluded_ids:
        query = query.filter(~Question.id.in_(excluded_ids))

    candidates = query.order_by(Lesson.id.asc(), Question.id.asc()).all()
    if not candidates:
        return []

    grouped: dict[int, list[Question]] = {}
    for question in candidates:
        grouped.setdefault(question.lesson_id, []).append(question)

    for lesson_questions in grouped.values():
        random.shuffle(lesson_questions)

    lesson_ids = list(grouped.keys())
    random.shuffle(lesson_ids)

    selected: list[Question] = []
    while len(selected) < limit and lesson_ids:
        remaining_lesson_ids: list[int] = []
        for lesson_id in lesson_ids:
            question_pool = grouped[lesson_id]
            if question_pool and len(selected) < limit:
                selected.append(question_pool.pop())
            if question_pool:
                remaining_lesson_ids.append(lesson_id)
        lesson_ids = remaining_lesson_ids

    return selected


def generate_adaptive_quiz(
    db: Session,
    *,
    user_id: int,
    question_count: int,
    level_code: CEFRLevelEnum | None,
) -> list[Question]:
    weaknesses = _load_weaknesses(db, user_id)
    selected: list[Question] = []
    selected_ids: set[int] = set()

    weak_target = int(question_count * 0.7)
    if weak_target == 0 and weaknesses:
        weak_target = 1

    for weakness in weaknesses:
        if len(selected) >= weak_target:
            break
        picked = _pick_question_for_weakness(db, weakness, selected_ids)
        if not picked:
            continue
        selected.append(picked)
        selected_ids.add(picked.id)

    remaining = question_count - len(selected)
    if remaining <= 0:
        return selected[:question_count]

    if not weaknesses and level_code is None:
        raise ValueError("Pour un nouvel utilisateur, level_code est requis")

    balanced = _balanced_questions_for_level(db, level_code=level_code, limit=remaining, excluded_ids=selected_ids)
    selected.extend(balanced)

    if len(selected) < question_count:
        fallback_query = db.query(Question)
        if selected_ids:
            fallback_query = fallback_query.filter(~Question.id.in_(selected_ids))
        fallback = fallback_query.order_by(func.random()).limit(question_count - len(selected)).all()
        selected.extend(fallback)

    return selected[:question_count]
