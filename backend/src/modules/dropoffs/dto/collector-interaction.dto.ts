import { IsString, IsEnum, IsOptional, IsDate, IsObject } from 'class-validator';
import { InteractionType, CancellationReason } from '../schemas/collector-interaction.schema';

export class CreateInteractionDto {
  @IsString()
  collectorId: string;

  @IsString()
  dropoffId: string;

  @IsEnum(InteractionType)
  interactionType: InteractionType;

  @IsOptional()
  @IsEnum(CancellationReason)
  cancellationReason?: CancellationReason;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsObject()
  location?: {
    type: string;
    coordinates: number[];
  };

  @IsOptional()
  @IsDate()
  interactionTime?: Date;

  @IsOptional()
  @IsString()
  dropoffStatus?: string;

  @IsOptional()
  numberOfItems?: number;

  @IsOptional()
  @IsString()
  bottleType?: string;
}

export class GetCollectorStatsDto {
  @IsString()
  collectorId: string;

  @IsOptional()
  @IsString()
  timeRange?: string;
}

export class GetCollectorHistoryDto {
  @IsString()
  collectorId: string;

  @IsOptional()
  @IsString()
  page?: string;

  @IsOptional()
  @IsString()
  limit?: string;
}

