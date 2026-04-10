from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.db.base import Base


class ListeningSession(Base):
    __tablename__ = "listening_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    language_code = Column(String, nullable=False, index=True)
    duration_seconds = Column(Integer, nullable=False)
    source_type = Column(String, nullable=True)
    source_ref = Column(String, nullable=True)
    listened_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User")