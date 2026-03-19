from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.dependencies import get_optional_user_identifier
from app.db.session import get_db
from app.repositories.stocks import StockRepository
from app.repositories.watchlists import WatchlistRepository
from app.schemas.common import ApiResponse
from app.schemas.stocks import StockDetailResponseData, StockSearchResponseData, StockSignalsResponseData
from app.services.stock_view import StockViewService

router = APIRouter(prefix="/stocks", tags=["stocks"])


@router.get("/search", response_model=ApiResponse[StockSearchResponseData])
def search_stocks(
    q: str = Query(..., min_length=1),
    db: Session = Depends(get_db),
) -> ApiResponse[StockSearchResponseData]:
    service = StockViewService(StockRepository(db), WatchlistRepository(db))
    data = service.search_stocks(q)
    return ApiResponse(message="종목 검색 결과입니다.", data=data)


@router.get("/{stock_code}", response_model=ApiResponse[StockDetailResponseData])
def get_stock_detail(
    stock_code: str,
    user_identifier: str | None = Depends(get_optional_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[StockDetailResponseData]:
    service = StockViewService(StockRepository(db), WatchlistRepository(db))
    data = service.get_stock_detail(stock_code, user_identifier)
    return ApiResponse(message="종목 상세 데이터입니다.", data=data)


@router.get("/{stock_code}/signals", response_model=ApiResponse[StockSignalsResponseData])
def get_stock_signals(
    stock_code: str,
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> ApiResponse[StockSignalsResponseData]:
    service = StockViewService(StockRepository(db), WatchlistRepository(db))
    data = service.get_stock_signals(stock_code, limit=limit)
    return ApiResponse(message="종목 신호 이벤트 목록입니다.", data=data)
