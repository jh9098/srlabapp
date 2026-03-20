from __future__ import annotations

import argparse
import logging

from app.db.session import SessionLocal
from app.services.signal_batch_service import SignalBatchService


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="지지/저항 기반 신호 자동 생성 배치")
    parser.add_argument("--dry-run", action="store_true", help="DB 저장 없이 생성 예정 신호만 출력합니다.")
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="로그 레벨",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    logging.basicConfig(level=getattr(logging, args.log_level), format="%(levelname)s %(message)s")

    db = SessionLocal()
    try:
        service = SignalBatchService(db)
        result = service.run(dry_run=args.dry_run)
        logging.info(
            "signal batch completed scanned=%s priced=%s levels=%s events=%s notifications=%s duplicates=%s dry_run_signals=%s errors=%s",
            result.scanned_stock_count,
            result.price_resolved_count,
            result.level_checked_count,
            result.signal_event_created_count,
            result.notification_created_count,
            result.duplicate_skip_count,
            result.dry_run_signal_count,
            result.error_count,
        )
        return 0 if result.error_count == 0 else 1
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
