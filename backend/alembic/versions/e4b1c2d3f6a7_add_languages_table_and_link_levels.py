"""add languages table and link levels

Revision ID: e4b1c2d3f6a7
Revises: b7a2c5f1e9d0
Create Date: 2026-04-12 17:15:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "e4b1c2d3f6a7"
down_revision: Union[str, Sequence[str], None] = "b7a2c5f1e9d0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "languages",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("code", sa.String(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
        sa.UniqueConstraint("code"),
    )
    op.create_index(op.f("ix_languages_id"), "languages", ["id"], unique=False)
    op.create_index(op.f("ix_languages_code"), "languages", ["code"], unique=False)

    op.execute(
        """
        INSERT INTO languages (name, code)
        VALUES
            ('English', 'en'),
            ('French', 'fr'),
            ('Spanish', 'es'),
            ('German', 'de'),
            ('Arabic', 'ar')
        ON CONFLICT (code) DO NOTHING
        """
    )

    op.add_column("levels", sa.Column("language_id", sa.Integer(), nullable=True))

    op.execute(
        """
        UPDATE levels
        SET language_id = l.id
        FROM languages l
        WHERE l.code = 'en' AND levels.language_id IS NULL
        """
    )

    op.alter_column("levels", "language_id", nullable=False)
    op.create_foreign_key(
        "fk_levels_language_id_languages",
        "levels",
        "languages",
        ["language_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_index(op.f("ix_levels_language_id"), "levels", ["language_id"], unique=False)

    op.execute(
        """
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM information_schema.table_constraints
                WHERE table_name = 'levels'
                  AND constraint_name = 'levels_code_key'
                  AND constraint_type = 'UNIQUE'
            ) THEN
                ALTER TABLE levels DROP CONSTRAINT levels_code_key;
            END IF;
        END $$;
        """
    )

    op.create_unique_constraint(
        "uq_levels_language_code",
        "levels",
        ["language_id", "code"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_levels_language_code", "levels", type_="unique")
    op.create_unique_constraint("levels_code_key", "levels", ["code"])

    op.drop_index(op.f("ix_levels_language_id"), table_name="levels")
    op.drop_constraint("fk_levels_language_id_languages", "levels", type_="foreignkey")
    op.drop_column("levels", "language_id")

    op.drop_index(op.f("ix_languages_code"), table_name="languages")
    op.drop_index(op.f("ix_languages_id"), table_name="languages")
    op.drop_table("languages")
