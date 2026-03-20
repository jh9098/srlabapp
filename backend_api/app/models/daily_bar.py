from datetime import date
from decimal import Decimal

from sqlalchemy import Date, ForeignKey, Index, Numeric, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin


class DailyBar(TimestampMixin, Base):
    __tablename__ = "daily_bars"
    __table_args__ = (
        Index("ix_daily_bars_stock_id", "stock_id"),
        Index("ix_daily_bars_trade_date", "trade_date"),
        UniqueConstraint("stock_id", "trade_date", name="uq_daily_bars_stock_id_trade_date"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    stock_id: Mapped[int] = mapped_column(ForeignKey("stocks.id", ondelete="CASCADE"), nullable=False)
    trade_date: Mapped[date] = mapped_column(Date, nullable=False)
    open_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    high_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    low_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    close_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    change_value: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False, default=Decimal("0"))
    change_pct: Mapped[Decimal] = mapped_column(Numeric(8, 2), nullable=False, default=Decimal("0"))
    volume: Mapped[int] = mapped_column(nullable=False, default=0)

    stock = relationship("Stock", back_populates="daily_bars")
