import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DropoffsService } from './dropoffs.service';
import { DropoffsController } from './dropoffs.controller';
import { Dropoff, DropoffSchema } from './schemas/dropoff.schema';
import { CollectorInteraction, CollectorInteractionSchema } from './schemas/collector-interaction.schema';
import { CollectionAttempt, CollectionAttemptSchema } from './schemas/collection-attempt.schema';
import { User, UserSchema } from '../users/schemas/user.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Dropoff.name, schema: DropoffSchema },
      { name: CollectorInteraction.name, schema: CollectorInteractionSchema },
      { name: CollectionAttempt.name, schema: CollectionAttemptSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  controllers: [DropoffsController],
  providers: [DropoffsService],
  exports: [DropoffsService],
})
export class DropoffsModule {} 