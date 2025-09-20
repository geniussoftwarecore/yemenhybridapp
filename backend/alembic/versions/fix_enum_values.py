"""fix approval channel enum values

Revision ID: fix_enum_values
Revises: cfa521bd4f28
Create Date: 2025-09-20 23:37:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fix_enum_values'
down_revision: Union[str, Sequence[str], None] = 'cfa521bd4f28'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Fix enum values to lowercase."""
    # First, add the lowercase values to the enum
    op.execute("ALTER TYPE approvalchannel ADD VALUE 'email'")
    op.execute("ALTER TYPE approvalchannel ADD VALUE 'whatsapp'")
    
    # Update any existing rows (if any) to use lowercase
    op.execute("UPDATE approval_requests SET sent_via = 'email' WHERE sent_via = 'EMAIL'")
    op.execute("UPDATE approval_requests SET sent_via = 'whatsapp' WHERE sent_via = 'WHATSAPP'")


def downgrade() -> None:
    """Revert enum values to uppercase."""
    # Update rows back to uppercase
    op.execute("UPDATE approval_requests SET sent_via = 'EMAIL' WHERE sent_via = 'email'")
    op.execute("UPDATE approval_requests SET sent_via = 'WHATSAPP' WHERE sent_via = 'whatsapp'")