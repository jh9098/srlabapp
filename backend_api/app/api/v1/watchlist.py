from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_required_user_identifier
from app.db.session import get_db
from app.repositories.stocks import StockRepository
from app.repositories.watchlists import WatchlistRepository
from app.schemas.common import ApiResponse
from app.schemas.watchlists import (
    WatchlistAlertUpdateRequest,
    WatchlistAlertUpdateResponseData,
    WatchlistCreateRequest,
    WatchlistCreateResponseData,
    WatchlistDeleteResponseData,
    WatchlistListResponseData,
)
from app.services.stock_view import StockViewService
from app.services.watchlist import WatchlistService

router = APIRouter(prefix="/watchlist", tags=["watchlist"])


def get_watchlist_service(db: Session) -> WatchlistService:
    stock_repository = StockRepository(db)
    watchlist_repository = WatchlistRepository(db)
    stock_view_service = StockViewService(stock_repository, watchlist_repository)
    return WatchlistService(stock_repository, watchlist_repository, stock_view_service)


@router.get("", response_model=ApiResponse[WatchlistListResponseData])
def list_watchlist(
    user_identifier: str = Depends(get_required_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[WatchlistListResponseData]:
    data = get_watchlist_service(db).list_watchlist(user_identifier)
    return ApiResponse(message="관심종목 목록입니다.", data=data)


@router.post("", response_model=ApiResponse[WatchlistCreateResponseData], status_code=status.HTTP_201_CREATED)
def create_watchlist(
    payload: WatchlistCreateRequest,
    user_identifier: str = Depends(get_required_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[WatchlistCreateResponseData]:
    data = get_watchlist_service(db).add_watchlist(
        user_identifier=user_identifier,
        stock_code=payload.stock_code,
        alert_enabled=payload.alert_enabled,
    )
    return ApiResponse(message="관심종목이 추가되었습니다.", data=data)


@router.delete("/{watchlist_id}", response_model=ApiResponse[WatchlistDeleteResponseData])
def delete_watchlist(
    watchlist_id: int,
    user_identifier: str = Depends(get_required_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[WatchlistDeleteResponseData]:
    data = get_watchlist_service(db).delete_watchlist(user_identifier=user_identifier, watchlist_id=watchlist_id)
    return ApiResponse(message="관심종목이 삭제되었습니다.", data=data)


@router.patch("/{watchlist_id}/alert", response_model=ApiResponse[WatchlistAlertUpdateResponseData])
def update_watchlist_alert(
    watchlist_id: int,
    payload: WatchlistAlertUpdateRequest,
    user_identifier: str = Depends(get_required_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[WatchlistAlertUpdateResponseData]:
    data = get_watchlist_service(db).update_alert(
        user_identifier=user_identifier,
        watchlist_id=watchlist_id,
        alert_enabled=payload.alert_enabled,
    )
    return ApiResponse(message="관심종목 알림 설정이 변경되었습니다.", data=data)
