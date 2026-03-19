from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, Text
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

    stock = relationship("Stock", back_populates="support_states")
    price_level = relationship("PriceLevel", back_populates="support_states")
