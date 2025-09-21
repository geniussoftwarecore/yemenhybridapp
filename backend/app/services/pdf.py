"""PDF generation service."""
import io
from datetime import datetime
from decimal import Decimal
from pathlib import Path
import os

# Import settings
try:
    from ..core.config import settings
except ImportError:
    # Fallback if settings not available
    class Settings:
        storage_dir = "./storage"
    settings = Settings()

from reportlab.lib.pagesizes import A4, letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_RIGHT, TA_LEFT, TA_CENTER
from reportlab.lib.units import inch, cm
from reportlab.lib.colors import black, darkblue, gray
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors

# Import Arabic text processing
try:
    import arabic_reshaper
    from bidi.algorithm import get_display
    ARABIC_SUPPORT = True
except ImportError:
    ARABIC_SUPPORT = False


class PDFService:
    def __init__(self):
        """Initialize PDF service with Arabic font support."""
        self.setup_arabic_fonts()
        
    def setup_arabic_fonts(self):
        """Setup Arabic fonts for PDF generation."""
        try:
            # Try to register a system Arabic font
            # You may need to adjust the path based on your system
            font_paths = [
                '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
                '/System/Library/Fonts/Arial.ttf',  # macOS
                'C:\\Windows\\Fonts\\arial.ttf',  # Windows
                '/usr/share/fonts/TTF/DejaVuSans.ttf',  # Some Linux
            ]
            
            for font_path in font_paths:
                if os.path.exists(font_path):
                    pdfmetrics.registerFont(TTFont('Arabic', font_path))
                    break
            else:
                # Fallback to default font
                print("Warning: No Arabic font found, using default font")
        except Exception as e:
            print(f"Warning: Could not register Arabic font: {e}")
    
    def process_arabic_text(self, text: str) -> str:
        """Process Arabic text for proper RTL display."""
        if not ARABIC_SUPPORT or not text:
            return text
        
        try:
            # Import modules locally to avoid unbound issues
            import arabic_reshaper
            from bidi.algorithm import get_display
            
            # Reshape Arabic text and apply bidi algorithm
            reshaped_text = arabic_reshaper.reshape(text)
            bidi_text = get_display(reshaped_text)
            # Ensure we return a string
            return str(bidi_text) if bidi_text else text
        except Exception as e:
            print(f"Warning: Arabic text processing failed: {e}")
            return text
    
    def get_styles(self):
        """Get paragraph styles for PDF."""
        styles = getSampleStyleSheet()
        
        # Arabic RTL style
        styles.add(ParagraphStyle(
            name='ArabicRTL',
            parent=styles['Normal'],
            fontName='Arabic' if 'Arabic' in pdfmetrics.getRegisteredFontNames() else 'Helvetica',
            fontSize=12,
            alignment=TA_RIGHT,
            wordWrap='LTR'
        ))
        
        # Header style
        styles.add(ParagraphStyle(
            name='Header',
            parent=styles['Heading1'],
            fontSize=18,
            textColor=darkblue,
            alignment=TA_CENTER,
            spaceAfter=20
        ))
        
        # Invoice details style
        styles.add(ParagraphStyle(
            name='InvoiceDetails',
            parent=styles['Normal'],
            fontSize=10,
            alignment=TA_LEFT
        ))
        
        return styles
    
    async def generate_invoice_pdf(self, invoice) -> bytes:
        """Generate PDF for invoice with Arabic support."""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=72, leftMargin=72,
                              topMargin=72, bottomMargin=18)
        
        # Build PDF content
        story = []
        styles = self.get_styles()
        
        # Header with Arabic font
        header_text = "Yemen Hybrid Service Center\nفاتورة خدمة"
        arabic_header_style = ParagraphStyle(
            name='ArabicHeader',
            parent=styles['Header'],
            fontName='Arabic' if 'Arabic' in pdfmetrics.getRegisteredFontNames() else 'Helvetica',
            alignment=TA_CENTER
        )
        story.append(Paragraph(self.process_arabic_text(header_text), arabic_header_style))
        story.append(Spacer(1, 20))
        
        # Invoice information
        invoice_info = [
            ['Invoice ID:', str(invoice.id), 'رقم الفاتورة:', str(invoice.id)],
            ['Date:', invoice.created_at.strftime('%Y-%m-%d'), 'التاريخ:', invoice.created_at.strftime('%Y-%m-%d')],
            ['Work Order:', str(invoice.work_order_id), 'أمر العمل:', str(invoice.work_order_id)]
        ]
        
        if hasattr(invoice, 'work_order') and invoice.work_order:
            if hasattr(invoice.work_order, 'customer') and invoice.work_order.customer:
                customer = invoice.work_order.customer
                invoice_info.extend([
                    ['Customer:', customer.name, 'العميل:', self.process_arabic_text(customer.name)],
                    ['Phone:', customer.phone or '', 'الهاتف:', customer.phone or ''],
                ])
            
            if hasattr(invoice.work_order, 'vehicle') and invoice.work_order.vehicle:
                vehicle = invoice.work_order.vehicle
                invoice_info.extend([
                    ['Vehicle:', f"{vehicle.make} {vehicle.model}", 'المركبة:', self.process_arabic_text(f"{vehicle.make} {vehicle.model}")],
                    ['Plate:', vehicle.plate_number or '', 'اللوحة:', vehicle.plate_number or '']
                ])
        
        # Create table for invoice info with Arabic font
        info_table = Table(invoice_info, colWidths=[2*cm, 4*cm, 2*cm, 4*cm])
        arabic_font = 'Arabic' if 'Arabic' in pdfmetrics.getRegisteredFontNames() else 'Helvetica'
        info_table.setStyle(TableStyle([
            ('FONTNAME', (0, 0), (1, -1), 'Helvetica'),  # English columns
            ('FONTNAME', (2, 0), (3, -1), arabic_font),   # Arabic columns
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('ALIGN', (2, 0), (3, -1), 'RIGHT'),  # Arabic columns right-aligned
        ]))
        
        story.append(info_table)
        story.append(Spacer(1, 20))
        
        # Work order items table
        if hasattr(invoice, 'work_order') and invoice.work_order and hasattr(invoice.work_order, 'items'):
            items_data = [['Item / البند', 'Qty / الكمية', 'Unit Price / سعر الوحدة', 'Total / المجموع']]
            
            for item in invoice.work_order.items:
                item_total = item.qty * item.unit_price
                items_data.append([
                    self.process_arabic_text(item.name),
                    str(item.qty),
                    f"{item.unit_price:.2f}",
                    f"{item_total:.2f}"
                ])
            
            items_table = Table(items_data, colWidths=[6*cm, 2*cm, 3*cm, 3*cm])
            arabic_font = 'Arabic' if 'Arabic' in pdfmetrics.getRegisteredFontNames() else 'Helvetica'
            items_table.setStyle(TableStyle([
                ('FONTNAME', (0, 0), (-1, 0), arabic_font + '-Bold' if arabic_font == 'Arabic' else 'Helvetica-Bold'),
                ('FONTNAME', (0, 1), (-1, -1), arabic_font),
                ('FONTSIZE', (0, 0), (-1, -1), 10),
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ]))
            
            story.append(Paragraph("Work Order Items / بنود أمر العمل", styles['Heading2']))
            story.append(items_table)
            story.append(Spacer(1, 20))
        
        # Financial summary
        financial_data = [
            ['Subtotal / المجموع الفرعي:', f"{invoice.subtotal:.2f}"],
            ['Discount / الخصم:', f"{invoice.discount:.2f}" if invoice.discount else "0.00"],
            ['Tax / الضريبة:', f"{invoice.tax:.2f}" if invoice.tax else "0.00"],
            ['Total / المجموع الإجمالي:', f"{invoice.total:.2f}"],
            ['Paid / المدفوع:', f"{invoice.paid:.2f}" if invoice.paid else "0.00"],
            ['Balance / الرصيد:', f"{(invoice.total - (invoice.paid or Decimal('0.00'))):.2f}"]
        ]
        
        financial_table = Table(financial_data, colWidths=[8*cm, 4*cm])
        financial_table.setStyle(TableStyle([
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 12),
            ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
            ('ALIGN', (1, 0), (1, -1), 'LEFT'),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('BACKGROUND', (0, -2), (-1, -1), colors.lightgrey),  # Highlight total and balance
        ]))
        
        story.append(financial_table)
        story.append(Spacer(1, 30))
        
        # Add workshop logo
        try:
            storage_dir = getattr(settings, 'storage_dir', './storage')
            logo_path = os.path.join(storage_dir, 'logo.png')
            if os.path.exists(logo_path):
                logo = Image(logo_path, width=2*inch, height=1*inch)
                story.insert(0, logo)  # Add logo at top
                story.insert(1, Spacer(1, 10))
        except Exception as e:
            print(f"Warning: Could not load workshop logo: {e}")
        
        # Add after-photos if available with proper image thumbnails
        if hasattr(invoice, 'work_order') and invoice.work_order and hasattr(invoice.work_order, 'media'):
            media_files = [m for m in invoice.work_order.media if m.file_type == 'image']
            if media_files:
                story.append(Paragraph(self.process_arabic_text("Service Photos / صور الخدمة"), styles['ArabicRTL']))
                
                # Create thumbnails table
                thumbnail_data = []
                for i in range(0, len(media_files[:4]), 2):  # Process 2 images per row
                    row = []
                    for j in range(2):
                        if i + j < len(media_files):
                            media = media_files[i + j]
                            try:
                                # Attempt to load and resize image
                                storage_dir = getattr(settings, 'storage_dir', './storage')
                                img_path = os.path.join(storage_dir, media.file_path)
                                if os.path.exists(img_path):
                                    thumbnail = Image(img_path, width=2*inch, height=1.5*inch)
                                    row.append(thumbnail)
                                else:
                                    row.append(Paragraph(f"Image: {media.file_path}", styles['Normal']))
                            except Exception as e:
                                print(f"Warning: Could not load image {media.file_path}: {e}")
                                row.append(Paragraph(f"Image: {media.file_path}", styles['Normal']))
                        else:
                            row.append("")
                    if row:
                        thumbnail_data.append(row)
                
                if thumbnail_data:
                    thumbnail_table = Table(thumbnail_data, colWidths=[6*cm, 6*cm])
                    thumbnail_table.setStyle(TableStyle([
                        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                        ('GRID', (0, 0), (-1, -1), 1, colors.black),
                    ]))
                    story.append(thumbnail_table)
                    story.append(Spacer(1, 20))
        
        # Footer
        story.append(Spacer(1, 50))
        footer_text = "شكراً لثقتكم بنا\nThank you for your business"
        story.append(Paragraph(self.process_arabic_text(footer_text), styles['ArabicRTL']))
        
        # Build PDF
        doc.build(story)
        buffer.seek(0)
        return buffer.getvalue()
    
    async def generate_report_pdf(self, report_data: dict, report_type: str) -> bytes:
        """Generate PDF for reports."""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4)
        
        story = []
        styles = self.get_styles()
        
        # Header
        header_text = f"Yemen Hybrid Service Center\n{report_type} Report"
        story.append(Paragraph(header_text, styles['Header']))
        story.append(Spacer(1, 20))
        
        # Report content (placeholder)
        story.append(Paragraph("Report content will be implemented based on report type", styles['Normal']))
        
        doc.build(story)
        buffer.seek(0)
        return buffer.getvalue()