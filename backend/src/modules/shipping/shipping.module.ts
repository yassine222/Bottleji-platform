import { Module } from '@nestjs/common';
import { ShippingLabelService } from './shipping-label.service';
import { ShippingController } from './shipping.controller';
import { RewardsModule } from '../rewards/rewards.module';

@Module({
  imports: [RewardsModule],
  providers: [ShippingLabelService],
  controllers: [ShippingController],
  exports: [ShippingLabelService],
})
export class ShippingModule {}
