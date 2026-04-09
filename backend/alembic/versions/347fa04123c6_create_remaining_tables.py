"""create remaining tables

Revision ID: 347fa04123c6
Revises: 603443ca88e8
Create Date: 2026-04-01 22:44:04.005502

"""
from alembic import op
import sqlalchemy as sa

revision = '347fa04123c6'
down_revision = '603443ca88e8'
branch_labels = None
depends_on = None

def upgrade():
    # Add missing columns to users
    op.add_column('users', sa.Column('username', sa.String(), nullable=True))
    op.add_column('users', sa.Column('professor_code', sa.String(), nullable=True))
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)
    op.create_index(op.f('ix_users_professor_code'), 'users', ['professor_code'], unique=True)

    # Create other tables
    op.create_table('lessons',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('title', sa.String(), nullable=True),
        sa.Column('description', sa.String(), nullable=True),
        sa.Column('cefr_level', sa.String(), server_default='A1', nullable=True),
        sa.Column('is_published', sa.Boolean(), server_default='false', nullable=True),
        sa.Column('order_index', sa.Integer(), server_default='0', nullable=True),
        sa.Column('professor_id', sa.Integer(), nullable=True),
        sa.Column('content', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['professor_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_lessons_id'), 'lessons', ['id'], unique=False)
    op.create_index(op.f('ix_lessons_title'), 'lessons', ['title'], unique=False)

    op.create_table('quizzes',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('lesson_id', sa.String(), nullable=True),
        sa.Column('title', sa.String(), nullable=True),
        sa.Column('total_questions', sa.Integer(), nullable=True),
        sa.Column('professor_id', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['lesson_id'], ['lessons.id'], ),
        sa.ForeignKeyConstraint(['professor_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_quizzes_id'), 'quizzes', ['id'], unique=False)
    op.create_index(op.f('ix_quizzes_lesson_id'), 'quizzes', ['lesson_id'], unique=False)

    op.create_table('quiz_questions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('quiz_id', sa.String(), nullable=True),
        sa.Column('question_text', sa.String(), nullable=True),
        sa.Column('type', sa.String(), nullable=True),
        sa.Column('options', sa.JSON(), nullable=True),
        sa.Column('correct_answer', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['quiz_id'], ['quizzes.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    op.create_table('quiz_attempts',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('quiz_id', sa.String(), nullable=True),
        sa.Column('score', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['quiz_id'], ['quizzes.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

def downgrade():
    op.drop_table('quiz_attempts')
    op.drop_table('quiz_questions')
    op.drop_table('quizzes')
    op.drop_table('lessons')
    op.drop_index(op.f('ix_users_username'), table_name='users')
    op.drop_column('users', 'professor_code')
    op.drop_column('users', 'username')