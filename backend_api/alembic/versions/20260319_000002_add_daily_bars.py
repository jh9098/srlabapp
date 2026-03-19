"""add daily bars table for stock detail api

Revision ID: 20260319_000002
Revises: 20260319_000001
Create Date: 2026-03-19 00:00:02
"""

from alembic import op
import sqlalchemy as sa


revision = "20260319_000002"
down_revision = "20260319_000001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "daily_bars",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("stock_id", sa.Integer(), nullable=False),
        sa.Column("trade_date", sa.Date(), nullable=False),
        sa.Column("open_price", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("high_price", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("low_price", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("close_price", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("change_value", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("change_pct", sa.Numeric(precision=8, scale=2), nullable=False),
        sa.Column("volume", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["stock_id"], ["stocks.id"], name=op.f("fk_daily_bars_stock_id_stocks"), ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_daily_bars")),
    )
    op.create_index(op.f("ix_daily_bars_stock_id"), "daily_bars", ["stock_id"], unique=False)
    op.create_index(op.f("ix_daily_bars_trade_date"), "daily_bars", ["trade_date"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_daily_bars_trade_date"), table_name="daily_bars")
    op.drop_index(op.f("ix_daily_bars_stock_id"), table_name="daily_bars")
    op.drop_table("daily_bars")
