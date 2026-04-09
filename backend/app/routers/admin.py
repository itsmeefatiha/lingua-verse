from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def admin_health():
    return {"message": "Admin endpoints"}
