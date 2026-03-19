from sqlalchemy import Enum, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import MarketType
from app.models.mixins import ActiveMixin, TimestampMixin


class Stock(TimestampMixin, ActiveMixin, Base):
    __tablename__ = "stocks"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(12), unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    market_type: Mapped[MarketType] = mapped_column(
        Enum(MarketType, name="market_type_enum"), nullable=False, default=MarketType.OTHER
    )
    sector: Mapped[str | None] = mapped_column(String(100), nullable=True)
    theme_tags: Mapped[str | None] = mapped_column(String(255), nullable=True)
    operator_memo: Mapped[str | None] = mapped_column(Text, nullable=True)

    price_levels = relationship("PriceLevel", back_populates="stock", cascade="all, delete-orphan")
    support_states = relationship("SupportState", back_populates="stock", cascade="all, delete-orphan")
    watchlists = relationship("Watchlist", back_populates="stock", cascade="all, delete-orphan")
