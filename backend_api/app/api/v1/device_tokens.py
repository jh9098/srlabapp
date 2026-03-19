from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.dependencies import get_required_user_identifier
from app.db.session import get_db
from app.models.device_token import DeviceToken
from app.schemas.common import ApiResponse

router = APIRouter(tags=["device_tokens"])


class DeviceTokenRequest(BaseModel):
    device_token: str
    platform: str
    provider: str = "stub"
    device_label: str | None = None


@router.post("/me/device-tokens", response_model=ApiResponse[dict])
def register_device_token(
    payload: DeviceTokenRequest,
    user_identifier: str = Depends(get_required_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[dict]:
    token = db.scalar(select(DeviceToken).where(DeviceToken.device_token == payload.device_token))
    if token is None:
        token = DeviceToken(device_token=payload.device_token, user_identifier=user_identifier, platform=payload.platform)
        db.add(token)
    token.user_identifier = user_identifier
    token.platform = payload.platform
    token.provider = payload.provider
    token.device_label = payload.device_label
    token.is_active = True
    db.commit()
    return ApiResponse(message="디바이스 토큰을 저장했습니다.", data={"id": token.id, "provider": token.provider})
