"""add support engine detail tables and home api resources

Revision ID: 20260319_000003
Revises: 20260319_000002
Create Date: 2026-03-19 00:00:03
"""

from alembic import op
import sqlalchemy as sa


revision = "20260319_000003"
down_revision = "20260319_000002"
branch_labels = None
depends_on = None


from sqlalchemy.dialects import postgresql

signal_type_enum = postgresql.ENUM(
    "SUPPORT_NEAR",
    "SUPPORT_TESTING",
    "SUPPORT_DIRECT_REBOUND_SUCCESS",
    "SUPPORT_BREAK_REBOUND_SUCCESS",
    "SUPPORT_REUSABLE",
    "SUPPORT_INVALIDATED",
    "RESISTANCE_NEAR",
    "RESISTANCE_BREAKOUT",
    "RESISTANCE_REJECTED",
    name="signal_type_enum",
    create_type=False,
)
from sqlalchemy.dialects import postgresql

theme_role_type_enum = postgresql.ENUM(
    "LEADER",
    "FOLLOWER",
    name="theme_role_type_enum",
    create_type=False,
)
content_category_enum = postgresql.ENUM(
    "STOCK_ANALYSIS",
    "THEME_BRIEF",
    "MARKET_SUMMARY",
    "SHORTS",
    "NOTICE",
    name="content_category_enum",
    create_type=False,
)


def upgrade() -> None:
    bind = op.get_bind()
    signal_type_enum.create(bind, checkfirst=True)
    theme_role_type_enum.create(bind, checkfirst=True)
    content_category_enum.create(bind, checkfirst=True)

    op.add_column("support_states", sa.Column("first_touched_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("support_states", sa.Column("last_touched_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("support_states", sa.Column("testing_low_price", sa.Numeric(12, 2), nullable=True))
    op.add_column("support_states", sa.Column("testing_high_price", sa.Numeric(12, 2), nullable=True))
    op.add_column("support_states", sa.Column("breakdown_occurred", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("support_states", sa.Column("breakdown_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("support_states", sa.Column("breakdown_low_price", sa.Numeric(12, 2), nullable=True))
    op.add_column("support_states", sa.Column("rebound_high_price", sa.Numeric(12, 2), nullable=True))
    op.add_column("support_states", sa.Column("rebound_pct", sa.Numeric(8, 2), nullable=True))
    op.add_column("support_states", sa.Column("reaction_confirmed_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("support_states", sa.Column("previous_major_high", sa.Numeric(12, 2), nullable=True))
    op.add_column("support_states", sa.Column("reusable_confirmed_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("support_states", sa.Column("invalidated_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("support_states", sa.Column("invalid_reason", sa.Text(), nullable=True))

    op.create_table(
        "themes",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("score", sa.Numeric(8, 2), nullable=True),
        sa.Column("summary", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_themes")),
        sa.UniqueConstraint("name", name=op.f("uq_themes_name")),
    )
    op.create_table(
        "theme_stock_maps",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("theme_id", sa.Integer(), nullable=False),
        sa.Column("stock_id", sa.Integer(), nullable=False),
        sa.Column("role_type", theme_role_type_enum, nullable=False),
        sa.Column("score", sa.Numeric(8, 2), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["stock_id"], ["stocks.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["theme_id"], ["themes.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_theme_stock_maps")),
        sa.UniqueConstraint("theme_id", "stock_id", name="uq_theme_stock_maps_theme_id_stock_id"),
    )
    op.create_table(
        "content_posts",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("category", content_category_enum, nullable=False),
        sa.Column("stock_id", sa.Integer(), nullable=True),
        sa.Column("theme_id", sa.Integer(), nullable=True),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("summary", sa.Text(), nullable=True),
        sa.Column("external_url", sa.Text(), nullable=True),
        sa.Column("thumbnail_url", sa.Text(), nullable=True),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["stock_id"], ["stocks.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["theme_id"], ["themes.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_content_posts")),
    )
    op.create_table(
        "signal_events",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("stock_id", sa.Integer(), nullable=False),
        sa.Column("price_level_id", sa.Integer(), nullable=True),
        sa.Column("support_state_id", sa.Integer(), nullable=True),
        sa.Column("signal_type", signal_type_enum, nullable=False),
        sa.Column("signal_key", sa.String(length=200), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("status_from", sa.String(length=50), nullable=True),
        sa.Column("status_to", sa.String(length=50), nullable=True),
        sa.Column("trigger_price", sa.Numeric(12, 2), nullable=True),
        sa.Column("event_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["price_level_id"], ["price_levels.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["stock_id"], ["stocks.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["support_state_id"], ["support_states.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_signal_events")),
        sa.UniqueConstraint("signal_key", name=op.f("uq_signal_events_signal_key")),
    )


def downgrade() -> None:
    op.drop_table("signal_events")
    op.drop_table("content_posts")
    op.drop_table("theme_stock_maps")
    op.drop_table("themes")

    for column in [
        "invalid_reason",
        "invalidated_at",
        "reusable_confirmed_at",
        "previous_major_high",
        "reaction_confirmed_at",
        "rebound_pct",
        "rebound_high_price",
        "breakdown_low_price",
        "breakdown_at",
        "breakdown_occurred",
        "testing_high_price",
        "testing_low_price",
        "last_touched_at",
        "first_touched_at",
    ]:
        op.drop_column("support_states", column)

    bind = op.get_bind()
    content_category_enum.drop(bind, checkfirst=True)
    theme_role_type_enum.drop(bind, checkfirst=True)
    signal_type_enum.drop(bind, checkfirst=True)
