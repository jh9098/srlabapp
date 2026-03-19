import json

from sqlalchemy.orm import Session

from app.models.admin_audit_log import AdminAuditLog


class AuditLogService:
    def __init__(self, db: Session) -> None:
        self.db = db

    def log(
        self,
        *,
        actor_identifier: str,
        action: str,
        entity_type: str,
        entity_id: str,
        memo: str | None = None,
        detail: dict | None = None,
    ) -> AdminAuditLog:
        entry = AdminAuditLog(
            actor_identifier=actor_identifier,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            memo=memo,
            detail_json=json.dumps(detail, ensure_ascii=False) if detail else None,
        )
        self.db.add(entry)
        self.db.flush()
        return entry
