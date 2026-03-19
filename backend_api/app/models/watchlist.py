from sqlalchemy import ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import ActiveMixin, TimestampMixin


class Watchlist(TimestampMixin, ActiveMixin, Base):
    __tablename__ = "watchlists"
    __table_args__ = (
        UniqueConstraint("user_identifier", "stock_id", name="uq_watchlists_user_identifier_stock_id"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_identifier: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    stock_id: Mapped[int] = mapped_column(ForeignKey("stocks.id", ondelete="CASCADE"), nullable=False)
    notification_enabled: Mapped[bool] = mapped_column(default=True, nullable=False)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)

    stock = relationship("Stock", back_populates="watchlists")
