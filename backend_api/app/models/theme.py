from decimal import Decimal

from sqlalchemy import Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import ActiveMixin, TimestampMixin


class Theme(TimestampMixin, ActiveMixin, Base):
    __tablename__ = "themes"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    score: Mapped[Decimal | None] = mapped_column(Numeric(8, 2), nullable=True)
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)

    stock_maps = relationship("ThemeStockMap", back_populates="theme", cascade="all, delete-orphan")
    content_posts = relationship("ContentPost", back_populates="theme")
