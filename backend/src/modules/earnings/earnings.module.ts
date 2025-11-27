import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { EarningsSession, EarningsSessionSchema } from './schemas/earnings-session.schema';
import { CollectionAttempt, CollectionAttemptSchema } from '../dropoffs/schemas/collection-attempt.schema';
import { EarningsSessionService } from './earnings-session.service';
import { EarningsController } from './earnings.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: EarningsSession.name, schema: EarningsSessionSchema },
      { name: CollectionAttempt.name, schema: CollectionAttemptSchema },
    ]),
  ],
  controllers: [EarningsController],
  providers: [EarningsSessionService],
  exports: [EarningsSessionService],
})
export class EarningsModule {}

