from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    # API Metadata
    PROJECT_NAME: str = "LinguaVerse API"
    LOG_LEVEL: str = "INFO"

    # JWT Authentication
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # PostgreSQL Database
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_SERVER: str
    POSTGRES_PORT: str
    POSTGRES_DB: str

    # Email (SMTP)
    SMTP_SERVER: str
    SMTP_PORT: int
    SMTP_USER: str
    SMTP_PASSWORD: str

    # OAuth2 Configuration
    GOOGLE_CLIENT_ID: Optional[str] = None
    GOOGLE_CLIENT_SECRET: Optional[str] = None
    GITHUB_CLIENT_ID: Optional[str] = None
    GITHUB_CLIENT_SECRET: Optional[str] = None

    # TTS / Audio generation
    TTS_ENGINE: str = "mock"  # mock | gtts
    TTS_DEFAULT_LANG: str = "en"
    TTS_STORAGE_BASE_URL: str = "https://storage.linguaverse.local/audio"
    TTS_OUTPUT_DIR: str = "generated_audio"

    # STT / Speech-to-Text
    STT_ENGINE: str = "simulated"  # simulated | whisper | speechrecognition

    @property
    def SQLALCHEMY_DATABASE_URI(self) -> str:
        """
        Dynamically builds the connection string.
        Change 'postgresql' to 'postgresql+asyncpg' if using async SQLAlchemy.
        """
        return (
            f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    model_config = SettingsConfigDict(
        env_file=".env", 
        env_file_encoding="utf-8", 
        case_sensitive=True
    )

# Singleton instance to be imported across the app
settings = Settings()