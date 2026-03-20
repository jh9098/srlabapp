from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1.health import build_health_payload
from app.api.v1.router import api_router
from app.core.config import get_settings
from app.core.errors import AppError
from app.schemas.common import ErrorResponse

settings = get_settings()

app = FastAPI(title=settings.app_name, debug=settings.app_debug, version=settings.app_version)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_origin_regex=settings.cors_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.api_v1_prefix)


@app.exception_handler(AppError)
async def handle_app_error(_: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            message=exc.message,
            error_code=exc.error_code,
        ).model_dump(),
    )


@app.exception_handler(RequestValidationError)
async def handle_validation_error(_: Request, exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(
        status_code=422,
        content=ErrorResponse(
            message="요청 값이 올바르지 않습니다.",
            error_code="VALIDATION_ERROR",
        ).model_dump(),
    )


@app.get("/")
def root() -> dict[str, str]:
    return {"message": f"{settings.app_name} is running", "environment": settings.app_env}


@app.get("/health")
def root_health() -> dict[str, object]:
    return build_health_payload()
