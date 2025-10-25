import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { RewardsService } from './rewards.service';
import { RewardsController } from './rewards.controller';
import { UserRewardsController } from './user-rewards.controller';
import { User, UserSchema } from '../users/schemas/user.schema';
import { RewardItem, RewardItemSchema } from './schemas/reward-item.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: RewardItem.name, schema: RewardItemSchema },
    ]),
  ],
  providers: [RewardsService],
  controllers: [RewardsController, UserRewardsController],
  exports: [RewardsService],
})
export class RewardsModule {}
