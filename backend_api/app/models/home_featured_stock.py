from sqlalchemy import ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import ActiveMixin, TimestampMixin


class HomeFeaturedStock(TimestampMixin, ActiveMixin, Base):
    __tablename__ = "home_featured_stocks"
    __table_args__ = (UniqueConstraint("stock_id", name="uq_home_featured_stocks_stock_id"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    stock_id: Mapped[int] = mapped_column(ForeignKey("stocks.id", ondelete="CASCADE"), nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, nullable=False, default=1)

    stock = relationship("Stock", back_populates="home_featured_entries")
