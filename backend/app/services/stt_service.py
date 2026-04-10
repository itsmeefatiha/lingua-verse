import base64
import logging

from app.core.config import settings

logger = logging.getLogger(__name__)


def _decode_audio_base64(audio_base64: str) -> bytes:
    try:
        return base64.b64decode(audio_base64, validate=True)
    except Exception as exc:
        raise ValueError("audio_base64 invalide") from exc


def transcribe_audio(*, audio_base64: str | None, transcript: str | None, language: str = "en-US") -> str:
    engine = settings.STT_ENGINE.lower()

    # Simulated mode: supports deterministic testing without external APIs.
    if engine == "simulated":
        if transcript:
            return transcript.strip()
        if audio_base64:
            _decode_audio_base64(audio_base64)
            return ""
        raise ValueError("Fournir transcript ou audio_base64")

    if engine == "whisper":
        logger.warning("Whisper mode non configuré dans cette version, fallback simulé")
        if transcript:
            return transcript.strip()
        if audio_base64:
            _decode_audio_base64(audio_base64)
            return ""
        raise ValueError("Fournir transcript ou audio_base64")

    if engine == "speechrecognition":
        logger.warning("SpeechRecognition mode non configuré dans cette version, fallback simulé")
        if transcript:
            return transcript.strip()
        if audio_base64:
            _decode_audio_base64(audio_base64)
            return ""
        raise ValueError("Fournir transcript ou audio_base64")

    raise ValueError(f"Moteur STT non supporté: {settings.STT_ENGINE}")
