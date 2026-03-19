from app.core.errors import AppError
from app.models.enums import PriceLevelType
from app.models.watchlist import Watchlist
from app.repositories.stocks import StockRepository
from app.repositories.watchlists import WatchlistRepository
from app.schemas.watchlists import (
    PriceDistance,
    WatchlistAlertUpdateResponseData,
    WatchlistCreateResponseData,
    WatchlistDeleteResponseData,
    WatchlistItem,
    WatchlistListResponseData,
    WatchlistSummaryCounts,
)
from app.services.stock_view import StockViewService


class WatchlistService:
    def __init__(
        self,
        stock_repository: StockRepository,
        watchlist_repository: WatchlistRepository,
        stock_view_service: StockViewService,
    ) -> None:
        self.stock_repository = stock_repository
        self.watchlist_repository = watchlist_repository
        self.stock_view_service = stock_view_service

    def list_watchlist(self, user_identifier: str) -> WatchlistListResponseData:
        watchlists = self.watchlist_repository.list_by_user(user_identifier)
        items = [self._build_item(item) for item in watchlists]
        warning_count = sum(1 for item in items if item.status.severity == "warning")
        support_near_count = sum(1 for item in items if item.status.code == "TESTING_SUPPORT")
        resistance_near_count = sum(1 for item in items if item.nearest_resistance and (item.nearest_resistance.distance_pct or 100) <= 2)
        return WatchlistListResponseData(
            items=items,
            summary=WatchlistSummaryCounts(
                total_count=len(items),
                support_near_count=support_near_count,
                resistance_near_count=resistance_near_count,
                warning_count=warning_count,
            ),
        )

    def add_watchlist(self, *, user_identifier: str, stock_code: str, alert_enabled: bool) -> WatchlistCreateResponseData:
        stock = self.stock_repository.get_by_code(stock_code)
        if not stock:
            raise AppError(message="종목을 찾을 수 없습니다.", error_code="STOCK_NOT_FOUND", status_code=404)
        duplicated = self.watchlist_repository.get_by_stock(stock.id, user_identifier)
        if duplicated:
            raise AppError(message="이미 관심종목에 추가된 종목입니다.", error_code="WATCHLIST_DUPLICATED", status_code=409)
        watchlist = self.watchlist_repository.create(
            user_identifier=user_identifier,
            stock_id=stock.id,
            alert_enabled=alert_enabled,
        )
        self.watchlist_repository.db.commit()
        return WatchlistCreateResponseData(
            watchlist_id=watchlist.id,
            stock_code=stock.code,
            alert_enabled=watchlist.notification_enabled,
        )

    def delete_watchlist(self, *, user_identifier: str, watchlist_id: int) -> WatchlistDeleteResponseData:
        watchlist = self._get_watchlist_or_404(watchlist_id, user_identifier)
        self.watchlist_repository.delete(watchlist)
        self.watchlist_repository.db.commit()
        return WatchlistDeleteResponseData(deleted=True)

    def update_alert(self, *, user_identifier: str, watchlist_id: int, alert_enabled: bool) -> WatchlistAlertUpdateResponseData:
        watchlist = self._get_watchlist_or_404(watchlist_id, user_identifier)
        watchlist.notification_enabled = alert_enabled
        self.watchlist_repository.db.add(watchlist)
        self.watchlist_repository.db.commit()
        self.watchlist_repository.db.refresh(watchlist)
        return WatchlistAlertUpdateResponseData(
            watchlist_id=watchlist.id,
            alert_enabled=watchlist.notification_enabled,
        )

    def _get_watchlist_or_404(self, watchlist_id: int, user_identifier: str) -> Watchlist:
        watchlist = self.watchlist_repository.get_by_id(watchlist_id, user_identifier)
        if not watchlist:
            raise AppError(message="관심종목을 찾을 수 없습니다.", error_code="WATCHLIST_NOT_FOUND", status_code=404)
        return watchlist

    def _build_item(self, watchlist: Watchlist) -> WatchlistItem:
        detail = self.stock_view_service.get_stock_detail(watchlist.stock.code, watchlist.user_identifier)
        nearest_support = next((level for level in detail.levels if level.level_type == PriceLevelType.SUPPORT.value), None)
        nearest_resistance = next((level for level in detail.levels if level.level_type == PriceLevelType.RESISTANCE.value), None)
        return WatchlistItem(
            watchlist_id=watchlist.id,
            stock_code=detail.stock.stock_code,
            stock_name=detail.stock.stock_name,
            current_price=detail.price.current_price,
            change_pct=detail.price.change_pct,
            status=detail.status,
            nearest_support=(
                PriceDistance(price=nearest_support.level_price, distance_pct=nearest_support.distance_pct)
                if nearest_support
                else None
            ),
            nearest_resistance=(
                PriceDistance(price=nearest_resistance.level_price, distance_pct=nearest_resistance.distance_pct)
                if nearest_resistance
                else None
            ),
            summary=detail.scenario.base,
            alert_enabled=watchlist.notification_enabled,
        )
