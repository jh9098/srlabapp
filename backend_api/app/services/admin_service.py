from datetime import datetime, timezone

from sqlalchemy import delete, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from app.core.errors import AppError
from app.models.admin_audit_log import AdminAuditLog
from app.models.content_post import ContentPost
from app.models.enums import ContentCategory, MarketType, PriceLevelType, SupportStatus, ThemeRoleType
from app.models.home_featured_stock import HomeFeaturedStock
from app.models.price_level import PriceLevel
from app.models.signal_event import SignalEvent
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.models.theme import Theme
from app.models.theme_stock_map import ThemeStockMap
from app.services.audit_log_service import AuditLogService
from app.services.firebase_watchlist_writer import FirebaseWatchlistWriter
from app.services.notification_service import NotificationService


class AdminService:
    def __init__(self, db: Session, firestore_client=None) -> None:
        self.db = db
        self.audit = AuditLogService(db)
        self.notifications = NotificationService(db)
        self.firebase_watchlist_writer = (
            FirebaseWatchlistWriter(db, firestore_client) if firestore_client is not None else None
        )

    def list_dashboard(self) -> dict:
        today = datetime.now(timezone.utc).date()
        today_events = list(
            self.db.scalars(
                select(SignalEvent).where(
                    SignalEvent.event_time >= datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc)
                )
            )
        )
        return {
            "stock_count": len(list(self.db.scalars(select(Stock).where(Stock.is_active.is_(True))))),
            "signal_event_count": len(today_events),
            "invalid_count": len([e for e in today_events if e.status_to == SupportStatus.INVALID.value]),
            "reusable_count": len([e for e in today_events if e.status_to == SupportStatus.REUSABLE.value]),
            "push_queue_count": len(
                [e for e in self.db.scalars(select(AdminAuditLog).where(AdminAuditLog.action == "manual_push"))]
            ),
            "content_count": len(list(self.db.scalars(select(ContentPost).where(ContentPost.is_published.is_(True))))),
        }

    def list_stocks(self, *, query: str | None = None) -> list[Stock]:
        stmt = select(Stock)
        if query:
            normalized = query.strip()
            if normalized:
                stmt = stmt.where(or_(Stock.name.ilike(f"%{normalized}%"), Stock.code.ilike(f"%{normalized}%")))
        stmt = stmt.order_by(Stock.is_active.desc(), Stock.name.asc())
        return list(self.db.scalars(stmt))

    def upsert_stock(self, *, stock_id: int | None, payload, actor_identifier: str) -> Stock:
        stock = self.db.get(Stock, stock_id) if stock_id else None
        if stock is None:
            stock = Stock(code=payload.code)
            self.db.add(stock)
        stock.code = payload.code
        stock.name = payload.name
        stock.market_type = MarketType(payload.market_type)
        stock.sector = payload.sector
        stock.theme_tags = payload.theme_tags
        stock.operator_memo = payload.operator_memo
        stock.is_active = payload.is_active
        try:
            self.db.flush()
        except IntegrityError as exc:
            raise AppError(message="이미 등록된 종목코드입니다.", error_code="DUPLICATE_STOCK_CODE", status_code=400) from exc
        self.audit.log(
            actor_identifier=actor_identifier,
            action="upsert_stock",
            entity_type="stock",
            entity_id=str(stock.id),
            detail={"code": stock.code, "name": stock.name, "is_active": stock.is_active},
        )
        self._sync_stock_to_firebase(stock=stock, actor_identifier=actor_identifier)
        return stock

    def list_price_levels(
        self,
        *,
        stock_id: int | None = None,
        query: str | None = None,
        level_type: str | None = None,
    ) -> list[PriceLevel]:
        stmt = select(PriceLevel).options(joinedload(PriceLevel.stock))
        if stock_id is not None:
            stmt = stmt.where(PriceLevel.stock_id == stock_id)
        if level_type:
            stmt = stmt.where(PriceLevel.level_type == PriceLevelType(level_type))
        if query:
            normalized = query.strip()
            if normalized:
                stmt = stmt.join(PriceLevel.stock).where(
                    or_(Stock.name.ilike(f"%{normalized}%"), Stock.code.ilike(f"%{normalized}%"))
                )
        stmt = stmt.order_by(PriceLevel.stock_id.asc(), PriceLevel.price.asc())
        return list(self.db.execute(stmt).unique().scalars())

    def upsert_price_level(self, *, level_id: int | None, payload, actor_identifier: str) -> PriceLevel:
        level = self.db.get(PriceLevel, level_id) if level_id else None
        if level is None:
            level = PriceLevel(stock_id=payload.stock_id, level_type=PriceLevelType(payload.level_type), price=payload.price)
            self.db.add(level)
        level.stock_id = payload.stock_id
        level.level_type = PriceLevelType(payload.level_type)
        level.price = payload.price
        level.proximity_threshold_pct = payload.proximity_threshold_pct
        level.rebound_threshold_pct = payload.rebound_threshold_pct
        level.source_label = payload.source_label
        level.note = payload.note
        level.is_active = payload.is_active
        self.db.flush()
        self._ensure_waiting_support_state(level)
        self.audit.log(
            actor_identifier=actor_identifier,
            action="upsert_price_level",
            entity_type="price_level",
            entity_id=str(level.id),
            detail={"stock_id": level.stock_id, "price": str(level.price), "type": level.level_type.value},
        )
        stock = self.db.get(Stock, level.stock_id)
        if stock is not None:
            self._sync_stock_to_firebase(stock=stock, actor_identifier=actor_identifier)
        return level

    def _ensure_waiting_support_state(self, level: PriceLevel) -> None:
        if level.level_type != PriceLevelType.SUPPORT or not level.is_active:
            return

        existing_state = self.db.scalar(
            select(SupportState).where(SupportState.price_level_id == level.id)
        )
        if existing_state is not None:
            return

        self.db.add(
            SupportState(
                stock_id=level.stock_id,
                price_level_id=level.id,
                status=SupportStatus.WAITING,
                reference_price=level.price,
                last_price=level.price,
                status_reason="관리자 지지선 등록으로 생성된 초기 상태",
            )
        )
        self.db.flush()

    def list_support_states(
        self,
        *,
        status: str | None = None,
        stock_id: int | None = None,
        query: str | None = None,
    ) -> list[SupportState]:
        stmt = select(SupportState).options(joinedload(SupportState.stock), joinedload(SupportState.price_level))
        if status:
            stmt = stmt.where(SupportState.status == SupportStatus(status))
        if stock_id is not None:
            stmt = stmt.where(SupportState.stock_id == stock_id)
        if query:
            normalized = query.strip()
            if normalized:
                stmt = stmt.join(SupportState.stock).where(
                    or_(Stock.name.ilike(f"%{normalized}%"), Stock.code.ilike(f"%{normalized}%"))
                )
        stmt = stmt.order_by(SupportState.updated_at.desc())
        return list(self.db.execute(stmt).unique().scalars())

    def force_update_support_state(self, *, state_id: int, payload, actor_identifier: str) -> SupportState:
        state = self.db.get(SupportState, state_id)
        if state is None:
            raise AppError(message="지지선 상태를 찾을 수 없습니다.", error_code="STATE_NOT_FOUND", status_code=404)
        previous_status = state.status.value
        state.status = SupportStatus(payload.status)
        state.status_reason = payload.status_reason or payload.memo
        if payload.invalid_reason:
            state.invalid_reason = payload.invalid_reason
        state.last_evaluated_at = datetime.now(timezone.utc)
        self.db.flush()
        self.audit.log(
            actor_identifier=actor_identifier,
            action="force_update_support_state",
            entity_type="support_state",
            entity_id=str(state.id),
            memo=payload.memo,
            detail={"from": previous_status, "to": state.status.value},
        )
        return state

    def list_signal_events(self) -> list[SignalEvent]:
        stmt = select(SignalEvent).options(joinedload(SignalEvent.stock)).order_by(SignalEvent.event_time.desc(), SignalEvent.id.desc())
        return list(self.db.execute(stmt).unique().scalars())

    def list_home_featured(self) -> list[HomeFeaturedStock]:
        stmt = select(HomeFeaturedStock).options(joinedload(HomeFeaturedStock.stock)).order_by(HomeFeaturedStock.display_order.asc())
        return list(self.db.execute(stmt).unique().scalars())

    def replace_home_featured(self, *, items, actor_identifier: str) -> list[HomeFeaturedStock]:
        requested_by_stock_id = {item.stock_id: item for item in items}
        existing_rows = list(self.db.scalars(select(HomeFeaturedStock)))
        existing_by_stock_id = {row.stock_id: row for row in existing_rows}
        synced_stock_codes: list[str] = []

        new_items: list[HomeFeaturedStock] = []
        for stock_id, item in requested_by_stock_id.items():
            row = existing_by_stock_id.get(stock_id)
            if row is None:
                row = HomeFeaturedStock(stock_id=stock_id, display_order=item.display_order, is_active=item.is_active)
                self.db.add(row)
            else:
                row.display_order = item.display_order
                row.is_active = item.is_active
            new_items.append(row)
            stock = self.db.get(Stock, stock_id)
            if stock is not None:
                synced_stock_codes.append(stock.code)

        for stock_id, row in existing_by_stock_id.items():
            if stock_id in requested_by_stock_id:
                continue
            row.is_active = False
            stock = self.db.get(Stock, stock_id)
            if stock is not None:
                synced_stock_codes.append(stock.code)

        self.db.flush()
        self.audit.log(
            actor_identifier=actor_identifier,
            action="replace_home_featured",
            entity_type="home_featured",
            entity_id="bulk",
            detail={"count": len(new_items)},
        )
        self._sync_home_featured_to_firebase(stock_codes=synced_stock_codes, actor_identifier=actor_identifier)
        return new_items

    def list_themes(self) -> list[Theme]:
        stmt = (
            select(Theme)
            .options(joinedload(Theme.stock_maps).joinedload(ThemeStockMap.stock))
            .order_by(Theme.is_active.desc(), Theme.score.desc().nullslast(), Theme.name.asc())
        )
        return list(self.db.execute(stmt).unique().scalars())

    def upsert_theme(self, *, theme_id: int | None, payload, actor_identifier: str) -> Theme:
        theme = self.db.get(Theme, theme_id) if theme_id else None
        if theme is None:
            theme = Theme(name=payload.name)
            self.db.add(theme)
            self.db.flush()
        theme.name = payload.name
        theme.score = payload.score
        theme.summary = payload.summary
        theme.is_active = payload.is_active
        self.db.execute(delete(ThemeStockMap).where(ThemeStockMap.theme_id == theme.id))
        for item in payload.stocks:
            self.db.add(
                ThemeStockMap(
                    theme_id=theme.id,
                    stock_id=item.stock_id,
                    role_type=ThemeRoleType(item.role_type),
                    score=item.score,
                )
            )
        self.db.flush()
        self.audit.log(
            actor_identifier=actor_identifier,
            action="upsert_theme",
            entity_type="theme",
            entity_id=str(theme.id),
            detail={"name": theme.name, "stock_count": len(payload.stocks), "is_active": theme.is_active},
        )
        return theme

    def list_contents(self) -> list[ContentPost]:
        stmt = (
            select(ContentPost)
            .options(joinedload(ContentPost.stock), joinedload(ContentPost.theme))
            .order_by(ContentPost.sort_order.asc(), ContentPost.published_at.desc().nullslast(), ContentPost.id.desc())
        )
        return list(self.db.execute(stmt).unique().scalars())

    def upsert_content(self, *, content_id: int | None, payload, actor_identifier: str) -> ContentPost:
        content = self.db.get(ContentPost, content_id) if content_id else None
        if content is None:
            content = ContentPost(category=ContentCategory(payload.category), title=payload.title)
            self.db.add(content)
        content.category = ContentCategory(payload.category)
        content.title = payload.title
        content.summary = payload.summary
        content.external_url = payload.external_url
        content.thumbnail_url = payload.thumbnail_url
        content.stock_id = payload.stock_id
        content.theme_id = payload.theme_id
        content.sort_order = payload.sort_order
        content.is_published = payload.is_published
        content.published_at = payload.published_at or (datetime.now(timezone.utc) if payload.is_published else None)
        self.db.flush()
        self.audit.log(
            actor_identifier=actor_identifier,
            action="upsert_content",
            entity_type="content_post",
            entity_id=str(content.id),
            detail={
                "title": content.title,
                "category": content.category.value,
                "is_published": content.is_published,
                "sort_order": content.sort_order,
            },
        )
        return content

    def list_audit_logs(self, limit: int = 100) -> list[AdminAuditLog]:
        stmt = select(AdminAuditLog).order_by(AdminAuditLog.created_at.desc(), AdminAuditLog.id.desc()).limit(limit)
        return list(self.db.scalars(stmt))

    def send_manual_push(self, *, payload, actor_identifier: str) -> None:
        self.notifications.create_admin_notice(
            user_identifier=payload.user_identifier,
            title=payload.title,
            message=payload.message,
            target_path=payload.target_path,
        )
        self.audit.log(
            actor_identifier=actor_identifier,
            action="manual_push",
            entity_type="notification",
            entity_id=payload.user_identifier,
            memo=payload.memo,
            detail={"title": payload.title, "target_path": payload.target_path},
        )

    def _sync_stock_to_firebase(self, *, stock: Stock, actor_identifier: str) -> None:
        if self.firebase_watchlist_writer is None:
            return
        try:
            self.firebase_watchlist_writer.sync_stock(stock=stock, actor_identifier=actor_identifier)
        except AppError:
            self.db.rollback()
            raise

    def _sync_home_featured_to_firebase(self, *, stock_codes: list[str], actor_identifier: str) -> None:
        if self.firebase_watchlist_writer is None or not stock_codes:
            return
        unique_codes = list(dict.fromkeys(stock_codes))
        try:
            self.firebase_watchlist_writer.sync_home_featured_flags(
                stock_codes=unique_codes,
                actor_identifier=actor_identifier,
            )
        except AppError:
            self.db.rollback()
            raise
