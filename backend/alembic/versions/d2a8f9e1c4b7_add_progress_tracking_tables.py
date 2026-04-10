"""add progress tracking tables

Revision ID: d2a8f9e1c4b7
Revises: c9f7d2e1b8a4
Create Date: 2026-04-09 10:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "d2a8f9e1c4b7"
down_revision: Union[str, Sequence[str], None] = "c9f7d2e1b8a4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        DO $$
        BEGIN
            CREATE TYPE progressstatusenum AS ENUM ('in_progress', 'completed');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
        """
    )

    op.create_table(
        "user_viewed_vocab",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("vocabulary_id", sa.Integer(), nullable=False),
        sa.Column("viewed_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["vocabulary_id"], ["vocabularies.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "vocabulary_id", name="uq_user_viewed_vocab_user_vocab"),
    )
    op.create_index(op.f("ix_user_viewed_vocab_id"), "user_viewed_vocab", ["id"], unique=False)
    op.create_index(op.f("ix_user_viewed_vocab_user_id"), "user_viewed_vocab", ["user_id"], unique=False)
    op.create_index(op.f("ix_user_viewed_vocab_vocabulary_id"), "user_viewed_vocab", ["vocabulary_id"], unique=False)

    op.create_table(
        "user_lesson_progress",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("lesson_id", sa.Integer(), nullable=False),
        sa.Column("status", postgresql.ENUM("in_progress", "completed", name="progressstatusenum", create_type=False), nullable=False),
        sa.Column("last_score", sa.Integer(), nullable=True),
        sa.Column("last_activity_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["lesson_id"], ["lessons.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "lesson_id", name="uq_user_lesson_progress_user_lesson"),
    )
    op.create_index(op.f("ix_user_lesson_progress_id"), "user_lesson_progress", ["id"], unique=False)
    op.create_index(op.f("ix_user_lesson_progress_user_id"), "user_lesson_progress", ["user_id"], unique=False)
    op.create_index(op.f("ix_user_lesson_progress_lesson_id"), "user_lesson_progress", ["lesson_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_user_lesson_progress_lesson_id"), table_name="user_lesson_progress")
    op.drop_index(op.f("ix_user_lesson_progress_user_id"), table_name="user_lesson_progress")
    op.drop_index(op.f("ix_user_lesson_progress_id"), table_name="user_lesson_progress")
    op.drop_table("user_lesson_progress")
    op.execute("DROP TYPE IF EXISTS progressstatusenum")

    op.drop_index(op.f("ix_user_viewed_vocab_vocabulary_id"), table_name="user_viewed_vocab")
    op.drop_index(op.f("ix_user_viewed_vocab_user_id"), table_name="user_viewed_vocab")
    op.drop_index(op.f("ix_user_viewed_vocab_id"), table_name="user_viewed_vocab")
    op.drop_table("user_viewed_vocab")
