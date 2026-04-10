import hashlib
import logging
from pathlib import Path
from urllib.parse import quote

from app.core.config import settings

logger = logging.getLogger(__name__)


def _build_deterministic_name(term: str, lang: str) -> str:
    digest = hashlib.sha1(f"{lang}:{term}".encode("utf-8")).hexdigest()[:12]
    safe_term = quote(term.strip().lower().replace(" ", "-"))
    return f"{safe_term}-{digest}.mp3"


def _mock_audio_url(term: str, lang: str) -> str:
    file_name = _build_deterministic_name(term, lang)
    return f"{settings.TTS_STORAGE_BASE_URL.rstrip('/')}/{file_name}"


def _generate_with_gtts(term: str, lang: str) -> str:
    try:
        from gtts import gTTS
    except Exception as exc:
        logger.warning("gTTS unavailable, falling back to mock URL: %s", exc)
        return _mock_audio_url(term, lang)

    output_dir = Path(settings.TTS_OUTPUT_DIR)
    output_dir.mkdir(parents=True, exist_ok=True)

    file_name = _build_deterministic_name(term, lang)
    output_path = output_dir / file_name

    if not output_path.exists():
        tts = gTTS(text=term, lang=lang)
        tts.save(str(output_path))

    return f"{settings.TTS_STORAGE_BASE_URL.rstrip('/')}/{file_name}"


def generate_audio_url(term: str, lang: str | None = None) -> str:
    chosen_lang = lang or settings.TTS_DEFAULT_LANG

    if settings.TTS_ENGINE.lower() == "gtts":
        return _generate_with_gtts(term=term, lang=chosen_lang)

    return _mock_audio_url(term=term, lang=chosen_lang)
