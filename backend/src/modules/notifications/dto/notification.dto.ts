import { IsEnum, IsString, IsOptional, IsObject, IsArray, IsBoolean, IsDateString, IsNumber } from 'class-validator';
import { Transform } from 'class-transformer';
import { NotificationType, NotificationPriority } from '../schemas/notification.schema';

export class CreateNotificationDto {
  @IsString()
  userId: string;

  @IsEnum(NotificationType)
  type: NotificationType;

  @IsString()
  title: string;

  @IsString()
  message: string;

  @IsOptional()
  @IsEnum(NotificationPriority)
  priority?: NotificationPriority;

  @IsOptional()
  @IsObject()
  data?: {
    orderId?: string;
    pointsAmount?: number;
    trackingNumber?: string;
    rejectionReason?: string;
    [key: string]: any;
  };

  @IsOptional()
  @IsArray()
  actions?: Array<{
    label: string;
    action: string;
    url?: string;
  }>;

  @IsOptional()
  @IsDateString()
  expiresAt?: Date;
}

export class UpdateNotificationDto {
  @IsOptional()
  @IsBoolean()
  isRead?: boolean;

  @IsOptional()
  @IsDateString()
  readAt?: Date;
}

export class NotificationFiltersDto {
  @IsOptional()
  @IsEnum(NotificationType)
  type?: NotificationType;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === 'true') return true;
    if (value === 'false') return false;
    return value;
  })
  @IsBoolean()
  isRead?: boolean;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') return 1;
    return parseInt(value);
  })
  @IsNumber()
  page?: number = 1;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') return 20;
    return parseInt(value);
  })
  @IsNumber()
  limit?: number = 20;
}
