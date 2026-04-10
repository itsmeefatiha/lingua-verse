from datetime import datetime, timezone
import enum

from sqlalchemy import Column, DateTime, Enum, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship

from app.db.base import Base


class XPSourceTypeEnum(str, enum.Enum):
    QUIZ_SUCCESS = "quiz_success"
    LESSON_COMPLETION = "lesson_completion"
    STREAK_BONUS = "streak_bonus"
    ADMIN_ADJUSTMENT = "admin_adjustment"


class XPTransaction(Base):
    __tablename__ = "xp_transactions"
    __table_args__ = (
        UniqueConstraint("user_id", "source_type", "source_ref", name="uq_xp_transaction_source"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    amount = Column(Integer, nullable=False)
    source_type = Column(Enum(XPSourceTypeEnum), nullable=False)
    source_ref = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User")
