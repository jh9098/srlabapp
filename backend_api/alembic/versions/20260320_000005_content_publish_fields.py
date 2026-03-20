"""add content publish fields

Revision ID: 20260320_000005
Revises: 20260319_000004
Create Date: 2026-03-20 00:05:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260320_000005"
down_revision = "20260319_000004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "content_posts",
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default=sa.text("0")),
    )
    op.add_column(
        "content_posts",
        sa.Column("is_published", sa.Boolean(), nullable=False, server_default=sa.true()),
    )

    bind = op.get_bind()
    if bind.dialect.name != "sqlite":
        op.alter_column("content_posts", "sort_order", server_default=None)
        op.alter_column("content_posts", "is_published", server_default=None)


def downgrade() -> None:
    op.drop_column("content_posts", "is_published")
    op.drop_column("content_posts", "sort_order")