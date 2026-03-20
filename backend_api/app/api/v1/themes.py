from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.repositories.stocks import StockRepository
from app.schemas.common import ApiResponse
from app.schemas.stocks import ThemeDetailResponseData, ThemesResponseData
from app.services.stock_view import StockViewService

router = APIRouter(tags=["themes"])


@router.get("/themes", response_model=ApiResponse[ThemesResponseData])
def get_themes(db: Session = Depends(get_db)) -> ApiResponse[ThemesResponseData]:
    service = StockViewService(StockRepository(db))
    data = service.get_themes()
    return ApiResponse(message="테마 목록입니다.", data=data)


@router.get("/themes/{theme_id}", response_model=ApiResponse[ThemeDetailResponseData])
def get_theme_detail(theme_id: int, db: Session = Depends(get_db)) -> ApiResponse[ThemeDetailResponseData]:
    service = StockViewService(StockRepository(db))
    data = service.get_theme_detail(theme_id)
    return ApiResponse(message="테마 상세 데이터입니다.", data=data)
