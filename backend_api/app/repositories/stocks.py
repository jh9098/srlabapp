from sqlalchemy import Select, select
from sqlalchemy.orm import Session, joinedload

from app.models.daily_bar import DailyBar
from app.models.price_level import PriceLevel
from app.models.stock import Stock
from app.models.support_state import SupportState


class StockRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def search(self, query: str, limit: int = 20) -> list[Stock]:
        stmt: Select[tuple[Stock]] = (
            select(Stock)
            .where(Stock.is_active.is_(True))
            .where((Stock.name.ilike(f"%{query}%")) | (Stock.code.ilike(f"%{query}%")))
            .order_by(Stock.name.asc())
            .limit(limit)
        )
        return list(self.db.scalars(stmt))

    def get_by_code(self, stock_code: str) -> Stock | None:
        stmt = (
            select(Stock)
            .options(
                joinedload(Stock.price_levels),
                joinedload(Stock.support_states).joinedload(SupportState.price_level),
                joinedload(Stock.daily_bars),
                joinedload(Stock.watchlists),
            )
            .where(Stock.code == stock_code, Stock.is_active.is_(True))
        )
        return self.db.execute(stmt).unique().scalar_one_or_none()

    def get_price_levels(self, stock_id: int) -> list[PriceLevel]:
        stmt = (
            select(PriceLevel)
            .where(PriceLevel.stock_id == stock_id, PriceLevel.is_active.is_(True))
            .order_by(PriceLevel.level_type.asc(), PriceLevel.price.asc())
        )
        return list(self.db.scalars(stmt))

    def get_latest_daily_bar(self, stock_id: int) -> DailyBar | None:
        stmt = (
            select(DailyBar)
            .where(DailyBar.stock_id == stock_id)
            .order_by(DailyBar.trade_date.desc())
            .limit(1)
        )
        return self.db.scalar(stmt)
