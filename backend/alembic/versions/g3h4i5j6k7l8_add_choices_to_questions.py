"""add choices to questions

Revision ID: g3h4i5j6k7l8
Revises: f1a9b3c2d4e5
Create Date: 2026-04-12 09:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "g3h4i5j6k7l8"
down_revision: Union[str, Sequence[str], None] = "f1a9b3c2d4e5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("questions", sa.Column("choices", sa.JSON(), nullable=True))


def downgrade() -> None:
    op.drop_column("questions", "choices")
