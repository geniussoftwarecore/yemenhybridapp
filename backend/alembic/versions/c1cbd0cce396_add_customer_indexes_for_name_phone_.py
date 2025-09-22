"""add customer indexes for name phone email

Revision ID: c1cbd0cce396
Revises: ef1b32bad0ad
Create Date: 2025-09-22 22:10:51.230639

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c1cbd0cce396'
down_revision: Union[str, Sequence[str], None] = 'ef1b32bad0ad'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_index('ix_customers_name', 'customers', ['name'], unique=False)
    op.create_index('ix_customers_phone', 'customers', ['phone'], unique=False)
    op.create_index('ix_customers_email', 'customers', ['email'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index('ix_customers_email', table_name='customers')
    op.drop_index('ix_customers_phone', table_name='customers')
    op.drop_index('ix_customers_name', table_name='customers')
