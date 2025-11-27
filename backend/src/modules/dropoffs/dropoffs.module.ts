import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DropoffsService } from './dropoffs.service';
import { DropoffsController } from './dropoffs.controller';
import { Dropoff, DropoffSchema } from './schemas/dropoff.schema';
import { CollectorInteraction, CollectorInteractionSchema } from './schemas/collector-interaction.schema';
import { CollectionAttempt, CollectionAttemptSchema } from './schemas/collection-attempt.schema';
import { DropReport, DropReportSchema } from './schemas/drop-report.schema';
import { User, UserSchema } from '../users/schemas/user.schema';
import { NotificationsModule } from '../notifications/notifications.module';
import { RewardsModule } from '../rewards/rewards.module';
import { EarningsModule } from '../earnings/earnings.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Dropoff.name, schema: DropoffSchema },
      { name: CollectorInteraction.name, schema: CollectorInteractionSchema },
      { name: CollectionAttempt.name, schema: CollectionAttemptSchema },
      { name: DropReport.name, schema: DropReportSchema },
      { name: User.name, schema: UserSchema },
    ]),
    forwardRef(() => NotificationsModule),
    RewardsModule,
    forwardRef(() => EarningsModule),
  ],
  controllers: [DropoffsController],
  providers: [DropoffsService],
  exports: [DropoffsService],
})
export class DropoffsModule {} 