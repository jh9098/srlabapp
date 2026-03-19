from decimal import Decimal

from sqlalchemy import Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import PriceLevelType
from app.models.mixins import ActiveMixin, TimestampMixin


class PriceLevel(TimestampMixin, ActiveMixin, Base):
    __tablename__ = "price_levels"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    stock_id: Mapped[int] = mapped_column(ForeignKey("stocks.id", ondelete="CASCADE"), nullable=False)
    level_type: Mapped[PriceLevelType] = mapped_column(
        Enum(PriceLevelType, name="price_level_type_enum"), nullable=False
    )
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    proximity_threshold_pct: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False, default=Decimal("1.50"))
    rebound_threshold_pct: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False, default=Decimal("5.00"))
    source_label: Mapped[str | None] = mapped_column(String(50), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    stock = relationship("Stock", back_populates="price_levels")
    support_states = relationship("SupportState", back_populates="price_level", cascade="all, delete-orphan")
    signal_events = relationship("SignalEvent", back_populates="price_level")
