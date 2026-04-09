from fastapi import APIRouter

router = APIRouter()

@router.get("/status")
async def ar_status():
    return {"message": "AR endpoints"}
