"""add quiz tables

Revision ID: c9f7d2e1b8a4
Revises: a4c3d8f7b2e1
Create Date: 2026-04-09 08:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c9f7d2e1b8a4"
down_revision: Union[str, Sequence[str], None] = "a4c3d8f7b2e1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "questions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("question_type", sa.Enum("QCM", "GAP_TEXT", "ORDERING", "VOICE", name="questiontypeenum"), nullable=False),
        sa.Column("correct_answer", sa.Text(), nullable=False),
        sa.Column("grammatical_explanation", sa.Text(), nullable=True),
        sa.Column("lesson_id", sa.Integer(), nullable=False),
        sa.Column("vocabulary_id", sa.Integer(), nullable=True),
        sa.Column("concept_id", sa.String(), nullable=True),
        sa.ForeignKeyConstraint(["lesson_id"], ["lessons.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["vocabulary_id"], ["vocabularies.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_questions_id"), "questions", ["id"], unique=False)
    op.create_index(op.f("ix_questions_lesson_id"), "questions", ["lesson_id"], unique=False)
    op.create_index(op.f("ix_questions_vocabulary_id"), "questions", ["vocabulary_id"], unique=False)
    op.create_index(op.f("ix_questions_concept_id"), "questions", ["concept_id"], unique=False)

    op.create_table(
        "user_progress",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("vocabulary_id", sa.Integer(), nullable=True),
        sa.Column("concept_id", sa.String(), nullable=True),
        sa.Column("lesson_id", sa.Integer(), nullable=True),
        sa.Column("error_count", sa.Integer(), nullable=False),
        sa.Column("success_count", sa.Integer(), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["lesson_id"], ["lessons.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["vocabulary_id"], ["vocabularies.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_user_progress_id"), "user_progress", ["id"], unique=False)
    op.create_index(op.f("ix_user_progress_user_id"), "user_progress", ["user_id"], unique=False)
    op.create_index(op.f("ix_user_progress_vocabulary_id"), "user_progress", ["vocabulary_id"], unique=False)
    op.create_index(op.f("ix_user_progress_concept_id"), "user_progress", ["concept_id"], unique=False)
    op.create_index(op.f("ix_user_progress_lesson_id"), "user_progress", ["lesson_id"], unique=False)

    op.create_table(
        "quiz_attempts",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("score", sa.Integer(), nullable=False),
        sa.Column("total_questions", sa.Integer(), nullable=False),
        sa.Column("correct_answers", sa.Integer(), nullable=False),
        sa.Column("level_code", sa.String(), nullable=True),
        sa.Column("attempted_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("submitted_answers", sa.JSON(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_quiz_attempts_id"), "quiz_attempts", ["id"], unique=False)
    op.create_index(op.f("ix_quiz_attempts_user_id"), "quiz_attempts", ["user_id"], unique=False)
    op.create_index(op.f("ix_quiz_attempts_level_code"), "quiz_attempts", ["level_code"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_quiz_attempts_level_code"), table_name="quiz_attempts")
    op.drop_index(op.f("ix_quiz_attempts_user_id"), table_name="quiz_attempts")
    op.drop_index(op.f("ix_quiz_attempts_id"), table_name="quiz_attempts")
    op.drop_table("quiz_attempts")

    op.drop_index(op.f("ix_user_progress_lesson_id"), table_name="user_progress")
    op.drop_index(op.f("ix_user_progress_concept_id"), table_name="user_progress")
    op.drop_index(op.f("ix_user_progress_vocabulary_id"), table_name="user_progress")
    op.drop_index(op.f("ix_user_progress_user_id"), table_name="user_progress")
    op.drop_index(op.f("ix_user_progress_id"), table_name="user_progress")
    op.drop_table("user_progress")

    op.drop_index(op.f("ix_questions_concept_id"), table_name="questions")
    op.drop_index(op.f("ix_questions_vocabulary_id"), table_name="questions")
    op.drop_index(op.f("ix_questions_lesson_id"), table_name="questions")
    op.drop_index(op.f("ix_questions_id"), table_name="questions")
    op.drop_table("questions")

    op.execute("DROP TYPE IF EXISTS questiontypeenum")
