"""Audit logging service."""
from sqlalchemy.ext.asyncio import AsyncSession
from ..db.models.audit_log import AuditLog
from ..db.models import User


async def log_action(
    db: AsyncSession,
    user: User,
    action: str,
    entity: str,
    entity_id: int,
    attachment_url: str = None
):
    """Log an action to the audit log."""
    audit_entry = AuditLog(
        actor_id=user.id,
        action=action,
        entity=entity,
        entity_id=entity_id,
        attachment_url=attachment_url
    )
    db.add(audit_entry)
    await db.flush()  # Don't commit, let the calling function handle that
    return audit_entry