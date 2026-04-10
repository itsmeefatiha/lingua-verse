"""add catalog and content tables

Revision ID: a4c3d8f7b2e1
Revises: 603443ca88e8
Create Date: 2026-04-08 10:15:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "a4c3d8f7b2e1"
down_revision: Union[str, Sequence[str], None] = "603443ca88e8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.execute("ALTER TYPE roleenum ADD VALUE IF NOT EXISTS 'ADMIN'")

    op.create_table(
        "levels",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("code", sa.Enum("A1", "A2", "B1", "B2", "C1", "C2", name="cefrlevelenum"), nullable=False),
        sa.Column("display_order", sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code"),
    )
    op.create_index(op.f("ix_levels_id"), "levels", ["id"], unique=False)

    op.create_table(
        "lessons",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("level_id", sa.Integer(), nullable=False),
        sa.Column("display_order", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["level_id"], ["levels.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_lessons_id"), "lessons", ["id"], unique=False)
    op.create_index(op.f("ix_lessons_level_id"), "lessons", ["level_id"], unique=False)

    op.create_table(
        "vocabularies",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("term", sa.String(), nullable=False),
        sa.Column("translation", sa.String(), nullable=False),
        sa.Column("example", sa.Text(), nullable=True),
        sa.Column("image_url", sa.String(), nullable=True),
        sa.Column("audio_url", sa.String(), nullable=True),
        sa.Column("lesson_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["lesson_id"], ["lessons.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_vocabularies_id"), "vocabularies", ["id"], unique=False)
    op.create_index(op.f("ix_vocabularies_lesson_id"), "vocabularies", ["lesson_id"], unique=False)

    level_table = sa.table(
        "levels",
        sa.column("code", sa.Enum("A1", "A2", "B1", "B2", "C1", "C2", name="cefrlevelenum")),
        sa.column("display_order", sa.Integer),
    )
    op.bulk_insert(
        level_table,
        [
            {"code": "A1", "display_order": 1},
            {"code": "A2", "display_order": 2},
            {"code": "B1", "display_order": 3},
            {"code": "B2", "display_order": 4},
            {"code": "C1", "display_order": 5},
            {"code": "C2", "display_order": 6},
        ],
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f("ix_vocabularies_lesson_id"), table_name="vocabularies")
    op.drop_index(op.f("ix_vocabularies_id"), table_name="vocabularies")
    op.drop_table("vocabularies")

    op.drop_index(op.f("ix_lessons_level_id"), table_name="lessons")
    op.drop_index(op.f("ix_lessons_id"), table_name="lessons")
    op.drop_table("lessons")

    op.drop_index(op.f("ix_levels_id"), table_name="levels")
    op.drop_table("levels")

    op.execute("DROP TYPE IF EXISTS cefrlevelenum")
    # PostgreSQL does not support removing a single enum value safely from roleenum.
