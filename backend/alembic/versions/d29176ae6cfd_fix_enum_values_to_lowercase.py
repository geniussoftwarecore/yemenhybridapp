"""Fix enum values to lowercase

Revision ID: d29176ae6cfd
Revises: 119cdc1d4872
Create Date: 2025-09-19 22:36:47.308681

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd29176ae6cfd'
down_revision: Union[str, Sequence[str], None] = '119cdc1d4872'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Fix enum values to lowercase."""
    # Fix UserRole enum
    op.execute("ALTER TYPE userrole RENAME VALUE 'ENGINEER' TO 'engineer'")
    op.execute("ALTER TYPE userrole RENAME VALUE 'SALES' TO 'sales'")
    op.execute("ALTER TYPE userrole RENAME VALUE 'ADMIN' TO 'admin'")
    
    # Fix WorkOrderStatus enum
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'NEW' TO 'new'")
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'AWAITING_APPROVAL' TO 'awaiting_approval'")
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'READY_TO_START' TO 'ready_to_start'")
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'IN_PROGRESS' TO 'in_progress'")
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'DONE' TO 'done'")
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'CLOSED' TO 'closed'")
    
    # Fix ItemType enum
    op.execute("ALTER TYPE itemtype RENAME VALUE 'PART' TO 'part'")
    op.execute("ALTER TYPE itemtype RENAME VALUE 'LABOR' TO 'labor'")
    
    # Fix MediaPhase enum  
    op.execute("ALTER TYPE mediaphase RENAME VALUE 'BEFORE' TO 'before'")
    op.execute("ALTER TYPE mediaphase RENAME VALUE 'DURING' TO 'during'")
    op.execute("ALTER TYPE mediaphase RENAME VALUE 'AFTER' TO 'after'")


def downgrade() -> None:
    """Reverse enum value changes."""
    # Reverse UserRole enum
    op.execute("ALTER TYPE userrole RENAME VALUE 'engineer' TO 'ENGINEER'")
    op.execute("ALTER TYPE userrole RENAME VALUE 'sales' TO 'SALES'")
    op.execute("ALTER TYPE userrole RENAME VALUE 'admin' TO 'ADMIN'")
    
    # Reverse WorkOrderStatus enum
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'new' TO 'NEW'")
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'awaiting_approval' TO 'AWAITING_APPROVAL'")
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'ready_to_start' TO 'READY_TO_START'")
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'in_progress' TO 'IN_PROGRESS'")
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'done' TO 'DONE'")
    op.execute("ALTER TYPE workorderstatus RENAME VALUE 'closed' TO 'CLOSED'")
    
    # Reverse ItemType enum
    op.execute("ALTER TYPE itemtype RENAME VALUE 'part' TO 'PART'")
    op.execute("ALTER TYPE itemtype RENAME VALUE 'labor' TO 'LABOR'")
    
    # Reverse MediaPhase enum
    op.execute("ALTER TYPE mediaphase RENAME VALUE 'before' TO 'BEFORE'")
    op.execute("ALTER TYPE mediaphase RENAME VALUE 'during' TO 'DURING'")
    op.execute("ALTER TYPE mediaphase RENAME VALUE 'after' TO 'AFTER'")
