from decimal import Decimal

from sqlalchemy import Enum, ForeignKey, Numeric, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import ThemeRoleType
from app.models.mixins import TimestampMixin


class ThemeStockMap(TimestampMixin, Base):
    __tablename__ = "theme_stock_maps"
    __table_args__ = (UniqueConstraint("theme_id", "stock_id", name="uq_theme_stock_maps_theme_id_stock_id"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    theme_id: Mapped[int] = mapped_column(ForeignKey("themes.id", ondelete="CASCADE"), nullable=False)
    stock_id: Mapped[int] = mapped_column(ForeignKey("stocks.id", ondelete="CASCADE"), nullable=False)
    role_type: Mapped[ThemeRoleType] = mapped_column(
        Enum(ThemeRoleType, name="theme_role_type_enum"), nullable=False, default=ThemeRoleType.FOLLOWER
    )
    score: Mapped[Decimal | None] = mapped_column(Numeric(8, 2), nullable=True)

    theme = relationship("Theme", back_populates="stock_maps")
    stock = relationship("Stock", back_populates="theme_maps")
