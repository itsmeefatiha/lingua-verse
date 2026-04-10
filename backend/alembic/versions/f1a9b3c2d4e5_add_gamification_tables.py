"""add gamification tables

Revision ID: f1a9b3c2d4e5
Revises: d2a8f9e1c4b7
Create Date: 2026-04-09 11:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "f1a9b3c2d4e5"
down_revision: Union[str, Sequence[str], None] = "d2a8f9e1c4b7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        DO $$
        BEGIN
            CREATE TYPE leagueenum AS ENUM ('bronze', 'argent', 'or');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
        """
    )
    op.execute(
        """
        DO $$
        BEGIN
            CREATE TYPE xpsourcetypeenum AS ENUM ('quiz_success', 'lesson_completion', 'streak_bonus', 'admin_adjustment');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
        """
    )

    op.add_column("users", sa.Column("total_xp", sa.Integer(), nullable=False, server_default=sa.text("0")))
    op.add_column("users", sa.Column("current_level", sa.Integer(), nullable=False, server_default=sa.text("1")))
    op.add_column("users", sa.Column("weekly_xp", sa.Integer(), nullable=False, server_default=sa.text("0")))
    op.add_column("users", sa.Column("current_league", postgresql.ENUM("bronze", "argent", "or", name="leagueenum", create_type=False), nullable=False, server_default=sa.text("'bronze'")))
    op.add_column("users", sa.Column("streak_count", sa.Integer(), nullable=False, server_default=sa.text("0")))
    op.add_column("users", sa.Column("last_activity_date", sa.Date(), nullable=True))

    op.create_table(
        "xp_transactions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("amount", sa.Integer(), nullable=False),
        sa.Column("source_type", postgresql.ENUM("quiz_success", "lesson_completion", "streak_bonus", "admin_adjustment", name="xpsourcetypeenum", create_type=False), nullable=False),
        sa.Column("source_ref", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "source_type", "source_ref", name="uq_xp_transaction_source"),
    )
    op.create_index(op.f("ix_xp_transactions_id"), "xp_transactions", ["id"], unique=False)
    op.create_index(op.f("ix_xp_transactions_user_id"), "xp_transactions", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_xp_transactions_user_id"), table_name="xp_transactions")
    op.drop_index(op.f("ix_xp_transactions_id"), table_name="xp_transactions")
    op.drop_table("xp_transactions")

    op.drop_column("users", "last_activity_date")
    op.drop_column("users", "streak_count")
    op.drop_column("users", "current_league")
    op.drop_column("users", "weekly_xp")
    op.drop_column("users", "current_level")
    op.drop_column("users", "total_xp")

    op.execute("DROP TYPE IF EXISTS xpsourcetypeenum")
    op.execute("DROP TYPE IF EXISTS leagueenum")
