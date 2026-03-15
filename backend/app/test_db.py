from sqlalchemy import create_engine, text
from urllib.parse import quote_plus

# Encode ton mot de passe
password = quote_plus("Lucas@2003..")

# Mets-le dans l'URL
SQLALCHEMY_DATABASE_URL = f"postgresql://postgres:{password}@localhost:5432/linguaverse_db"

engine = create_engine(SQLALCHEMY_DATABASE_URL)

try:
    with engine.connect() as connection:
        result = connection.execute(text("SELECT version();"))
        version = result.fetchone()
        print("PostgreSQL version :", version[0])
except Exception as e:
    print("Erreur de connexion :", e)