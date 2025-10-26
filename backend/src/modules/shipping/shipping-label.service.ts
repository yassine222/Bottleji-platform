import { Injectable } from '@nestjs/common';
import * as PDFDocument from 'pdfkit';
import * as QRCode from 'qrcode';

export interface ShippingAddress {
  street: string;
  city: string;
  state: string;
  zipCode: string;
  country: string;
  phoneNumber: string;
  additionalNotes?: string;
}

export interface ShippingLabelData {
  trackingNumber: string;
  senderAddress: ShippingAddress;
  recipientAddress: ShippingAddress;
  orderId: string;
  itemName: string;
  weight?: string;
  serviceType?: string;
}

@Injectable()
export class ShippingLabelService {
  public readonly SENDER_ADDRESS: ShippingAddress = {
    street: '123 Business Street',
    city: 'Tunis',
    state: 'Tunis',
    zipCode: '1000',
    country: 'Tunisia',
    phoneNumber: '+216 71 123 456',
    additionalNotes: 'Botleji Headquarters'
  };

  /**
   * Generate DHL shipping label PDF
   */
  async generateDHLShippingLabel(data: ShippingLabelData): Promise<Buffer> {
    const doc = new PDFDocument({
      size: [612, 792], // Letter size
      margins: {
        top: 20,
        bottom: 20,
        left: 20,
        right: 20
      }
    });

    const buffers: Buffer[] = [];
    doc.on('data', buffers.push.bind(buffers));
    
    return new Promise((resolve, reject) => {
      doc.on('end', () => {
        const pdfBuffer = Buffer.concat(buffers);
        resolve(pdfBuffer);
      });

      try {
        this.drawDHLHeader(doc);
        this.drawSenderInfo(doc, data.senderAddress);
        this.drawRecipientInfo(doc, data.recipientAddress);
        this.drawTrackingInfo(doc, data.trackingNumber);
        this.drawOrderInfo(doc, data);
        this.drawQRCode(doc, data.trackingNumber);
        this.drawDHLFooter(doc);
        
        doc.end();
      } catch (error) {
        reject(error);
      }
    });
  }

  private drawDHLHeader(doc: PDFKit.PDFDocument) {
    // DHL Logo area (simulated)
    doc.rect(20, 20, 572, 60)
       .fillColor('#D40511')
       .fill();

    doc.fillColor('white')
       .fontSize(24)
       .font('Helvetica-Bold')
       .text('DHL', 30, 35);

    doc.fontSize(12)
       .text('EXPRESS WORLDWIDE', 80, 40);

    doc.fontSize(10)
       .text('Shipping Label', 80, 55);

    // Service type
    doc.fillColor('black')
       .fontSize(14)
       .font('Helvetica-Bold')
       .text('EXPRESS WORLDWIDE', 400, 35);

    doc.fontSize(10)
       .text('Service Type', 400, 50);
  }

  private drawSenderInfo(doc: PDFKit.PDFDocument, senderAddress: ShippingAddress) {
    const startY = 100;
    
    doc.fillColor('black')
       .fontSize(12)
       .font('Helvetica-Bold')
       .text('FROM:', 20, startY);

    doc.fontSize(10)
       .font('Helvetica')
       .text('Botleji', 20, startY + 20)
       .text(senderAddress.street, 20, startY + 35)
       .text(`${senderAddress.city}, ${senderAddress.state} ${senderAddress.zipCode}`, 20, startY + 50)
       .text(senderAddress.country, 20, startY + 65)
       .text(`Tel: ${senderAddress.phoneNumber}`, 20, startY + 80);

    if (senderAddress.additionalNotes) {
      doc.text(senderAddress.additionalNotes, 20, startY + 95);
    }
  }

  private drawRecipientInfo(doc: PDFKit.PDFDocument, recipientAddress: ShippingAddress) {
    const startY = 100;
    
    doc.fillColor('black')
       .fontSize(12)
       .font('Helvetica-Bold')
       .text('TO:', 300, startY);

    doc.fontSize(10)
       .font('Helvetica')
       .text(recipientAddress.street, 300, startY + 20)
       .text(`${recipientAddress.city}, ${recipientAddress.state} ${recipientAddress.zipCode}`, 300, startY + 35)
       .text(recipientAddress.country, 300, startY + 50)
       .text(`Tel: ${recipientAddress.phoneNumber}`, 300, startY + 65);

    if (recipientAddress.additionalNotes) {
      doc.text(recipientAddress.additionalNotes, 300, startY + 80);
    }
  }

  private drawTrackingInfo(doc: PDFKit.PDFDocument, trackingNumber: string) {
    const startY = 220;
    
    // Tracking number box
    doc.rect(20, startY, 572, 40)
       .stroke();

    doc.fillColor('black')
       .fontSize(16)
       .font('Helvetica-Bold')
       .text('TRACKING NUMBER:', 30, startY + 10);

    doc.fontSize(20)
       .font('Courier-Bold')
       .text(trackingNumber, 30, startY + 25);

    // Barcode area (simulated)
    doc.rect(400, startY + 5, 180, 30)
       .stroke();

    doc.fontSize(8)
       .font('Helvetica')
       .text('BARCODE', 450, startY + 15);
  }

  private drawOrderInfo(doc: PDFKit.PDFDocument, data: ShippingLabelData) {
    const startY = 280;
    
    doc.fillColor('black')
       .fontSize(12)
       .font('Helvetica-Bold')
       .text('ORDER INFORMATION:', 20, startY);

    doc.fontSize(10)
       .font('Helvetica')
       .text(`Order ID: ${data.orderId}`, 20, startY + 20)
       .text(`Item: ${data.itemName}`, 20, startY + 35)
       .text(`Weight: ${data.weight || '0.5 kg'}`, 20, startY + 50)
       .text(`Service: ${data.serviceType || 'Express Worldwide'}`, 20, startY + 65);
  }

  private async drawQRCode(doc: PDFKit.PDFDocument, trackingNumber: string) {
    try {
      const qrCodeDataURL = await QRCode.toDataURL(trackingNumber, {
        width: 100,
        margin: 1,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        }
      });

      // Convert data URL to buffer
      const base64Data = qrCodeDataURL.replace(/^data:image\/png;base64,/, '');
      const imageBuffer = Buffer.from(base64Data, 'base64');

      doc.image(imageBuffer, 450, 300, { width: 100, height: 100 });
      
      doc.fontSize(8)
         .font('Helvetica')
         .text('SCAN FOR TRACKING', 450, 410);
    } catch (error) {
      console.error('Error generating QR code:', error);
      // Fallback text if QR code fails
      doc.fontSize(10)
         .font('Helvetica')
         .text('QR Code Error', 450, 350);
    }
  }

  private drawDHLFooter(doc: PDFKit.PDFDocument) {
    const startY = 450;
    
    // Footer line
    doc.moveTo(20, startY)
       .lineTo(592, startY)
       .stroke();

    doc.fillColor('black')
       .fontSize(8)
       .font('Helvetica')
       .text('DHL Express Worldwide - Delivered by DHL', 20, startY + 10)
       .text('For tracking visit: www.dhl.com', 20, startY + 25)
       .text('Customer Service: +1-800-CALL-DHL', 300, startY + 10)
       .text('Generated by Botleji System', 300, startY + 25);

    // Terms and conditions
    doc.fontSize(6)
       .text('Terms and conditions apply. Subject to DHL Express Terms and Conditions.', 20, startY + 45)
       .text('This label is valid for 30 days from generation date.', 20, startY + 55);
  }

  /**
   * Generate tracking number in DHL format
   */
  generateTrackingNumber(): string {
    const prefix = 'TRK';
    const timestamp = Date.now().toString().slice(-8);
    const random = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `${prefix}${timestamp}${random}`;
  }
}
