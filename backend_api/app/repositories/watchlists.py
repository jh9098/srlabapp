from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session, joinedload

from app.models.stock import Stock
from app.models.support_state import SupportState
from app.models.watchlist import Watchlist


class WatchlistRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_by_user(self, user_identifier: str) -> list[Watchlist]:
        stmt: Select[tuple[Watchlist]] = (
            select(Watchlist)
            .options(
                joinedload(Watchlist.stock).joinedload(Stock.price_levels),
                joinedload(Watchlist.stock).joinedload(Stock.support_states).joinedload(SupportState.price_level),
                joinedload(Watchlist.stock).joinedload(Stock.daily_bars),
            )
            .where(Watchlist.user_identifier == user_identifier, Watchlist.is_active.is_(True))
            .order_by(Watchlist.created_at.desc())
        )
        return list(self.db.execute(stmt).unique().scalars())

    def get_by_id(self, watchlist_id: int, user_identifier: str) -> Watchlist | None:
        stmt = (
            select(Watchlist)
            .options(joinedload(Watchlist.stock))
            .where(
                Watchlist.id == watchlist_id,
                Watchlist.user_identifier == user_identifier,
                Watchlist.is_active.is_(True),
            )
        )
        return self.db.execute(stmt).unique().scalar_one_or_none()

    def get_by_stock(self, stock_id: int, user_identifier: str) -> Watchlist | None:
        stmt = select(Watchlist).where(
            Watchlist.stock_id == stock_id,
            Watchlist.user_identifier == user_identifier,
            Watchlist.is_active.is_(True),
        )
        return self.db.scalar(stmt)

    def create(self, *, user_identifier: str, stock_id: int, alert_enabled: bool, memo: str | None = None) -> Watchlist:
        watchlist = Watchlist(
            user_identifier=user_identifier,
            stock_id=stock_id,
            notification_enabled=alert_enabled,
            memo=memo,
        )
        self.db.add(watchlist)
        self.db.flush()
        self.db.refresh(watchlist)
        return watchlist

    def delete(self, watchlist: Watchlist) -> None:
        self.db.delete(watchlist)

    def count_by_user(self, user_identifier: str) -> int:
        stmt = select(func.count(Watchlist.id)).where(
            Watchlist.user_identifier == user_identifier,
            Watchlist.is_active.is_(True),
        )
        return int(self.db.scalar(stmt) or 0)
