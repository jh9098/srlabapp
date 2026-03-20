from __future__ import annotations

import json
import logging
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.db.session import SessionLocal
from app.integrations.firebase_admin import get_firestore_client
from app.services.firebase_sync_service import FirebaseSyncService, build_cli_parser, format_sync_summary


def main() -> int:
    parser = build_cli_parser()
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s %(message)s")

    firestore_client = get_firestore_client()
    db = SessionLocal()
    try:
        service = FirebaseSyncService(db, firestore_client)
        if args.mode == "watchlist":
            summary = {
                "watchlist": service.sync_watchlist_stocks_and_levels(
                    tickers=args.tickers,
                    dry_run=args.dry_run,
                )
            }
        elif args.mode == "prices":
            summary = {
                "prices": service.sync_daily_bars(
                    tickers=args.tickers,
                    replace_existing=args.replace_existing_bars,
                    max_bars_per_stock=args.max_bars_per_stock,
                    dry_run=args.dry_run,
                )
            }
        elif args.mode == "home-featured":
            summary = {
                "home_featured": service.sync_home_featured(
                    tickers=args.tickers,
                    enabled=True,
                    limit=args.home_featured_limit,
                    dry_run=args.dry_run,
                )
            }
        else:
            summary = service.run_full_sync(
                tickers=args.tickers,
                sync_home_featured=args.sync_home_featured,
                home_featured_limit=args.home_featured_limit,
                replace_existing_bars=args.replace_existing_bars,
                max_bars_per_stock=args.max_bars_per_stock,
                dry_run=args.dry_run,
            )
        print(format_sync_summary(summary))
        print(json.dumps(summary, ensure_ascii=False, indent=2, default=str))
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
