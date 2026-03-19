from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Numeric, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import SupportStatus
from app.models.mixins import TimestampMixin


class SupportState(TimestampMixin, Base):
    __tablename__ = "support_states"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    stock_id: Mapped[int] = mapped_column(ForeignKey("stocks.id", ondelete="CASCADE"), nullable=False)
    price_level_id: Mapped[int] = mapped_column(
        ForeignKey("price_levels.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[SupportStatus] = mapped_column(
        Enum(SupportStatus, name="support_status_enum"), nullable=False, default=SupportStatus.WAITING
    )
    reference_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    last_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    last_evaluated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    first_touched_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_touched_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    testing_low_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    testing_high_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    breakdown_occurred: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    breakdown_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    breakdown_low_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    rebound_high_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    rebound_pct: Mapped[Decimal | None] = mapped_column(Numeric(8, 2), nullable=True)
    reaction_confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    previous_major_high: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    reusable_confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    invalidated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    invalid_reason: Mapped[str | None] = mapped_column(Text, nullable=True)

    stock = relationship("Stock", back_populates="support_states")
    price_level = relationship("PriceLevel", back_populates="support_states")
    signal_events = relationship("SignalEvent", back_populates="support_state")
