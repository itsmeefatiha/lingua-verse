from app.db.base import Base 

# 2. Import ALL your models here
from app.models.user import User
from app.models.content import Language, Level, Lesson, Vocabulary
from app.models.quiz import Question, UserProgress, QuizAttempt
from app.models.progress import ProgressStatusEnum, UserViewedVocab, UserLessonProgress
from app.models.gamification import XPSourceTypeEnum, XPTransaction
from app.models.analytics import ListeningSession