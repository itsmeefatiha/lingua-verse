from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.quiz import Lesson, VocabularyItem
from typing import Optional

router = APIRouter()

CEFR_LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"]

CEFR_DESCRIPTIONS = {
    "A1": "Débutant – Expressions de base, interactions simples",
    "A2": "Élémentaire – Phrases courtes, situations courantes",
    "B1": "Intermédiaire – Sujets familiers, voyages, travail",
    "B2": "Intermédiaire avancé – Textes complexes, discussions abstraites",
    "C1": "Avancé – Expression fluide et spontanée",
    "C2": "Maîtrise – Compréhension totale, expression précise",
}


@router.get("/levels")
async def get_catalog_by_levels(db: Session = Depends(get_db)):
    """
    Retourne le catalogue complet des leçons publiées, groupées par niveau CECRL (A1→C2).
    """
    result = []
    for level in CEFR_LEVELS:
        lessons = (
            db.query(Lesson)
            .filter(Lesson.cefr_level == level, Lesson.is_published == True)
            .order_by(Lesson.order_index)
            .all()
        )
        lesson_list = []
        for lesson in lessons:
            vocab_count = db.query(VocabularyItem).filter(VocabularyItem.lesson_id == lesson.id).count()
            lesson_list.append({
                "id": lesson.id,
                "title": lesson.title,
                "description": lesson.description,
                "cefr_level": lesson.cefr_level,
                "is_published": lesson.is_published,
                "order_index": lesson.order_index,
                "professor_id": lesson.professor_id,
                "content": lesson.content,
                "created_at": lesson.created_at,
                "vocabulary_count": vocab_count,
            })
        result.append({
            "level": level,
            "description": CEFR_DESCRIPTIONS.get(level, ""),
            "lesson_count": len(lesson_list),
            "lessons": lesson_list,
        })
    return result


@router.get("/levels/{level}")
async def get_lessons_by_level(
    level: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    """
    Retourne les leçons publiées pour un niveau CECRL spécifique (ex: A1, B2…).
    """
    level = level.upper()
    if level not in CEFR_LEVELS:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail=f"Niveau invalide. Valeurs acceptées: {', '.join(CEFR_LEVELS)}")

    lessons = (
        db.query(Lesson)
        .filter(Lesson.cefr_level == level, Lesson.is_published == True)
        .order_by(Lesson.order_index)
        .offset(skip)
        .limit(limit)
        .all()
    )

    lesson_list = []
    for lesson in lessons:
        vocab_count = db.query(VocabularyItem).filter(VocabularyItem.lesson_id == lesson.id).count()
        lesson_list.append({
            "id": lesson.id,
            "title": lesson.title,
            "description": lesson.description,
            "cefr_level": lesson.cefr_level,
            "is_published": lesson.is_published,
            "order_index": lesson.order_index,
            "professor_id": lesson.professor_id,
            "content": lesson.content,
            "created_at": lesson.created_at,
            "vocabulary_count": vocab_count,
        })

    return {
        "level": level,
        "description": CEFR_DESCRIPTIONS.get(level, ""),
        "total": len(lesson_list),
        "lessons": lesson_list,
    }


@router.get("/search")
async def search_catalog(
    q: str = Query(..., min_length=1, description="Terme de recherche"),
    level: Optional[str] = Query(None, description="Filtrer par niveau CECRL"),
    db: Session = Depends(get_db),
):
    """
    Recherche dans le catalogue par titre ou description, avec filtre niveau optionnel.
    """
    query = db.query(Lesson).filter(
        Lesson.is_published == True,
        (Lesson.title.ilike(f"%{q}%")) | (Lesson.description.ilike(f"%{q}%"))
    )
    if level:
        level = level.upper()
        if level in CEFR_LEVELS:
            query = query.filter(Lesson.cefr_level == level)

    lessons = query.order_by(Lesson.cefr_level, Lesson.order_index).limit(30).all()

    result = []
    for lesson in lessons:
        vocab_count = db.query(VocabularyItem).filter(VocabularyItem.lesson_id == lesson.id).count()
        result.append({
            "id": lesson.id,
            "title": lesson.title,
            "description": lesson.description,
            "cefr_level": lesson.cefr_level,
            "vocabulary_count": vocab_count,
        })
    return result


@router.get("/stats")
async def get_catalog_stats(db: Session = Depends(get_db)):
    """
    Statistiques globales du catalogue : nombre de leçons par niveau, total vocabulaire.
    """
    stats = []
    total_lessons = 0
    total_vocab = 0

    for level in CEFR_LEVELS:
        count = db.query(Lesson).filter(Lesson.cefr_level == level, Lesson.is_published == True).count()
        total_lessons += count
        stats.append({"level": level, "lesson_count": count})

    total_vocab = db.query(VocabularyItem).count()

    return {
        "total_published_lessons": total_lessons,
        "total_vocabulary_items": total_vocab,
        "by_level": stats,
    }
