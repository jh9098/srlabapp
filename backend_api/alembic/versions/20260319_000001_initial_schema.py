"""initial schema for backend scaffold

Revision ID: 20260319_000001
Revises: 
Create Date: 2026-03-19 00:00:01
"""

from alembic import op
import sqlalchemy as sa


revision = "20260319_000001"
down_revision = None
branch_labels = None
depends_on = None


market_type_enum = sa.Enum("KOSPI", "KOSDAQ", "ETF", "ETN", "OTHER", name="market_type_enum")
price_level_type_enum = sa.Enum("SUPPORT", "RESISTANCE", name="price_level_type_enum")
support_status_enum = sa.Enum(
    "WAITING",
    "TESTING_SUPPORT",
    "DIRECT_REBOUND_SUCCESS",
    "BREAK_REBOUND_SUCCESS",
    "REUSABLE",
    "INVALID",
    name="support_status_enum",
)


def upgrade() -> None:
    bind = op.get_bind()
    market_type_enum.create(bind, checkfirst=True)
    price_level_type_enum.create(bind, checkfirst=True)
    support_status_enum.create(bind, checkfirst=True)

    op.create_table(
        "stocks",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("code", sa.String(length=12), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("market_type", market_type_enum, nullable=False),
        sa.Column("sector", sa.String(length=100), nullable=True),
        sa.Column("theme_tags", sa.String(length=255), nullable=True),
        sa.Column("operator_memo", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_stocks")),
        sa.UniqueConstraint("code", name=op.f("uq_stocks_code")),
    )
    op.create_index(op.f("ix_stocks_code"), "stocks", ["code"], unique=False)
    op.create_index(op.f("ix_stocks_name"), "stocks", ["name"], unique=False)

    op.create_table(
        "price_levels",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("stock_id", sa.Integer(), nullable=False),
        sa.Column("level_type", price_level_type_enum, nullable=False),
        sa.Column("price", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("proximity_threshold_pct", sa.Numeric(precision=5, scale=2), nullable=False),
        sa.Column("rebound_threshold_pct", sa.Numeric(precision=5, scale=2), nullable=False),
        sa.Column("source_label", sa.String(length=50), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["stock_id"], ["stocks.id"], name=op.f("fk_price_levels_stock_id_stocks"), ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_price_levels")),
    )

    op.create_table(
        "support_states",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("stock_id", sa.Integer(), nullable=False),
        sa.Column("price_level_id", sa.Integer(), nullable=False),
        sa.Column("status", support_status_enum, nullable=False),
        sa.Column("reference_price", sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column("last_price", sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column("last_evaluated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status_reason", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["price_level_id"], ["price_levels.id"], name=op.f("fk_support_states_price_level_id_price_levels"), ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["stock_id"], ["stocks.id"], name=op.f("fk_support_states_stock_id_stocks"), ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_support_states")),
    )

    op.create_table(
        "watchlists",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_identifier", sa.String(length=128), nullable=False),
        sa.Column("stock_id", sa.Integer(), nullable=False),
        sa.Column("notification_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("memo", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["stock_id"], ["stocks.id"], name=op.f("fk_watchlists_stock_id_stocks"), ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_watchlists")),
        sa.UniqueConstraint("user_identifier", "stock_id", name="uq_watchlists_user_identifier_stock_id"),
    )
    op.create_index(op.f("ix_watchlists_user_identifier"), "watchlists", ["user_identifier"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_watchlists_user_identifier"), table_name="watchlists")
    op.drop_table("watchlists")
    op.drop_table("support_states")
    op.drop_table("price_levels")
    op.drop_index(op.f("ix_stocks_name"), table_name="stocks")
    op.drop_index(op.f("ix_stocks_code"), table_name="stocks")
    op.drop_table("stocks")

    bind = op.get_bind()
    support_status_enum.drop(bind, checkfirst=True)
    price_level_type_enum.drop(bind, checkfirst=True)
    market_type_enum.drop(bind, checkfirst=True)
