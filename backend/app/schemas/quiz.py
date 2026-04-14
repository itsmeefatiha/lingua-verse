from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.models.content import CEFRLevelEnum
from app.models.quiz import QuestionTypeEnum


class QuestionBase(BaseModel):
    text: str = Field(min_length=1)
    question_type: QuestionTypeEnum
    correct_answer: str = Field(min_length=1)
    choices: Optional[list[str]] = None
    grammatical_explanation: Optional[str] = None
    lesson_id: int
    vocabulary_id: Optional[int] = None
    concept_id: Optional[str] = Field(default=None, max_length=120)


class QuestionCreate(QuestionBase):
    pass


class QuestionUpdate(BaseModel):
    text: Optional[str] = Field(default=None, min_length=1)
    question_type: Optional[QuestionTypeEnum] = None
    correct_answer: Optional[str] = Field(default=None, min_length=1)
    choices: Optional[list[str]] = None
    grammatical_explanation: Optional[str] = None
    lesson_id: Optional[int] = None
    vocabulary_id: Optional[int] = None
    concept_id: Optional[str] = Field(default=None, max_length=120)


class QuestionResponse(BaseModel):
    id: int
    text: str
    question_type: QuestionTypeEnum
    correct_answer: str
    choices: Optional[list[str]]
    grammatical_explanation: Optional[str]
    lesson_id: int
    vocabulary_id: Optional[int]
    concept_id: Optional[str]

    model_config = {"from_attributes": True}


class QuestionPublicResponse(BaseModel):
    id: int
    text: str
    question_type: QuestionTypeEnum
    correct_answer: str
    choices: Optional[list[str]]
    grammatical_explanation: Optional[str]
    lesson_id: int
    vocabulary_id: Optional[int]
    concept_id: Optional[str]

    model_config = {"from_attributes": True}


class QuizGenerateRequest(BaseModel):
    level_code: Optional[CEFRLevelEnum] = None
    language_code: Optional[str] = None
    question_count: int = Field(default=10, ge=1, le=30)


class QuizAnswerInput(BaseModel):
    question_id: int
    answer: str


class QuizSubmitRequest(BaseModel):
    level_code: Optional[CEFRLevelEnum] = None
    language_code: Optional[str] = None
    duration_seconds: Optional[int] = Field(default=None, ge=0)
    answers: list[QuizAnswerInput] = Field(min_length=1)


class AnswerFeedback(BaseModel):
    question_id: int
    is_correct: bool
    correct_answer: str
    explanation: Optional[str]


class QuizSubmitResponse(BaseModel):
    score: int
    total_questions: int
    correct_answers: int
    feedback: list[AnswerFeedback]


class QuizAttemptResponse(BaseModel):
    id: int
    score: int
    total_questions: int
    correct_answers: int
    language_code: Optional[str]
    duration_seconds: Optional[int]
    level_code: Optional[str]
    attempted_at: datetime
    submitted_answers: list[dict]

    model_config = {"from_attributes": True}


class STTValidationRequest(BaseModel):
    audio_base64: Optional[str] = None
    transcript: Optional[str] = None
    language: Optional[str] = "en-US"


class STTValidationResponse(BaseModel):
    transcribed_text: str
    is_correct: bool
    correct_answer: str
    explanation: Optional[str]
