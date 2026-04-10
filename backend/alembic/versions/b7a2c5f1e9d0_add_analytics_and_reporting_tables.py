"""add analytics and reporting tables

Revision ID: b7a2c5f1e9d0
Revises: f1a9b3c2d4e5
Create Date: 2026-04-09 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b7a2c5f1e9d0"
down_revision: Union[str, Sequence[str], None] = "f1a9b3c2d4e5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("vocabularies", sa.Column("category", sa.String(), nullable=True))
    op.create_index(op.f("ix_vocabularies_category"), "vocabularies", ["category"], unique=False)

    op.add_column("quiz_attempts", sa.Column("language_code", sa.String(), nullable=True))
    op.add_column("quiz_attempts", sa.Column("duration_seconds", sa.Integer(), nullable=True))
    op.create_index(op.f("ix_quiz_attempts_language_code"), "quiz_attempts", ["language_code"], unique=False)

    op.create_table(
        "listening_sessions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("language_code", sa.String(), nullable=False),
        sa.Column("duration_seconds", sa.Integer(), nullable=False),
        sa.Column("source_type", sa.String(), nullable=True),
        sa.Column("source_ref", sa.String(), nullable=True),
        sa.Column("listened_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_listening_sessions_id"), "listening_sessions", ["id"], unique=False)
    op.create_index(op.f("ix_listening_sessions_user_id"), "listening_sessions", ["user_id"], unique=False)
    op.create_index(op.f("ix_listening_sessions_language_code"), "listening_sessions", ["language_code"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_listening_sessions_language_code"), table_name="listening_sessions")
    op.drop_index(op.f("ix_listening_sessions_user_id"), table_name="listening_sessions")
    op.drop_index(op.f("ix_listening_sessions_id"), table_name="listening_sessions")
    op.drop_table("listening_sessions")

    op.drop_index(op.f("ix_quiz_attempts_language_code"), table_name="quiz_attempts")
    op.drop_column("quiz_attempts", "duration_seconds")
    op.drop_column("quiz_attempts", "language_code")

    op.drop_index(op.f("ix_vocabularies_category"), table_name="vocabularies")
    op.drop_column("vocabularies", "category")
