from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import ContentCategory
from app.models.mixins import TimestampMixin


class ContentPost(TimestampMixin, Base):
    __tablename__ = "content_posts"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    category: Mapped[ContentCategory] = mapped_column(
        Enum(ContentCategory, name="content_category_enum"), nullable=False
    )
    stock_id: Mapped[int | None] = mapped_column(ForeignKey("stocks.id", ondelete="SET NULL"), nullable=True)
    theme_id: Mapped[int | None] = mapped_column(ForeignKey("themes.id", ondelete="SET NULL"), nullable=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    external_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    thumbnail_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    stock = relationship("Stock", back_populates="content_posts")
    theme = relationship("Theme", back_populates="content_posts")
