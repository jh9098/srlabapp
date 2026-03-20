from fastapi import APIRouter

from app.api.v1.admin import router as admin_router
from app.api.v1.device_tokens import router as device_tokens_router
from app.api.v1.health import router as health_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.home import router as home_router
from app.api.v1.stocks import router as stocks_router
from app.api.v1.themes import router as themes_router
from app.api.v1.contents import router as contents_router
from app.api.v1.watchlist import router as watchlist_router

api_router = APIRouter()
api_router.include_router(health_router)
api_router.include_router(home_router)
api_router.include_router(stocks_router)
api_router.include_router(themes_router)
api_router.include_router(contents_router)
api_router.include_router(watchlist_router)

api_router.include_router(notifications_router)
api_router.include_router(device_tokens_router)
api_router.include_router(admin_router)
