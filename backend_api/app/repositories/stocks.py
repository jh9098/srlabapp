from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session, joinedload

from app.models.content_post import ContentPost
from app.models.daily_bar import DailyBar
from app.models.price_level import PriceLevel
from app.models.enums import SupportStatus
from app.models.signal_event import SignalEvent
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.models.theme import Theme
from app.models.theme_stock_map import ThemeStockMap
from app.models.watchlist import Watchlist


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
                joinedload(Stock.theme_maps).joinedload(ThemeStockMap.theme),
                joinedload(Stock.content_posts),
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

    def list_signal_events(self, stock_id: int, limit: int = 20) -> list[SignalEvent]:
        stmt = (
            select(SignalEvent)
            .where(SignalEvent.stock_id == stock_id)
            .order_by(SignalEvent.event_time.desc(), SignalEvent.id.desc())
            .limit(limit)
        )
        return list(self.db.scalars(stmt))

    def list_featured_stocks(self, limit: int = 5) -> list[Stock]:
        subquery = (
            select(SupportState.stock_id, func.max(SupportState.last_evaluated_at).label("last_eval"))
            .group_by(SupportState.stock_id)
            .subquery()
        )
        stmt = (
            select(Stock)
            .join(subquery, subquery.c.stock_id == Stock.id)
            .options(
                joinedload(Stock.daily_bars),
                joinedload(Stock.support_states),
            )
            .where(Stock.is_active.is_(True))
            .order_by(subquery.c.last_eval.desc())
            .limit(limit)
        )
        return list(self.db.execute(stmt).unique().scalars())

    def list_themes(self, limit: int = 20) -> list[Theme]:
        stmt = (
            select(Theme)
            .options(
                joinedload(Theme.stock_maps).joinedload(ThemeStockMap.stock),
            )
            .where(Theme.is_active.is_(True))
            .order_by(Theme.score.desc().nullslast(), Theme.id.asc())
            .limit(limit)
        )
        return list(self.db.execute(stmt).unique().scalars())

    def list_recent_contents(self, limit: int = 4) -> list[ContentPost]:
        stmt = (
            select(ContentPost)
            .options(
                joinedload(ContentPost.stock),
                joinedload(ContentPost.theme),
            )
            .order_by(ContentPost.published_at.desc().nullslast(), ContentPost.id.desc())
            .limit(limit)
        )
        return list(self.db.execute(stmt).unique().scalars())

    def count_watchlist_signal_summary(self, user_identifier: str | None) -> dict[str, int]:
        base = {"support_near_count": 0, "resistance_near_count": 0, "warning_count": 0}
        if not user_identifier:
            return base
        stmt = (
            select(Watchlist, Stock, SupportState)
            .join(Stock, Watchlist.stock_id == Stock.id)
            .join(SupportState, SupportState.stock_id == Stock.id)
            .where(Watchlist.user_identifier == user_identifier, Watchlist.is_active.is_(True))
        )
        rows = self.db.execute(stmt).all()
        seen_stock_ids: set[int] = set()
        for _watchlist, stock, support_state in rows:
            if stock.id in seen_stock_ids:
                continue
            seen_stock_ids.add(stock.id)
            if support_state.status == SupportStatus.TESTING_SUPPORT:
                base["support_near_count"] += 1
            elif support_state.status == SupportStatus.INVALID:
                base["warning_count"] += 1
        return base
