from datetime import datetime, timezone

from sqlalchemy import delete, select
from sqlalchemy.orm import Session, joinedload

from app.core.errors import AppError
from app.models.admin_audit_log import AdminAuditLog
from app.models.enums import MarketType, PriceLevelType, SupportStatus, ThemeRoleType
from app.models.home_featured_stock import HomeFeaturedStock
from app.models.price_level import PriceLevel
from app.models.signal_event import SignalEvent
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.models.theme import Theme
from app.models.theme_stock_map import ThemeStockMap
from app.services.audit_log_service import AuditLogService
from app.services.notification_service import NotificationService


class AdminService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.audit = AuditLogService(db)
        self.notifications = NotificationService(db)

    def list_dashboard(self) -> dict:
        today = datetime.now(timezone.utc).date()
        today_events = list(
            self.db.scalars(
                select(SignalEvent).where(SignalEvent.event_time >= datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc))
            )
        )
        return {
            "stock_count": len(list(self.db.scalars(select(Stock).where(Stock.is_active.is_(True))))),
            "signal_event_count": len(today_events),
            "invalid_count": len([e for e in today_events if e.status_to == SupportStatus.INVALID.value]),
            "reusable_count": len([e for e in today_events if e.status_to == SupportStatus.REUSABLE.value]),
            "push_queue_count": len([e for e in self.db.scalars(select(AdminAuditLog).where(AdminAuditLog.action == "manual_push"))]),
        }

    def list_stocks(self) -> list[Stock]:
        return list(self.db.scalars(select(Stock).order_by(Stock.is_active.desc(), Stock.name.asc())))

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
        self.db.flush()
        self.audit.log(
            actor_identifier=actor_identifier,
            action="upsert_stock",
            entity_type="stock",
            entity_id=str(stock.id),
            detail={"code": stock.code, "name": stock.name, "is_active": stock.is_active},
        )
        return stock

    def list_price_levels(self) -> list[PriceLevel]:
        stmt = select(PriceLevel).options(joinedload(PriceLevel.stock)).order_by(PriceLevel.stock_id.asc(), PriceLevel.price.asc())
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
        self.audit.log(
            actor_identifier=actor_identifier,
            action="upsert_price_level",
            entity_type="price_level",
            entity_id=str(level.id),
            detail={"stock_id": level.stock_id, "price": str(level.price), "type": level.level_type.value},
        )
        return level

    def list_support_states(self) -> list[SupportState]:
        stmt = select(SupportState).options(joinedload(SupportState.stock), joinedload(SupportState.price_level)).order_by(SupportState.updated_at.desc())
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
        self.db.execute(delete(HomeFeaturedStock))
        new_items: list[HomeFeaturedStock] = []
        for item in items:
            row = HomeFeaturedStock(stock_id=item.stock_id, display_order=item.display_order, is_active=item.is_active)
            self.db.add(row)
            new_items.append(row)
        self.db.flush()
        self.audit.log(
            actor_identifier=actor_identifier,
            action="replace_home_featured",
            entity_type="home_featured",
            entity_id="bulk",
            detail={"count": len(new_items)},
        )
        return new_items

    def list_themes(self) -> list[Theme]:
        stmt = select(Theme).options(joinedload(Theme.stock_maps).joinedload(ThemeStockMap.stock)).order_by(Theme.is_active.desc(), Theme.name.asc())
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
            detail={"name": theme.name, "stock_count": len(payload.stocks)},
        )
        return theme

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
