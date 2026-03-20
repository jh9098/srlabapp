"""add notification dispatcher delivery fields

Revision ID: 20260320_000006
Revises: 20260319_000004
Create Date: 2026-03-20 00:00:05
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260320_000006"
down_revision = "20260320_000005"
branch_labels = None
depends_on = None

notification_delivery_status_enum = postgresql.ENUM(
    "pending",
    "sending",
    "sent",
    "failed",
    "no_token",
    "skipped",
    name="notification_delivery_status_enum",
    create_type=False,
)


def upgrade() -> None:
    bind = op.get_bind()
    notification_delivery_status_enum.create(bind, checkfirst=True)

    op.add_column(
        "notifications",
        sa.Column(
            "delivery_status",
            notification_delivery_status_enum,
            nullable=False,
            server_default="pending",
        ),
    )
    op.add_column("notifications", sa.Column("response_message_id", sa.String(length=255), nullable=True))
    op.add_column("notifications", sa.Column("failure_reason", sa.Text(), nullable=True))
    op.add_column(
        "notifications",
        sa.Column("retry_count", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column("notifications", sa.Column("last_attempt_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("notifications", sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True))

    op.add_column("device_tokens", sa.Column("app_version", sa.String(length=32), nullable=True))
    op.add_column(
        "device_tokens",
        sa.Column(
            "last_seen_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )


def downgrade() -> None:
    op.drop_column("device_tokens", "last_seen_at")
    op.drop_column("device_tokens", "app_version")

    op.drop_column("notifications", "sent_at")
    op.drop_column("notifications", "last_attempt_at")
    op.drop_column("notifications", "retry_count")
    op.drop_column("notifications", "failure_reason")
    op.drop_column("notifications", "response_message_id")
    op.drop_column("notifications", "delivery_status")

    bind = op.get_bind()
    notification_delivery_status_enum.drop(bind, checkfirst=True)
