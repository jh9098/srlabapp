from sqlalchemy import Boolean, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.mixins import TimestampMixin


class AlertSetting(TimestampMixin, Base):
    __tablename__ = "alert_settings"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_identifier: Mapped[str] = mapped_column(String(128), unique=True, index=True, nullable=False)
    price_signal_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    theme_signal_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    content_update_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    admin_notice_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    push_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
