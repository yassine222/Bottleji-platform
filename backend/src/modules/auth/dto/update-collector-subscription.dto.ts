import { IsString, IsIn } from 'class-validator';

export class UpdateCollectorSubscriptionDto {
  @IsString()
  @IsIn(['basic', 'premium'])
  collectorSubscriptionType: string;
}
