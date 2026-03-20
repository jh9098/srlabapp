"""add unique constraint to daily bars stock/date

Revision ID: 20260320_000007
Revises: 20260320_000006
Create Date: 2026-03-20 00:00:07
"""

from alembic import op
import sqlalchemy as sa


revision = "20260320_000007"
down_revision = "20260320_000006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_unique_constraint(
        "uq_daily_bars_stock_id_trade_date",
        "daily_bars",
        ["stock_id", "trade_date"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_daily_bars_stock_id_trade_date",
        "daily_bars",
        type_="unique",
    )
