import {
  Controller,
  Get,
  Param,
  Res,
  UseGuards,
  NotFoundException,
} from '@nestjs/common';
import { Response } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/schemas/user.schema';
import { ShippingLabelService } from './shipping-label.service';
import { RewardsService } from '../rewards/rewards.service';

@Controller('admin/shipping')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
export class ShippingController {
  constructor(
    private readonly shippingLabelService: ShippingLabelService,
    private readonly rewardsService: RewardsService,
  ) {}

  /**
   * Generate and download DHL shipping label for a redemption
   * GET /admin/shipping/label/:redemptionId
   */
  @Get('label/:redemptionId')
  async generateShippingLabel(
    @Param('redemptionId') redemptionId: string,
    @Res() res: Response,
  ) {
    try {
      // Get redemption details
      const redemption = await this.rewardsService.getRedemptionById(redemptionId);
      
      if (!redemption) {
        throw new NotFoundException('Redemption not found');
      }

      if (redemption.status !== 'approved') {
        throw new NotFoundException('Only approved orders can generate shipping labels');
      }

      // Prepare shipping label data
      const shippingData = {
        trackingNumber: redemption.trackingNumber || this.shippingLabelService.generateTrackingNumber(),
        senderAddress: this.shippingLabelService.SENDER_ADDRESS,
        recipientAddress: redemption.deliveryAddress,
        orderId: redemptionId,
        itemName: redemption.rewardItemName,
        weight: '0.5 kg', // Default weight, can be made configurable
        serviceType: 'Express Worldwide',
      };

      // Generate PDF
      const pdfBuffer = await this.shippingLabelService.generateDHLShippingLabel(shippingData);

      // Set response headers for PDF download
      res.set({
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="DHL_Shipping_Label_${redemption.trackingNumber || shippingData.trackingNumber}.pdf"`,
        'Content-Length': pdfBuffer.length.toString(),
      });

      // Send PDF
      res.send(pdfBuffer);

    } catch (error) {
      console.error('Error generating shipping label:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to generate shipping label',
        error: error.message,
      });
    }
  }
}
