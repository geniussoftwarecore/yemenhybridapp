"""Notification service coordinator."""
import logging
import asyncio
from typing import List, Optional
from abc import ABC, abstractmethod

from ..core.config import settings

logger = logging.getLogger(__name__)

# Abstract base classes
class EmailDriver(ABC):
    @abstractmethod
    async def send_email(self, to: str, subject: str, html: str) -> bool:
        pass

class WhatsAppDriver(ABC):
    @abstractmethod
    async def send_whatsapp(self, to: str, text: str, media_urls: List[str] = None) -> bool:
        pass

# Console drivers for development
class ConsoleEmailDriver(EmailDriver):
    async def send_email(self, to: str, subject: str, html: str) -> bool:
        logger.info(f"📧 [CONSOLE EMAIL] To: {to}")
        logger.info(f"📧 [CONSOLE EMAIL] Subject: {subject}")
        logger.info(f"📧 [CONSOLE EMAIL] HTML Body:\n{html}")
        logger.info("📧 [CONSOLE EMAIL] Email sent successfully (console mode)")
        return True

class ConsoleWhatsAppDriver(WhatsAppDriver):
    async def send_whatsapp(self, to: str, text: str, media_urls: List[str] = None) -> bool:
        logger.info(f"📱 [CONSOLE WHATSAPP] To: {to}")
        logger.info(f"📱 [CONSOLE WHATSAPP] Text: {text}")
        if media_urls:
            logger.info(f"📱 [CONSOLE WHATSAPP] Media URLs: {media_urls}")
        logger.info("📱 [CONSOLE WHATSAPP] Message sent successfully (console mode)")
        return True

# Real drivers for production
class SMTPEmailDriver(EmailDriver):
    def __init__(self):
        self.smtp_host = settings.smtp_host
        self.smtp_port = settings.smtp_port
        self.smtp_user = settings.smtp_user
        self.smtp_pass = settings.smtp_pass
    
    async def send_email(self, to: str, subject: str, html: str) -> bool:
        try:
            def _send_smtp():
                import smtplib
                from email.mime.text import MIMEText
                from email.mime.multipart import MIMEMultipart
                
                msg = MIMEMultipart('alternative')
                msg['Subject'] = subject
                msg['From'] = self.smtp_user
                msg['To'] = to
                
                html_part = MIMEText(html, 'html')
                msg.attach(html_part)
                
                with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                    server.starttls()
                    server.login(self.smtp_user, self.smtp_pass)
                    server.send_message(msg)
            
            # Run SMTP in thread pool to avoid blocking event loop
            await asyncio.get_event_loop().run_in_executor(None, _send_smtp)
            
            logger.info(f"📧 Email sent successfully to {to}")
            return True
        except Exception as e:
            logger.error(f"📧 Failed to send email to {to}: {str(e)}")
            return False

class TwilioWhatsAppDriver(WhatsAppDriver):
    def __init__(self):
        self.account_sid = settings.whatsapp_sid
        self.auth_token = settings.whatsapp_token
        self.from_number = settings.whatsapp_from
    
    async def send_whatsapp(self, to: str, text: str, media_urls: List[str] = None) -> bool:
        try:
            def _send_twilio():
                from twilio.rest import Client
                
                client = Client(self.account_sid, self.auth_token)
                
                message_params = {
                    'from_': f'whatsapp:{self.from_number}',
                    'to': f'whatsapp:{to}',
                    'body': text
                }
                
                if media_urls:
                    message_params['media_url'] = media_urls
                
                message = client.messages.create(**message_params)
                return message.sid
            
            # Run Twilio in thread pool to avoid blocking event loop
            message_sid = await asyncio.get_event_loop().run_in_executor(None, _send_twilio)
            
            logger.info(f"📱 WhatsApp message sent successfully to {to}, SID: {message_sid}")
            return True
        except Exception as e:
            logger.error(f"📱 Failed to send WhatsApp message to {to}: {str(e)}")
            return False

# Main notification service
class NotificationService:
    def __init__(self):
        # Initialize email driver
        if self._is_production() and self._has_smtp_credentials():
            self.email_driver = SMTPEmailDriver()
            logger.info("📧 Using SMTP email driver (production)")
        else:
            self.email_driver = ConsoleEmailDriver()
            if not self._is_production():
                logger.info("📧 Using console email driver (development environment)")
            else:
                logger.info("📧 Using console email driver (no SMTP credentials)")
        
        # Initialize WhatsApp driver
        if self._is_production() and self._has_whatsapp_credentials():
            self.whatsapp_driver = TwilioWhatsAppDriver()
            logger.info("📱 Using Twilio WhatsApp driver (production)")
        else:
            self.whatsapp_driver = ConsoleWhatsAppDriver()
            if not self._is_production():
                logger.info("📱 Using console WhatsApp driver (development environment)")
            else:
                logger.info("📱 Using console WhatsApp driver (no Twilio credentials)")
    
    def _has_smtp_credentials(self) -> bool:
        return all([
            settings.smtp_host,
            settings.smtp_user,
            settings.smtp_pass
        ])
    
    def _has_whatsapp_credentials(self) -> bool:
        return all([
            settings.whatsapp_sid,
            settings.whatsapp_token,
            settings.whatsapp_from
        ])
    
    def _is_production(self) -> bool:
        """Check if we're in production environment."""
        env = getattr(settings, 'environment', 'development').lower()
        return env in ('production', 'prod')
    
    async def send_email(self, to: str, subject: str, html: str) -> bool:
        """Send email notification."""
        return await self.email_driver.send_email(to, subject, html)
    
    async def send_whatsapp(self, to: str, text: str, media_urls: List[str] = None) -> bool:
        """Send WhatsApp notification."""
        if media_urls is None:
            media_urls = []
        return await self.whatsapp_driver.send_whatsapp(to, text, media_urls)

# Singleton instance
notify = NotificationService()