from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import SignalType
from app.models.mixins import TimestampMixin


class SignalEvent(TimestampMixin, Base):
    __tablename__ = "signal_events"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    stock_id: Mapped[int] = mapped_column(ForeignKey("stocks.id", ondelete="CASCADE"), nullable=False)
    price_level_id: Mapped[int | None] = mapped_column(
        ForeignKey("price_levels.id", ondelete="CASCADE"), nullable=True
    )
    support_state_id: Mapped[int | None] = mapped_column(
        ForeignKey("support_states.id", ondelete="SET NULL"), nullable=True
    )
    signal_type: Mapped[SignalType] = mapped_column(
        Enum(SignalType, name="signal_type_enum"), nullable=False
    )
    signal_key: Mapped[str] = mapped_column(String(200), nullable=False, unique=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    status_from: Mapped[str | None] = mapped_column(String(50), nullable=True)
    status_to: Mapped[str | None] = mapped_column(String(50), nullable=True)
    trigger_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    event_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    stock = relationship("Stock", back_populates="signal_events")
    price_level = relationship("PriceLevel", back_populates="signal_events")
    support_state = relationship("SupportState", back_populates="signal_events")
    notifications = relationship("Notification", back_populates="signal_event")
