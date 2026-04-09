from fastapi import APIRouter

router = APIRouter()

@router.get("/status")
async def gamification_status():
    return {"message": "Gamification endpoints"}
