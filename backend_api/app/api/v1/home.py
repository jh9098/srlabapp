from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.dependencies import get_optional_user_identifier
from app.db.session import get_db
from app.repositories.stocks import StockRepository
from app.repositories.watchlists import WatchlistRepository
from app.schemas.common import ApiResponse
from app.schemas.stocks import HomeResponseData
from app.services.stock_view import StockViewService

router = APIRouter(tags=["home"])


@router.get("/home", response_model=ApiResponse[HomeResponseData])
def get_home(
    user_identifier: str | None = Depends(get_optional_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[HomeResponseData]:
    service = StockViewService(StockRepository(db), WatchlistRepository(db))
    data = service.get_home(user_identifier)
    return ApiResponse(message="홈 화면 데이터입니다.", data=data)
