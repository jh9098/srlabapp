from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.repositories.stocks import StockRepository
from app.schemas.common import ApiResponse
from app.schemas.stocks import ContentListResponseData
from app.services.stock_view import StockViewService

router = APIRouter(tags=["contents"])


@router.get('/contents', response_model=ApiResponse[ContentListResponseData])
def get_contents(
    category: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> ApiResponse[ContentListResponseData]:
    service = StockViewService(StockRepository(db))
    data = service.get_contents(category=category, limit=limit)
    return ApiResponse(message='콘텐츠 목록입니다.', data=data)
