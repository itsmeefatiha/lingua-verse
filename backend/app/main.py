from fastapi import FastAPI

app = FastAPI(
    title="Lingua Verse API",
    description="API asynchrone pour l'apprentissage des langues avec support AR.",
    version="1.0.0"
)

@app.get("/")
async def root():
    return {"message": "Bienvenue sur l'API de Lingua Verse !"}