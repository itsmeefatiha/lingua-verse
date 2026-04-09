from app.db.base import Base 

# 2. Import ALL your models here
from app.models.user import User
from app.models.quiz import Lesson, Quiz, QuizQuestion

__all__ = ["User", "Lesson", "Quiz", "QuizQuestion"]