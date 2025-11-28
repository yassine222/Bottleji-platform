import { IsString, IsNumber, IsEnum, IsObject, IsOptional, Min, IsNotEmpty, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class DeliveryAddressDto {
  @IsString()
  @IsNotEmpty()
  street: string;

  @IsString()
  @IsNotEmpty()
  city: string;

  @IsString()
  @IsNotEmpty()
  state: string;

  @IsString()
  @IsNotEmpty()
  zipCode: string;

  @IsString()
  @IsOptional()
  country?: string;

  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @IsString()
  @IsOptional()
  additionalNotes?: string;
}

export class CreateRedemptionDto {
  @IsString()
  @IsNotEmpty()
  userId: string;

  @IsString()
  @IsNotEmpty()
  rewardItemId: string;

  @IsNumber()
  @Min(0)
  pointsSpent: number;

  @ValidateNested()
  @Type(() => DeliveryAddressDto)
  @IsObject()
  deliveryAddress: DeliveryAddressDto;

  @IsString()
  @IsOptional()
  selectedSize?: string;

  @IsString()
  @IsOptional()
  sizeType?: string;
}

export class UpdateRedemptionStatusDto {
  @IsEnum(['pending', 'approved', 'processing', 'shipped', 'delivered', 'cancelled', 'rejected'])
  status: string;

  @IsString()
  @IsOptional()
  adminNotes?: string;

  @IsString()
  @IsOptional()
  rejectionReason?: string;

  @IsString()
  @IsOptional()
  trackingNumber?: string;

  @IsOptional()
  estimatedDelivery?: Date;
}
