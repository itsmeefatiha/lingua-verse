from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.database import get_db
from app.models.user import User
from app.schemas.analytics import AnalyticsDashboardResponse, ListeningSessionCreate, ListeningSessionResponse
from app.services import analytics_service

router = APIRouter()


@router.get("/dashboard", response_model=AnalyticsDashboardResponse)
def get_dashboard_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return analytics_service.get_dashboard_analytics(db, current_user.id)


@router.post("/listening-sessions", response_model=ListeningSessionResponse, status_code=status.HTTP_201_CREATED)
def record_listening_session(
    session_in: ListeningSessionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return analytics_service.create_listening_session(
        db,
        user_id=current_user.id,
        language_code=session_in.language_code,
        duration_seconds=session_in.duration_seconds,
        source_type=session_in.source_type,
        source_ref=session_in.source_ref,
    )


@router.get("/report/progression.pdf")
def download_progress_report_pdf(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    pdf_bytes = analytics_service.generate_progress_report_pdf(db, current_user.id)
    return StreamingResponse(
        iter([pdf_bytes]),
        media_type="application/pdf",
        headers={"Content-Disposition": 'attachment; filename="linguaverse_progress_report.pdf"'},
    )
