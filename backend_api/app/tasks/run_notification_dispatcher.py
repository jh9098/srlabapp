from __future__ import annotations

import argparse
import json

from app.db.session import SessionLocal
from app.services.notification_service import NotificationService


def main() -> None:
    parser = argparse.ArgumentParser(description="pending notification을 FCM으로 발송합니다.")
    parser.add_argument("--limit", type=int, default=50, help="한 번에 처리할 pending 알림 수")
    parser.add_argument("--max-retry-count", type=int, default=3, help="재시도 최대 횟수")
    args = parser.parse_args()

    db = SessionLocal()
    try:
        service = NotificationService(db)
        summary = service.dispatch_pending(limit=args.limit, max_retry_count=args.max_retry_count)
        db.commit()
        print(json.dumps(summary, ensure_ascii=False))
    finally:
        db.close()


if __name__ == "__main__":
    main()
