"""cleanup roles to user admin

Revision ID: h1a2b3c4d5e6f
Revises: h8k1m2n3p4q5
Create Date: 2026-04-14 09:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "h1a2b3c4d5e6f"
down_revision: Union[str, Sequence[str], None] = "h8k1m2n3p4q5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        CREATE TYPE roleenum_new AS ENUM ('user', 'admin');
        """
    )

    op.execute(
        """
        ALTER TABLE users
        ALTER COLUMN role DROP DEFAULT
        """
    )

    op.execute(
        """
        ALTER TABLE users
        ALTER COLUMN role TYPE roleenum_new
        USING (
            CASE
                WHEN upper(role::text) = 'ADMIN' THEN 'admin'
                ELSE 'user'
            END
        )::roleenum_new
        """
    )

    op.execute("DROP TYPE roleenum")
    op.execute("ALTER TYPE roleenum_new RENAME TO roleenum")
    op.execute("ALTER TABLE users ALTER COLUMN role SET DEFAULT 'user'")
    op.execute("ALTER TABLE users ALTER COLUMN role SET NOT NULL")


def downgrade() -> None:
    op.execute(
        """
        CREATE TYPE roleenum_old AS ENUM ('STUDENT', 'TEACHER', 'ADMIN');
        """
    )

    op.execute("ALTER TABLE users ALTER COLUMN role DROP DEFAULT")
    op.execute(
        """
        ALTER TABLE users
        ALTER COLUMN role TYPE roleenum_old
        USING (
            CASE
                WHEN role::text = 'admin' THEN 'ADMIN'
                ELSE 'STUDENT'
            END
        )::roleenum_old
        """
    )
    op.execute("DROP TYPE roleenum")
    op.execute("ALTER TYPE roleenum_old RENAME TO roleenum")
    op.execute("ALTER TABLE users ALTER COLUMN role SET DEFAULT 'STUDENT'")
    op.execute("ALTER TABLE users ALTER COLUMN role SET NOT NULL")
