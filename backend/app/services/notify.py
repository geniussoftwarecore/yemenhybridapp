"""Notification service coordinator."""
from .email import EmailService
from .whatsapp import WhatsAppService

class NotificationService:
    def __init__(self):
        self.email_service = EmailService()
        self.whatsapp_service = WhatsAppService()
    
    async def send_approval_notification(self, approval_data: dict, recipients: list):
        """Send approval notifications via multiple channels."""
        # TODO: Implement multi-channel notification logic
        pass
    
    async def send_invoice_notification(self, invoice_data: dict, recipients: list):
        """Send invoice notifications via multiple channels."""
        # TODO: Implement invoice notification logic
        pass