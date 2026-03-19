from fastapi import APIRouter

from app.api.v1.health import router as health_router
from app.api.v1.home import router as home_router
from app.api.v1.stocks import router as stocks_router
from app.api.v1.themes import router as themes_router
from app.api.v1.watchlist import router as watchlist_router

api_router = APIRouter()
api_router.include_router(health_router)
api_router.include_router(home_router)
api_router.include_router(stocks_router)
api_router.include_router(themes_router)
api_router.include_router(watchlist_router)
