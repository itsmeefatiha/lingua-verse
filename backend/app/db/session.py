# app/session.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from urllib.parse import quote_plus

# Encode le mot de passe pour éviter les problèmes avec @ et .
password = quote_plus("Lucas@2003..")

# URL de connexion
SQLALCHEMY_DATABASE_URL = f"postgresql://postgres:{password}@localhost:5432/linguaverse_db"

# Créer l'engine
engine = create_engine(SQLALCHEMY_DATABASE_URL, echo=True)

# Créer la session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base pour déclarer les modèles
Base = declarative_base()

# Dépendance FastAPI pour obtenir une session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()