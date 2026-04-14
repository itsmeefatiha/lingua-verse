import random

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.content import CEFRLevelEnum, Lesson, Level, Vocabulary
from app.models.quiz import Question, QuestionTypeEnum, UserProgress
from app.services import content_service


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


def _generate_choices(db: Session, question: Question, num_choices: int = 4) -> list[str]:
    """Generate multiple choice options for a question."""
    if question.choices and len(question.choices) > 0:
        # Use existing choices if available
        return question.choices
    
    choices_set = {question.correct_answer}
    
    # Get additional vocabulary from the same lesson for distractors
    if question.vocabulary_id:
        distractors = (
            db.query(Vocabulary.translation)
            .filter(
                Vocabulary.lesson_id == question.lesson_id,
                Vocabulary.id != question.vocabulary_id,
            )
            .order_by(func.random())
            .limit(num_choices - 1)
            .all()
        )
    else:
        # Get from all vocabularies in the same lesson
        distractors = (
            db.query(Vocabulary.translation)
            .filter(Vocabulary.lesson_id == question.lesson_id)
            .order_by(func.random())
            .limit(num_choices - 1)
            .all()
        )
    
    for distractor_tuple in distractors:
        choices_set.add(distractor_tuple[0])
    
    # If we don't have enough choices, add more from other lessons in the same level
    if len(choices_set) < num_choices:
        lesson = db.query(Lesson).filter(Lesson.id == question.lesson_id).first()
        if lesson:
            additional = (
                db.query(Vocabulary.translation)
                .join(Lesson, Vocabulary.lesson_id == Lesson.id)
                .filter(
                    Lesson.level_id == lesson.level_id,
                    Lesson.id != question.lesson_id,
                )
                .order_by(func.random())
                .limit(num_choices - len(choices_set) + 1)
                .all()
            )
            for distractor_tuple in additional:
                choices_set.add(distractor_tuple[0])
    
    choices = list(choices_set)
    random.shuffle(choices)
    return choices[:num_choices]


def _level_vocabularies(db: Session, *, level_code: CEFRLevelEnum, language_code: str) -> list[Vocabulary]:
    lessons = content_service.list_lessons_by_level_code_and_language(
        db,
        level_code=level_code,
        language_code=language_code,
    )
    lesson_ids = [lesson.id for lesson in lessons]
    if not lesson_ids:
        return []

    return (
        db.query(Vocabulary)
        .join(Lesson, Vocabulary.lesson_id == Lesson.id)
        .filter(Vocabulary.lesson_id.in_(lesson_ids))
        .order_by(Lesson.display_order.asc(), Lesson.id.asc(), Vocabulary.id.asc())
        .all()
    )


def _question_pool_for_level(db: Session, *, level_code: CEFRLevelEnum, language_code: str) -> list[Vocabulary]:
    vocabularies = _level_vocabularies(db, level_code=level_code, language_code=language_code)
    if not vocabularies:
        raise ValueError("Aucun vocabulaire disponible pour ce niveau et cette langue")
    return vocabularies


def _build_level_choices(pool: list[Vocabulary], *, correct_answer: str, num_choices: int = 4) -> list[str]:
    choices = [correct_answer]
    seen = {correct_answer.strip().lower()}
    pool_candidates = []

    for vocab in pool:
        candidate = vocab.translation.strip()
        normalized = candidate.lower()
        if not candidate or normalized in seen:
            continue
        pool_candidates.append(candidate)

    random.shuffle(pool_candidates)

    while len(choices) < num_choices and pool_candidates:
        candidate = pool_candidates.pop()
        normalized = candidate.lower()
        if normalized in seen:
            continue
        choices.append(candidate)
        seen.add(normalized)

    random.shuffle(choices)
    return choices[:num_choices]


def _upsert_level_question(
    db: Session,
    *,
    lesson: Lesson,
    vocabulary: Vocabulary,
    question_type: QuestionTypeEnum,
    text: str,
    correct_answer: str,
    choices: list[str] | None,
    grammatical_explanation: str | None,
) -> Question:
    question = (
        db.query(Question)
        .filter(
            Question.lesson_id == lesson.id,
            Question.vocabulary_id == vocabulary.id,
            Question.question_type == question_type,
        )
        .first()
    )

    if question is None:
        question = Question(
            text=text,
            question_type=question_type,
            correct_answer=correct_answer,
            choices=choices,
            grammatical_explanation=grammatical_explanation,
            lesson_id=lesson.id,
            vocabulary_id=vocabulary.id,
            concept_id=f"level-{lesson.level_id}-{question_type.value}-{vocabulary.id}",
        )
        db.add(question)
        db.flush()
        return question

    question.text = text
    question.correct_answer = correct_answer
    question.choices = choices
    question.grammatical_explanation = grammatical_explanation
    return question


def generate_level_quiz_questions(
    db: Session,
    *,
    level_code: CEFRLevelEnum,
    language_code: str,
    question_count: int,
) -> list[Question]:
    lessons = content_service.list_lessons_by_level_code_and_language(
        db,
        level_code=level_code,
        language_code=language_code,
    )
    if not lessons:
        raise ValueError("Aucune leçon disponible pour ce niveau et cette langue")

    lesson_map = {lesson.id: lesson for lesson in lessons}
    vocabularies = _question_pool_for_level(db, level_code=level_code, language_code=language_code)

    voice_target = max(1, round(question_count * 0.4)) if question_count > 1 else 1
    if question_count > 1 and voice_target >= question_count:
        voice_target = question_count - 1
    qcm_target = max(1, question_count - voice_target) if question_count > 1 else 1

    shuffled_vocab = vocabularies[:]
    random.shuffle(shuffled_vocab)

    qcm_questions: list[Question] = []
    voice_questions: list[Question] = []

    for index in range(qcm_target):
        vocabulary = shuffled_vocab[index % len(shuffled_vocab)]
        lesson = lesson_map[vocabulary.lesson_id]
        qcm_questions.append(
            _upsert_level_question(
                db,
                lesson=lesson,
                vocabulary=vocabulary,
                question_type=QuestionTypeEnum.QCM,
                text=f'Choose the correct translation for "{vocabulary.term}".',
                correct_answer=vocabulary.translation,
                choices=_build_level_choices(vocabularies, correct_answer=vocabulary.translation),
                grammatical_explanation="Select the correct translation for the word from this level.",
            )
        )

    random.shuffle(shuffled_vocab)
    for index in range(voice_target):
      vocabulary = shuffled_vocab[index % len(shuffled_vocab)]
      lesson = lesson_map[vocabulary.lesson_id]
      voice_questions.append(
          _upsert_level_question(
              db,
              lesson=lesson,
              vocabulary=vocabulary,
              question_type=QuestionTypeEnum.VOICE,
              text=f'Say the word for "{vocabulary.translation}".',
              correct_answer=vocabulary.term,
              choices=None,
              grammatical_explanation="Speak the target language word aloud.",
          )
      )

    selected = qcm_questions + voice_questions
    random.shuffle(selected)
    db.commit()
    return selected[:question_count]


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
        # Generate choices for selected questions
        for q in selected:
            if not q.choices or len(q.choices) == 0:
                q.choices = _generate_choices(db, q)
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

    # Generate choices for all selected questions
    for q in selected:
        if not q.choices or len(q.choices) == 0:
            q.choices = _generate_choices(db, q)
    
    return selected[:question_count]
