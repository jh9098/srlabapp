"""add admin notifications push foundation

Revision ID: 20260319_000004
Revises: 20260319_000003
Create Date: 2026-03-19 00:00:04
"""

from alembic import op
import sqlalchemy as sa


revision = "20260319_000004"
down_revision = "20260319_000003"
branch_labels = None
depends_on = None


notification_type_enum = sa.Enum(
    "PRICE_SIGNAL",
    "THEME_SIGNAL",
    "CONTENT_UPDATE",
    "ADMIN_NOTICE",
    name="notification_type_enum",
)


def upgrade() -> None:
    bind = op.get_bind()
    notification_type_enum.create(bind, checkfirst=True)

    op.create_table(
        "notifications",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_identifier", sa.String(length=128), nullable=False),
        sa.Column("stock_id", sa.Integer(), nullable=True),
        sa.Column("signal_event_id", sa.Integer(), nullable=True),
        sa.Column("notification_type", notification_type_enum, nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("target_path", sa.String(length=255), nullable=True),
        sa.Column("is_read", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("read_at", sa.String(length=64), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["signal_event_id"], ["signal_events.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["stock_id"], ["stocks.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_notifications")),
    )
    op.create_index(op.f("ix_notifications_user_identifier"), "notifications", ["user_identifier"], unique=False)

    op.create_table(
        "alert_settings",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_identifier", sa.String(length=128), nullable=False),
        sa.Column("price_signal_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("theme_signal_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("content_update_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("admin_notice_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("push_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_alert_settings")),
        sa.UniqueConstraint("user_identifier", name=op.f("uq_alert_settings_user_identifier")),
    )
    op.create_index(op.f("ix_alert_settings_user_identifier"), "alert_settings", ["user_identifier"], unique=False)

    op.create_table(
        "device_tokens",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_identifier", sa.String(length=128), nullable=False),
        sa.Column("device_token", sa.String(length=255), nullable=False),
        sa.Column("platform", sa.String(length=32), nullable=False),
        sa.Column("provider", sa.String(length=32), nullable=False),
        sa.Column("device_label", sa.String(length=100), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_device_tokens")),
        sa.UniqueConstraint("device_token", name=op.f("uq_device_tokens_device_token")),
    )
    op.create_index(op.f("ix_device_tokens_user_identifier"), "device_tokens", ["user_identifier"], unique=False)

    op.create_table(
        "admin_audit_logs",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("actor_identifier", sa.String(length=128), nullable=False),
        sa.Column("action", sa.String(length=100), nullable=False),
        sa.Column("entity_type", sa.String(length=50), nullable=False),
        sa.Column("entity_id", sa.String(length=50), nullable=False),
        sa.Column("memo", sa.Text(), nullable=True),
        sa.Column("detail_json", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_admin_audit_logs")),
    )
    op.create_index(op.f("ix_admin_audit_logs_actor_identifier"), "admin_audit_logs", ["actor_identifier"], unique=False)
    op.create_index(op.f("ix_admin_audit_logs_action"), "admin_audit_logs", ["action"], unique=False)

    op.create_table(
        "home_featured_stocks",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("stock_id", sa.Integer(), nullable=False),
        sa.Column("display_order", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["stock_id"], ["stocks.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_home_featured_stocks")),
        sa.UniqueConstraint("stock_id", name="uq_home_featured_stocks_stock_id"),
    )


def downgrade() -> None:
    op.drop_table("home_featured_stocks")
    op.drop_index(op.f("ix_admin_audit_logs_action"), table_name="admin_audit_logs")
    op.drop_index(op.f("ix_admin_audit_logs_actor_identifier"), table_name="admin_audit_logs")
    op.drop_table("admin_audit_logs")
    op.drop_index(op.f("ix_device_tokens_user_identifier"), table_name="device_tokens")
    op.drop_table("device_tokens")
    op.drop_index(op.f("ix_alert_settings_user_identifier"), table_name="alert_settings")
    op.drop_table("alert_settings")
    op.drop_index(op.f("ix_notifications_user_identifier"), table_name="notifications")
    op.drop_table("notifications")

    bind = op.get_bind()
    notification_type_enum.drop(bind, checkfirst=True)
